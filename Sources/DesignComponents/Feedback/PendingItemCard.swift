//
//  PendingItemCard.swift
//  DesignKit
//
//  Something made offline and not on the server yet (3.6.0, audit round 5): its title and how
//  long ago, "waiting to upload" or "couldn't upload" with the reason, Retry and Delete, and
//  the item's own content under it. Dalada's queued trips and reports drew this card twice;
//  the queue, the retry and the delete stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Where a queued item stands: what a `PendingItemCard` says under its title.
public enum PendingItemState: Equatable, Sendable {
    /// In the queue; it goes once the device is online.
    case waiting
    /// The server refused it or the upload broke; `message` says why (may be empty).
    case failed(message: String)
}

/// A card for an item waiting in an upload queue.
///
/// ```swift
/// PendingItemCard(title: trip.title, systemImage: trip.activity.systemImage, date: trip.startedAt,
///                 state: trip.failure.map { .failed(message: $0) } ?? .waiting,
///                 onRetry: { await sync.retry(trip.id) },
///                 onDiscard: { await sync.discard(trip.id) }) {
///     MetaLine([.text(distance), .text(duration)]).font(AppTypography.caption)
/// }
/// ```
///
/// Delete asks first (a confirmation dialog); `discardConfirmation` words the question for the
/// item ("Delete the trip and its track?"). Strings: `pending.waiting`, `pending.failed`,
/// `common.retry`, `pending.discard`, `pending.discard.confirm`.
public struct PendingItemCard<Content: View>: View {
    public typealias State = PendingItemState

    let title: String
    let systemImage: String?
    let date: Date?
    let state: State
    let discardConfirmation: String?
    let onRetry: () async -> Void
    let onDiscard: () async -> Void
    let content: Content

    @SwiftUI.State private var confirmsDiscard = false

    /// - Parameters:
    ///   - systemImage: A symbol before the title, in the accent; none by default.
    ///   - date: When the item was made, shown as a running "5 min"; nil shows no time.
    ///   - discardConfirmation: The question Delete asks; `pending.discard.confirm` by default.
    ///   - content: What the item is (its facts, its note), under the status.
    public init(
        title: String,
        systemImage: String? = nil,
        date: Date?,
        state: State,
        discardConfirmation: String? = nil,
        onRetry: @escaping () async -> Void,
        onDiscard: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.date = date
        self.state = state
        self.discardConfirmation = discardConfirmation
        self.onRetry = onRetry
        self.onDiscard = onDiscard
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(AppColors.accent)
                        .accessibilityHidden(true)
                }
                Text(verbatim: title)
                    .font(AppTypography.bodyEmphasis)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let date {
                    Text(date, style: .relative)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.tertiary)
                }
            }
            status
            content
        }
        .cardContentPadding()
        .cardStyle()
        .confirmationDialog(
            Text(verbatim: discardConfirmation
                 ?? String(localized: "pending.discard.confirm", defaultValue: "Delete it? It won’t reach the server.")),
            isPresented: $confirmsDiscard,
            titleVisibility: .visible
        ) {
            Button(String(localized: "pending.discard", defaultValue: "Delete"), role: .destructive) {
                Task { await onDiscard() }
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        switch state {
        case .waiting:
            Label(String(localized: "pending.waiting", defaultValue: "Waiting to upload: it goes once you’re online"),
                  systemImage: "icloud.and.arrow.up")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.warning)
        case .failed(let message):
            Label(String(localized: "pending.failed", defaultValue: "Couldn’t upload"),
                  systemImage: "exclamationmark.triangle.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.destructive)
            if !message.isEmpty {
                Text(verbatim: message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            HStack(spacing: AppSpacing.md) {
                Button(String(localized: "common.retry", defaultValue: "Retry")) {
                    Task { await onRetry() }
                }
                .dsButton(.secondary)
                Button(String(localized: "pending.discard", defaultValue: "Delete"), role: .destructive) {
                    confirmsDiscard = true
                }
                .dsButton(.secondary)
            }
        }
    }
}

public extension PendingItemCard where Content == EmptyView {
    /// A card with nothing under the status.
    init(
        title: String,
        systemImage: String? = nil,
        date: Date?,
        state: State,
        discardConfirmation: String? = nil,
        onRetry: @escaping () async -> Void,
        onDiscard: @escaping () async -> Void
    ) {
        self.init(title: title, systemImage: systemImage, date: date, state: state,
                  discardConfirmation: discardConfirmation,
                  onRetry: onRetry, onDiscard: onDiscard) { EmptyView() }
    }
}

// MARK: - Skeleton

/// Placeholder of a `PendingItemCard`: the title and time, the status line, `contentLines`
/// lines for the content, in the same glass card.
public struct PendingItemCardSkeleton: View {
    let contentLines: Int

    public init(contentLines: Int = 1) {
        self.contentLines = contentLines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                SkeletonText(AppTypography.bodyEmphasis, width: 160)
                Spacer(minLength: 0)
                SkeletonText(AppTypography.caption, width: 60)
            }
            SkeletonText(AppTypography.caption, width: 200)
            ForEach(0..<max(contentLines, 0), id: \.self) { _ in
                SkeletonText(AppTypography.caption, width: 140)
            }
        }
        .shimmer()
        .cardContentPadding()
        .cardStyle()
        .skeletonLoadingLabel()
    }
}
