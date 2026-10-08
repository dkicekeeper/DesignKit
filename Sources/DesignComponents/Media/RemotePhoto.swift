//
//  RemotePhoto.swift
//  DesignKit
//
//  A photo loaded by its address (3.1.0): while it loads, a grey skeleton with the shimmer fills
//  its frame (or the small version, when the app already has it, with the shimmer over it), and
//  the photo comes into focus in its place. The app loads it (`DesignKitPhotoLoader`), so its
//  cache and signed links stay its own. Ported from Dalada's RemotePhoto, whose spinner the
//  skeleton replaces; the cache (`PhotoCache`) stays in Dalada.
//

import SwiftUI
import UIKit
import DesignTokens
import DesignSupport

/// A photo by key and URL: a skeleton while it loads, then the photo, revealed from a light blur.
///
/// ```swift
/// PhotoTile { RemotePhoto(key: photo.thumbnailPath, url: urls[photo.thumbnailPath]) }
/// RemotePhoto(key: photo.path, url: urls[photo.path], contentMode: .fit,
///             placeholderKey: photo.thumbnailPath)                      // the viewer
/// ```
///
/// Fills the frame it is given (a tile, a grid cell, a card's image) and does not clip: the
/// container gives the shape. With no URL, or when loading fails, the photo symbol stands in.
/// A photo the app already holds (`DesignKitPhotoLoader.cached`) shows at once.
public struct RemotePhoto: View {
    let key: String
    let url: URL?
    let contentMode: ContentMode
    let placeholderKey: String?

    @State private var image: UIImage?
    @State private var failed = false

    /// - Parameters:
    ///   - key: What the app knows the photo by (a storage path): the cache's key, which a new
    ///     signed URL does not change.
    ///   - url: Where to load it from; `nil` shows the photo symbol.
    ///   - contentMode: `.fill` crops it to the frame (a tile); `.fit` shows all of it (a viewer).
    ///   - placeholderKey: A smaller version to show while this one loads (the thumbnail under the
    ///     full photo), when the app already has it.
    public init(key: String, url: URL?, contentMode: ContentMode = .fill, placeholderKey: String? = nil) {
        self.key = key
        self.url = url
        self.contentMode = contentMode
        self.placeholderKey = placeholderKey
    }

    private var shown: UIImage? {
        image ?? DesignKitPhotoLoader.cached?(key)
    }

    public var body: some View {
        ZStack {
            if let shown {
                Image(uiImage: shown)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.skeletonReveal)
            } else if let placeholderKey, let placeholder = DesignKitPhotoLoader.cached?(placeholderKey) {
                // The small version, sharpened by the large one; the shimmer says it is coming.
                Image(uiImage: placeholder)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .shimmer()
                    .transition(.opacity)
            } else if failed || url == nil {
                PhotoPlaceholderSymbol()
                    .accessibilityHidden(true)
            } else {
                RemotePhotoSkeleton()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: RemotePhotoMetrics.reveal), value: shown != nil)
        .task(id: url) {
            guard image == nil, DesignKitPhotoLoader.cached?(key) == nil, let url else { return }
            failed = false
            image = await DesignKitPhotoLoader.load(key: key, url: url)
            failed = image == nil
        }
    }
}

enum RemotePhotoMetrics {
    /// The photo coming into focus: as long as `SkeletonReveal`.
    static let reveal: Double = 0.45
}

// MARK: - Skeleton

/// Placeholder of a `RemotePhoto`: the skeleton's grey with the shimmer, filling the frame. The
/// container gives the corner (a `PhotoTile`, a grid cell), as it does for the photo.
public struct RemotePhotoSkeleton: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Skeleton.fill)
            .shimmer()
            .skeletonLoadingLabel()
    }
}
