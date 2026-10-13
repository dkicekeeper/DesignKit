//
//  MessageBubble.swift
//  DesignKit
//
//  One message in a conversation (4.6.0): the person's own on the trailing side in the accent,
//  the other side's on the leading side in grey. A message that could not be sent says so under
//  the bubble, with a retry. Rich replies (cards, charts) are the app's own views laid out under
//  an incoming bubble or in its place.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A chat message in a bubble.
///
/// ```swift
/// MessageBubble("How much did I spend on cafés?")                              // mine
/// MessageBubble("Here is October so far.", role: .incoming)
/// MessageBubble(text, failure: "No connection") { Task { await retry() } }    // not sent
/// ```
///
/// The bubble grows to about 80% of the width and leaves the rest empty on the far side; the text
/// is selectable. Retry's title: key `common.retry` (default "Retry").
public struct MessageBubble: View {
    /// Whose message it is.
    public enum Role: Hashable, Sendable {
        /// The person's own: trailing, in the accent.
        case outgoing
        /// The other side's: leading, in grey.
        case incoming
    }

    let text: String
    let role: Role
    let failure: String?
    let onRetry: (() -> Void)?

    /// - Parameters:
    ///   - failure: Why the message was not sent; shown under the bubble in red.
    ///   - onRetry: Adds a Retry button next to the failure.
    public init(_ text: String, role: Role = .outgoing, failure: String? = nil, onRetry: (() -> Void)? = nil) {
        self.text = text
        self.role = role
        self.failure = failure
        self.onRetry = onRetry
    }

    private var isOutgoing: Bool { role == .outgoing }

    public var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 0) {
                if isOutgoing { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
                Text(text)
                    .font(AppTypography.body)
                    .foregroundStyle(isOutgoing ? AppColors.Text.onAccent : AppColors.Text.primary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        isOutgoing ? AppColors.accent : AppColors.Background.neutral1,
                        in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    )
                    .opacity(failure == nil ? 1 : MessageBubbleMetrics.failedOpacity)
                if !isOutgoing { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
            }
            if let failure {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(AppColors.Status.negative)
                    Text(failure)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Status.negative)
                    if let onRetry {
                        Button(String(localized: "common.retry", defaultValue: "Retry"), action: onRetry)
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }
}

public enum MessageBubbleMetrics {
    /// The empty side: the bubble never reaches the far edge.
    public static let farSideMargin: CGFloat = 56
    /// A message that was not sent is drawn faded.
    static let failedOpacity: Double = 0.6
}

// MARK: - Skeleton

/// Placeholder of a `MessageBubble`: a grey bubble of two lines on its side.
public struct MessageBubbleSkeleton: View {
    let role: MessageBubble.Role

    public init(role: MessageBubble.Role = .incoming) {
        self.role = role
    }

    public var body: some View {
        HStack(spacing: 0) {
            if role == .outgoing { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.body, width: 200)
                SkeletonText(AppTypography.body, width: 120)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.Background.neutral1, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            if role == .incoming { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
