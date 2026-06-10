//
//  DesignKitLogoLoader.swift
//  DesignKit
//
//  Brand-logo loading is an app concern (which provider chain, caching, network).
//  DesignKit ships no networking — host apps inject a loader. When none is set,
//  `BrandLogoView` shows its fallback icon.
//

import UIKit

public enum DesignKitLogoLoader {
    /// App-provided async loader: maps a brand name (e.g. "netflix.com") to an image.
    /// Tenra wires this to its `LogoService`; the Gallery leaves it nil (fallback icon).
    public static var loader: (@Sendable (String) async -> UIImage?)?
}
