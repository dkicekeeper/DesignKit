//
//  GalleryLogos.swift
//  DesignKit Gallery
//
//  Invented brands for the logo demos (no real brand): the Gallery's DesignKitLogoLoader draws
//  them on the fly, so PackedCircleIcons, Icon and the snapshot tests can show logos without a
//  network. Any other name has no logo, and Icon shows its fallback symbol.
//

import SwiftUI
import DesignSupport

enum GalleryLogos {
    struct Brand {
        let name: String
        let symbol: String
        let background: Color
        let foreground: Color
    }

    /// A film service, a notes app on white (the hard case: a white logo), music, cloud storage.
    static let brands: [Brand] = [
        Brand(name: "Reelio", symbol: "film.fill", background: Color(red: 0.95, green: 0.33, blue: 0.18), foreground: .white),
        Brand(name: "Leafnote", symbol: "leaf.fill", background: .white, foreground: Color(red: 0.09, green: 0.64, blue: 0.29)),
        Brand(name: "Tunewave", symbol: "music.note", background: Color(red: 0.11, green: 0.08, blue: 0.19), foreground: Color(red: 0.65, green: 0.55, blue: 0.98)),
        Brand(name: "Cloudy", symbol: "cloud.fill", background: Color(red: 0.18, green: 0.44, blue: 0.93), foreground: .white),
    ]

    /// The Gallery's `DesignKitLogoLoader`: a picture for an invented brand, nil for the rest.
    static func load(_ name: String) async -> UIImage? {
        guard let brand = brands.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            return nil
        }
        return await MainActor.run { image(for: brand) }
    }

    @MainActor
    private static func image(for brand: Brand) -> UIImage? {
        let renderer = ImageRenderer(
            content: Image(systemName: brand.symbol)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(brand.foreground)
                .frame(width: 128, height: 128)
                .background(brand.background)
        )
        renderer.scale = 3
        return renderer.uiImage
    }
}
