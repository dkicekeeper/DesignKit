//
//  PhotoStrip.swift
//  DesignKit
//
//  A row of photo tiles that scrolls sideways (2.8.0): the photos of a report or a review (a tap
//  opens one), or the photos picked for a form (each with a remove button). Ported from Dalada's
//  ReportPhotoStrip, PhotoDraftStrip and the row in its place header; the app passes each image.
//

import SwiftUI
import DesignTokens
import DesignSupport

enum PhotoStripMetrics {
    /// The remove button's glyph: big enough to hit on an 88 pt tile.
    static let removeGlyph: CGFloat = 22
}

/// Photo tiles in a horizontal scroll.
///
/// ```swift
/// // A report's photos: a tap opens the viewer
/// PhotoStrip(report.media, onOpen: { opened = $0 }) { AppRemotePhoto(path: $0.thumbnailPath) }
/// // Picked for a form: each can be removed
/// PhotoStrip(draft.photos, onRemove: { draft.remove($0) }) { PhotoTileImage(image: $0.image) }
/// ```
public struct PhotoStrip<Item: Identifiable, Photo: View>: View {
    let items: [Item]
    let size: CGFloat
    let onOpen: ((Item) -> Void)?
    let onRemove: ((Item) -> Void)?
    let openLabel: String
    let removeLabel: String
    let photo: (Item) -> Photo

    /// - Parameters:
    ///   - size: Each tile's side.
    ///   - onOpen: A tap on a photo; `nil` leaves the photos still.
    ///   - onRemove: Shows a remove button on each photo.
    ///   - openLabel, removeLabel: What VoiceOver says for the tap and the remove button.
    public init(
        _ items: [Item],
        size: CGFloat = PhotoTileMetrics.size,
        onOpen: ((Item) -> Void)? = nil,
        onRemove: ((Item) -> Void)? = nil,
        openLabel: String = String(localized: "photo.open", defaultValue: "Open photo"),
        removeLabel: String = String(localized: "photo.remove", defaultValue: "Remove photo"),
        @ViewBuilder photo: @escaping (Item) -> Photo
    ) {
        self.items = items
        self.size = size
        self.onOpen = onOpen
        self.onRemove = onRemove
        self.openLabel = openLabel
        self.removeLabel = removeLabel
        self.photo = photo
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: AppSpacing.sm) {
                ForEach(items) { item in
                    tile(item)
                }
            }
            // Room for the remove buttons, which sit on the tiles' corners.
            .padding(.vertical, onRemove == nil ? 0 : AppSpacing.xxs)
        }
    }

    @ViewBuilder
    private func tile(_ item: Item) -> some View {
        let photoTile = PhotoTile(size: size) { photo(item) }
        if let onOpen {
            Button {
                onOpen(item)
            } label: {
                photoTile
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: openLabel))
            .overlay(alignment: .topTrailing) { removeButton(item) }
        } else {
            photoTile.overlay(alignment: .topTrailing) { removeButton(item) }
        }
    }

    @ViewBuilder
    private func removeButton(_ item: Item) -> some View {
        if let onRemove {
            Button {
                onRemove(item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: PhotoStripMetrics.removeGlyph))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppColors.staticWhite, Color.black.opacity(0.55))
            }
            .buttonStyle(.borderless)
            .padding(AppSpacing.xxs)
            .accessibilityLabel(Text(verbatim: removeLabel))
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `PhotoStrip`: a few tiles in a row.
public struct PhotoStripSkeleton: View {
    let count: Int
    let size: CGFloat

    public init(count: Int = 3, size: CGFloat = PhotoTileMetrics.size) {
        self.count = max(1, count)
        self.size = size
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(Skeleton.fill)
                    .frame(width: size, height: size)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
