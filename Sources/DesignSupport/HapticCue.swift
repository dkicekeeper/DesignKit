//
//  HapticCue.swift
//  DesignKit
//
//  Haptics named by what they mean (2.3.0), to pair with motion: the touch and the picture
//  should say the same thing at the same moment (HIG: Playing haptics — "use haptics
//  consistently", "complement other feedback"). Seven cues, each a `SensoryFeedback`:
//
//  • tap       — a light press that does something small
//  • select    — a choice moved (a segment, a chip, a picker)
//  • tick      — a step or a detent passed (a stepped slider, an edge)
//  • confirm   — it worked (success)
//  • warn      — careful (warning)
//  • fail      — it did not work (error)
//  • celebrate — success, then two rising taps: a goal reached (`.celebration` plays it)
//
//  Haptics are not motion: Reduce Motion and `.designKitMotion(false)` leave them on; the
//  system's own haptics switch turns them off.
//

import SwiftUI
import UIKit

/// A haptic named by its meaning.
public enum HapticCue: Hashable, Sendable {
    case tap, select, tick, confirm, warn, fail, celebrate

    /// The first (or only) beat.
    public var feedback: SensoryFeedback {
        switch self {
        case .tap: .impact(weight: .light)
        case .select: .selection
        case .tick: .impact(flexibility: .rigid, intensity: HapticCueMetrics.tickIntensity)
        case .confirm, .celebrate: .success
        case .warn: .warning
        case .fail: .error
        }
    }
}

enum HapticCueMetrics {
    static let tickIntensity: Double = 0.7
    /// After the success beat of `.celebrate`: when the two rising taps play, and how strong.
    static let celebrationBeats: [(delay: Double, intensity: Double)] = [(0.18, 0.55), (0.32, 0.85)]
}

public extension View {
    /// Plays `cue` each time `trigger` changes (and `condition`, when given, allows it).
    ///
    /// ```swift
    /// Picker(…).hapticCue(.select, trigger: selection)
    /// ProgressRing(…).hapticCue(.confirm, trigger: isDone) { _, done in done }
    /// ```
    func hapticCue<T: Equatable>(
        _ cue: HapticCue,
        trigger: T,
        condition: ((_ oldValue: T, _ newValue: T) -> Bool)? = nil
    ) -> some View {
        modifier(HapticCueModifier(cue: cue, trigger: trigger, condition: condition))
    }
}

public extension HapticManager {
    /// Plays `cue` now, from an action (a button's closure).
    static func play(_ cue: HapticCue) {
        switch cue {
        case .tap: light()
        case .select: selection()
        case .tick: UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: HapticCueMetrics.tickIntensity)
        case .confirm: success()
        case .warn: warning()
        case .fail: error()
        case .celebrate:
            success()
            for beat in HapticCueMetrics.celebrationBeats {
                DispatchQueue.main.asyncAfter(deadline: .now() + beat.delay) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: beat.intensity)
                }
            }
        }
    }
}

struct HapticCueModifier<T: Equatable>: ViewModifier {
    let cue: HapticCue
    let trigger: T
    let condition: ((T, T) -> Bool)?

    /// The rising taps of `.celebrate`, counted; each new value plays the next one.
    @State private var beats = 0

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(trigger: trigger) { old, new in
                guard condition?(old, new) ?? true else { return nil }
                return cue.feedback
            }
            .sensoryFeedback(trigger: beats) { _, new in
                guard new > 0 else { return nil }
                let beat = HapticCueMetrics.celebrationBeats[(new - 1) % HapticCueMetrics.celebrationBeats.count]
                return .impact(weight: .medium, intensity: beat.intensity)
            }
            .onChange(of: trigger) { old, new in
                guard cue == .celebrate, condition?(old, new) ?? true else { return }
                Task { @MainActor in
                    var elapsed = 0.0
                    for beat in HapticCueMetrics.celebrationBeats {
                        try? await Task.sleep(for: .seconds(beat.delay - elapsed))
                        elapsed = beat.delay
                        beats += 1
                    }
                }
            }
    }
}
