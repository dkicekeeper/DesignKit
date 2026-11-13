//
//  NoticeCard.swift
//  DesignKit
//
//  A message the app writes to the person (4.14.0): a picture on the leading edge (a mascot,
//  an icon, `NoticeCardMetrics.leadingSize` since 5.2.0), a title and a line or two of text, a
//  button that hides it, and an action under the text, in line with it ("Go through it"; 5.2.0,
//  under the picture before), and since 8.11.0 a second, quieter action beside it ("Pause":
//  something the person can do about the message without opening anything). On a glass card that pads it (its own since 8.0.0;
//  `FormSection(style: .glass)` from 5.0.0, `ListCard` before). Ported from Tenra's AssistantNoticeCard; what the message is, when it shows and what
//  the action does stay in the app.
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
///         .frame(width: NoticeCardMetrics.leadingSize, height: NoticeCardMetrics.leadingSize)
/// }
/// ```
public struct NoticeCard<Leading: View>: View {
    let title: String
    let message: String
    let actionTitle: String?
    let actionSystemImage: String?
    let action: (() -> Void)?
    let secondaryActionTitle: String?
    let secondaryActionSystemImage: String?
    let secondaryAction: (() -> Void)?
    let hideLabel: String
    let onHide: (() -> Void)?
    let leading: Leading

    /// - Parameters:
    ///   - actionTitle: The flat button under the text, in line with it; it shows only with
    ///     `action`.
    ///   - secondaryActionTitle: A second flat button after the first, in the neutral colour
    ///     (8.11.0); it shows only with `secondaryAction`, and goes under the first when the two
    ///     do not fit in a line.
    ///   - hideLabel: VoiceOver's name of the hide button ("Hide").
    ///   - onHide: The ✕ on the trailing edge; none leaves it out.
    ///   - leading: The picture before the text, at the size it should be
    ///     (`NoticeCardMetrics.leadingSize` for a mascot or an icon; hidden from VoiceOver by the
    ///     caller when it says nothing).
    public init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryActionSystemImage: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        hideLabel: String = String(localized: "common.hide", defaultValue: "Hide"),
        onHide: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryActionSystemImage = secondaryActionSystemImage
        self.secondaryAction = secondaryAction
        self.hideLabel = hideLabel
        self.onHide = onHide
        self.leading = leading()
    }

    public var body: some View {
        // One glass card that pads its content on every side (FormSection(style: .glass) until
        // 8.0.0, when sections became rows with dividers).
        Group {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                leading
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.Text.primary)
                    Text(message)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                    // In the text's column, so it starts where the text does (5.2.0).
                    if let secondaryActionTitle, let secondaryAction {
                        // Two actions (8.11.0): in a line when they fit, else one under the other.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AppSpacing.sm) {
                                primaryButton
                                secondaryButton(secondaryActionTitle, secondaryAction)
                            }
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                primaryButton
                                secondaryButton(secondaryActionTitle, secondaryAction)
                            }
                        }
                        .padding(.top, AppSpacing.xs)
                    } else if let actionTitle, let action {
                        DSButton(actionTitle, systemImage: actionSystemImage, appearance: .flat, size: .small, action: action)
                            .padding(.top, AppSpacing.xs)
                    }
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
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }

    /// The first action, when there is one.
    @ViewBuilder
    private var primaryButton: some View {
        if let actionTitle, let action {
            DSButton(actionTitle, systemImage: actionSystemImage, appearance: .flat, size: .small, action: action)
        }
    }

    private func secondaryButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        DSButton(title, systemImage: secondaryActionSystemImage, appearance: .flat, role: .neutral, size: .small, action: action)
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
        secondaryActionTitle: String? = nil,
        secondaryActionSystemImage: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        hideLabel: String = String(localized: "common.hide", defaultValue: "Hide"),
        onHide: (() -> Void)? = nil
    ) {
        self.init(
            title: title, message: message,
            actionTitle: actionTitle, actionSystemImage: actionSystemImage, action: action,
            secondaryActionTitle: secondaryActionTitle, secondaryActionSystemImage: secondaryActionSystemImage,
            secondaryAction: secondaryAction,
            hideLabel: hideLabel, onHide: onHide
        ) { EmptyView() }
    }
}

public enum NoticeCardMetrics {
    /// The picture before the text: a mascot or an icon (5.2.0; 32 pt in 4.14.0's example).
    public static let leadingSize: CGFloat = AppIconSize.Tile.md
}

// MARK: - Skeleton

/// Placeholder of a `NoticeCard`: the same card, a grey circle of `leadingSize` (or none), the
/// title and two lines of text, and the action's line under them, in the text's column.
public struct NoticeCardSkeleton: View {
    let leadingSize: CGFloat?
    let showsAction: Bool

    public init(leadingSize: CGFloat? = NoticeCardMetrics.leadingSize, showsAction: Bool = true) {
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
                    if showsAction {
                        SkeletonText(AppTypography.bodySmall, width: 120)
                            .padding(.top, AppSpacing.xs)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .shimmer()
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
