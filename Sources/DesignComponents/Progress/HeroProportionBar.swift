//
//  HeroProportionBar.swift
//  Tenra
//
//  Full-size interactive hero sibling of the feed's `MiniProportionBar`
//  (2026-07 visual refresh follow-up). The mini is a text-free stacked bar;
//  at hero size the composition becomes explorable and self-explanatory:
//  - legend rows (color dot + name + share % + amount) make the bar readable
//    without guessing which stripe is which
//  - tapping a segment or its legend row highlights that slice (others dim)
//  - staggered left-to-right entrance, colour-matched glow underlay
//
//  Legend labels/amounts are data-driven (DonutSlice) — no localization keys.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct HeroProportionBar: View {
    let segments: [DonutSlice]
    /// ISO currency code for the legend amounts.
    var currency: String = ""
    /// Extra delay before the entrance — pass the nav-transition duration so
    /// the bar animates after the push settles (see InsightDetailView).
    var entranceDelay: Double = 0

    var barHeight: CGFloat = 20
    var segmentGap: CGFloat = 3

    @State private var entered = false
    @State private var selectedID: String?
    @Environment(\.amountsHidden) private var amountsHidden

    private var immediate: Bool { AppAnimation.isReduceMotionEnabled }
    private static let waveStep: Double = 0.08

    private var total: Double { segments.reduce(0.0) { $0 + $1.amount } }

    public init(
        segments: [DonutSlice],
        currency: String = "",
        entranceDelay: Double = 0,
        barHeight: CGFloat = 20,
        segmentGap: CGFloat = 3
    ) {
        self.segments = segments
        self.currency = currency
        self.entranceDelay = entranceDelay
        self.barHeight = barHeight
        self.segmentGap = segmentGap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            bar
                .chartGlow(radius: 14, yOffset: 8, opacity: 0.5)
            legend
        }
        .onAppear { entered = true }
    }

    // MARK: - Bar

    private var bar: some View {
        GeometryReader { geo in
            HStack(spacing: segmentGap) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    barSegment(segment, index: index, totalWidth: geo.size.width)
                }
            }
            .frame(height: barHeight)
            .clipShape(Capsule())
        }
        .frame(height: barHeight)
        .animation(AppAnimation.chartBannerFade, value: selectedID)
    }

    private func segmentWidth(_ segment: DonutSlice, totalWidth: CGFloat) -> CGFloat {
        let gapTotal: CGFloat = segmentGap * CGFloat(segments.count - 1)
        let fraction: CGFloat = total > 0 ? CGFloat(segment.amount / total) : 0
        // A sliver stays visible as a nub.
        return max(barHeight / 2, (totalWidth - gapTotal) * fraction)
    }

    private func barSegment(_ segment: DonutSlice, index: Int, totalWidth: CGFloat) -> some View {
        let entranceAnimation: Animation? = immediate
            ? nil
            : .spring(response: 0.45, dampingFraction: 0.75)
                .delay(entranceDelay + Double(index) * Self.waveStep)
        return RoundedRectangle(cornerRadius: AppRadius.xl)
            .fill(segment.color)
            .frame(width: segmentWidth(segment, totalWidth: totalWidth))
            .opacity(opacity(for: segment.id))
            .scaleEffect(entered ? 1 : 0.4, anchor: .leading)
            .opacity(entered ? 1 : 0)
            .animation(entranceAnimation, value: entered)
            .onTapGesture { select(segment.id) }
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                legendRow(segment)
                    .materialize(
                        delay: entranceDelay + 0.25 + Double(index) * Self.waveStep,
                        animatesOnAppear: !immediate
                    )
            }
        }
        .animation(AppAnimation.chartBannerFade, value: selectedID)
    }

    private func legendRow(_ segment: DonutSlice) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(segment.color)
                .frame(width: 9, height: 9)

            Text(segment.label)
                .font(selectedID == segment.id ? AppTypography.bodyEmphasis : AppTypography.body)
                .foregroundStyle(AppColors.Text.primary)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.sm)

            Text("\(Int(segment.percentage.rounded()))%")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)

            Text(amountsHidden
                 ? Formatting.hiddenAmount(currency: currency)
                 : Formatting.formatCurrencySmart(segment.amount, currency: currency))
                .font(AppTypography.numbers(AppTypography.bodyEmphasis))
                .foregroundStyle(AppColors.Text.primary)
        }
        .opacity(opacity(for: segment.id))
        .contentShape(Rectangle())
        .onTapGesture { select(segment.id) }
    }

    // MARK: - Selection

    private func opacity(for id: String) -> Double {
        guard let selectedID else { return 1 }
        return selectedID == id ? 1 : 0.35
    }

    private func select(_ id: String) {
        HapticManager.selection()
        selectedID = selectedID == id ? nil : id
    }
}

// MARK: - Previews

// MARK: - Skeleton

/// Placeholder of a `HeroProportionBar`: the capsule bar, then a legend line per segment.
public struct HeroProportionBarSkeleton: View {
    let segments: Int
    let barHeight: CGFloat

    public init(segments: Int = 4, barHeight: CGFloat = 20) {
        self.segments = max(1, segments)
        self.barHeight = barHeight
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Skeleton.capsule(height: barHeight)
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(0..<segments, id: \.self) { _ in
                    HStack(spacing: AppSpacing.sm) {
                        Skeleton.circle(9)
                        SkeletonText(AppTypography.body, width: 90)
                        Spacer(minLength: AppSpacing.sm)
                        SkeletonText(AppTypography.bodySmall, width: 32)
                        SkeletonText(AppTypography.bodyEmphasis, width: 80)
                    }
                }
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
