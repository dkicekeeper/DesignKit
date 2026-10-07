//
//  GalleryVoice.swift
//  DesignKit Gallery
//
//  A voice level for the voice effects' pages (VoiceWave, EdgeGlow): a fixed value, a made-up
//  voice, or the microphone. The microphone's samples only become a level; nothing is
//  recorded or kept. The apps measure their own level (Tenra: its SilenceDetector's RMS).
//

import SwiftUI
import AVFoundation
import Observation

/// Where a voice page's level comes from.
enum VoiceSourceKind: Hashable {
    case fixed, simulated, microphone
}

/// The microphone's level, 0…1, while it runs.
@MainActor @Observable
final class GalleryMicrophone {
    private(set) var level: Double = 0
    private(set) var isRunning = false
    private(set) var isDenied = false
    @ObservationIgnored private let engine = AVAudioEngine()

    func start() async {
        guard !isRunning else { return }
        guard await AVAudioApplication.requestRecordPermission() else {
            isDenied = true
            return
        }
        isDenied = false
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
                // On the audio thread: only the number crosses to the main actor.
                let level = GalleryMicrophone.level(of: buffer)
                Task { @MainActor [weak self] in self?.level = level }
            }
            try engine.start()
            isRunning = true
        } catch {
            stop()
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
        level = 0
    }

    /// RMS in decibels, −50 dB (a quiet room) … −10 dB (a voice close by) → 0…1.
    nonisolated static func level(of buffer: AVAudioPCMBuffer) -> Double {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<count { sum += samples[index] * samples[index] }
        let decibels = 20 * log10(max(sqrt(sum / Float(count)), 1e-7))
        return Double(min(max((decibels + 50) / 40, 0), 1))
    }
}

/// A made-up voice: about five syllables a second, in phrases of two seconds with pauses.
enum SpeechSimulator {
    static func level(at time: Double) -> Double {
        let phrase = time.truncatingRemainder(dividingBy: 3.2)
        guard phrase < 2.2 else { return 0.03 }
        let syllable = max(0, sin(time * 2 * .pi * 4.7))
        let stress = 0.55 + 0.45 * sin(time * 1.9 + 1)
        return min(1, 0.15 + 0.85 * syllable * stress)
    }
}

/// Feeds `content` a level from `kind`.
struct VoiceLevelSource<Content: View>: View {
    let kind: VoiceSourceKind
    let fixed: Double
    let microphone: GalleryMicrophone
    @ViewBuilder let content: (Double) -> Content

    var body: some View {
        switch kind {
        case .simulated:
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                content(SpeechSimulator.level(at: timeline.date.timeIntervalSinceReferenceDate))
            }
        case .microphone:
            content(microphone.level)
        case .fixed:
            content(fixed)
        }
    }
}
