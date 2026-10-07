//
//  AuroraBackground.swift
//  DesignKit
//
//  A slow aurora behind a premium screen, a paywall or an onboarding (2.2.0): a 3×3
//  MeshGradient whose inner points drift on long, out-of-step loops, so the light never
//  repeats in a way the eye catches.
//
//  Light: the GPU draws a mesh gradient in one pass, with no blur; it redraws at 30 fps only
//  while motion is allowed (AmbientMotionGate: Reduce Motion, iOS 27's request to save
//  resources) and `.designKitMotion` is on. Otherwise it is one still frame, the same layout.
//
//  For a screen's background, behind content on materials or glass; not under small text with
//  no surface of its own.
//

import SwiftUI
import UIKit
import DesignTokens

/// A slowly drifting aurora of `colors`.
///
/// ```swift
/// ZStack {
///     AuroraBackground().ignoresSafeArea()
///     PaywallContent()
/// }
/// AuroraBackground(colors: [.teal, .indigo, .purple], intensity: 0.6)
/// ```
public struct AuroraBackground: View {
    let colors: [Color]
    let intensity: Double

    @Environment(\.designKitMotion) private var designKitMotion

    /// - Parameters:
    ///   - colors: The aurora's colours, spread over the nine points; by default the accent and
    ///     its neighbours on the colour wheel.
    ///   - intensity: 0…1, how strongly the aurora shows over the screen's background.
    public init(colors: [Color]? = nil, intensity: Double = 1) {
        let given = colors ?? []
        self.colors = given.isEmpty ? AuroraBackground.palette(around: AppColors.accent) : given
        self.intensity = min(max(intensity, 0), 1)
    }

    public var body: some View {
        AmbientMotionGate { allowsAmbientMotion in
            if allowsAmbientMotion && designKitMotion {
                TimelineView(.periodic(from: .now, by: AuroraMetrics.frameInterval)) { timeline in
                    mesh(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                mesh(at: 0)
            }
        }
        .background(AppColors.Background.base)
        .accessibilityHidden(true)
    }

    private func mesh(at time: Double) -> some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: Self.points(at: time),
            colors: (0..<9).map { colors[$0 % colors.count] }
        )
        .opacity(intensity)
    }

    /// Corners fixed, edge midpoints sliding along their edge, the centre drifting: each on its
    /// own period, so the pattern takes minutes to come round.
    static func points(at time: Double) -> [SIMD2<Float>] {
        func wave(_ period: Double, _ phase: Double, _ amplitude: Double) -> Float {
            Float(sin(time * 2 * .pi / period + phase) * amplitude)
        }
        let a = AuroraMetrics.drift
        return [
            [0, 0], [0.5 + wave(13, 0, a), 0], [1, 0],
            [0, 0.5 + wave(17, 1, a)], [0.5 + wave(11, 2, a), 0.5 + wave(19, 3, a)], [1, 0.5 + wave(15, 4, a)],
            [0, 1], [0.5 + wave(14, 5, a), 1], [1, 1],
        ]
    }

    /// The accent and its neighbours on the colour wheel (±30°, ±60°), lighter and deeper.
    public static func palette(around color: Color) -> [Color] {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        func shifted(_ degrees: CGFloat, brightness b: CGFloat) -> Color {
            var h = hue + degrees / 360
            h -= floor(h)
            return Color(hue: Double(h), saturation: Double(min(1, saturation * 0.9 + 0.1)), brightness: Double(min(1, b)))
        }
        return [
            shifted(0, brightness: brightness),
            shifted(30, brightness: brightness * 1.1),
            shifted(-30, brightness: brightness * 0.9),
            shifted(60, brightness: brightness * 1.05),
            shifted(0, brightness: brightness * 1.15),
            shifted(-60, brightness: brightness),
            shifted(30, brightness: brightness * 0.85),
            shifted(-30, brightness: brightness * 1.1),
            shifted(0, brightness: brightness * 0.95),
        ]
    }
}

enum AuroraMetrics {
    /// 30 fps: the drift is slow, a display-rate redraw would only cost energy.
    static let frameInterval: Double = 1.0 / 30
    /// How far a point drifts from its place, in unit coordinates.
    static let drift: Double = 0.18
}
