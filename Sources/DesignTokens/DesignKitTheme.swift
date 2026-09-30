//
//  DesignKitTheme.swift
//  DesignKit
//
//  Per-app brand values. DesignKit is shared by several apps (Tenra, Dalada); the
//  tokens stay common, the brand accent is the host app's choice.
//

import SwiftUI

public enum DesignKitTheme {
    /// Brand accent behind `AppColors.accent` — interactive tint, primary CTA,
    /// selection, onboarding glow. Default: system indigo (Tenra).
    ///
    /// Set it once, first thing in `App.init()`, before any view renders:
    /// ```swift
    /// init() {
    ///     DesignKitTheme.accent = .green
    ///     DesignKitFonts.registerIfNeeded()
    /// }
    /// ```
    /// Also set the asset-catalog `AccentColor` to the same colour: it drives
    /// system chrome (active tab tint, default buttons, text cursor) that never
    /// reads `AppColors`.
    nonisolated(unsafe) public static var accent: Color = .indigo
}
