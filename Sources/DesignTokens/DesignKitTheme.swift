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

    /// How the app's surfaces draw (8.12.0): `.glass` (Liquid Glass, the default: Tenra, Dalada)
    /// or `.fill`, a grey card on the white page with no glass (Platina). It reaches every
    /// `cardStyle()` card and what is built on it (`FormSection`, `CardList`, the cards), filter
    /// chips, tiles, an `Icon`'s glass plate and `MessageBanner`; buttons and floating chrome stay
    /// glass (`SurfaceStyle`).
    ///
    /// Set it once, next to the accent, before any view renders:
    /// ```swift
    /// init() {
    ///     DesignKitTheme.accent = .teal
    ///     DesignKitTheme.surface = .fill
    /// }
    /// ```
    /// A subtree can differ with `.surfaceStyle(_:)`.
    nonisolated(unsafe) public static var surface: SurfaceStyle = .glass
}
