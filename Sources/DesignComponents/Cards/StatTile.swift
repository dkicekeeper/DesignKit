//
//  StatTile.swift
//  DesignKit
//
//  One metric: a caption over a large value ("Distance / 12.4 km"). Lay several out in
//  an HStack or Grid. From Dalada's TripStat; for a money amount with a period
//  comparison use InsightsStatCard instead.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Caption + value metric. The value is pre-formatted by the caller (units included).
///
/// ```swift
/// HStack {
///     StatTile(title: "Distance", value: "12.4 km")
///     StatTile(title: "Moving", value: "2 h 15 min")
/// }
/// StatTile(title: "Catches", value: "7", systemImage: "fish", valueColor: AppColors.accent)
/// ```
///
/// Fills the available width, leading-aligned. Long values shrink to 70 % before truncating.
public struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String?
    let valueColor: Color

    public init(
        title: String,
        value: String,
        systemImage: String? = nil,
        valueColor: Color = AppColors.Text.primary
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.valueColor = valueColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            caption
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.Text.secondary)
            Text(verbatim: value)
                .font(AppTypography.h4)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var caption: some View {
        if let systemImage {
            Label {
                Text(verbatim: title)
            } icon: {
                Image(systemName: systemImage)
            }
        } else {
            Text(verbatim: title)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `StatTile`: the caption and the value.
public struct StatTileSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            SkeletonText(AppTypography.caption, width: 72)
            SkeletonText(AppTypography.h4, width: 96)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
