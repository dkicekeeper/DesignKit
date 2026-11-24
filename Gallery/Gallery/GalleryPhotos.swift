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
//  The layers of a picture hero (8.17.0) are held too: "gallery-backdrop-<n>", the sample's
//  gradient with no symbol, and "gallery-figure", a cut-out figure on a transparent square.
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

    /// The key of sample `index` as a backdrop: its gradient with no symbol (8.17.0).
    static func backdropKey(_ index: Int) -> String {
        "gallery-backdrop-\(index)"
    }

    /// The key of the cut-out figure that stands in front of a backdrop (8.17.0).
    static let figureKey = "gallery-figure"

    /// An address for the figure; never fetched.
    static let figureURL = URL(string: "https://gallery.invalid/figure.png")!

    static func cached(_ key: String) -> UIImage? {
        if let layer = layerImage(key) { return layer }
        guard let index = sampleIndex(key) else { return nil }
        if key == self.key(index) || loaded.contains(key) {
            return image(index)
        }
        return nil
    }

    static func load(_ key: String) async -> UIImage? {
        if let layer = layerImage(key) { return layer }
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

    private static var layers: [String: UIImage] = [:]

    /// A hero's layer by key (8.17.0): a backdrop or the figure, or nil for any other key.
    private static func layerImage(_ key: String) -> UIImage? {
        if let image = layers[key] { return image }
        let image: UIImage
        if key == figureKey {
            image = figure()
        } else if key.hasPrefix("gallery-backdrop-"), let index = Int(key.dropFirst("gallery-backdrop-".count)),
                  GalleryPhoto.samples.indices.contains(index) {
            image = backdrop(index)
        } else {
            return nil
        }
        layers[key] = image
        return image
    }

    /// The sample's gradient alone, 16:9, as a game's backdrop.
    private static func backdrop(_ index: Int) -> UIImage {
        let photo = GalleryPhoto.samples[index]
        let size = CGSize(width: 640, height: 360)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = photo.colors.map { UIColor($0).cgColor } as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: nil) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }
        }
    }

    /// A hiker in white on a transparent square, with a soft shadow: a cut-out figure.
    private static func figure() -> UIImage {
        let size = CGSize(width: 480, height: 480)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let config = UIImage.SymbolConfiguration(pointSize: 300, weight: .regular)
            guard let symbol = UIImage(systemName: "figure.hiking", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
            let scale = min(size.width * 0.8 / symbol.size.width, size.height * 0.9 / symbol.size.height)
            let drawn = CGSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
            let origin = CGPoint(x: (size.width - drawn.width) / 2, y: size.height - drawn.height)
            context.cgContext.setShadow(offset: .zero, blur: 24, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            symbol.draw(in: CGRect(origin: origin, size: drawn))
        }
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
