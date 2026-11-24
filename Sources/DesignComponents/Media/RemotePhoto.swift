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
    @Environment(\.remotePhotoLoading) private var loading

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
                // The small version, sharpened by the large one; the shimmer says it is coming
                // (still: blurred, so its few pixels read as colours).
                Image(uiImage: placeholder)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .modifier(RemotePhotoPlaceholderLook(loading: loading))
                    .transition(.opacity)
            } else if loading == .still {
                // Behind text: a still fill while it loads, and where there is none.
                Rectangle()
                    .fill(Skeleton.fill)
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
    /// The small version under a `.still` photo: blurred so its few pixels read as colours.
    static let stillBlur: CGFloat = 24
}

/// How a `RemotePhoto` looks while it loads (8.15.0).
public enum RemotePhotoLoading: Hashable, Sendable {
    /// The skeleton's grey with the shimmer, or the small version with the shimmer over it: a
    /// photo in a tile, a grid, a card. The default.
    case skeleton
    /// A still grey, or the small version blurred, with no shimmer and no photo symbol: a
    /// picture behind text and buttons, where a moving shimmer is noise.
    /// `.heroBackground(picture:)` sets it.
    case still
}

public extension EnvironmentValues {
    /// How the `RemotePhoto`s inside look while they load (8.15.0).
    @Entry var remotePhotoLoading: RemotePhotoLoading = .skeleton
}

public extension View {
    /// How the `RemotePhoto`s inside look while they load (8.15.0): `.still` for a picture behind
    /// text and buttons (`.heroBackground(picture:)` sets it on its picture).
    func remotePhotoLoading(_ loading: RemotePhotoLoading) -> some View {
        environment(\.remotePhotoLoading, loading)
    }
}

/// The small version while the photo loads: under the shimmer, or blurred and still.
private struct RemotePhotoPlaceholderLook: ViewModifier {
    let loading: RemotePhotoLoading

    func body(content: Content) -> some View {
        switch loading {
        case .skeleton:
            content.shimmer()
        case .still:
            content.blur(radius: RemotePhotoMetrics.stillBlur, opaque: true)
        }
    }
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
