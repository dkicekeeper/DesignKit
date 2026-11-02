//
//  DesignKitIconPhotos.swift
//  DesignKit
//
//  8.5.0: an icon from the person's own picture (a logo the catalog doesn't have). Where the
//  picture is kept and how the icon names it is the app's concern: it sets `save`, and
//  `IconPicker` then offers "Photo" (pick a picture, crop it to a square with
//  `SquareImageCropper`, keep it). Without it the option is hidden.
//

import UIKit

@MainActor
public enum DesignKitIconPhotos {
    /// Keeps a square picture the person cropped and returns the icon that shows it (Tenra:
    /// a `.brandService` key its logo loader reads from the file); nil when it could not be kept.
    public static var save: ((UIImage) async -> IconSource?)?

    /// Whether `source` is a picture `save` returned, so the picker can show it as the current
    /// photo. Defaults to never.
    public static var isPhoto: (IconSource) -> Bool = { _ in false }
}
