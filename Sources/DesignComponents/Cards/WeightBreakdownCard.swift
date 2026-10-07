//
//  WeightBreakdownCard.swift
//  DesignKit
//
//  How a whole splits into weighted parts: a title, an explanation, one stacked bar and a
//  legend of icon, name and weight. Ported from Tenra's HealthScoreWeightingCard; the
//  health-score parts, their weights and copy stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A stacked bar of weighted parts with a legend underneath.
///
/// ```swift
/// WeightBreakdownCard(
///     title: "How the score works",
///     message: "Five parts, each weighted by how much it matters.",
///     segments: [
///         .init(title: "Savings", systemImage: "banknote.fill", color: AppColors.success, weight: 40),
///         .init(title: "Cash flow", systemImage: "chart.line.uptrend.xyaxis",
///               color: AppColors.destructive, weight: 60),
///     ]
/// )
/// ```
public struct WeightBreakdownCard: View {
    public struct Segment: Identifiable {
        public let id: String
        public let title: String
        public let systemImage: String
        public let color: Color
        /// Share of the bar, 0…100. The weights of a card add up to 100.
        public let weight: Double
        /// Trailing text of the legend row; "40%" when `nil`.
        public let weightLabel: String

        public init(
            id: String? = nil,
            title: String,
            systemImage: String,
            color: Color,
            weight: Double,
            weightLabel: String? = nil
        ) {
            self.id = id ?? title
            self.title = title
            self.systemImage = systemImage
            self.color = color
            self.weight = weight
            self.weightLabel = weightLabel ?? "\(Int(weight.rounded()))%"
        }
    }

    let title: String
    let message: String?
    let caption: String?
    let segments: [Segment]
    let footnote: String?

    /// - Parameters:
    ///   - message: The explanation under the title.
    ///   - caption: A quieter line under it (the period the weights apply to, for example).
    ///   - footnote: A note under the legend.
    public init(
        title: String,
        message: String? = nil,
        caption: String? = nil,
        segments: [Segment],
        footnote: String? = nil
    ) {
        self.title = title
        self.message = message
        self.caption = caption
        self.segments = segments
        self.footnote = footnote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.Text.primary)

            if let message {
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let caption {
                Text(caption)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            stackedBar
                .frame(height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(spacing: AppSpacing.sm) {
                ForEach(segments) { segment in
                    legendRow(segment)
                }
            }

            if let footnote {
                Text(footnote)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    private var stackedBar: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: proxy.size.width * segment.weight / 100.0)
                }
            }
        }
    }

    private func legendRow(_ segment: Segment) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: segment.systemImage)
                .font(.system(size: AppIconSize.sm))
                .foregroundStyle(segment.color)
                .frame(width: 24)

            Text(segment.title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.primary)

            Spacer()

            Text(segment.weightLabel)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `WeightBreakdownCard`: the same card, the title and message, the stacked
/// bar with its corner and a legend line per segment.
public struct WeightBreakdownCardSkeleton: View {
    let segments: Int

    public init(segments: Int = 3) {
        self.segments = max(1, segments)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SkeletonText(AppTypography.bodyEmphasis, width: 140)
            SkeletonText(AppTypography.body, lines: 2)
            SkeletonView(height: 14, cornerRadius: 7)
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<segments, id: \.self) { _ in
                    HStack(spacing: AppSpacing.md) {
                        SkeletonView.circle(AppIconSize.sm)
                            .frame(width: 24)
                        SkeletonText(AppTypography.body, width: 100)
                        Spacer()
                        SkeletonText(AppTypography.bodySmall, width: 40)
                    }
                }
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
