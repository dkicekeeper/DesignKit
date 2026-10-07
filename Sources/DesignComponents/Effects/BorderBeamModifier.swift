//
//  BorderBeamModifier.swift
//  Tenra
//
//  A comet of light travelling round a card's border (2.4.0: along the path, with a bloom),
//  for highlights and focus states; and a static halo to pair with it.
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - BorderBeamModifier

/// Overlays a comet of light that travels around the view's border.
///
/// 2.4.0: the comet runs along the border itself (a trimmed path), so it keeps one speed and
/// one length on every side and round every corner. Its head is bright with a small bloom,
/// its tail fades and thins, and a wide faint spill lights the edge it is passing. One or two
/// comets (the second opposite the first).
///
/// Driven by `TimelineView(.animation)` so it ticks only while the overlay is visible —
/// flipping `isActive` to `false` stops the work entirely (no orphan animation).
/// The overlay is skipped under Reduce Motion, `.designKitMotion(false)`, and (iOS 27+) while
/// the system prefers reduced resource usage — routed through `AmbientMotionGate`.
public struct BorderBeamModifier: ViewModifier {
    var isActive: Bool
    var colors: [Color]
    var cornerRadius: CGFloat
    var lineWidth: CGFloat
    var duration: Double
    var beams: Int

    @Environment(\.designKitMotion) private var designKitMotion

    public init(
        isActive: Bool,
        colors: [Color],
        cornerRadius: CGFloat,
        lineWidth: CGFloat,
        duration: Double,
        beams: Int = 1
    ) {
        self.isActive = isActive
        self.colors = colors
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.duration = duration
        self.beams = min(max(beams, 1), 2)
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                AmbientMotionGate { allowsAmbientMotion in
                    if isActive && allowsAmbientMotion && designKitMotion {
                        // Display-synced: the comet moves fast enough that 30 fps would step.
                        TimelineView(.animation) { timeline in
                            let phase = timeline.date.timeIntervalSinceReferenceDate
                                .truncatingRemainder(dividingBy: duration) / duration
                            Canvas { context, size in
                                BorderComet.draw(
                                    in: &context,
                                    size: size,
                                    head: phase,
                                    beams: beams,
                                    colors: colors.isEmpty ? [AppColors.accent] : colors,
                                    cornerRadius: cornerRadius,
                                    lineWidth: lineWidth
                                )
                            }
                        }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
            }
    }
}

/// Draws the comets of a border beam.
enum BorderComet {
    /// The comet's length, as a share of the border.
    static let length: Double = 0.22
    /// Steps the tail fades in.
    static let segments = 12

    static func draw(
        in context: inout GraphicsContext,
        size: CGSize,
        head: Double,
        beams: Int,
        colors: [Color],
        cornerRadius: CGFloat,
        lineWidth: CGFloat
    ) {
        let inset = lineWidth / 2
        let border = RoundedRectangle(cornerRadius: max(cornerRadius - inset, 0))
            .path(in: CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset))

        for beam in 0..<beams {
            let tip = (head + Double(beam) / Double(beams)).truncatingRemainder(dividingBy: 1)

            // The spill: a wide faint light on the edge the comet is passing.
            stroke(border, from: tip - length * 1.3, to: tip, in: &context,
                   with: .color(colors[0].opacity(0.14)),
                   style: StrokeStyle(lineWidth: lineWidth * 5, lineCap: .round))

            // The tail: brightest and widest at the head, fading and thinning behind it.
            for index in 0..<segments {
                let near = Double(index) / Double(segments)          // 0 at the head
                let from = tip - length * Double(index + 1) / Double(segments)
                let to = tip - length * near + 0.002                  // a hair of overlap
                let strength = pow(1 - near, 1.6)
                let color = colors.count > 1
                    ? colors[min(Int(near * Double(colors.count)), colors.count - 1)]
                    : colors[0]
                stroke(border, from: from, to: to, in: &context,
                       with: .color(color.opacity(strength)),
                       style: StrokeStyle(lineWidth: lineWidth * CGFloat(0.5 + 0.5 * (1 - near)), lineCap: .butt))
            }

            // The head's bloom.
            if let point = border.trimmedPath(from: 0, to: max(tip, 0.0001)).currentPoint {
                let bloom = lineWidth * 4 + 4
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - bloom, y: point.y - bloom, width: bloom * 2, height: bloom * 2)),
                    with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.9), colors[0].opacity(0.5), colors[0].opacity(0)]),
                        center: point, startRadius: 0, endRadius: bloom
                    )
                )
            }
        }
    }

    /// Strokes the part of `path` from `from` to `to` (shares of its length), across the start
    /// when `from` is below 0.
    private static func stroke(
        _ path: Path,
        from: Double,
        to: Double,
        in context: inout GraphicsContext,
        with shading: GraphicsContext.Shading,
        style: StrokeStyle
    ) {
        if from < 0 {
            context.stroke(path.trimmedPath(from: from + 1, to: 1), with: shading, style: style)
            context.stroke(path.trimmedPath(from: 0, to: max(to, 0)), with: shading, style: style)
        } else {
            context.stroke(path.trimmedPath(from: from, to: min(to, 1)), with: shading, style: style)
        }
    }
}

// MARK: - BorderGlowModifier

/// Static, non-animated halo around a view's border. Designed to layer with
/// `BorderBeamModifier` so the card always reads as "lit up" even before the
/// traveling beam reaches a given edge.
public struct BorderGlowModifier: ViewModifier {
    var isActive: Bool
    var colors: [Color]
    var cornerRadius: CGFloat
    var lineWidth: CGFloat
    var glowRadius: CGFloat
    var opacity: Double

    public init(
        isActive: Bool,
        colors: [Color],
        cornerRadius: CGFloat,
        lineWidth: CGFloat,
        glowRadius: CGFloat,
        opacity: Double
    ) {
        self.isActive = isActive
        self.colors = colors
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.glowRadius = glowRadius
        self.opacity = opacity
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    ZStack {
                        // Outer soft halo — wider, heavily blurred.
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(gradient, lineWidth: lineWidth + 2)
                            .blur(radius: glowRadius)
                            .opacity(opacity)
                        // Inner crisp ring — anchors the glow against the card edge.
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(gradient.opacity(0.6), lineWidth: lineWidth)
                            .blur(radius: max(0, glowRadius * 0.25))
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
    }

    private var gradient: AngularGradient {
        let palette = colors.isEmpty ? [AppColors.accent] : colors
        return AngularGradient(
            gradient: Gradient(colors: palette + [palette[0]]),
            center: .center
        )
    }
}

// MARK: - View Extension

public extension View {
    /// Adds a comet of light that travels around this view's border.
    ///
    /// - Parameters:
    ///   - isActive: Beam runs only while `true`. When `false` the overlay is removed
    ///     and the timeline stops ticking. Default: `true`.
    ///   - colors: Beam colors from leading to trailing edge.
    ///   - cornerRadius: Match your card's corner radius. Default: `AppRadius.xl`.
    ///   - lineWidth: Stroke width of the sharp beam layer. Default: `1.5`.
    ///   - duration: Seconds for one full revolution. Default: `3.0`.
    ///   - beams: One comet, or two running opposite each other (2.4.0). Default: `1`.
    func borderBeam(
        isActive: Bool = true,
        colors: [Color] = [AppColors.accent, .purple, .pink],
        cornerRadius: CGFloat = AppRadius.xl,
        lineWidth: CGFloat = 1.5,
        duration: Double = 3.0,
        beams: Int = 1
    ) -> some View {
        modifier(BorderBeamModifier(
            isActive: isActive,
            colors: colors,
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            duration: duration,
            beams: beams
        ))
    }

    /// Adds a static (non-animated) glowing halo around this view's border.
    /// Pairs well with `borderBeam` — the halo provides constant edge
    /// presence while the beam sweeps through.
    ///
    /// - Parameter isActive: Halo is rendered only while `true`; the overlay
    ///   is removed entirely otherwise. Default: `true`.
    func borderGlow(
        isActive: Bool = true,
        colors: [Color] = [AppColors.accent, .purple, .pink],
        cornerRadius: CGFloat = AppRadius.xl,
        lineWidth: CGFloat = 1,
        glowRadius: CGFloat = 6,
        opacity: Double = 0.55
    ) -> some View {
        modifier(BorderGlowModifier(
            isActive: isActive,
            colors: colors,
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius,
            opacity: opacity
        ))
    }
}

// MARK: - Preview


@ViewBuilder
private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
        Text(title)
            .font(AppTypography.caption)
            .foregroundStyle(.secondary)
        content()
    }
}
