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
//  `.heroBackground(picture:)` (8.14.0) lays a picture there instead of a colour, as a film's
//  page in Apple's TV app does: a game's cover, a trip's photo, tall and edge to edge from the
//  screen's top, sharp where nothing is over it, then flowing into its own colours, blurred and
//  darkened, where the hero's text and buttons are, in white, in both modes; the hero ends on the
//  page with an edge. The bar's buttons and the status bar are light while it is under them.
//  `.heroScrollEdge(isHeroUnderBar:)` tells the screen while the hero is under the bar: a screen
//  whose hero carries the title (a logo) keeps the bar's title empty until then.
//
//  `.heroBackground(picture:subject:)` (8.17.0) lays a cut-out figure in front of the picture, as
//  a game's page on a PlayStation stands its hero before the world: as wide as the screen, or as
//  tall as the hero where that is less, just under the bars, so a phone shows the figure whole
//  where a wide cover cropped to its width showed a shoulder. Scrolled up, the figure moves
//  faster than the picture behind it and slower than the content: depth.
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
    /// How far the content has scrolled from its resting place, from `.heroScrollEdge()`
    /// (8.15.0): negative while it is pulled down. A picture hero stretches and moves by it.
    @Entry var heroScrolled: CGFloat = 0
    /// Inside `.heroBackground(_:)` in light mode (4.5.1): on its pale tint, where a hero's text
    /// that is grey on the page is black.
    @Entry var heroOnPale: Bool = false
}

public extension View {
    /// Lays the hero's gradient of `color` behind this view, from the screen's top edge and
    /// fading out below it (4.5.0): deep with DesignKit's hero pieces in white in dark mode, a
    /// pale tint with the pieces as on the page in light mode (4.5.1). Put it on the hero at the
    /// top of a scroll view, edge to edge (no `.screenPadding()` on it; pad what is inside), and
    /// `.heroScrollEdge()` on the scroll view. The hero takes the full width (5.2.0), its
    /// content centred in it.
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

    /// Lays a picture behind the hero, as a film's page in Apple's TV app does (8.14.0): a game's
    /// cover, a trip's photo, edge to edge from the screen's top edge. It is sharp down to
    /// `clearHeight` below the bars, the room the hero leaves it (a logo may stand at its foot),
    /// then flows into its own colours, blurred and darkened, under the hero's text and buttons,
    /// which are drawn in white (the dark scheme) in light and dark mode alike; the hero ends on
    /// the page with an edge. Put it on the hero at the top of a scroll view, edge to edge (pad
    /// what is inside), and `.heroScrollEdge()` on the scroll view: the picture then reaches the
    /// screen's top, and the bar's buttons and the status bar are light while it is under them.
    ///
    /// ```swift
    /// ScrollView {
    ///     VStack(spacing: AppSpacing.xl) {
    ///         GameHero(game)                     // room, the logo, then text and buttons
    ///             .heroBackground(clearHeight: 280) {
    ///                 RemotePhoto(key: "art-\(game.id)", url: game.artURL)
    ///             }
    ///         …
    ///     }
    /// }
    /// .heroScrollEdge(isHeroUnderBar: $heroUnderBar)
    /// .navigationTitle(heroUnderBar ? "" : game.name)
    /// ```
    ///
    /// - Parameters:
    ///   - clearHeight: How far below the bars the picture stays sharp with nothing over it: the
    ///     hero's room for it, down to the foot of a logo standing in it (240 pt by default).
    ///   - picture: The picture, filling whatever frame it is given (`RemotePhoto`, an `Image`
    ///     that is `.resizable().scaledToFill()`); it is cropped to the hero.
    func heroBackground<Picture: View>(
        clearHeight: CGFloat = HeroPictureMetrics.clearHeight,
        @ViewBuilder picture: () -> Picture
    ) -> some View {
        modifier(HeroPictureBackgroundModifier(picture: picture(), subject: EmptyView(), clearHeight: clearHeight))
    }

    /// `.heroBackground(clearHeight:picture:)` with a cut-out figure standing in front of the
    /// picture (8.17.0), as a game's page on a PlayStation stands its hero before the world: a
    /// game's character over its backdrop, each a layer of its own.
    ///
    /// The figure gets a square as wide as the hero, or as tall as the hero below the bars where
    /// that is less (an iPad, a Mac window), centred, its top at the bars' foot: on a phone it
    /// shows whole, where the same art drawn into one wide cover and cropped to the phone's width
    /// showed a shoulder. It is part of the picture: sharp in the clear part, blurred and
    /// darkened with it under the hero's text. Scrolled up, the picture lags behind the content
    /// and the figure lags less, so it rises in front of the picture (still under Reduce Motion);
    /// pulled down, both grow with the pull. While the figure loads, and if it fails, nothing
    /// stands in for it (`RemotePhotoLoading.hidden`): the picture shows alone.
    ///
    /// ```swift
    /// GameHero(game)
    ///     .heroBackground(clearHeight: 256) {
    ///         RemotePhoto(key: "backdrop-\(game.id)", url: game.backdropURL)
    ///     } subject: {
    ///         RemotePhoto(key: "character-\(game.id)", url: game.characterURL)
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - clearHeight: How far below the bars the picture stays sharp with nothing over it but
    ///     the figure and a title logo at its foot (240 pt by default).
    ///   - picture: The picture behind, filling whatever frame it is given; it is cropped to the
    ///     hero.
    ///   - subject: The figure in front: a picture with a transparent background (a PNG), filling
    ///     the square it is given (`RemotePhoto`, an `Image` that is `.resizable().scaledToFill()`).
    ///     Pass the backdrop it was drawn for as `picture`, not a cover that already shows it.
    func heroBackground<Picture: View, Subject: View>(
        clearHeight: CGFloat = HeroPictureMetrics.clearHeight,
        @ViewBuilder picture: () -> Picture,
        @ViewBuilder subject: () -> Subject
    ) -> some View {
        modifier(HeroPictureBackgroundModifier(picture: picture(), subject: subject(), clearHeight: clearHeight))
    }

    /// `.heroScrollEdge()` that also tells the screen whether the hero is under the navigation
    /// bar (8.14.0): true at rest, false once the content after the hero scrolls under the bar. A
    /// screen whose hero shows its title keeps the bar's title empty while it is true; start the
    /// binding at true.
    func heroScrollEdge(isHeroUnderBar: Binding<Bool>) -> some View {
        modifier(HeroScrollEdgeModifier(isHeroUnderBar: isHeroUnderBar))
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

/// `.heroBackground(picture:)` (8.14.0): how the picture gives way to its own colours under the
/// hero's text.
public enum HeroPictureMetrics {
    /// How far below the bars the picture stays sharp with nothing over it, by default.
    public static let clearHeight: CGFloat = 240
    /// The blur it flows into: its own colours, no detail that competes with text.
    static let blur: CGFloat = 40
    /// Black over the blurred picture: white text on it reads on a bright picture too.
    static let shade: Double = 0.55
    /// It starts giving way this far above the end of the clear part…
    static let blendAbove: CGFloat = 48
    /// …and is blurred and shaded through this far below it.
    static let blendBelow: CGFloat = 120
    /// Scrolled up, the picture moves at this share of the content's pace (8.15.0): behind the
    /// content, as a film's page in the TV app. Still under Reduce Motion.
    static let parallax: CGFloat = 0.5
    /// Scrolled up, the figure in front of the picture lags behind the content by this share
    /// (8.17.0): it moves at three quarters of the content's pace, the picture behind it at half,
    /// so it rises in front of the picture. Still under Reduce Motion.
    static let subjectParallax: CGFloat = 0.25

    /// The side of the figure's square (8.17.0): as wide as the hero, or as tall as the hero
    /// below the bars (`room`) where that is less.
    static func subjectSide(width: CGFloat, room: CGFloat) -> CGFloat {
        max(0, min(width, room))
    }

    /// Where, as shares of the picture's height from the screen's top edge, it starts and
    /// finishes giving way; `clearEnd` is the end of the clear part from the same edge.
    static func blend(height: CGFloat, clearEnd: CGFloat) -> (start: CGFloat, end: CGFloat) {
        guard height > 0 else { return (0, 1) }
        let start = min(max((clearEnd - blendAbove) / height, 0), 1)
        let end = min(max((clearEnd + blendBelow) / height, start), 1)
        return (start, end)
    }
}

private struct HeroBackgroundModifier: ViewModifier {
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            // Edge to edge however narrow the hero is (5.2.0): the colour is the screen's top,
            // not a block behind the hero's widest piece.
            .frame(maxWidth: .infinity)
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

private struct HeroPictureBackgroundModifier<Picture: View, Subject: View>: ViewModifier {
    let picture: Picture
    let subject: Subject
    let clearHeight: CGFloat
    @State private var heroHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            // White on the picture's own dark colours, in both modes: DesignKit's pieces in their
            // dark look, hero pieces in white.
            .environment(\.colorScheme, .dark)
            .environment(\.heroTone, .onColor)
            .background {
                HeroPictureFill(picture: picture, subject: subject, clearHeight: clearHeight)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                heroHeight = height
            }
            .preference(key: HeroBackgroundHeightKey.self, value: heroHeight)
            // `.heroScrollEdge()` makes the bar's items and the status bar light over it.
            .preference(key: HeroIsDarkKey.self, value: true)
    }
}

/// The picture from the screen's top edge to the hero's foot: sharp down to the end of the clear
/// part, then a blurred copy and black over it take over, through `HeroPictureMetrics.blendBelow`.
/// Pulled down, the picture keeps to the screen's top and grows with the pull; scrolled up, it
/// moves at half the content's pace (8.15.0). While it loads, a still dark fill, or its small
/// version blurred, stands in: no shimmer behind the hero's text (`RemotePhotoLoading.still`).
/// A figure in front of it (8.17.0) is a layer of the picture, with a parallax of its own.
struct HeroPictureFill<Picture: View, Subject: View>: View {
    let picture: Picture
    let subject: Subject
    let clearHeight: CGFloat
    /// From the hero's top up to the screen's top edge (`.heroScrollEdge()`).
    @Environment(\.heroBarInset) private var barInset
    /// How far the content has scrolled (`.heroScrollEdge()`), negative while pulled down.
    @Environment(\.heroScrolled) private var scrolled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var motionEnabled

    /// Pulled down: how far the picture reaches above the hero's top, to the screen's top edge.
    private var stretch: CGFloat { max(0, -scrolled) }

    /// Scrolled up: how far a layer lags behind the content, at `share` of the scroll.
    private func parallax(_ share: CGFloat) -> CGFloat {
        reduceMotion || !motionEnabled ? 0 : max(0, scrolled) * share
    }

    var body: some View {
        GeometryReader { proxy in
            let blend = HeroPictureMetrics.blend(height: proxy.size.height, clearEnd: barInset + stretch + clearHeight)
            let backdrop = picture
                .frame(width: proxy.size.width, height: proxy.size.height)
                .offset(y: parallax(HeroPictureMetrics.parallax))
            let figure = HeroPictureSubject(
                subject: subject,
                size: proxy.size,
                barInset: barInset,
                stretch: stretch,
                parallax: parallax(HeroPictureMetrics.subjectParallax)
            )
            // Where the picture gives way: clear above `blend.start`, whole below `blend.end`.
            let blurred = LinearGradient(
                stops: [.init(color: .clear, location: blend.start), .init(color: .black, location: blend.end)],
                startPoint: .top, endPoint: .bottom
            )
            let sharp = LinearGradient(
                stops: [.init(color: .black, location: blend.start), .init(color: .clear, location: blend.end)],
                startPoint: .top, endPoint: .bottom
            )
            // Black under the picture: while it loads its still grey reads dark, as the picture
            // under the hero's white text will be.
            Color.black
                .overlay { backdrop }
                .overlay {
                    backdrop
                        .blur(radius: HeroPictureMetrics.blur, opaque: true)
                        .mask { blurred }
                }
                // The figure in front (8.17.0), sharp and then blurred as the picture is; its own
                // blur keeps the transparency around it (an opaque blur of the two together drew
                // the figure's square).
                .overlay { figure.mask { sharp } }
                .overlay {
                    figure
                        .blur(radius: HeroPictureMetrics.blur, opaque: false)
                        .mask { blurred }
                }
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0), location: blend.start),
                            .init(color: .black.opacity(HeroPictureMetrics.shade), location: blend.end),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                .clipped()
        }
        // The picture from the screen's top edge, behind the status and navigation bars, and
        // pulled down, still from that edge.
        .padding(.top, -barInset - stretch)
        .ignoresSafeArea(edges: .top)
        // Dark while it loads, as the picture under white text will be; no shimmer.
        .environment(\.colorScheme, .dark)
        .remotePhotoLoading(.still)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The figure in front of the picture (8.17.0), in the fill's frame (from the screen's top edge to
/// the hero's foot, `stretch` taller while pulled down): a square as wide as the hero, or as tall
/// as the hero below the bars, centred, its top at the bars' foot.
private struct HeroPictureSubject<Subject: View>: View {
    let subject: Subject
    let size: CGSize
    let barInset: CGFloat
    let stretch: CGFloat
    let parallax: CGFloat

    var body: some View {
        // At rest the fill is the bars and the hero; pulled down, the figure grows with it.
        let rest = size.height - stretch
        let side = HeroPictureMetrics.subjectSide(width: size.width, room: rest - barInset)
        let grow = rest > 0 ? size.height / rest : 1
        subject
            .frame(width: side, height: side)
            // Its top at the bars' foot: the figure stands under them, not behind them.
            .padding(.top, barInset)
            .scaleEffect(grow, anchor: .top)
            .offset(y: parallax)
            .frame(width: size.width, height: size.height, alignment: .top)
            // Nothing while it loads or if it fails: the picture shows alone.
            .remotePhotoLoading(.hidden)
    }
}

/// A hero drawn in the dark scheme is at the top (`.heroBackground(picture:)`): the bar's items
/// and the status bar go light over it.
struct HeroIsDarkKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
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
    /// Told whether the hero is under the bar (8.14.0, `.heroScrollEdge(isHeroUnderBar:)`).
    var isHeroUnderBar: Binding<Bool>? = nil
    /// The hero's height, from its background.
    @State private var heroHeight: CGFloat = 0
    /// How far the content has scrolled from its resting place, in whole points.
    @State private var scrolled: CGFloat = 0
    /// The scroll view's top inset: the bars above its content.
    @State private var barInset: CGFloat = 0
    /// The hero is a picture, drawn dark (`.heroBackground(picture:)`, 8.14.0).
    @State private var heroIsDark = false

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
            .onPreferenceChange(HeroIsDarkKey.self) { isDark in
                heroIsDark = isDark
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
            // Light bar items and status bar over a picture hero, the system's own after it.
            .toolbarColorScheme(heroIsDark && colourIsUnderBar ? .dark : nil, for: .navigationBar)
            // Once the hero is measured: before that it reads as not under the bar, and a
            // title kept empty at rest would flash in.
            .onChange(of: colourIsUnderBar, initial: true) { _, isUnder in
                if heroHeight > 0, let isHeroUnderBar, isHeroUnderBar.wrappedValue != isUnder {
                    isHeroUnderBar.wrappedValue = isUnder
                }
            }
            // Once the cards are under the bar, its edge is the soft one, named (5.1.0): built
            // with Xcode 27 the style as it comes is hard (docs/gotchas.md).
            .scrollEdgeEffectStyle(.soft, for: .top)
            // The hero's gradient starts at the screen's top edge.
            .environment(\.heroBarInset, barInset)
            // A picture hero stretches when pulled down and lags behind when scrolled (8.15.0).
            .environment(\.heroScrolled, scrolled)
    }
}
