//
//  DesignKitPhotoLoader.swift
//  DesignKit
//
//  Host hook for photos DesignKit shows by address (3.1.0): `RemotePhoto` asks the app for the
//  picture behind a key (a storage path) and its URL, so the app keeps its own cache, its signed
//  links and its network. Set once in `App.init()`, like `DesignKitLogoLoader`.
//

import UIKit

/// How DesignKit gets a photo it shows by key and URL (`RemotePhoto`).
///
/// ```swift
/// // App.init()
/// DesignKitPhotoLoader.loader = { key, url in await PhotoCache.shared.image(path: key, url: url) }
/// DesignKitPhotoLoader.cached = { PhotoCache.shared.cached($0) }
/// ```
///
/// Dalada wires it to its `PhotoCache` (the storage path is the key: a signed link changes with
/// every load, the path does not); the Gallery draws stand-in photos (`GalleryPhotos`).
@MainActor
public enum DesignKitPhotoLoader {
    /// Loads the photo for `key` from `url`: the app's cache first, then the network. Without a
    /// loader, `RemotePhoto` downloads `url` itself and keeps nothing.
    public static var loader: (@MainActor (_ key: String, _ url: URL) async -> UIImage?)?

    /// The photo for `key` if the app already holds it, without waiting: a photo seen before
    /// shows at once, with no skeleton. Without it every photo starts from its skeleton.
    public static var cached: (@MainActor (_ key: String) -> UIImage?)?

    /// Loads `url` with `URLSession` when the app gives no loader: a 200 response decoded into an
    /// image, prepared for display off the main thread.
    static func download(_ url: URL) async -> UIImage? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let image = UIImage(data: data)
        else { return nil }
        return await image.byPreparingForDisplay() ?? image
    }

    /// The photo for `key`: the app's loader, or a plain download.
    static func load(key: String, url: URL) async -> UIImage? {
        if let loader {
            return await loader(key, url)
        }
        return await download(url)
    }
}
