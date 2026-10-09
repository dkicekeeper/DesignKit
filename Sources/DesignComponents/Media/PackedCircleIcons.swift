//
//  PackedCircleIcons.swift
//  Tenra
//
//  Packed circle layout for subscription/loan icon display.
//  Circle size reflects item cost; circles are tightly packed without overlap.
//
//  2.9.0: glossy marbles by default. A symbol sits on a marble of its colour; a logo becomes
//  the marble's skin. A highlight, shading and a shadow of the item's colour (a logo's main
//  colour) give it depth, the marbles burst out of the middle and then sway. `.flat` is the
//  look before 2.9.0. 3.3.0: a softer gloss; two more styles, `.fan` (playing cards fanned
//  along an arc, PackedCircleIconsFan.swift) and `.orbit` (marbles on a turning orbit,
//  PackedCircleIconsOrbit.swift).
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - Data Model

public struct PackedCircleItem: Identifiable {
    public let id: String
    public let iconSource: IconSource?
    public let amount: Double
    /// Optional monochrome tint for SF symbol items (e.g. category color).
    /// Brand-service items always render with `.original` tint regardless.
    public let tint: Color?

    public init(id: String, iconSource: IconSource?, amount: Double, tint: Color? = nil) {
        self.id = id
        self.iconSource = iconSource
        self.amount = amount
        self.tint = tint
    }
}

/// How `PackedCircleIcons` draws its circles.
public enum PackedCircleIconsStyle: Sendable {
    /// Glossy marbles (2.9.0, the default): a symbol on a marble of its colour, a logo as the
    /// marble's skin; a highlight, shading and a coloured shadow. They burst out of the middle
    /// and sway gently (still under Reduce Motion).
    case glossy
    /// The look before 2.9.0: a symbol on a pale disc of its colour, a logo edge to edge.
    case flat
    /// Playing cards fanned along an arc (3.3.0): the largest amount in the middle, in front and
    /// highest, the rest by amount to either side and behind. They are dealt out of a deck, and
    /// now and then a light runs across them (not under Reduce Motion).
    case fan
    /// An orbit (3.3.0): the largest amount as a marble in the middle, the rest as smaller marbles
    /// on a tilted orbit around it that turns slowly, the far ones smaller and darker. They fly
    /// out of the middle onto it; under Reduce Motion the orbit stands still.
    case orbit
}

enum PackedCircleMetrics {
    /// The marbles' entrance: out of the middle, overshooting a little.
    static let burstSpring = Animation.spring(response: 0.55, dampingFraction: 0.62)
    static let burstHiddenScale: CGFloat = 0.2
    /// One sway, up or down.
    static let swayDuration: Double = 2.1
    /// Where each marble starts its sway, so they never move together.
    static let swayPhase: Double = 0.9

    /// Room around a white symbol inside its circle. Icon's default curve gives ~10% on the
    /// 28-44pt bracket, which at these small diameters reads as no padding at all; the curve
    /// is bumped so a symbol always has visible breathing room inside its circle.
    static func symbolPadding(for diameter: CGFloat) -> CGFloat {
        switch diameter {
        case ..<32:   return diameter * 0.18
        case 32..<48: return diameter * 0.22
        default:      return diameter * 0.26
        }
    }
}

// MARK: - Main View

public struct PackedCircleIcons: View {
    let items: [PackedCircleItem]
    var maxVisible: Int = 5
    var containerWidth: CGFloat = 120
    let style: PackedCircleIconsStyle

    /// - Parameter style: `.glossy` (2.9.0) or `.flat` (the look before).
    public init(
        items: [PackedCircleItem],
        maxVisible: Int = 5,
        containerWidth: CGFloat = 120,
        style: PackedCircleIconsStyle = .glossy
    ) {
        self.items = items
        self.maxVisible = maxVisible
        self.containerWidth = containerWidth
        self.style = style
    }

    private let containerHeight: CGFloat = 100
    private let borderWidth: CGFloat = 1

    private var visible: [PackedCircleItem] {
        Array(items.prefix(maxVisible))
    }

    private var overflowCount: Int {
        max(0, items.count - maxVisible)
    }

    /// Packed layout — derived **synchronously** from `items`, not stored in `@State`.
    ///
    /// `CirclePackingLayout.pack` is pure geometry with no SwiftUI dependency and is
    /// cheap for ≤6 circles, so it is safe to compute in `body`. Doing it here (rather
    /// than mutating `@State` from a `.task`) means every render already has the final
    /// positions: icons are never inserted with one layout and then repositioned when
    /// balances / currency conversions finish loading. That async "insert → recompute →
    /// move" was what let the icon positions get caught in an ambient animation
    /// transaction and visibly slide across the card on every Finances-tab open.
    private var packedCircles: [PackedCircle] {
        var amounts = visible.map(\.amount)
        var ids = visible.map(\.id)

        // Add overflow badge as smallest circle
        if overflowCount > 0 {
            amounts.append(0) // Will get minDiameter
            ids.append("__overflow__")
        }

        let diameters: [CGFloat]
        if overflowCount > 0 {
            // Compute diameters for visible items, force badge to minDiameter
            var d = CirclePackingLayout.diameters(for: Array(amounts.dropLast()))
            d.append(CirclePackingLayout.minDiameter)
            diameters = d
        } else {
            diameters = CirclePackingLayout.diameters(for: amounts)
        }

        return CirclePackingLayout.pack(
            ids: ids,
            diameters: diameters,
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )
    }

    public var body: some View {
        switch style {
        case .glossy, .flat:
            packed
        case .fan:
            PackedCardFan(items: visible, overflowCount: overflowCount, size: boxSize)
        case .orbit:
            PackedOrbit(items: visible, overflowCount: overflowCount, size: boxSize)
        }
    }

    private var boxSize: CGSize {
        CGSize(width: containerWidth, height: containerHeight)
    }

    private var packed: some View {
        ZStack {
            ForEach(Array(packedCircles.enumerated()), id: \.element.id) { index, circle in
                let target = CGSize(width: circle.x, height: circle.y)
                if index < visible.count {
                    PackedCircleIcon(
                        iconSource: visible[index].iconSource,
                        tintOverride: visible[index].tint,
                        diameter: circle.diameter,
                        borderWidth: borderWidth,
                        style: style,
                        index: index,
                        targetOffset: target
                    )
                } else {
                    // Overflow badge
                    PackedOverflowBadge(
                        count: overflowCount,
                        diameter: circle.diameter,
                        borderWidth: borderWidth,
                        style: style,
                        index: index,
                        targetOffset: target
                    )
                }
            }
        }
        .frame(width: containerWidth, height: containerHeight)
    }
}

// MARK: - Packed Circle Icon

private struct PackedCircleIcon: View {
    let iconSource: IconSource?
    let tintOverride: Color?
    let diameter: CGFloat
    let borderWidth: CGFloat
    let style: PackedCircleIconsStyle
    let index: Int
    let targetOffset: CGSize

    private var symbolTint: Color { tintOverride ?? AppColors.accent }

    private var flatStyle: IconStyle {
        switch iconSource {
        case .sfSymbol:
            // The symbol on a pale disc of its own colour, like every icon backing (2.0.0;
            // a grey disc before).
            let tint: IconTint = tintOverride.map { .monochrome($0) } ?? .accentMonochrome
            return .circle(
                size: diameter,
                tint: tint,
                backgroundColor: AppColors.pale(symbolTint),
                padding: PackedCircleMetrics.symbolPadding(for: diameter)
            )
        case .brandService, .none:
            // Brand logos render edge-to-edge by Icon convention — they
            // already include their own internal padding/whitespace.
            return .circle(size: diameter, tint: .original)
        }
    }

    var body: some View {
        PackedCircleEntrance(style: style, index: index, targetOffset: targetOffset) {
            switch style {
            case .flat:
                Icon(source: iconSource, style: flatStyle)
                    .overlay(Circle().strokeBorder(.background, lineWidth: borderWidth))
            case .glossy, .fan, .orbit:
                PackedMarble(iconSource: iconSource, tint: tintOverride, diameter: diameter, index: index)
            }
        }
    }
}

// MARK: - Marble

/// One item as a glossy marble (2.9.0), for `.glossy` and `.orbit`: a white symbol on a marble
/// of its colour, or the logo as the marble's skin, edge to edge, with a shadow of the logo's
/// main colour once it is known.
struct PackedMarble: View {
    let iconSource: IconSource?
    let tint: Color?
    let diameter: CGFloat
    let index: Int
    /// The slow sway of `.glossy`; an orbit moves its marbles itself.
    var sways = true

    /// A logo's main colour, for its marble's shadow.
    @State private var logoColor: Color?

    init(iconSource: IconSource?, tint: Color?, diameter: CGFloat, index: Int, sways: Bool = true) {
        self.iconSource = iconSource
        self.tint = tint
        self.diameter = diameter
        self.index = index
        self.sways = sways
    }

    private var symbolTint: Color { tint ?? AppColors.accent }

    private var brandName: String? {
        if case .brandService(let name) = iconSource { return name }
        return nil
    }

    var body: some View {
        marble
            .task(id: brandName) {
                guard let brandName else { return }
                logoColor = await DominantColorExtractor.accentColor(forBrand: brandName)
            }
    }

    @ViewBuilder
    private var marble: some View {
        switch iconSource {
        case .sfSymbol:
            GlossyMarble(diameter: diameter, shadowColor: symbolTint, index: index, sways: sways) {
                MarbleBody(tint: symbolTint, diameter: diameter)
                    .overlay {
                        Icon(source: iconSource, style: .circle(size: diameter, tint: .monochrome(.white),
                                                                padding: PackedCircleMetrics.symbolPadding(for: diameter)))
                            .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
                    }
            }
        case .brandService, .none:
            GlossyMarble(diameter: diameter, shadowColor: logoColor ?? AppColors.Text.tertiary, index: index, sways: sways) {
                Icon(source: iconSource, style: .circle(size: diameter, tint: .original))
            }
        }
    }
}

/// The "+N" marble: grey, the count in white.
struct PackedOverflowMarble: View {
    let count: Int
    let diameter: CGFloat
    let index: Int
    var sways = true

    var body: some View {
        GlossyMarble(diameter: diameter, shadowColor: AppColors.Text.tertiary, index: index, sways: sways) {
            MarbleBody(tint: AppColors.Text.tertiary, diameter: diameter)
                .overlay { PackedOverflowLabel(count: count, size: diameter).foregroundStyle(.white) }
        }
    }
}

/// "+N" for the items that did not fit, in rounded figures a third of `size`.
struct PackedOverflowLabel: View {
    let count: Int
    let size: CGFloat

    var body: some View {
        Text("+\(count)")
            .font(.system(size: size * 0.35, weight: .semibold, design: .rounded))
    }
}

// MARK: - Overflow Badge

private struct PackedOverflowBadge: View {
    let count: Int
    let diameter: CGFloat
    let borderWidth: CGFloat
    let style: PackedCircleIconsStyle
    let index: Int
    let targetOffset: CGSize

    var body: some View {
        PackedCircleEntrance(style: style, index: index, targetOffset: targetOffset) {
            switch style {
            case .flat:
                ZStack {
                    Circle().fill(.quaternary)
                    PackedOverflowLabel(count: count, size: diameter).foregroundStyle(.secondary)
                }
                .frame(width: diameter, height: diameter)
                .overlay(Circle().stroke(.background, lineWidth: borderWidth))
            case .glossy, .fan, .orbit:
                PackedOverflowMarble(count: count, diameter: diameter, index: index)
            }
        }
    }
}

// MARK: - Entrance

/// Brings a circle in. Glossy: it bursts out of the middle of the box to its place, growing
/// and overshooting a little, one after another. Flat: a staggered pop-in where it stands.
/// Under Reduce Motion it is simply there.
private struct PackedCircleEntrance<Content: View>: View {
    let style: PackedCircleIconsStyle
    let index: Int
    let targetOffset: CGSize
    @ViewBuilder let content: Content

    @State private var hasAppeared = false

    private var bursts: Bool { style == .glossy }

    private var animation: Animation {
        if AppAnimation.isReduceMotionEnabled { return .linear(duration: 0) }
        let delay = Double(index) * AppAnimation.facepileStagger
        return (bursts ? PackedCircleMetrics.burstSpring : AppAnimation.facepileSpring).delay(delay)
    }

    var body: some View {
        content
            .scaleEffect(hasAppeared ? 1 : (bursts ? PackedCircleMetrics.burstHiddenScale : AppAnimation.facepileHiddenScale))
            .opacity(hasAppeared ? 1 : 0)
            // A glossy marble starts in the middle of the box (offset zero) and flies out.
            .offset(bursts && !hasAppeared ? .zero : targetOffset)
            .animation(animation, value: hasAppeared)
            // Position is layout, never animation. The packed layout is recomputed
            // when balances/conversions finish loading; without this, that recompute
            // gets caught in an ambient transaction and the icons visibly slide into
            // place every time the Finances tab opens.
            .animation(nil, value: targetOffset)
            .task { hasAppeared = true }
    }
}

// MARK: - Glossy marble

/// A marble's coloured body: lighter where the light falls (upper left), darker at the far
/// edge, with light bounced up from below.
struct MarbleBody: View {
    let tint: Color
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(
                RadialGradient(
                    colors: [tint.mix(with: .white, by: 0.15), tint, tint.mix(with: .black, by: 0.3)],
                    center: UnitPoint(x: 0.45, y: 0.4),
                    startRadius: 0,
                    endRadius: diameter * 0.62
                )
            )
            Circle().fill(
                RadialGradient(
                    colors: [tint.mix(with: .white, by: 0.3), tint.opacity(0)],
                    center: UnitPoint(x: 0.5, y: 1.2),
                    startRadius: 0,
                    endRadius: diameter * 0.6
                )
            )
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Wraps a circle's face into a glossy marble: the highlight and shading over it, a shadow of
/// its colour under it, and (`sways`) a slow sway. In a `cardStyle()` card it keeps its colours
/// (the glass is behind the content since 3.0.0); under a `.glassEffect` applied to the content
/// itself the glass would blend its layers, and a drawing group cannot hold a loading logo's
/// spinner.
struct GlossyMarble<Face: View>: View {
    let diameter: CGFloat
    let shadowColor: Color
    let index: Int
    var sways = true
    @ViewBuilder let face: Face

    var body: some View {
        face
            .frame(width: diameter, height: diameter)
            .overlay { MarbleGloss(diameter: diameter) }
            .clipShape(Circle())
            .shadow(color: shadowColor.opacity(MarbleGlossMetrics.shadowOpacity),
                    radius: max(4, diameter * 0.12), y: max(3, diameter * 0.1))
            .modifier(MarbleSway(diameter: diameter, delay: Double(index) * PackedCircleMetrics.swayPhase, enabled: sways))
    }
}

/// How strongly a marble shines (3.3.0: softer than 2.9.0's 0.9 highlight, 0.7 rim and 0.5
/// coloured shadow, which read as too glossy).
enum MarbleGlossMetrics {
    static let highlight: Double = 0.62
    static let highlightFalloff: Double = 0.18
    static let rim: Double = 0.42
    static let shadowOpacity: Double = 0.38
}

/// The light on a marble: a highlight at the upper left, a rim light along the top, the edge
/// turning away from the light and the shade at the bottom.
private struct MarbleGloss: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(
                RadialGradient(
                    stops: [
                        .init(color: .white.opacity(MarbleGlossMetrics.highlight), location: 0),
                        .init(color: .white.opacity(MarbleGlossMetrics.highlightFalloff), location: 0.44),
                        .init(color: .white.opacity(0), location: 1),
                    ],
                    center: UnitPoint(x: 0.32, y: 0.22),
                    startRadius: 0,
                    endRadius: diameter * 0.33
                )
            )
            Circle().fill(
                RadialGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.58),
                        .init(color: .black.opacity(0.18), location: 1),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.71
                )
            )
            Circle().fill(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.55),
                        .init(color: .black.opacity(0.16), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            Circle().strokeBorder(
                LinearGradient(colors: [.white.opacity(MarbleGlossMetrics.rim), .white.opacity(0)], startPoint: .top, endPoint: .center),
                lineWidth: max(1, diameter * 0.025)
            )
        }
        .allowsHitTesting(false)
    }
}

/// A slow sway up and down, each marble on its own beat. An ambient loop: still under Reduce
/// Motion, while the system saves resources and under `.designKitMotion(false)`.
private struct MarbleSway: ViewModifier {
    let diameter: CGFloat
    let delay: Double
    let enabled: Bool

    @Environment(\.designKitMotion) private var designKitMotion
    @State private var isUp = false

    private var amplitude: CGFloat { min(2, diameter * 0.04) }

    func body(content: Content) -> some View {
        AmbientMotionGate { allowsAmbientMotion in
            let sways = enabled && allowsAmbientMotion && designKitMotion
            content
                .offset(y: sways && isUp ? -amplitude : 0)
                .animation(
                    sways
                        ? Animation.easeInOut(duration: PackedCircleMetrics.swayDuration).repeatForever(autoreverses: true).delay(delay)
                        : nil,
                    value: isUp
                )
                .task(id: sways) { isUp = sways }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `PackedCircleIcons` in its style: a few circles of falling sizes packed in
/// the same box; for `.fan` (3.3.0) grey cards fanned the same way, for `.orbit` a grey middle
/// circle with three on its orbit.
public struct PackedCircleIconsSkeleton: View {
    let containerWidth: CGFloat
    let style: PackedCircleIconsStyle

    public init(containerWidth: CGFloat = 120, style: PackedCircleIconsStyle = .glossy) {
        self.containerWidth = containerWidth
        self.style = style
    }

    private let height: CGFloat = 100

    public var body: some View {
        Group {
            switch style {
            case .glossy, .flat: circles
            case .fan: fan
            case .orbit: orbit
            }
        }
        .frame(width: containerWidth, height: height)
        .shimmer()
        .skeletonLoadingLabel()
    }

    /// Three circles touching each other, centred in the box: a big one and two smaller.
    private var circles: some View {
        let big = min(containerWidth, height) * 0.56
        let medium = big * 0.7
        let small = big * 0.5
        return ZStack {
            Skeleton.circle(big)
                .offset(x: -medium * 0.35, y: -small * 0.15)
            Skeleton.circle(medium)
                .offset(x: big * 0.45, y: -small * 0.35)
            Skeleton.circle(small)
                .offset(x: big * 0.35, y: medium * 0.5)
        }
    }

    /// Four grey cards fanned as the cards are.
    private var fan: some View {
        let slots = PackedFanLayout.slots(ids: ["0", "1", "2", "3"], scales: [1, 0.93, 0.87, 0.8],
                                          in: CGSize(width: containerWidth, height: height))
        return ZStack {
            ForEach(slots) { slot in
                RoundedRectangle(cornerRadius: slot.size.width * PackedFanMetrics.cornerRatio, style: .continuous)
                    .fill(Skeleton.fill)
                    // A seam of the background between the cards, so the fan does not merge.
                    .overlay {
                        RoundedRectangle(cornerRadius: slot.size.width * PackedFanMetrics.cornerRatio, style: .continuous)
                            .strokeBorder(.background, lineWidth: 1.5)
                    }
                    .frame(width: slot.size.width, height: slot.size.height)
                    .rotationEffect(slot.angle)
                    .offset(slot.offset)
                    .zIndex(Double(slots.count - slot.rank))
            }
        }
    }

    /// A grey middle circle, the orbit's line and three circles on it.
    private var orbit: some View {
        let geometry = PackedOrbitGeometry(box: CGSize(width: containerWidth, height: height))
        return ZStack {
            PackedOrbitPath(geometry: geometry)
            Skeleton.circle(geometry.centreDiameter)
            ForEach(0..<3, id: \.self) { index in
                let place = geometry.place(at: PackedOrbitGeometry.startAngle(index, of: 3))
                Skeleton.circle(geometry.satelliteDiameter * PackedOrbitGeometry.depthScale(place.nearness))
                    .offset(place.offset)
                    .zIndex(Double(place.nearness) * 2 - 1)
            }
        }
    }
}
