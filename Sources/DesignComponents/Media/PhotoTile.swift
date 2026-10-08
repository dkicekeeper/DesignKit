//
//  PhotoTile.swift
//  DesignKit
//
//  A photo in a square tile (2.8.0): the muted background shows while it loads, the corners are
//  `AppRadius.md`. The tile of `PhotoStrip` and `PhotoGrid`, and on its own the preview of a photo
//  picked for a form. Ported from Dalada's PhotoDraftThumbnail and the tiles of its photo rows;
//  loading the photo (signed URLs, the cache) stays in the app, which passes the image view.
//

import SwiftUI
import UIKit
import DesignTokens

public enum PhotoTileMetrics {
    /// The side of a tile in a row of photos.
    public static let size: CGFloat = 88
}

/// A photo cropped to a square, on the muted background, with rounded corners.
///
/// ```swift
/// PhotoTile(image: UIImage(data: draft.thumbnail))            // a picked photo, or the placeholder
/// PhotoTile(size: 150) { AppRemotePhoto(path: photo.path) }   // the app's loader
/// PhotoTile(size: nil) { … }                                   // fills the width (a grid cell)
/// ```
public struct PhotoTile<Photo: View>: View {
    let size: CGFloat?
    let cornerRadius: CGFloat
    let photo: Photo

    /// - Parameters:
    ///   - size: The tile's side; `nil` fills the proposed width and stays square.
    ///   - cornerRadius: `0` for an edge-to-edge gallery.
    ///   - photo: The image, filling the tile (`.resizable().scaledToFill()`); it is cropped.
    public init(
        size: CGFloat? = PhotoTileMetrics.size,
        cornerRadius: CGFloat = AppRadius.md,
        @ViewBuilder photo: () -> Photo
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.photo = photo()
    }

    public var body: some View {
        square
            .overlay { photo }
            .background(AppColors.bgMuted)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var square: some View {
        if let size {
            Color.clear.frame(width: size, height: size)
        } else {
            Color.clear.aspectRatio(1, contentMode: .fit)
        }
    }
}

public extension PhotoTile where Photo == PhotoTileImage {
    /// A loaded image, or the photo placeholder when there is none.
    init(image: UIImage?, size: CGFloat? = PhotoTileMetrics.size, cornerRadius: CGFloat = AppRadius.md) {
        self.init(size: size, cornerRadius: cornerRadius) { PhotoTileImage(image: image) }
    }
}

/// An image filling a photo tile, or a photo symbol when there is none (not loaded, failed).
public struct PhotoTileImage: View {
    let image: UIImage?

    public init(image: UIImage?) {
        self.image = image
    }

    public var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            PhotoPlaceholderSymbol()
        }
    }
}

/// The photo symbol in the tertiary colour: a photo that is missing or failed to load.
public struct PhotoPlaceholderSymbol: View {
    public init() {}

    public var body: some View {
        Image(systemName: "photo")
            .foregroundStyle(AppColors.Text.tertiary)
    }
}

// MARK: - Skeleton

/// Placeholder of a `PhotoTile`: the tile's shape in the skeleton grey.
public struct PhotoTileSkeleton: View {
    let size: CGFloat?
    let cornerRadius: CGFloat

    public init(size: CGFloat? = PhotoTileMetrics.size, cornerRadius: CGFloat = AppRadius.md) {
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Group {
            if let size {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Skeleton.fill)
                    .frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Skeleton.fill)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
