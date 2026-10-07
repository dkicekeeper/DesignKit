//
//  StreakCard.swift
//  DesignKit
//
//  A streak: a symbol (a flame while it runs, grey once it has stopped), what the streak is
//  and what to do next, and the best result on the right. Ported from Dalada's StreakCard
//  ("3 weeks in a row · best 5"); counting the streak and caching it stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A streak card.
///
/// ```swift
/// StreakCard(systemImage: "flame.fill", isActive: true,
///            title: "3 weeks in a row", subtitle: "Head out by Sunday to keep it",
///            value: "5", valueCaption: "best")
/// ```
///
/// A card: pads itself and draws its own glass. VoiceOver reads it as one element.
public struct StreakCard: View {
    let systemImage: String
    let isActive: Bool
    let title: String
    let subtitle: String
    let value: String
    let valueCaption: String

    /// - Parameters:
    ///   - isActive: The symbol in the accent colour; grey (`textTertiary`) when the streak
    ///     has stopped.
    ///   - value: On the right (the best streak), with `valueCaption` under it.
    public init(
        systemImage: String,
        isActive: Bool,
        title: String,
        subtitle: String,
        value: String,
        valueCaption: String
    ) {
        self.systemImage = systemImage
        self.isActive = isActive
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.valueCaption = valueCaption
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.lg))
                .foregroundStyle(isActive ? AppColors.accent : AppColors.Text.tertiary)
                .frame(width: AppIconSize.xxl)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                Text(verbatim: subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(verbatim: value)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .monospacedDigit()
                Text(verbatim: valueCaption)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .cardContentPadding()
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Skeleton

/// Placeholder of a `StreakCard`: the same glass card with a soft square for the symbol, the
/// title and subtitle lines, and the value lines on the right.
public struct StreakCardSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Skeleton(height: AppIconSize.lg, width: AppIconSize.lg)
                .frame(width: AppIconSize.xxl)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                SkeletonText(AppTypography.bodyEmphasis, width: 140)
                SkeletonText(AppTypography.caption, width: 200)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                SkeletonText(AppTypography.bodyEmphasis, width: 24)
                SkeletonText(AppTypography.caption, width: 40)
            }
        }
        .shimmer()
        .cardContentPadding()
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
