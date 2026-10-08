//
//  DesignKitLogoLoader.swift
//  DesignKit
//
//  Brand-logo loading is an app concern (which provider chain, caching, network).
//  DesignKit ships no networking — host apps inject a loader. When none is set,
//  `Icon(source: .brandService(name))` shows its fallback icon.
//

import UIKit

public enum DesignKitLogoLoader {
    /// App-provided async loader: maps a brand name (e.g. "netflix.com") to an image.
    /// Tenra wires this to its `LogoService`; the Gallery draws a few invented brands
    /// (`GalleryLogos`). Without a loader, `Icon` shows its fallback symbol.
    public static var loader: (@Sendable (String) async -> UIImage?)?
}
