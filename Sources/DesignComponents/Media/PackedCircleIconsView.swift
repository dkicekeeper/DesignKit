//
//  PackedCircleIconsView.swift
//  Tenra
//
//  Packed circle layout for subscription/loan icon display.
//  Circle size reflects item cost; circles are tightly packed without overlap.
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

// MARK: - Main View

public struct PackedCircleIconsView: View {
    let items: [PackedCircleItem]
    var maxVisible: Int = 5
    var containerWidth: CGFloat = 120

    public init(items: [PackedCircleItem], maxVisible: Int = 5, containerWidth: CGFloat = 120) {
        self.items = items
        self.maxVisible = maxVisible
        self.containerWidth = containerWidth
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
        ZStack {
            ForEach(Array(packedCircles.enumerated()), id: \.element.id) { index, circle in
                let target = CGSize(width: circle.x, height: circle.y)
                if index < visible.count {
                    PackedCircleIcon(
                        iconSource: visible[index].iconSource,
                        tintOverride: visible[index].tint,
                        diameter: circle.diameter,
                        borderWidth: borderWidth,
                        animationDelay: Double(index) * AppAnimation.facepileStagger,
                        targetOffset: target
                    )
                } else {
                    // Overflow badge
                    PackedOverflowBadge(
                        count: overflowCount,
                        diameter: circle.diameter,
                        borderWidth: borderWidth,
                        animationDelay: Double(index) * AppAnimation.facepileStagger,
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
    let animationDelay: Double
    let targetOffset: CGSize

    @State private var hasAppeared = false

    /// Adaptive padding for packed-circle SF symbols. IconView's default curve
    /// gives ~10% on the 28-44pt bracket, which at our small packed diameters
    /// reads as no padding at all (especially with the 2pt outer stroke). We
    /// bump the curve so SF symbols always have visible breathing room inside
    /// their circle background, matching the spirit of IconView's padding rules.
    private var sfSymbolPadding: CGFloat {
        switch diameter {
        case ..<32:   return diameter * 0.18
        case 32..<48: return diameter * 0.22
        default:      return diameter * 0.26
        }
    }

    private var iconStyle: IconStyle {
        switch iconSource {
        case .sfSymbol:
            let tint: IconTint = tintOverride.map { .monochrome($0) } ?? .accentMonochrome
            return .circle(
                size: diameter,
                tint: tint,
                backgroundColor: AppColors.Background.neutral1,
                padding: sfSymbolPadding
            )
        case .brandService, .none:
            // Brand logos render edge-to-edge by IconView convention — they
            // already include their own internal padding/whitespace.
            return .circle(size: diameter, tint: .original)
        }
    }

    public var body: some View {
        IconView(source: iconSource, style: iconStyle)
            .overlay(Circle().strokeBorder(.background, lineWidth: borderWidth))
            // Entrance animates scale + opacity only — a staggered pop-in, no slide.
            .scaleEffect(hasAppeared ? 1 : AppAnimation.facepileHiddenScale)
            .opacity(hasAppeared ? 1 : 0)
            .animation(
                AppAnimation.isReduceMotionEnabled
                    ? .linear(duration: 0)
                    : AppAnimation.facepileSpring.delay(animationDelay),
                value: hasAppeared
            )
            .offset(targetOffset)
            // Position is layout, never animation. The packed layout is recomputed
            // when balances/conversions finish loading; without this, that recompute
            // gets caught in an ambient transaction and the icons visibly slide into
            // place every time the Finances tab opens.
            .animation(nil, value: targetOffset)
            .task { hasAppeared = true }
    }
}

// MARK: - Overflow Badge

private struct PackedOverflowBadge: View {
    let count: Int
    let diameter: CGFloat
    let borderWidth: CGFloat
    let animationDelay: Double
    let targetOffset: CGSize

    @State private var hasAppeared = false

    public var body: some View {
        ZStack {
            Circle().fill(.quaternary)
            Text("+\(count)")
                .font(.system(size: diameter * 0.35, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(width: diameter, height: diameter)
        .overlay(Circle().stroke(.background, lineWidth: borderWidth))
        .scaleEffect(hasAppeared ? 1 : AppAnimation.facepileHiddenScale)
        .opacity(hasAppeared ? 1 : 0)
        .animation(
            AppAnimation.isReduceMotionEnabled
                ? .linear(duration: 0)
                : AppAnimation.facepileSpring.delay(animationDelay),
            value: hasAppeared
        )
        .offset(targetOffset)
        .animation(nil, value: targetOffset)
        .task { hasAppeared = true }
    }
}

// MARK: - Previews





// MARK: - Skeleton

/// Placeholder of a `PackedCircleIconsView`: a few circles of falling sizes packed in the
/// same box.
public struct PackedCircleIconsViewSkeleton: View {
    let containerWidth: CGFloat

    public init(containerWidth: CGFloat = 120) {
        self.containerWidth = containerWidth
    }

    public var body: some View {
        // Three circles touching each other, centred in the box: a big one and two smaller.
        let height: CGFloat = 100
        let big = min(containerWidth, height) * 0.56
        let medium = big * 0.7
        let small = big * 0.5
        ZStack {
            SkeletonView.circle(big)
                .offset(x: -medium * 0.35, y: -small * 0.15)
            SkeletonView.circle(medium)
                .offset(x: big * 0.45, y: -small * 0.35)
            SkeletonView.circle(small)
                .offset(x: big * 0.35, y: medium * 0.5)
        }
        .frame(width: containerWidth, height: height)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
