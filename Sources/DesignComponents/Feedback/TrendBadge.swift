//
//  TrendBadge.swift
//  DesignKit
//
//  Direction arrow + signed percentage change ("↗ +12.4%"). Ported from Tenra's
//  InsightTrendBadge without its InsightTrend model: Tenra keeps a thin adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Compact trend indicator: direction icon + percentage change.
///
/// Three styles:
/// - `.pill` — tinted capsule background (cards)
/// - `.inline` — flat, no background (detail headers)
/// - `.changeIndicator` — icon above the percentage (comparison cards)
///
/// ```swift
/// TrendBadge(direction: .up, changePercent: 12.4)
/// TrendBadge(direction: .up, changePercent: 8, color: AppColors.destructive) // up is bad here
/// ```
public struct TrendBadge: View {
    public enum Direction: Hashable, Sendable {
        case up, down, flat

        /// Default semantic colour: up = income green, down = destructive, flat = secondary.
        public var color: Color {
            switch self {
            case .up: return AppColors.income
            case .down: return AppColors.destructive
            case .flat: return AppColors.Text.secondary
            }
        }

        public var systemImage: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .flat: return "arrow.right"
            }
        }
    }

    public enum Style: Hashable, Sendable {
        /// Tinted capsule background.
        case pill
        /// Flat, no background.
        case inline
        /// Vertical layout: icon on top, percentage below. No background.
        case changeIndicator
    }

    let direction: Direction
    let changePercent: Double?
    let style: Style
    let color: Color?

    /// - Parameters:
    ///   - direction: Arrow direction.
    ///   - changePercent: Signed change in percent (`12.4` → "+12.4%"). `nil` shows the arrow only.
    ///   - style: `.pill` (default), `.inline` or `.changeIndicator`.
    ///   - color: Overrides the direction's default colour — e.g. expenses, where up is bad.
    public init(
        direction: Direction,
        changePercent: Double?,
        style: Style = .pill,
        color: Color? = nil
    ) {
        self.direction = direction
        self.changePercent = changePercent
        self.style = style
        self.color = color
    }

    private var effectiveColor: Color { color ?? direction.color }

    public var body: some View {
        if style == .changeIndicator {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: direction.systemImage)
                if let percent = changePercent {
                    Text(Self.format(percent))
                        .font(AppTypography.numbers(AppTypography.bodyEmphasis))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(effectiveColor)
        } else {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: direction.systemImage)
                    .font(AppTypography.bodyEmphasis)

                if let percent = changePercent {
                    Text(Self.format(percent))
                        .font(AppTypography.numbers(AppTypography.bodyEmphasis))
                        .fontWeight(.semibold)
                }
            }
            .lineLimit(1)
            .foregroundStyle(effectiveColor)
            .modifier(TrendPillModifier(isActive: style == .pill, color: effectiveColor))
            // Keep the pill's intrinsic width — never let a tight parent squeeze the
            // icon + percent into a wrap; ViewThatFits can then drop it to a new line.
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    /// "+12.4%" / "-5.1%" — always signed, one decimal.
    public static func format(_ percent: Double) -> String {
        String(format: "%+.1f%%", percent)
    }
}

// MARK: - Pill modifier

private struct TrendPillModifier: ViewModifier {
    let isActive: Bool
    let color: Color

    func body(content: Content) -> some View {
        if isActive {
            content
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.pale(color))
                .clipShape(Capsule())
        } else {
            content
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `TrendBadge`: the pill's capsule, or the arrow and percentage of the
/// inline and change-indicator styles.
public struct TrendBadgeSkeleton: View {
    let style: TrendBadge.Style

    public init(style: TrendBadge.Style = .pill) {
        self.style = style
    }

    public var body: some View {
        Group {
            switch style {
            case .pill:
                Text(verbatim: "Ag")
                    .font(AppTypography.bodyEmphasis)
                    .hidden()
                    .frame(width: 56)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(SkeletonView.fill, in: Capsule())
            case .inline:
                HStack(spacing: AppSpacing.xs) {
                    SkeletonView.circle(AppIconSize.sm)
                    SkeletonText(AppTypography.bodyEmphasis, width: 40)
                }
            case .changeIndicator:
                VStack(spacing: AppSpacing.xs) {
                    SkeletonView.circle(AppIconSize.sm)
                    SkeletonText(AppTypography.bodyEmphasis, width: 40)
                }
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
