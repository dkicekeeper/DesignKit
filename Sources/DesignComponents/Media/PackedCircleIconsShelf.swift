//
//  PackedCircleIconsShelf.swift
//  DesignKit
//
//  `PackedCircleIcons(style: .shelf)` (4.4.0): the items as app icons standing in a row. Square
//  tiles of one size, the largest amount on the left, each a little over the one before it and
//  turned a few degrees, so every icon reads.
//  4.5.1: the tiles are one size in every shelf, whatever the count (they shrank with more items
//  before); as many as fit the width stand in the row, the rest go into the "+N" tile, and the
//  box is as wide and as tall as the row, up to the size it is given.
//  4.14.0 (the owner's review on a device): the tiles are whole, 48 pt (36 pt before), and the
//  shelf is 160 pt wide by default (120 pt before), four tiles; until then the box's lower edge
//  cut them off as if they stood in a pocket.
//  They come up one after another on appear, and every few seconds a light runs across them
//  from left to right. It replaced 3.3.0's fan of playing cards, where the cards behind the top
//  one barely showed.
//
//  A logo fills its tile, as an app icon does; a symbol is white on a tile of its colour; the
//  "+N" tile is grey.
//

import SwiftUI
import DesignTokens
import DesignSupport

enum PackedShelfMetrics {
    /// A tile's side in every shelf (48 pt since 4.14.0, 36 pt in 4.5.1), less only in a box
    /// too small for one tile.
    static let side: CGFloat = 48
    /// How far a tile covers the one before it, in widths: when there is room, and the most
    /// they close up to fit one more tile in the width.
    static let targetOverlap: CGFloat = 0.1
    static let maxOverlap: CGFloat = 0.36
    /// Room for the turned tiles' corners and lifts, in sides, and for their shadows.
    static let tiltSlack: CGFloat = 0.1
    static let margin: CGFloat = 4
    /// An app icon's corner, as a share of its side.
    static let cornerRatio: CGFloat = 0.225
    /// Each tile's turn (degrees, clockwise) and lift (in sides), by position: never two alike
    /// side by side, as if put in by hand.
    static let tilts: [Double] = [-6, 4, -3, 5, -4, 3, -5]
    static let lifts: [CGFloat] = [0, 0.03, 0.01, 0.04, 0.02, 0.035, 0.015]
    /// The entrance: tile after tile, from the left, each coming up from a little lower and
    /// growing a little as it fades in.
    static let riseSpring = Animation.spring(response: 0.55, dampingFraction: 0.72)
    static let riseStagger: Double = 0.07
    static let riseDrop: CGFloat = 0.3
    static let riseHiddenScale: CGFloat = 0.9
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
    /// A tile's side in `box`: `PackedShelfMetrics.side`, whatever the count (4.5.1), less only
    /// when the box is too low or too narrow for one tile.
    static func side(in box: CGSize) -> CGFloat {
        guard box.width > 0, box.height > 0 else { return 0 }
        let metrics = PackedShelfMetrics.self
        let byHeight = (box.height - 2 * metrics.margin) / (1 + metrics.tiltSlack)
        let byWidth = (box.width - 2 * metrics.margin) / (1 + metrics.tiltSlack)
        return max(0, min(metrics.side, byHeight, byWidth))
    }

    /// How many tiles fit across `box`, overlapping at most `maxOverlap`.
    static func capacity(in box: CGSize) -> Int {
        let metrics = PackedShelfMetrics.self
        let side = side(in: box)
        guard side > 0 else { return 0 }
        let room = box.width - 2 * metrics.margin - side * (1 + metrics.tiltSlack)
        return 1 + max(0, Int((room / (side * (1 - metrics.maxOverlap))).rounded(.down)))
    }

    /// From one tile's centre to the next for `count` tiles across `width`: `targetOverlap`
    /// apart, closer (up to `maxOverlap`, `capacity`) when the width is short.
    static func step(count: Int, side: CGFloat, width: CGFloat) -> CGFloat {
        guard count > 1 else { return 0 }
        let metrics = PackedShelfMetrics.self
        let room = width - 2 * metrics.margin - side * (1 + metrics.tiltSlack)
        return max(0, min(side * (1 - metrics.targetOverlap), room / CGFloat(count - 1)))
    }

    /// The box the row of `count` tiles takes: as wide as the row and as tall as its turned
    /// tiles, up to the box it is given.
    static func fittedBox(count: Int, in box: CGSize) -> CGSize {
        let metrics = PackedShelfMetrics.self
        let side = side(in: box)
        let row = side * (1 + metrics.tiltSlack)
            + CGFloat(max(count - 1, 0)) * step(count: count, side: side, width: box.width)
        return CGSize(width: min(box.width, row + 2 * metrics.margin),
                      height: min(box.height, side * (1 + metrics.tiltSlack) + 2 * metrics.margin))
    }

    /// The row for `ids` (left to right) in `box` (`fittedBox`), centred, each tile lifted a
    /// little by its position.
    static func slots(ids: [String], in box: CGSize) -> [PackedShelfSlot] {
        let count = ids.count
        guard count > 0, box.width > 0, box.height > 0 else { return [] }
        let metrics = PackedShelfMetrics.self
        let side = side(in: box)
        let step = step(count: count, side: side, width: box.width)
        let gaps = CGFloat(count - 1)
        let row = side + step * gaps
        // The lifts are centred in the box's room for them.
        let middleLift = (metrics.lifts.max() ?? 0) / 2

        return ids.enumerated().map { position, id in
            let lift = side * metrics.lifts[position % metrics.lifts.count]
            return PackedShelfSlot(
                id: id,
                position: position,
                angle: .degrees(metrics.tilts[position % metrics.tilts.count]),
                offset: CGSize(
                    width: -row / 2 + side / 2 + CGFloat(position) * step,
                    height: side * middleLift - lift
                ),
                side: side
            )
        }
    }
}

// MARK: - Shelf

struct PackedShelf: View {
    static let overflowID = "__overflow__"

    /// All the items: the shelf shows the largest that fit.
    let items: [PackedCircleItem]
    /// The most items shown; past it, or past the width, the rest go into "+N".
    let maxVisible: Int
    let size: CGSize

    @Environment(\.designKitMotion) private var designKitMotion
    /// Counts the lights that have run across the shelf.
    @State private var sweep = 0

    init(items: [PackedCircleItem], maxVisible: Int, size: CGSize) {
        self.items = items
        self.maxVisible = maxVisible
        self.size = size
    }

    /// The items shown, by amount, the largest first (on the left), and how many go into "+N".
    static func shown(_ items: [PackedCircleItem], maxVisible: Int, in size: CGSize) -> (items: [PackedCircleItem], overflow: Int) {
        let ranked = items.sorted { $0.amount > $1.amount }
        let room = PackedShelfLayout.capacity(in: size)
        if ranked.count <= min(maxVisible, room) { return (ranked, 0) }
        // One tile goes to "+N".
        let count = max(0, min(maxVisible, room - 1))
        return (Array(ranked.prefix(count)), ranked.count - count)
    }

    var body: some View {
        let shown = Self.shown(items, maxVisible: maxVisible, in: size)
        let ranked = shown.items
        let overflowCount = shown.overflow
        let ids = ranked.map(\.id) + (overflowCount > 0 ? [Self.overflowID] : [])
        let box = PackedShelfLayout.fittedBox(count: ids.count, in: size)
        let slots = PackedShelfLayout.slots(ids: ids, in: box)
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
            }
            .frame(width: box.width, height: box.height)
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
            // A little lower, smaller and clear until it comes up.
            .scaleEffect(hasRisen ? 1 : PackedShelfMetrics.riseHiddenScale)
            .opacity(hasRisen ? 1 : 0)
            .offset(x: slot.offset.width,
                    y: slot.offset.height + (hasRisen ? 0 : side * PackedShelfMetrics.riseDrop))
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

    /// A white symbol on a tile of its colour, lit from the upper left.
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
        }
    }

    /// "+N" on a grey tile.
    private var overflowFace: some View {
        let grey = AppColors.Text.tertiary
        return ZStack {
            Rectangle().fill(
                LinearGradient(colors: [grey.mix(with: .white, by: 0.15), grey.mix(with: .black, by: 0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            PackedOverflowLabel(count: overflowCount, size: side)
                .foregroundStyle(.white)
        }
    }
}
