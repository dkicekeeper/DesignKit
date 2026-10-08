//
//  EdgeGlow.swift
//  DesignKit
//
//  Light along the edges of the screen while the app listens or thinks (2.4.0; it replaces
//  SiriGlow and SiriWave): colours of the aurora flow around the rim, the band breathes in
//  width, and a voice level makes it wider, brighter and faster. (HIG: Apple Intelligence's
//  edge light; the screen shows it is listening.)
//
//  One Metal colour effect (Shaders/EdgeGlow.metal): a pass per pixel, no blur, at 30 fps
//  while motion is allowed (AmbientMotionGate, `.designKitMotion`). Otherwise it is one still
//  frame whose brightness still follows the level. The level is smoothed here: it rises fast
//  and falls slowly, so speech reads as a swell, not a flicker.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A glow along the edges of the view, for the screen while the app listens.
///
/// ```swift
/// ZStack {
///     EdgeGlow(level: voice.level).ignoresSafeArea()
///     VoiceInputContent()
/// }
/// ```
///
/// It fades in as it appears, passes every touch through, and is hidden from VoiceOver.
public struct EdgeGlow: View {
    let level: Double?
    let colors: [Color]
    let cornerRadius: CGFloat
    let thickness: CGFloat

    @Environment(\.designKitMotion) private var designKitMotion
    @State private var driver = VoiceLevelDriver()
    @State private var isVisible = false

    /// - Parameters:
    ///   - level: The voice level, 0…1 (from the microphone's RMS, say). `nil` breathes on its
    ///     own, as SiriGlow did.
    ///   - colors: The colours flowing round the rim; by default the accent's aurora palette.
    ///   - cornerRadius: The corner of the surface; by default about an iPhone screen's.
    ///   - thickness: How deep the soft light reaches in, before the voice widens it.
    public init(
        level: Double? = nil,
        colors: [Color]? = nil,
        cornerRadius: CGFloat = EdgeGlowMetrics.screenCornerRadius,
        thickness: CGFloat = EdgeGlowMetrics.thickness
    ) {
        self.level = level.map { min(max($0, 0), 1) }
        let given = colors ?? []
        self.colors = given.isEmpty ? VoiceWave.defaultColors : given
        self.cornerRadius = cornerRadius
        self.thickness = thickness
    }

    public var body: some View {
        Group {
            if let library = DesignKitShaders.library {
                AmbientMotionGate { allowsAmbientMotion in
                    if allowsAmbientMotion && designKitMotion {
                        TimelineView(.periodic(from: .now, by: EdgeGlowMetrics.frameInterval)) { timeline in
                            let frame = driver.advance(to: timeline.date, target: level)
                            glow(library, time: frame.time, level: frame.level, flow: frame.flow)
                        }
                    } else {
                        glow(library, time: 0, level: level ?? VoiceLevelDriver.restingLevel, flow: 0)
                    }
                }
            } else {
                // The compiled shaders are missing: a plain soft rim, still.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AngularGradient(colors: colors + [colors[0]], center: .center), lineWidth: thickness * 0.5)
                    .blur(radius: thickness * 0.4)
            }
        }
        .opacity(isVisible || !designKitMotion ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(AppAnimation.gentleSpring) { isVisible = true }
        }
    }

    private func glow(_ library: ShaderLibrary, time: Double, level: Double, flow: Double) -> some View {
        let colors = colors
        let cornerRadius = cornerRadius
        let thickness = thickness
        return Rectangle()
            .fill(.white)
            .visualEffect { content, proxy in
                content.colorEffect(
                    library.EdgeGlow(
                        .float2(proxy.size),
                        .float(cornerRadius),
                        .float(time),
                        .float(level),
                        .float(flow),
                        .float(thickness),
                        .colorArray(colors)
                    )
                )
            }
    }
}

public enum EdgeGlowMetrics {
    /// About the corner of a current iPhone's screen. The system does not publish it; the glow
    /// is soft enough that a few points either way do not show.
    public static let screenCornerRadius: CGFloat = 55
    /// How deep the soft light reaches in at rest.
    public static let thickness: CGFloat = 28
    /// 30 fps: the light drifts slowly; the voice swells are smoothed anyway.
    static let frameInterval: Double = 1.0 / 30
}

// MARK: - Voice level

/// Smooths a voice level frame by frame: fast up, slow down, so speech swells and settles
/// instead of flickering with every sample. Also integrates the flow of colour, whose speed
/// follows the level, so the flow never jumps. A reference type written from inside a
/// `TimelineView`, so smoothing never re-renders anything.
final class VoiceLevelDriver {
    /// What the glow and the wave show with no level given, or at rest.
    static let restingLevel: Double = 0.2
    /// Per second: how fast the shown level rises towards a louder voice, and falls back.
    static let attack: Double = 18
    static let release: Double = 4

    private(set) var level: Double = 0
    private(set) var flow: Double = 0
    private var start: Date?
    private var last: Date?

    /// Advances to `date` towards `target` (or a slow breathing when `nil`).
    func advance(to date: Date, target: Double?) -> (time: Double, level: Double, flow: Double) {
        let start = self.start ?? date
        self.start = start
        let time = date.timeIntervalSince(start)
        let step = last.map { min(max(date.timeIntervalSince($0), 0), 0.1) } ?? 0
        last = date

        let goal = target ?? Self.restingLevel + 0.08 * sin(time * 1.3)
        let rate = goal > level ? Self.attack : Self.release
        level += (goal - level) * (1 - exp(-rate * step))
        flow += step * (0.04 + level * 0.12)
        return (time, level, flow)
    }
}
