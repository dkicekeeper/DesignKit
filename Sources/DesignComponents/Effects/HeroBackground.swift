//
//  HeroBackground.swift
//  DesignKit
//
//  The top of a detail screen on colour (4.5.0). `.heroBackground(color)` lays a gradient of
//  `color` behind a hero: mesh light in its shades, from the screen's top edge (behind the
//  navigation bar) to below the hero (and past the top edge, so a pull down shows more colour,
//  not the page), fading into the page below the hero, where the cards that follow rise over it.
//  In dark mode it is a tone deeper and its content is told it is on colour (`\.heroTone`), so
//  DesignKit's hero pieces draw in white: `HeroSection`, `TrendBadge`, `HeroHalfGauge`,
//  `HeroBarPair`, `HeroSparkline`, `HeroMilestoneGauge`, `HeroProportionBar` and
//  `ChartSelectionBanner`. In light mode (4.5.1) it is a pale tint of the colour and the pieces
//  draw as on the page, the text in black. `ScoreGaugeCard(style: .hero)` lies on it since 4.2.0.
//
//  `.heroScrollEdge()` goes on the screen's scroll view: iOS 26 fades the content under the
//  navigation bar into the page (the soft scroll edge effect), which cut the colour off under
//  the bar. It keeps the effect off while the hero's colour is under the bar and brings it back
//  once the content after the hero scrolls under it; and it tells the gradient how far the
//  screen's top edge is above the hero (4.5.1), so the gradient starts there, not under the bar.
//

import SwiftUI
import DesignTokens

/// What a hero piece is drawn on (4.2.0 as `HeroHalfGauge.Tone`, for every hero piece since
/// 4.5.0).
public enum HeroTone: Hashable, Sendable {
    /// The page's background: marks in their colours, grey tracks and secondary text.
    case onSurface
    /// A coloured background (`.heroBackground(_:)` in dark mode): white marks, translucent
    /// white tracks, white text.
    case onColor
}

public extension EnvironmentValues {
    /// `.onColor` inside `.heroBackground(_:)` in dark mode (4.5.0): hero pieces draw in white.
    /// In light mode the gradient is pale and the tone stays `.onSurface` (4.5.1).
    @Entry var heroTone: HeroTone = .onSurface
}

extension EnvironmentValues {
    /// How far the screen's top edge is above the top of the scroll view's content (the
    /// navigation bar and the status bar), from `.heroScrollEdge()`: the hero's gradient starts
    /// there (4.5.1).
    @Entry var heroBarInset: CGFloat = 0
    /// Inside `.heroBackground(_:)` in light mode (4.5.1): on its pale tint, where a hero's text
    /// that is grey on the page is black.
    @Entry var heroOnPale: Bool = false
}

public extension View {
    /// Lays the hero's gradient of `color` behind this view, from the screen's top edge and
    /// fading out below it (4.5.0): deep with DesignKit's hero pieces in white in dark mode, a
    /// pale tint with the pieces as on the page in light mode (4.5.1). Put it on the hero at the
    /// top of a scroll view, edge to edge (no `.screenPadding()` on it; pad what is inside), and
    /// `.heroScrollEdge()` on the scroll view.
    ///
    /// ```swift
    /// ScrollView {
    ///     VStack(spacing: AppSpacing.xl) {
    ///         VStack { HeroSection(…); HeroBarPair(…) }
    ///             .padding(.bottom, AppSpacing.xxl)
    ///             .heroBackground(AppColors.warning)
    ///         DetailCard(…).padding(.top, -AppSpacing.xxl)   // rises over the fade
    ///     }
    /// }
    /// .heroScrollEdge()
    /// ```
    func heroBackground(_ color: Color) -> some View {
        modifier(HeroBackgroundModifier(color: color))
    }

    /// On the scroll view of a screen with `.heroBackground(_:)` (4.5.0): keeps the navigation
    /// bar's soft scroll edge off while the hero's colour is under the bar, so the colour
    /// reaches the top of the screen, and brings it back once the content after the hero
    /// scrolls under the bar. The hero's gradient starts at the screen's top edge (4.5.1).
    func heroScrollEdge() -> some View {
        modifier(HeroScrollEdgeModifier())
    }
}

enum HeroBackgroundMetrics {
    /// Shades of one colour, as the hero glow (`.accentGlow`, 3.4.0).
    static let hueSpread: Double = 12
    /// How far below the hero its gradient fades out (under the cards that rise over it).
    static let fade: CGFloat = 96
    /// Dark mode: the colour is deepened to this share of its brightness behind white text:
    /// white on the deepened success, warning and destructive colours is at least 3:1, the
    /// minimum for large text (the plain colours give about 2:1).
    static let depth: CGFloat = 0.78
    /// Light mode: the shades of the colour at this opacity over the page, a pale tint behind
    /// black text (4.5.1; the deep gradient read as brown there).
    static let paleOpacity: Double = 0.3
    /// Colour above the screen's top edge, for a pull down past the top.
    static let overscroll: CGFloat = 600
}

private struct HeroBackgroundModifier: ViewModifier {
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            // White on the deep gradient; as on the page, in black, on the pale one.
            .environment(\.heroTone, colorScheme == .dark ? .onColor : .onSurface)
            .environment(\.heroOnPale, colorScheme != .dark)
            .background {
                HeroBackgroundFill(color: color)
            }
            // How tall the opaque colour is, for `.heroScrollEdge()`.
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                heroHeight = height
            }
            .preference(key: HeroBackgroundHeightKey.self, value: heroHeight)
    }

    @State private var heroHeight: CGFloat = 0
}

/// The gradient: mesh light in shades of the colour (a tone deeper in dark mode, a pale tint in
/// light mode) from the screen's top edge; above it, the mesh's top edge carried on up past the
/// screen; below it, a fade into the page. A fine grain against banding.
struct HeroBackgroundFill: View {
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    /// From the hero's top up to the screen's top edge (`.heroScrollEdge()`).
    @Environment(\.heroBarInset) private var barInset

    var body: some View {
        let mesh = HeroBackgroundMesh(color: color, isPale: colorScheme != .dark)
        VStack(spacing: 0) {
            // The mesh's top row, carried up for a pull down past the top.
            LinearGradient(colors: mesh.topRow, startPoint: .leading, endPoint: .trailing)
                .frame(height: HeroBackgroundMetrics.overscroll)
            mesh.gradient
        }
        .grain()
        .mask {
            VStack(spacing: 0) {
                Rectangle()
                LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: HeroBackgroundMetrics.fade)
            }
        }
        // The mesh from the screen's top edge, its top row carried on above it.
        .padding(.top, -(HeroBackgroundMetrics.overscroll + barInset))
        .padding(.bottom, -HeroBackgroundMetrics.fade)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Three columns of shades in three rows (as `.accentGlow`'s aurora): opaque and a tone deeper,
/// or a pale tint over the page (`isPale`, light mode).
struct HeroBackgroundMesh {
    let color: Color
    var isPale = false

    /// The colour a tone deeper (`HeroBackgroundMetrics.depth`), or as it is for the pale tint.
    var base: Color {
        guard !isPale else { return color }
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: Double(hue), saturation: Double(min(1, saturation * 1.05)),
                     brightness: Double(brightness * HeroBackgroundMetrics.depth))
    }

    private var columns: [Color] {
        let palette = AuroraBackground.palette(around: base, spread: HeroBackgroundMetrics.hueSpread)
        let shades = [palette[0], palette[1], palette[5]]
        return isPale ? shades.map { $0.opacity(HeroBackgroundMetrics.paleOpacity) } : shades
    }

    /// The colours along the mesh's top edge, left to right.
    var topRow: [Color] { columns }

    var gradient: MeshGradient {
        let columns = self.columns
        var points = [SIMD2<Float>]()
        var colors = [Color]()
        for row in 0..<3 {
            for column in 0..<3 {
                points.append(SIMD2(Float(column) / 2, Float(row) / 2))
                colors.append(columns[(column + row) % columns.count])
            }
        }
        return MeshGradient(width: 3, height: 3, points: points, colors: colors)
    }
}

/// The opaque height of the hero background inside a scroll view (0 without one).
struct HeroBackgroundHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct HeroScrollEdgeModifier: ViewModifier {
    /// The hero's height, from its background.
    @State private var heroHeight: CGFloat = 0
    /// How far the content has scrolled from its resting place, in whole points.
    @State private var scrolled: CGFloat = 0
    /// The scroll view's top inset: the bars above its content.
    @State private var barInset: CGFloat = 0

    /// While the content under the bar is still the hero's colour (the cards after the hero
    /// rise `AppSpacing.xxl` over its end).
    private var colourIsUnderBar: Bool {
        heroHeight > 0 && scrolled < heroHeight - AppSpacing.xxl
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(HeroBackgroundHeightKey.self) { height in
                heroHeight = height
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                (geometry.contentOffset.y + geometry.contentInsets.top).rounded()
            } action: { _, offset in
                scrolled = offset
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentInsets.top.rounded()
            } action: { _, inset in
                barInset = inset
            }
            .scrollEdgeEffectHidden(colourIsUnderBar, for: .top)
            // Once the cards are under the bar, its edge is the soft one, named (5.1.0): built
            // with Xcode 27 the style as it comes is hard (docs/gotchas.md).
            .scrollEdgeEffectStyle(.soft, for: .top)
            // The hero's gradient starts at the screen's top edge.
            .environment(\.heroBarInset, barInset)
    }
}
