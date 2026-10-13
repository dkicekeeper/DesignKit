//
//  PackedCircleIconsShelf.swift
//  DesignKit
//
//  `PackedCircleIcons(style: .shelf)` (4.4.0): the items as app icons standing in a row in a
//  pocket. Square tiles of one size, the largest amount on the left, each a little over the one
//  before it and turned a few degrees, cut off flat by the box's lower edge, so every icon reads.
//  The box is as tall as the row needs, up to the height it is given.
//  They rise out of the pocket one after another on appear, and every few seconds a light runs
//  across them from left to right. It replaced 3.3.0's fan of playing cards, where the cards
//  behind the top one barely showed.
//
//  A logo fills its tile, as an app icon does; a symbol is white on a tile of its colour; the
//  "+N" tile is grey.
//

import SwiftUI
import DesignTokens
import DesignSupport

enum PackedShelfMetrics {
    /// The share of a tile's height above the pocket.
    static let exposure: CGFloat = 0.74
    /// How far a tile covers the one before it, in widths: the most the tiles keep to, and the
    /// most they take to stay `minSide` wide in a narrow box.
    static let targetOverlap: CGFloat = 0.1
    static let maxOverlap: CGFloat = 0.3
    /// The least they overlap when the box is wide: they never stand apart.
    static let minOverlap: CGFloat = 0.06
    static let minSide: CGFloat = 28
    /// Room for the turned tiles' corners and lifts, in widths, and for their shadows.
    static let tiltSlack: CGFloat = 0.1
    static let margin: CGFloat = 4
    /// An app icon's corner, as a share of its side.
    static let cornerRatio: CGFloat = 0.225
    /// Each tile's turn (degrees, clockwise) and lift (in sides), by position: never two alike
    /// side by side, as if put in by hand.
    static let tilts: [Double] = [-6, 4, -3, 5, -4, 3, -5]
    static let lifts: [CGFloat] = [0, 0.03, 0.01, 0.04, 0.02, 0.035, 0.015]
    /// The shade where the tiles go into the pocket, in sides above its edge.
    static let shadeDepth: CGFloat = 0.22
    static let shadeOpacity: Double = 0.16
    /// The rise out of the pocket: tile after tile, from the left.
    static let riseSpring = Animation.spring(response: 0.55, dampingFraction: 0.72)
    static let riseStagger: Double = 0.07
    /// The light running across the tiles: once after the rise, then every few seconds, tile
    /// after tile from the left.
    static let firstShine: Double = 1.0
    static let shineInterval: Double = 4.5
    static let shineStagger: Double = 0.09
}

/// Where a tile stands on the shelf.
struct PackedShelfSlot: Identifiable, Equatable {
    let id: String
    /// Left to right, from 0.
    let position: Int
    /// The tile's turn, clockwise.
    let angle: Angle
    /// The tile's centre, from the box's centre.
    let offset: CGSize
    let side: CGFloat
}

enum PackedShelfLayout {
    /// A tile's side for `count` tiles in `box`: as large as the height allows and as close as
    /// `targetOverlap` lets them fit; in a narrow box they overlap more (up to `maxOverlap`) to
    /// stay `minSide` wide.
    static func side(count: Int, in box: CGSize) -> CGFloat {
        guard count > 0, box.width > 0, box.height > 0 else { return 0 }
        let metrics = PackedShelfMetrics.self
        let width = box.width - 2 * metrics.margin
        let gaps = CGFloat(count - 1)
        func widthFitting(overlap: CGFloat) -> CGFloat {
            width / (1 + metrics.tiltSlack + gaps * (1 - overlap))
        }
        let byHeight = (box.height - metrics.margin) / (metrics.exposure + metrics.tiltSlack)
        let byWidth = max(widthFitting(overlap: metrics.targetOverlap),
                          min(metrics.minSide, widthFitting(overlap: metrics.maxOverlap)))
        return max(0, min(byHeight, byWidth))
    }

    /// The box the row takes: the width it is given, and as tall as the tiles above the pocket
    /// need, up to the height it is given.
    static func fittedBox(count: Int, in box: CGSize) -> CGSize {
        let metrics = PackedShelfMetrics.self
        let side = side(count: count, in: box)
        return CGSize(width: box.width,
                      height: min(box.height, side * (metrics.exposure + metrics.tiltSlack) + metrics.margin))
    }

    /// The row for `ids` (left to right) in `box`, the pocket's edge at the box's lower edge.
    /// The tiles spread over the width, overlapping at least `minOverlap`, the row centred.
    static func slots(ids: [String], in box: CGSize) -> [PackedShelfSlot] {
        let count = ids.count
        guard count > 0, box.width > 0, box.height > 0 else { return [] }
        let metrics = PackedShelfMetrics.self
        let width = box.width - 2 * metrics.margin
        let gaps = CGFloat(count - 1)
        let side = side(count: count, in: box)
        let step = count > 1
            ? min(side * (1 - metrics.minOverlap), (width - side * (1 + metrics.tiltSlack)) / gaps)
            : 0
        let row = side + step * gaps
        let pocket = box.height / 2

        return ids.enumerated().map { position, id in
            let lift = side * metrics.lifts[position % metrics.lifts.count]
            return PackedShelfSlot(
                id: id,
                position: position,
                angle: .degrees(metrics.tilts[position % metrics.tilts.count]),
                offset: CGSize(
                    width: -row / 2 + side / 2 + CGFloat(position) * step,
                    height: pocket - side * metrics.exposure - lift + side / 2
                ),
                side: side
            )
        }
    }
}

/// Clips to everything above the view's lower edge: the tiles' tops, turned corners and
/// shadows stay whole, and below the edge they are in the pocket.
struct PackedPocketShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX - rect.width, y: rect.minY - rect.height,
                    width: rect.width * 3, height: rect.height * 2))
    }
}

// MARK: - Shelf

struct PackedShelf: View {
    static let overflowID = "__overflow__"

    let items: [PackedCircleItem]
    let overflowCount: Int
    let size: CGSize

    @Environment(\.designKitMotion) private var designKitMotion
    /// Counts the lights that have run across the shelf.
    @State private var sweep = 0

    init(items: [PackedCircleItem], overflowCount: Int, size: CGSize) {
        self.items = items
        self.overflowCount = overflowCount
        self.size = size
    }

    /// The items by amount, the largest first (on the left).
    private var ranked: [PackedCircleItem] {
        items.sorted { $0.amount > $1.amount }
    }

    private var ids: [String] {
        var ids = ranked.map(\.id)
        if overflowCount > 0 { ids.append(Self.overflowID) }
        return ids
    }

    var body: some View {
        let ranked = self.ranked
        let ids = self.ids
        let box = PackedShelfLayout.fittedBox(count: ids.count, in: size)
        let slots = PackedShelfLayout.slots(ids: ids, in: box)
        let side = slots.first?.side ?? 0
        AmbientMotionGate { allowsAmbientMotion in
            ZStack {
                ForEach(slots) { slot in
                    PackedShelfTile(
                        item: slot.position < ranked.count ? ranked[slot.position] : nil,
                        overflowCount: overflowCount,
                        slot: slot,
                        sweep: sweep
                    )
                    // Each tile stands over the one on its left.
                    .zIndex(Double(slot.position))
                }
                // The tiles darken where they go into the pocket.
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(PackedShelfMetrics.shadeOpacity)],
                    startPoint: UnitPoint(x: 0.5, y: max(0, 1 - side * PackedShelfMetrics.shadeDepth / max(box.height, 1))),
                    endPoint: .bottom
                )
                .blendMode(.sourceAtop)
                .zIndex(Double(slots.count))
                .allowsHitTesting(false)
            }
            .frame(width: box.width, height: box.height)
            .compositingGroup()
            .clipShape(PackedPocketShape())
            .task(id: allowsAmbientMotion && designKitMotion) {
                guard allowsAmbientMotion && designKitMotion else { return }
                try? await Task.sleep(for: .seconds(PackedShelfMetrics.firstShine))
                while !Task.isCancelled {
                    sweep += 1
                    try? await Task.sleep(for: .seconds(PackedShelfMetrics.shineInterval))
                }
            }
        }
    }
}

// MARK: - Tile

private struct PackedShelfTile: View {
    /// `nil`: the "+N" tile.
    let item: PackedCircleItem?
    let overflowCount: Int
    let slot: PackedShelfSlot
    let sweep: Int

    @Environment(\.designKitMotion) private var designKitMotion
    @State private var hasRisen = false
    @State private var shine = 0

    private var side: CGFloat { slot.side }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: side * PackedShelfMetrics.cornerRatio, style: .continuous)
    }

    private var symbolName: String? {
        if case .sfSymbol(let name) = item?.iconSource { return name }
        return nil
    }

    private var riseAnimation: Animation? {
        guard designKitMotion, !AppAnimation.isReduceMotionEnabled else { return nil }
        return PackedShelfMetrics.riseSpring.delay(Double(slot.position) * PackedShelfMetrics.riseStagger)
    }

    var body: some View {
        face
            .frame(width: side, height: side)
            .clipShape(shape)
            .overlay {
                // Light catching the upper edge, as on a glossy app icon.
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0)], startPoint: .top, endPoint: .center),
                    lineWidth: max(1, side * 0.02)
                )
            }
            .shine(trigger: shine, in: shape)
            // Falls on the tile to the left, under this one.
            .shadow(color: .black.opacity(0.2), radius: max(2, side * 0.06), x: -side * 0.025, y: side * 0.01)
            .rotationEffect(slot.angle)
            // Below the pocket's edge until it rises.
            .offset(x: slot.offset.width, y: slot.offset.height + (hasRisen ? 0 : side * 1.2))
            .animation(riseAnimation, value: hasRisen)
            // Position is layout, never animation (see PackedCircleEntrance).
            .animation(nil, value: slot)
            .task { hasRisen = true }
            .task(id: sweep) {
                guard sweep > 0 else { return }
                // The light runs from the left: the tiles further left catch it first.
                try? await Task.sleep(for: .seconds(Double(slot.position) * PackedShelfMetrics.shineStagger))
                guard !Task.isCancelled else { return }
                shine += 1
            }
    }

    @ViewBuilder
    private var face: some View {
        if let item, let symbolName {
            symbolFace(tint: item.tint ?? AppColors.accent, symbolName: symbolName)
        } else if let item {
            // The logo is the tile, edge to edge, as an app icon; white behind a logo that
            // does not fill its square.
            ZStack {
                Rectangle().fill(.white)
                Icon(source: item.iconSource, style: .square(size: side, tint: .original))
            }
        } else {
            overflowFace
        }
    }

    /// A white symbol on a tile of its colour, lit from the upper left, in the part of the tile
    /// above the pocket.
    private func symbolFace(tint: Color, symbolName: String) -> some View {
        ZStack {
            Rectangle().fill(
                LinearGradient(
                    colors: [tint.mix(with: .white, by: 0.18), tint, tint.mix(with: .black, by: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            Image(systemName: symbolName)
                .font(.system(size: side * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5)
                .offset(y: -side * 0.06)
        }
    }

    /// "+N" on a grey tile, in the part above the pocket.
    private var overflowFace: some View {
        let grey = AppColors.Text.tertiary
        return ZStack {
            Rectangle().fill(
                LinearGradient(colors: [grey.mix(with: .white, by: 0.15), grey.mix(with: .black, by: 0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            PackedOverflowLabel(count: overflowCount, size: side)
                .foregroundStyle(.white)
                .offset(y: -side * 0.08)
        }
    }
}
