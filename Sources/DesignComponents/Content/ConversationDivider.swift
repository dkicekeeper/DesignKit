//
//  ConversationDivider.swift
//  DesignKit
//
//  A line across a conversation (8.9.0, benchmark round 4: Astryx's ChatSystemMessage): the day
//  the next messages are from ("Today", "Yesterday", "3 November"), or something that happened
//  in it ("Ten changed the October budget", "Alex joined"). Tenra's assistant chat, Dalada's
//  comments and threads.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A centred caption between two hairlines, in a conversation's list of messages.
///
/// ```swift
/// ConversationDivider(date: message.sentAt)            // "Today", "Yesterday", "3 November"
/// ConversationDivider("Ten changed the October budget", systemImage: "pencil")
/// ```
///
/// The day reads as `Formatting.dayTitle(_:)` (the `DesignKitDateFormat.day` hook for an older
/// one). VoiceOver reads the caption alone; a date one is a heading, so the rotor jumps by day.
public struct ConversationDivider: View {
    let text: String
    let systemImage: String?
    let isDay: Bool

    /// Something that happened in the conversation, with an optional symbol before it.
    public init(_ text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.isDay = false
    }

    /// The day the messages under it are from.
    public init(date: Date) {
        self.text = Formatting.dayTitle(date)
        self.systemImage = nil
        self.isDay = true
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            hairline
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Icon(systemImage, size: AppIconSize.xs)
                }
                Text(verbatim: text)
                    .multilineTextAlignment(.center)
            }
            .font(AppTypography.caption.weight(isDay ? .semibold : .regular))
            .foregroundStyle(AppColors.Text.secondary)
            .layoutPriority(1)
            hairline
        }
        .padding(.vertical, AppSpacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: text))
        .accessibilityAddTraits(isDay ? .isHeader : [])
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.Border.normal)
            .frame(height: 1 / 3)
            .frame(minWidth: AppSpacing.lg, maxWidth: .infinity)
    }
}

// MARK: - Skeleton

/// Placeholder of a `ConversationDivider`: a short grey caption between the hairlines.
public struct ConversationDividerSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Rectangle().fill(AppColors.Border.normal).frame(height: 1 / 3)
            SkeletonText(AppTypography.caption, width: 72)
            Rectangle().fill(AppColors.Border.normal).frame(height: 1 / 3)
        }
        .padding(.vertical, AppSpacing.sm)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
