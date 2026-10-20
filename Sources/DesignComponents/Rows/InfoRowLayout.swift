//
//  InfoRowLayout.swift
//  DesignKit
//
//  A detail's label and value on one line (InfoRow's layout until 7.0.0, now
//  `UniversalRow(accessory: .info)`'s), and the placeholder of that row.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Label + trailing-value layout for info rows.
///
/// Single line: the trailing value keeps its full intrinsic width (higher layout
/// priority), and the leading label truncates with an ellipsis when the two can't
/// both fit. This keeps money amounts intact and never breaks the value onto a
/// second line.
public struct InfoRowLayout<Value: View>: View {
    let label: String
    @ViewBuilder let value: () -> Value

    public init(
        label: String,
        @ViewBuilder value: @escaping () -> Value
    ) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: AppSpacing.sm)
            value()
                .layoutPriority(1)
        }
    }
}

/// Info row component for displaying label + value pairs
/// Now built on top of UniversalRow for consistency

/// Placeholder of a detail row (`accessory: .info`): the label and the value, and the icon when the row has one.
struct RowInfoSkeleton: View {
    let showsIcon: Bool

    var body: some View {
        HStack(spacing: RowConfiguration.info.spacing) {
            if showsIcon {
                Skeleton.circle(AppIconSize.lg)
            }
            HStack(spacing: AppSpacing.md) {
                SkeletonText(AppTypography.body, width: 100)
                Spacer(minLength: AppSpacing.sm)
                SkeletonText(AppTypography.bodyEmphasis, width: 90)
            }
        }
        .shimmer()
        .padding(.vertical, RowConfiguration.info.verticalPadding)
        .skeletonLoadingLabel()
    }
}
