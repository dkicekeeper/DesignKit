//
//  AppColors.swift
//  DesignKit
//
//  The brand accent, and the flat names of 1.x. Every other colour lives in a group by role
//  (AppColors+Semantic.swift: Text, Background, Status, Border), the data colours in
//  AppColors+Data.swift and the deep hues in AppColors+Palette.swift.
//

import SwiftUI

// MARK: - Semantic Colors

/// DesignKit's colours. The accent is flat (`accent`, `accentFill`); everything else is grouped by
/// role (`AppColors.Text`, `.Background`, `.Status`, `.Border`, `.Data`, `.Palette`). The flat
/// names of 1.x below are deprecated (8.21.0) and go in 9.0.0; a finance colour (money in, money
/// out, a transfer) is the app's own (Tenra's `DesignKitBridge.swift`).
public enum AppColors {
    // MARK: Accent

    /// The brand accent: tints, outlines, tracks, selection. Configured per app via
    /// `DesignKitTheme.accent` (default: indigo). As text use `AppColors.Text.action`, its
    /// readable form.
    public nonisolated static var accent: Color { DesignKitTheme.accent }

    /// The accent as a fill under white text or a white symbol (8.10.0): a primary button, the
    /// person's own message, a send button, a picked day or icon. `readableFill` of the accent, so
    /// white on it is 4.5:1 in both themes: Tenra's indigo is a step deeper in dark mode only,
    /// Dalada's green a step deeper in both. Tints, outlines and tracks keep `accent`.
    public nonisolated static var accentFill: Color { readableFill(DesignKitTheme.accent) }

    // MARK: Deprecated flat names (1.x)

    /// The screen.
    @available(*, deprecated, message: "Use AppColors.Background.page.")
    public static let bgBase = Background.page

    /// An opaque grey surface.
    @available(*, deprecated, message: "Use AppColors.Background.card for an opaque grey surface, AppColors.Background.container inside a card.")
    public static let bgCard = Background.card

    /// A sunken grey: tracks, chips.
    @available(*, deprecated, message: "Use AppColors.Background.containerStrong (SurfaceStyle.containerStrong where a Color is needed).")
    public static let bgMuted = SurfaceStyle.glass.containerStrong

    /// Main text.
    @available(*, deprecated, message: "Use AppColors.Text.primary.")
    public static let textPrimary = Text.primary

    /// Secondary text.
    @available(*, deprecated, message: "Use AppColors.Text.secondary.")
    public static let textSecondary = Text.secondary

    /// Hints, placeholders.
    @available(*, deprecated, message: "Use AppColors.Text.tertiary.")
    public nonisolated static let textTertiary = Text.tertiary

    /// Destructive actions, errors.
    @available(*, deprecated, message: "Use AppColors.Status.negative (Status.negativeText for text).")
    public nonisolated static let destructive = Status.negative

    /// Success, a positive state.
    @available(*, deprecated, message: "Use AppColors.Status.positive (Status.positiveText for text).")
    public nonisolated static let success = Status.positive

    /// A warning.
    @available(*, deprecated, message: "Use AppColors.Status.warning (Status.warningText for text).")
    public nonisolated static let warning = Status.warning

    /// White in both themes, on dark photos and colours.
    @available(*, deprecated, message: "Use AppColors.Text.primaryOnDark.")
    public static let staticWhite = Text.primaryOnDark

    /// Planned, scheduled things.
    @available(*, deprecated, message: "Use AppColors.Status.info.")
    public static let planned = Status.info

    // MARK: Deprecated finance colours (the app's own since 8.21.0)

    /// Money in: a green of its own, RGB(0.13, 0.70, 0.37).
    @available(*, deprecated, message: "A finance colour is the app's own: define it in the app (Tenra: DesignKitBridge.swift) or use AppColors.Status.positive.")
    public nonisolated static let income = Color(red: 0.13, green: 0.70, blue: 0.37)

    /// Money in as text: `readable(income)`.
    @available(*, deprecated, message: "Use AppColors.readable(<the app's income colour>) or AppColors.Text.positive.")
    public nonisolated static let incomeText = readable(Color(red: 0.13, green: 0.70, blue: 0.37))

    /// Money out: the primary text colour.
    @available(*, deprecated, message: "Use AppColors.Text.primary, or the app's own expense colour.")
    public nonisolated static let expense = Color.primary

    /// An internal transfer: cyan-teal.
    @available(*, deprecated, message: "A finance colour is the app's own: define it in the app (Tenra: DesignKitBridge.swift).")
    public static let transfer = Color(red: 0.0, green: 0.75, blue: 0.85)
}

// MARK: - Category Color Palette

/// The colour of a name, by hash, and the colours a person picks. Deprecated (8.21.0): the same
/// colours as `AppColors.Data`, which names them for any data, not one app's categories.
@available(*, deprecated, message: "Use AppColors.Data (color(for:opacity:), paletteIndex(for:), palette, pickerPalette).")
public struct CategoryColors {
    /// The colours a user can pick: `AppColors.Data.pickerPalette`.
    public nonisolated static var pickerPalette: [String] { AppColors.Data.pickerPalette }

    /// The 14 hash palette colours: `AppColors.Data.palette`.
    public nonisolated static var paletteColors: [Color] { AppColors.Data.palette }

    /// The colour of a name: `AppColors.Data.color(for:opacity:)`.
    public nonisolated static func color(for name: String, opacity: Double = 1.0) -> Color {
        AppColors.Data.color(for: name, opacity: opacity)
    }

    /// The palette slot of a name: `AppColors.Data.paletteIndex(for:)`.
    public nonisolated static func paletteIndex(for category: String) -> Int {
        AppColors.Data.paletteIndex(for: category)
    }
}
