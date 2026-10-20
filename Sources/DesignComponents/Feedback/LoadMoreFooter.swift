//
//  LoadMoreFooter.swift
//  DesignKit
//
//  The end of a list that loads in pages (4.1.0, benchmark round 3; M3, Polaris, Carbon and
//  Atlassian have one): placeholders while the next page comes, "Couldn't load more" with
//  Retry when it fails, nothing once the list is complete. Dalada's reviews, threads, photos,
//  feed and trips and Tenra's history loaded the next page by hand, with a bare spinner or
//  nothing; the requests and the cursor stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Where loading the next page of a list stands; what a `LoadMoreFooter` shows.
public enum LoadMoreState: Equatable, Sendable {
    /// There is more: the footer asks for it as soon as it shows.
    case more
    /// The next page is on its way: placeholders.
    case loading
    /// The last request failed; `message` says why (nil: a generic line). Retry asks again.
    case failed(message: String?)
    /// The list is complete: nothing.
    case end
}

/// The footer of a list that loads in pages. Put it after the rows; it calls `onLoad` when
/// it scrolls into view in `.more`, shows `placeholder` (`rows` times) in `.loading`, and a
/// message with Retry in `.failed`.
///
/// ```swift
/// List {
///     ForEach(reviews) { ReviewRow(review: $0) }
///     LoadMoreFooter(state: loadState, onLoad: loadMore) {
///         ReviewCardSkeleton()
///     }
/// }
/// ```
///
/// In a `List` it hides its row separator. The app keeps one request in flight (`onLoad`
/// may be called again while the footer stays on screen after a short page) and maps its
/// own flags to the state. Strings: `loadMore.failed`, `common.retry`.
public struct LoadMoreFooter<Placeholder: View>: View {
    let state: LoadMoreState
    let rows: Int
    let onLoad: () async -> Void
    let placeholder: Placeholder

    /// - Parameters:
    ///   - rows: How many placeholders stand for the coming page.
    ///   - placeholder: The skeleton of one row (`SkeletonRow()` by default).
    public init(
        state: LoadMoreState,
        rows: Int = 2,
        onLoad: @escaping () async -> Void,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.state = state
        self.rows = rows
        self.onLoad = onLoad
        self.placeholder = placeholder()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .animation(AppAnimation.smooth, value: state)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .more:
            // A sliver that asks for the next page when it scrolls into view.
            Color.clear
                .frame(height: 1)
                .task { await onLoad() }
        case .loading:
            VStack(spacing: AppSpacing.md) {
                ForEach(0..<max(rows, 1), id: \.self) { _ in
                    placeholder
                }
            }
            .transition(.opacity)
        case .failed(let message):
            VStack(spacing: AppSpacing.sm) {
                Label {
                    Text(verbatim: message ?? String(localized: "loadMore.failed", defaultValue: "Couldn’t load more"))
                } icon: {
                    Icon("exclamationmark.triangle", size: AppIconSize.xs)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.Text.secondary)
                .multilineTextAlignment(.center)
                Button(String(localized: "common.retry", defaultValue: "Retry")) {
                    Task { await onLoad() }
                }
                .dsButton(.secondary)
            }
            .padding(.vertical, AppSpacing.md)
            .transition(.opacity)
        case .end:
            EmptyView()
        }
    }
}

public extension LoadMoreFooter where Placeholder == SkeletonRow {
    /// A footer whose placeholders are plain `SkeletonRow`s.
    init(state: LoadMoreState, rows: Int = 2, onLoad: @escaping () async -> Void) {
        self.init(state: state, rows: rows, onLoad: onLoad) { SkeletonRow() }
    }
}

// MARK: - Reaching the end

public extension View {
    /// Calls `action` when this row, one of `items`, appears within `threshold` rows of the
    /// end: to ask for the next page a little before the footer shows (a feed of tall cards).
    /// A `LoadMoreFooter` asks on its own; use this to start sooner.
    ///
    /// ```swift
    /// ForEach(items) { item in
    ///     FeedCard(item).onReachEnd(of: item, in: items, threshold: 3) { Task { await loadMore() } }
    /// }
    /// ```
    func onReachEnd<Items: RandomAccessCollection>(
        of item: Items.Element,
        in items: Items,
        threshold: Int = 0,
        perform action: @escaping () -> Void
    ) -> some View where Items.Element: Identifiable {
        onAppear {
            guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
            let fromEnd = items.distance(from: index, to: items.endIndex) - 1
            if fromEnd <= max(threshold, 0) { action() }
        }
    }
}
