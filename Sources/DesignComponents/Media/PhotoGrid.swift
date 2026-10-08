//
//  PhotoGrid.swift
//  DesignKit
//
//  Photos in a grid of square cells (2.8.0): a person's photos (rounded tiles, small gaps) or a
//  place's gallery (square cells, hairline gaps, more loaded as the last cell appears). A tap
//  opens a photo. Ported from Dalada's PhotoGrid and its place gallery; the app passes each image.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Square photo cells in a fixed number of columns, filling the width.
///
/// ```swift
/// PhotoGrid(photos, onOpen: { opened = $0 }) { AppRemotePhoto(path: $0.thumbnailPath) }
/// PhotoGrid(gallery, style: .edgeToEdge, onOpen: { opened = $0 },
///           onReachEnd: { Task { await loadMore() } }) { … }
/// ```
///
/// Lazy: put it in a `ScrollView`.
public struct PhotoGrid<Item: Identifiable, Photo: View>: View {
    public typealias Style = PhotoGridStyle

    let items: [Item]
    let columns: Int
    let style: Style
    let onOpen: (Item) -> Void
    let onReachEnd: (() -> Void)?
    let label: (Item) -> String?
    let photo: (Item) -> Photo

    /// - Parameters:
    ///   - onReachEnd: Called when the last cell appears: load the next page.
    ///   - label: What VoiceOver says for a photo ("Kapchagay"); `nil` says "Open photo".
    public init(
        _ items: [Item],
        columns: Int = 3,
        style: Style = .rounded,
        onOpen: @escaping (Item) -> Void,
        onReachEnd: (() -> Void)? = nil,
        label: @escaping (Item) -> String? = { _ in nil },
        @ViewBuilder photo: @escaping (Item) -> Photo
    ) {
        self.items = items
        self.columns = max(1, columns)
        self.style = style
        self.onOpen = onOpen
        self.onReachEnd = onReachEnd
        self.label = label
        self.photo = photo
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: style.gap), count: columns), spacing: style.gap) {
            ForEach(items) { item in
                Button {
                    onOpen(item)
                } label: {
                    PhotoTile(size: nil, cornerRadius: style.cornerRadius) { photo(item) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: label(item) ?? String(localized: "photo.open", defaultValue: "Open photo")))
                .onAppear {
                    if let onReachEnd, item.id == items.last?.id {
                        onReachEnd()
                    }
                }
            }
        }
    }
}

/// How the cells of a `PhotoGrid` sit together.
public enum PhotoGridStyle: Hashable, Sendable {
    /// Rounded tiles `AppSpacing.xs` apart: a person's photos, a section of a profile.
    case rounded
    /// Square cells 2 pt apart: a gallery that fills the screen.
    case edgeToEdge

    var gap: CGFloat { self == .rounded ? AppSpacing.xs : PhotoGridMetrics.hairline }
    var cornerRadius: CGFloat { self == .rounded ? AppRadius.md : 0 }
}

enum PhotoGridMetrics {
    /// The gap of an edge-to-edge gallery.
    static let hairline: CGFloat = 2
}

// MARK: - Skeleton

/// Placeholder of a `PhotoGrid`: rows of grey cells in the grid's style.
public struct PhotoGridSkeleton: View {
    let count: Int
    let columns: Int
    let style: PhotoGridStyle

    public init(count: Int = 6, columns: Int = 3, style: PhotoGridStyle = .rounded) {
        self.count = max(1, count)
        self.columns = max(1, columns)
        self.style = style
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: style.gap), count: columns), spacing: style.gap) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(Skeleton.fill)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
