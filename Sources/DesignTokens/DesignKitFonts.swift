//
//  DesignKitFonts.swift
//  DesignKit
//
//  Registers the bundled Inter variable fonts so `Font.custom("Inter", …)`
//  resolves inside any host app. Makes the package self-contained — consumers
//  don't need to add the fonts to their own Info.plist / UIAppFonts.
//

import CoreText
import Foundation

public enum DesignKitFonts {
    private static var registered = false

    /// Registers DesignKit's bundled fonts. Idempotent — safe to call on every launch.
    /// Call once early in app startup (e.g. in `App.init()`), before any view renders.
    public static func registerIfNeeded() {
        guard !registered else { return }
        registered = true

        let fontFileNames = [
            "Inter-VariableFont_opsz,wght",
            "Inter-Italic-VariableFont_opsz,wght",
        ]
        for name in fontFileNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
