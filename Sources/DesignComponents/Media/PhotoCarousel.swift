//
//  PhotoCarousel.swift
//  DesignKit
//
//  The photos of a post, paged (2.8.0): one photo at a time in a rounded 4:3 frame, swiped
//  sideways, page dots when there are several; a tap opens the photo. Ported from Dalada's
//  PostPhotoCarousel (feed posts); the app passes each image.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Photos paged sideways in a rounded frame.
///
/// ```swift
/// PhotoCarousel(post.media, onOpen: { opened = $0 }) { AppRemotePhoto(path: $0.path) }
/// ```
public struct PhotoCarousel<Item: Identifiable, Photo: View>: View where Item.ID: Hashable {
    let items: [Item]
    let aspectRatio: CGFloat
    let onOpen: ((Item) -> Void)?
    let openLabel: String
    let photo: (Item) -> Photo

    /// - Parameters:
    ///   - aspectRatio: Width over height of the frame; 4:3 by default.
    ///   - onOpen: A tap on the photo; `nil` leaves it still.
    public init(
        _ items: [Item],
        aspectRatio: CGFloat = PhotoCarouselMetrics.aspectRatio,
        onOpen: ((Item) -> Void)? = nil,
        openLabel: String = String(localized: "photo.open", defaultValue: "Open photo"),
        @ViewBuilder photo: @escaping (Item) -> Photo
    ) {
        self.items = items
        self.aspectRatio = aspectRatio
        self.onOpen = onOpen
        self.openLabel = openLabel
        self.photo = photo
    }

    public var body: some View {
        TabView {
            ForEach(items) { item in
                page(item)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: items.count > 1 ? .automatic : .never))
        .aspectRatio(aspectRatio, contentMode: .fit)
        .background(AppColors.bgMuted)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    @ViewBuilder
    private func page(_ item: Item) -> some View {
        let picture = Color.clear
            .overlay { photo(item) }
            .clipped()
            .contentShape(Rectangle())
        if let onOpen {
            Button {
                onOpen(item)
            } label: {
                picture
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: openLabel))
        } else {
            picture
        }
    }
}

public enum PhotoCarouselMetrics {
    /// The frame of a post's photos.
    public static let aspectRatio: CGFloat = 4.0 / 3.0
}

// MARK: - Skeleton

/// Placeholder of a `PhotoCarousel`: its rounded frame in the skeleton grey.
public struct PhotoCarouselSkeleton: View {
    let aspectRatio: CGFloat

    public init(aspectRatio: CGFloat = PhotoCarouselMetrics.aspectRatio) {
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.md)
            .fill(Skeleton.fill)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .shimmer()
            .skeletonLoadingLabel()
    }
}
