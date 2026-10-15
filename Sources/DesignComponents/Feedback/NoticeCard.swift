//
//  NoticeCard.swift
//  DesignKit
//
//  A message the app writes to the person (4.13.0): a picture on the leading edge (a mascot,
//  an icon), a title and a line or two of text, a button that hides it, and an action under
//  them ("Go through it"). On a `ListCard`. Ported from Tenra's AssistantNoticeCard; what the
//  message is, when it shows and what the action does stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "🫧 A payment is due tomorrow / Internet, 12 000 ₸ ……… ✕" and "✨ Go through it" under it.
///
/// ```swift
/// NoticeCard(
///     title: "A payment is due tomorrow",
///     message: "Internet, 12 000 ₸",
///     actionTitle: "Go through it", actionSystemImage: "sparkles", action: { ask() },
///     onHide: { markRead() }
/// ) {
///     ParticleCreature(mood: .worried, style: .compact)
///         .frame(width: AppIconSize.xl, height: AppIconSize.xl)
/// }
/// ```
public struct NoticeCard<Leading: View>: View {
    let title: String
    let message: String
    let actionTitle: String?
    let actionSystemImage: String?
    let action: (() -> Void)?
    let hideLabel: String
    let onHide: (() -> Void)?
    let leading: Leading

    /// - Parameters:
    ///   - actionTitle: The flat button under the text; it shows only with `action`.
    ///   - hideLabel: VoiceOver's name of the hide button ("Hide").
    ///   - onHide: The ✕ on the trailing edge; none leaves it out.
    ///   - leading: The picture before the text, at the size it should be (hidden from VoiceOver
    ///     by the caller when it says nothing).
    public init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil,
        hideLabel: String = String(localized: "common.hide", defaultValue: "Hide"),
        onHide: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
        self.hideLabel = hideLabel
        self.onHide = onHide
        self.leading = leading()
    }

    public var body: some View {
        ListCard {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                leading
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.Text.primary)
                    Text(message)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let onHide {
                    DSButton(
                        hideLabel,
                        systemImage: "xmark",
                        iconPlacement: .only,
                        appearance: .flat,
                        role: .neutral,
                        size: .small,
                        action: onHide
                    )
                }
            }
            if let actionTitle, let action {
                DSButton(actionTitle, systemImage: actionSystemImage, appearance: .flat, size: .small, action: action)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

public extension NoticeCard where Leading == EmptyView {
    /// A notice with nothing before its text.
    init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil,
        hideLabel: String = String(localized: "common.hide", defaultValue: "Hide"),
        onHide: (() -> Void)? = nil
    ) {
        self.init(
            title: title, message: message,
            actionTitle: actionTitle, actionSystemImage: actionSystemImage, action: action,
            hideLabel: hideLabel, onHide: onHide
        ) { EmptyView() }
    }
}

// MARK: - Skeleton

/// Placeholder of a `NoticeCard`: the same card, a grey circle of `leadingSize` (or none), the
/// title and two lines of text, and the action's line under them.
public struct NoticeCardSkeleton: View {
    let leadingSize: CGFloat?
    let showsAction: Bool

    public init(leadingSize: CGFloat? = AppIconSize.xl, showsAction: Bool = true) {
        self.leadingSize = leadingSize
        self.showsAction = showsAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                if let leadingSize {
                    Skeleton.circle(leadingSize)
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.bodyEmphasis, width: 180)
                    SkeletonText(AppTypography.bodySmall, lines: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if showsAction {
                SkeletonText(AppTypography.bodySmall, width: 120)
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
