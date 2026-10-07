//
//  AchievementMedal.swift
//  DesignKit
//
//  Achievements: a round medal (in its colour once earned, grey until then), a tile with the
//  medal, its title and the progress towards it, and a "next up" row with a progress bar.
//  Ported from Dalada's AchievementMedal, AchievementTile and AchievementProgressRow; the
//  catalogue of achievements, their titles and progress texts stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A round achievement medal.
///
/// ```swift
/// AchievementMedal(systemImage: "flame.fill", color: .orange, isEarned: true, size: 56)
/// ```
///
/// Decorative for VoiceOver: the tile or row next to it carries the title.
public struct AchievementMedal: View {
    let systemImage: String
    let color: Color
    let isEarned: Bool
    let size: CGFloat

    /// - Parameter color: The disc once earned; grey (`bgMuted`) until then.
    public init(systemImage: String, color: Color, isEarned: Bool, size: CGFloat) {
        self.systemImage = systemImage
        self.color = color
        self.isEarned = isEarned
        self.size = size
    }

    public var body: some View {
        IconView(
            source: .sfSymbol(systemImage),
            style: .circle(
                size: size,
                tint: .monochrome(isEarned ? AppColors.staticWhite : AppColors.Text.tertiary),
                backgroundColor: isEarned ? color : AppColors.Background.neutral2,
                padding: size * 0.24
            )
        )
        .accessibilityHidden(true)
    }
}

/// An achievement in a grid: the medal, the title under it and, if not earned yet, the
/// progress ("3 of 10").
///
/// ```swift
/// LazyVGrid(columns: columns) {
///     ForEach(achievements) { a in
///         AchievementTile(title: a.title, systemImage: a.symbol, color: a.color,
///                         isEarned: a.isEarned, medalSize: 64, progressText: a.progress)
///     }
/// }
/// ```
public struct AchievementTile: View {
    let title: String
    let systemImage: String
    let color: Color
    let isEarned: Bool
    let medalSize: CGFloat
    let progressText: String?

    /// - Parameter progressText: Under the title while not earned; none hides it.
    public init(
        title: String,
        systemImage: String,
        color: Color,
        isEarned: Bool,
        medalSize: CGFloat,
        progressText: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.isEarned = isEarned
        self.medalSize = medalSize
        self.progressText = progressText
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xs) {
            AchievementMedal(systemImage: systemImage, color: color, isEarned: isEarned, size: medalSize)
            Text(verbatim: title)
                .font(AppTypography.caption)
                .foregroundStyle(isEarned ? AppColors.Text.primary : AppColors.Text.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let progressText, !isEarned {
                Text(verbatim: progressText)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.Text.tertiary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The achievement closest to being earned: a small grey medal, "Up next:" and its title, the
/// progress text on the right and a bar under them.
///
/// ```swift
/// AchievementProgressRow(label: "Up next:", title: "10 trips", progressText: "7 of 10",
///                        fraction: 0.7, systemImage: "figure.hiking", color: .green)
/// ```
public struct AchievementProgressRow: View {
    let label: String
    let title: String
    let progressText: String
    let fraction: Double
    let systemImage: String
    let color: Color
    let isEarned: Bool

    /// - Parameters:
    ///   - label: Before the title, in the secondary colour ("Up next:").
    ///   - fraction: The bar, 0…1.
    public init(
        label: String,
        title: String,
        progressText: String,
        fraction: Double,
        systemImage: String,
        color: Color,
        isEarned: Bool = false
    ) {
        self.label = label
        self.title = title
        self.progressText = progressText
        self.fraction = fraction
        self.systemImage = systemImage
        self.color = color
        self.isEarned = isEarned
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            AchievementMedal(systemImage: systemImage, color: color, isEarned: isEarned, size: AppIconSize.xl)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(verbatim: label)
                        .foregroundStyle(AppColors.Text.secondary)
                    Text(verbatim: title)
                        .foregroundStyle(AppColors.Text.primary)
                    Spacer(minLength: 0)
                    Text(verbatim: progressText)
                        .foregroundStyle(AppColors.Text.secondary)
                        .monospacedDigit()
                }
                .font(AppTypography.bodySmall)
                .lineLimit(1)
                LinearProgressBar(value: fraction, height: AchievementMetrics.barHeight)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Sizes shared by the achievement views and their skeletons.
enum AchievementMetrics {
    static let barHeight: CGFloat = 6
}

// MARK: - Skeletons

/// Placeholder of an `AchievementMedal`: a circle of its size.
public struct AchievementMedalSkeleton: View {
    let size: CGFloat

    public init(size: CGFloat) {
        self.size = size
    }

    public var body: some View {
        SkeletonView.circle(size)
            .skeletonLoadingLabel()
    }
}

/// Placeholder of an `AchievementTile`: the medal circle and a title line under it.
public struct AchievementTileSkeleton: View {
    let medalSize: CGFloat

    public init(medalSize: CGFloat) {
        self.medalSize = medalSize
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xs) {
            SkeletonView.circle(medalSize)
            SkeletonText(AppTypography.caption, width: medalSize)
        }
        .frame(maxWidth: .infinity)
        .shimmer()
        .skeletonLoadingLabel()
    }
}

/// Placeholder of an `AchievementProgressRow`: the small medal, a text line and the bar's track.
public struct AchievementProgressRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            SkeletonView.circle(AppIconSize.xl)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.bodySmall, width: 200)
                LinearProgressBarSkeleton(height: AchievementMetrics.barHeight)
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
