//
//  AccentGlow.swift
//  Tenra
//
//  Ambient glow rising from a screen edge. Two styles:
//  • `.aurora` (2.5.0, the default): a band of mesh-gradient light in shades of the tint
//    (hues within ±12°, 3.4.0; ±60° before, which turned a red icon's glow orange and
//    purple), fading towards the middle of the screen, with a fine grain. No blur, so it
//    costs less than the soft style; still unless `drifts`.
//  • `.soft` (before 2.5): a gradient-filled circle offset mostly off-screen and heavily
//    blurred.
//  Hit-testing disabled, hidden from VoiceOver.
//
//  Presets:
//  • `.onboardingAccentGlow()` — full-intensity glow from the bottom edge,
//    the onboarding-screen background; the aurora drifts slowly there.
//  • `.heroAccentGlow(icon:tint:)` — softer glow from the top edge behind
//    entity-detail hero sections. Tint resolves from the hero icon: explicit
//    `IconTint` colour for SF Symbols, dominant logo colour (async, via
//    `DominantColorExtractor`) for `.brandService`, `AppColors.accent`
//    otherwise. The brand colour fades in over the fallback when ready.
//

import SwiftUI
import DesignTokens
import DesignSupport

public extension View {
    /// Tinted glow rising from a screen edge. Sits in `background`,
    /// ignores safe areas, never intercepts touches.
    ///
    /// - Parameters:
    ///   - style: `.aurora` (2.5.0, the default) or `.soft`, the blurred circle of before.
    ///   - drifts: The aurora's light drifts slowly (30 fps while motion is allowed). Off by
    ///     default: under Liquid Glass a moving background makes the glass redraw each frame.
    func accentGlow(
        _ tint: Color,
        edge: VerticalEdge = .bottom,
        intensity: Double = 1,
        style: AccentGlowStyle = .aurora,
        drifts: Bool = false
    ) -> some View {
        background {
            switch style {
            case .aurora:
                AuroraGlowBackground(tint: tint, edge: edge, intensity: intensity, drifts: drifts)
            case .soft:
                AccentGlowBackground(tint: tint, edge: edge, intensity: intensity)
            }
        }
    }

    /// Onboarding background: full-intensity accent glow from the bottom edge; the aurora
    /// drifts slowly.
    func onboardingAccentGlow(tint: Color = AppColors.accent) -> some View {
        accentGlow(tint, drifts: true)
    }

    /// Ambient top glow for entity-detail screens, tinted from the hero icon.
    /// Apply to the screen container (e.g. `EntityDetailScaffold`), passing
    /// the same `icon`/`tint` the `HeroSection` receives.
    func heroAccentGlow(
        icon: IconSource?,
        tint: IconTint? = nil,
        intensity: Double = GlowMetrics.heroIntensity
    ) -> some View {
        modifier(HeroAccentGlowModifier(icon: icon, tint: tint, intensity: intensity))
    }
}

/// How an accent glow is drawn (2.5.0).
public enum AccentGlowStyle: Hashable, Sendable {
    /// A band of mesh-gradient light in shades of the tint, with a fine grain.
    case aurora
    /// A heavily blurred circle of the tint, as before 2.5.
    case soft
}

/// Shared glow tunables. Not `AppAnimation` material — the glow is static.
public enum GlowMetrics {
    public static let blurRadius: CGFloat = 120
    /// Fraction of the circle's own height pushed past the screen edge,
    /// leaving only a soft crown visible.
    public nonisolated static let offScreenFraction: CGFloat = 0.85
    /// Hero glow sits under title/amount text — keep it well below full
    /// intensity so text contrast survives in both themes.
    public static let heroIntensity: Double = 1
}

// MARK: - Glow background

private struct AccentGlowBackground: View {
    let tint: Color
    let edge: VerticalEdge
    let intensity: Double

    public var body: some View {
        Circle()
            .fill(tint.gradient)
            .visualEffect { [edge] content, proxy in
                let direction: CGFloat = edge == .bottom ? 1 : -1
                return content.offset(y: direction * proxy.size.height * GlowMetrics.offScreenFraction)
            }
            .frame(
                maxHeight: .infinity,
                alignment: edge == .bottom ? .bottom : .top
            )
            .blur(radius: GlowMetrics.blurRadius)
            .opacity(intensity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Aurora glow (2.5.0)

/// A band of aurora light along one edge: three columns in shades of the tint (hues within
/// `AuroraGlowMetrics.hueSpread`), four rows fading from the edge to clear. The rows bend a
/// little, so the light reads as an aurora, not a stripe.
private struct AuroraGlowBackground: View {
    let tint: Color
    let edge: VerticalEdge
    let intensity: Double
    let drifts: Bool

    @Environment(\.designKitMotion) private var designKitMotion

    var body: some View {
        GeometryReader { proxy in
            AmbientMotionGate { allowsAmbientMotion in
                if drifts && allowsAmbientMotion && designKitMotion {
                    TimelineView(.periodic(from: .now, by: AuroraMetrics.frameInterval)) { timeline in
                        mesh(at: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    mesh(at: 0)
                }
            }
            .grain()
            .frame(height: proxy.size.height * AuroraGlowMetrics.reach)
            .frame(maxHeight: .infinity, alignment: edge == .bottom ? .bottom : .top)
        }
        .opacity(intensity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mesh(at time: Double) -> some View {
        let palette = AuroraBackground.palette(around: tint, spread: AuroraGlowMetrics.hueSpread)
        let columns = [palette[0], palette[1], palette[5]]
        // Opacity of each row from the edge inwards.
        let rows = AuroraGlowMetrics.rowOpacity
        func wave(_ period: Double, _ phase: Double) -> Float {
            time == 0 ? Float(sin(phase) * 0.04) : Float(sin(time * 2 * .pi / period + phase) * AuroraGlowMetrics.drift)
        }
        // Rows from the edge (y = 0) inwards; flipped for the bottom edge.
        var points = [SIMD2<Float>]()
        var colors = [Color]()
        for row in 0..<rows.count {
            let base = Float(row) / Float(rows.count - 1)
            for column in 0..<3 {
                let inner = row > 0 && row < rows.count - 1
                let x = Float(column) / 2 + (inner && column == 1 ? wave(13 + Double(row), Double(row)) : 0)
                let y = base + (inner ? wave(17 + Double(column) * 3, Double(column) * 1.7 + Double(row)) : 0)
                points.append(SIMD2(x, edge == .bottom ? 1 - y : y))
                colors.append(columns[(column + row) % columns.count].opacity(rows[row]))
            }
        }
        if edge == .bottom {
            // Keep the rows in top-to-bottom order for the mesh.
            let edgeFirstPoints = points
            let edgeFirstColors = colors
            let reversedRows = stride(from: rows.count - 1, through: 0, by: -1)
            points = reversedRows.flatMap { row in edgeFirstPoints[(row * 3)..<(row * 3 + 3)] }
            colors = reversedRows.flatMap { row in edgeFirstColors[(row * 3)..<(row * 3 + 3)] }
        }
        return MeshGradient(width: 3, height: rows.count, points: points, colors: colors)
    }
}

enum AuroraGlowMetrics {
    /// How far the light reaches in from its edge, as a share of the height.
    static let reach: CGFloat = 0.6
    /// The rows' opacity from the edge inwards.
    static let rowOpacity: [Double] = [0.7, 0.42, 0.14, 0]
    /// How far an inner point drifts, when the glow drifts.
    static let drift: Double = 0.05
    /// The widest hue step from the tint, in degrees: a category's or a logo's colour stays
    /// one colour in several shades (3.4.0; the full ±60° wheel mixed in distant hues).
    static let hueSpread: Double = 12
}

// MARK: - Hero icon tint resolution

private struct HeroAccentGlowModifier: ViewModifier {
    let icon: IconSource?
    let tint: IconTint?
    let intensity: Double

    /// Dominant logo colour, resolved asynchronously for `.brandService`.
    @State private var brandColor: Color?

    private var brandName: String? {
        if case .brandService(let name) = icon { return name }
        return nil
    }

    /// Synchronous tint shown immediately (and kept when no brand colour
    /// can be extracted — e.g. pure black/white logos).
    private var fallbackColor: Color {
        switch tint {
        case .monochrome(let color), .hierarchical(let color):
            return color
        case .palette(let colors) where !colors.isEmpty:
            return colors[0]
        default:
            return AppColors.accent
        }
    }

    public func body(content: Content) -> some View {
        content
            .accentGlow(brandColor ?? fallbackColor, edge: .top, intensity: intensity)
            // Keyed on the brand so an icon edit re-resolves (or clears) the
            // colour; same-value re-renders don't re-fire.
            .task(id: brandName) {
                guard let brandName else {
                    brandColor = nil
                    return
                }
                guard let color = await DominantColorExtractor.accentColor(forBrand: brandName) else {
                    brandColor = nil
                    return
                }
                withAnimation(AppAnimation.gentleSpring) {
                    brandColor = color
                }
            }
    }
}

// MARK: - Previews
