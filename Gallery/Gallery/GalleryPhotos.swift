//
//  GalleryPhotos.swift
//  DesignKit Gallery
//
//  The Gallery's DesignKitPhotoLoader (3.1.0): `RemotePhoto` asks it for stand-in photos (the
//  gradients of `GalleryPhoto.samples`, drawn into images), so the page and the snapshot tests
//  show loading, a loaded photo and a failure without a network.
//
//  A key "gallery-photo-<n>" is already held (it shows at once); "gallery-photo-<n>-<anything>"
//  arrives after `delay`, as from the network, and is held from then on; "…-pending" never
//  arrives (the snapshot of a photo still loading).
//

import SwiftUI
import UIKit
import DesignSupport

@MainActor
enum GalleryPhotos {
    /// How long a photo "downloads".
    static let delay: Duration = .seconds(1.2)

    private static var images: [Int: UIImage] = [:]
    private static var loaded: Set<String> = []

    /// Wires the hook; called from `GalleryApp.init`.
    static func install() {
        DesignKitPhotoLoader.cached = { cached($0) }
        DesignKitPhotoLoader.loader = { key, _ in await load(key) }
    }

    /// The key of sample `index`; `attempt` > 0 makes one that is not held yet (it loads).
    static func key(_ index: Int, attempt: Int = 0) -> String {
        attempt == 0 ? "gallery-photo-\(index)" : "gallery-photo-\(index)-\(attempt)"
    }

    /// An address for the sample; never fetched, the hook answers first.
    static func url(_ index: Int) -> URL {
        URL(string: "https://gallery.invalid/photo/\(index).jpg")!
    }

    static func cached(_ key: String) -> UIImage? {
        guard let index = sampleIndex(key) else { return nil }
        if key == self.key(index) || loaded.contains(key) {
            return image(index)
        }
        return nil
    }

    static func load(_ key: String) async -> UIImage? {
        guard let index = sampleIndex(key) else { return nil }
        if key.hasSuffix("-pending") {
            try? await Task.sleep(for: .seconds(3600))
            return nil
        }
        try? await Task.sleep(for: delay)
        loaded.insert(key)
        return image(index)
    }

    private static func sampleIndex(_ key: String) -> Int? {
        let parts = key.split(separator: "-")
        guard parts.count >= 3, parts[0] == "gallery", parts[1] == "photo", let index = Int(parts[2]),
              GalleryPhoto.samples.indices.contains(index)
        else { return nil }
        return index
    }

    /// The sample drawn as a 4:3 picture: its gradient and its symbol in white.
    private static func image(_ index: Int) -> UIImage {
        if let image = images[index] { return image }
        let photo = GalleryPhoto.samples[index]
        let size = CGSize(width: 480, height: 360)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = photo.colors.map { UIColor($0).cgColor } as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: nil) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }
            let config = UIImage.SymbolConfiguration(pointSize: 96, weight: .regular)
            if let symbol = UIImage(systemName: photo.symbol, withConfiguration: config)?
                .withTintColor(UIColor.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal) {
                let origin = CGPoint(x: (size.width - symbol.size.width) / 2, y: (size.height - symbol.size.height) / 2)
                symbol.draw(at: origin)
            }
        }
        images[index] = image
        return image
    }
}
