//
//  PackedCircleIconsFan.swift
//  DesignKit
//
//  `PackedCircleIcons(style: .fan)` (3.3.0): the items as playing cards fanned along an arc.
//  The largest amount stands in the middle, in front and highest; the rest follow by amount to
//  either side, each turned further out and lying behind the one before. The cards are dealt
//  out of a deck on appear, and every few seconds a light runs across them from left to right.
//
//  A symbol is white on a card of its colour, with small copies in two corners as a playing
//  card has; a logo sits on a white card, its corners and edge in the logo's main colour.
//

import SwiftUI
import DesignTokens
import DesignSupport

enum PackedFanMetrics {
    /// A playing card's width to its height (63 × 88 mm).
    static let aspect: CGFloat = 0.7
    /// From the arc's centre to the cards' lower edges, in heights of the largest card.
    static let pivot: CGFloat = 1.3
    /// The smallest card's height next to the largest one's, and the "+N" card's.
    static let smallestScale: CGFloat = 0.8
    static let overflowScale: CGFloat = 0.76
    /// Room for the shadows inside the box.
    static let margin: CGFloat = 4
    /// The corner, as a share of the card's width.
    static let cornerRatio: CGFloat = 0.12
    /// The deal: card after card, from the deck to its place.
    static let dealSpring = Animation.spring(response: 0.5, dampingFraction: 0.72)
    static let dealStagger: Double = 0.07
    static let deckScale: CGFloat = 0.86
    /// The light running across the cards: every few seconds, card after card from the left.
    static let shineInterval: Double = 4.5
    static let shineStagger: Double = 0.09

    /// The angle between neighbouring cards, in degrees: wider with fewer cards.
    static func step(count: Int) -> Double {
        guard count > 1 else { return 0 }
        return max(7, 15 - 1.5 * Double(count - 1))
    }
}

/// Where a card lies in the fan.
struct PackedFanSlot: Identifiable, Equatable {
    let id: String
    /// 0 for the largest amount, which lies on top.
    let rank: Int
    /// Left to right, from 0.
    let position: Int
    /// The card's turn, clockwise.
    let angle: Angle
    /// The card's centre, from the box's centre.
    let offset: CGSize
    let size: CGSize
}

enum PackedFanLayout {
    /// The fan for cards of relative heights `scales` (in rank order, 1 for the largest), fitted
    /// into `box`. The positions run left to right at equal angles around a centre below the
    /// box, every card's lower edge on one arc; the largest takes the middle position and the
    /// rest the next ones out, the right one first.
    static func slots(ids: [String], scales: [CGFloat], in box: CGSize) -> [PackedFanSlot] {
        let count = min(ids.count, scales.count)
        guard count > 0, box.width > 0, box.height > 0 else { return [] }
        let step = PackedFanMetrics.step(count: count) * .pi / 180
        let middle = Double(count - 1) / 2
        let positions = (0..<count).sorted { a, b in
            let da = abs(Double(a) - middle), db = abs(Double(b) - middle)
            return da == db ? a > b : da < db
        }

        // The arc's centre at the origin, y up.
        var cards: [(angle: Double, center: CGPoint, size: CGSize)] = []
        var minX = Double.infinity, maxX = -Double.infinity
        var minY = Double.infinity, maxY = -Double.infinity
        for rank in 0..<count {
            let angle = (Double(positions[rank]) - middle) * step
            let height = Double(scales[rank])
            let width = height * Double(PackedFanMetrics.aspect)
            let radius = Double(PackedFanMetrics.pivot) + height / 2
            let center = CGPoint(x: radius * sin(angle), y: radius * cos(angle))
            for (u, v) in [(-width / 2, -height / 2), (width / 2, -height / 2), (-width / 2, height / 2), (width / 2, height / 2)] {
                let x = center.x + u * cos(angle) + v * sin(angle)
                let y = center.y - u * sin(angle) + v * cos(angle)
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
            cards.append((angle, center, CGSize(width: width, height: height)))
        }

        let margin = Double(PackedFanMetrics.margin)
        let scale = max(0, min((Double(box.width) - 2 * margin) / (maxX - minX),
                               (Double(box.height) - 2 * margin) / (maxY - minY)))
        let midX = (minX + maxX) / 2, midY = (minY + maxY) / 2
        return cards.enumerated().map { rank, card in
            PackedFanSlot(
                id: ids[rank],
                rank: rank,
                position: positions[rank],
                angle: .radians(card.angle),
                offset: CGSize(width: (card.center.x - midX) * scale, height: -(card.center.y - midY) * scale),
                size: CGSize(width: card.size.width * scale, height: card.size.height * scale)
            )
        }
    }

    /// Heights for items of `amounts` in rank order: the largest 1, the rest down to
    /// `smallestScale` by the square root of their share, and the "+N" card after them.
    static func scales(amounts: [Double], hasOverflow: Bool) -> [CGFloat] {
        let largest = amounts.first.map { max($0, 0) } ?? 0
        let smallest = PackedFanMetrics.smallestScale
        var scales = amounts.map { amount -> CGFloat in
            guard largest > 0 else { return 1 }
            return smallest + (1 - smallest) * CGFloat((max(amount, 0) / largest).squareRoot())
        }
        if hasOverflow { scales.append(PackedFanMetrics.overflowScale) }
        return scales
    }
}

// MARK: - Fan

struct PackedCardFan: View {
    let items: [PackedCircleItem]
    let overflowCount: Int
    let size: CGSize

    @Environment(\.designKitMotion) private var designKitMotion
    /// Counts the lights that have run across the fan.
    @State private var sweep = 0

    init(items: [PackedCircleItem], overflowCount: Int, size: CGSize) {
        self.items = items
        self.overflowCount = overflowCount
        self.size = size
    }

    /// The items by amount, the largest first.
    private var ranked: [PackedCircleItem] {
        items.sorted { $0.amount > $1.amount }
    }

    private var slots: [PackedFanSlot] {
        let ranked = self.ranked
        var ids = ranked.map(\.id)
        if overflowCount > 0 { ids.append(PackedFanCard.overflowID) }
        let scales = PackedFanLayout.scales(amounts: ranked.map(\.amount), hasOverflow: overflowCount > 0)
        return PackedFanLayout.slots(ids: ids, scales: scales, in: size)
    }

    var body: some View {
        let ranked = self.ranked
        let slots = self.slots
        AmbientMotionGate { allowsAmbientMotion in
            ZStack {
                ForEach(slots) { slot in
                    PackedFanCard(
                        item: slot.rank < ranked.count ? ranked[slot.rank] : nil,
                        overflowCount: overflowCount,
                        slot: slot,
                        deck: slots.first?.offset ?? .zero,
                        sweep: sweep
                    )
                    .zIndex(Double(slots.count - slot.rank))
                }
            }
            .frame(width: size.width, height: size.height)
            .task(id: allowsAmbientMotion && designKitMotion) {
                guard allowsAmbientMotion && designKitMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(PackedFanMetrics.shineInterval))
                    guard !Task.isCancelled else { break }
                    sweep += 1
                }
            }
        }
    }
}

// MARK: - Card

private struct PackedFanCard: View {
    static let overflowID = "__overflow__"

    /// `nil`: the "+N" card.
    let item: PackedCircleItem?
    let overflowCount: Int
    let slot: PackedFanSlot
    /// Where the deck lies before the deal: the top card's place.
    let deck: CGSize
    let sweep: Int

    @Environment(\.designKitMotion) private var designKitMotion
    @State private var isDealt = false
    @State private var shine = 0
    /// A logo's main colour, for its card's corners and edge.
    @State private var logoColor: Color?

    private var width: CGFloat { slot.size.width }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: width * PackedFanMetrics.cornerRatio, style: .continuous)
    }

    private var brandName: String? {
        if case .brandService(let name) = item?.iconSource { return name }
        return nil
    }

    private var symbolName: String? {
        if case .sfSymbol(let name) = item?.iconSource { return name }
        return nil
    }

    private var dealAnimation: Animation? {
        guard designKitMotion, !AppAnimation.isReduceMotionEnabled else { return nil }
        return PackedFanMetrics.dealSpring.delay(Double(slot.rank) * PackedFanMetrics.dealStagger)
    }

    var body: some View {
        face
            .frame(width: slot.size.width, height: slot.size.height)
            .clipShape(shape)
            .shine(trigger: shine, in: shape)
            .shadow(color: .black.opacity(0.22), radius: max(2, width * 0.09), y: max(1, width * 0.05))
            .scaleEffect(isDealt ? 1 : PackedFanMetrics.deckScale)
            .rotationEffect(isDealt ? slot.angle : .zero)
            .offset(isDealt ? slot.offset : deck)
            .opacity(isDealt ? 1 : 0)
            .animation(dealAnimation, value: isDealt)
            // Position is layout, never animation (see PackedCircleEntrance).
            .animation(nil, value: slot)
            .task { isDealt = true }
            .task(id: sweep) {
                guard sweep > 0 else { return }
                // The light runs from the left: the cards further left catch it first.
                try? await Task.sleep(for: .seconds(Double(slot.position) * PackedFanMetrics.shineStagger))
                guard !Task.isCancelled else { return }
                shine += 1
            }
            .task(id: brandName) {
                guard let brandName else { return }
                logoColor = await DominantColorExtractor.accentColor(forBrand: brandName)
            }
    }

    @ViewBuilder
    private var face: some View {
        if let item, let symbolName {
            symbolFace(item: item, symbolName: symbolName)
        } else if let item {
            logoFace(item: item)
        } else {
            overflowFace
        }
    }

    /// A white symbol on a card of its colour, lit from the upper left, with small copies in
    /// two corners.
    private func symbolFace(item: PackedCircleItem, symbolName: String) -> some View {
        let tint = item.tint ?? AppColors.accent
        return ZStack {
            Rectangle().fill(
                LinearGradient(
                    colors: [tint.mix(with: .white, by: 0.2), tint, tint.mix(with: .black, by: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            Icon(source: item.iconSource, style: .circle(size: width * 0.66, tint: .monochrome(.white),
                                                         padding: PackedCircleMetrics.symbolPadding(for: width * 0.66)))
                .shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5)
        }
        .overlay { corners { Image(systemName: symbolName).font(.system(size: width * 0.14, weight: .semibold)) } }
        .foregroundStyle(.white.opacity(0.85))
        .overlay { edge(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom)) }
    }

    /// A logo on a white card, its corners and edge in the logo's main colour.
    private func logoFace(item: PackedCircleItem) -> some View {
        let accent = logoColor ?? AppColors.Text.tertiary
        return ZStack {
            Rectangle().fill(.white)
            Icon(source: item.iconSource, style: .circle(size: width * 0.66, tint: .original))
        }
        .overlay { corners { Circle().fill(accent).frame(width: width * 0.11, height: width * 0.11) } }
        .overlay { edge(accent.opacity(0.55)) }
    }

    /// "+N" on a grey card, and small in two corners: an outer card shows only its edge.
    private var overflowFace: some View {
        let grey = AppColors.Text.tertiary
        return ZStack {
            Rectangle().fill(
                LinearGradient(colors: [grey.mix(with: .white, by: 0.15), grey.mix(with: .black, by: 0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            PackedOverflowLabel(count: overflowCount, size: width)
        }
        .overlay { corners { PackedOverflowLabel(count: overflowCount, size: width * 0.42) } }
        .foregroundStyle(.white)
        .overlay { edge(Color.white.opacity(0.3)) }
    }

    /// A pip in the upper left corner and, upside down, in the lower right one.
    private func corners<Pip: View>(@ViewBuilder _ pip: () -> Pip) -> some View {
        let pip = pip()
        let inset = width * 0.1
        return ZStack {
            pip
                .padding(inset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            pip
                .rotationEffect(.degrees(180))
                .padding(inset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .accessibilityHidden(true)
    }

    private func edge<S: ShapeStyle>(_ style: S) -> some View {
        shape.strokeBorder(style, lineWidth: max(1, width * 0.025))
    }
}
