//
//  BadgeView.swift
//  DesignKit
//
//  Small capsule label for a status, a tag or a count ("Pending", "Closed", "3").
//  From Dalada's RuleStatusBadge (tinted) and its friend-request counter (filled).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Capsule badge: short text with an optional SF Symbol.
///
/// - `.tinted` — coloured text on a 12 % tint of the same colour (statuses, tags).
/// - `.filled` — white text on a solid colour (counters that need attention).
///
/// ```swift
/// BadgeView("Closed", color: AppColors.destructive)
/// BadgeView("3", systemImage: "person.badge.plus", color: AppColors.destructive, style: .filled)
/// ```
///
/// For an icon-only lifecycle status use `StatusIndicatorBadge`; for a trend use `TrendBadge`.
public struct BadgeView: View {
    public enum Style: Hashable, Sendable {
        case tinted
        case filled
    }

    let text: String
    let systemImage: String?
    let color: Color
    let style: Style

    public init(
        _ text: String,
        systemImage: String? = nil,
        color: Color = AppColors.accent,
        style: Style = .tinted
    ) {
        self.text = text
        self.systemImage = systemImage
        self.color = color
        self.style = style
    }

    public var body: some View {
        label
            .font(AppTypography.caption)
            .lineLimit(1)
            .foregroundStyle(style == .filled ? AppColors.staticWhite : color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(style == .filled ? color : AppColors.pale(color), in: Capsule())
            .fixedSize()
    }

    @ViewBuilder
    private var label: some View {
        if let systemImage {
            Label {
                Text(verbatim: text)
            } icon: {
                Image(systemName: systemImage)
            }
        } else {
            Text(verbatim: text)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `BadgeView`: its capsule, as tall as a badge.
public struct BadgeViewSkeleton: View {
    let width: CGFloat

    public init(width: CGFloat = 64) {
        self.width = width
    }

    public var body: some View {
        // A badge's own layout, invisible, gives the height; the capsule is the badge's shape.
        Text(verbatim: "Ag")
            .font(AppTypography.caption)
            .hidden()
            .frame(width: width)
            .padding(.vertical, AppSpacing.xxs)
            .background(SkeletonView.fill, in: Capsule())
            .shimmer()
            .skeletonLoadingLabel()
    }
}
