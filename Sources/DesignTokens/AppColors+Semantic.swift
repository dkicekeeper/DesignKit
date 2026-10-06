//
//  AppColors+Semantic.swift
//  DesignKit
//
//  Semantic colour tokens v2 (1.6.0): grouped by what they colour (Text, Background, Status,
//  Border), named "group / name / modifier" after T-Bank's TUI structure. Modifiers:
//  `OnDark` / `OnLight` stay the same in both themes (content on photos, gradients, coloured
//  headers); `Pale` is a tinted container; `Opaque` has no transparency.
//
//  The flat names in AppColors.swift (`textPrimary`, `bgCard`, `destructive`, …) are aliases of
//  these and keep working. New code uses the groups. Adding them changed no existing colour.
//

import SwiftUI
import UIKit

public extension AppColors {
    // MARK: - Text

    /// Text and icons.
    enum Text {
        /// Main text and icons on base, elevation and neutral backgrounds.
        public nonisolated static let primary = Color.primary
        /// Subtitles, metadata, secondary icons.
        public nonisolated static let secondary = Color.secondary
        /// Hints, placeholders, disclaimers, disabled labels.
        public nonisolated static let tertiary = Color.gray
        /// Interactive text and icons: links, text buttons. The app's accent.
        public nonisolated static var action: Color { DesignKitTheme.accent }
        /// A positive value or label: a rise, money in, "done".
        public nonisolated static let positive = Color.green
        /// A negative value or label: a fall, an error.
        public nonisolated static let negative = Color.red
        /// A warning label or icon.
        public nonisolated static let warning = Color.orange
        /// Text and icons on an accent fill (a filled button, a badge).
        public nonisolated static let onAccent = Color.white

        /// Main text on dark photos, gradients and coloured headers. The same in both themes.
        public nonisolated static let primaryOnDark = Color.white
        /// Secondary text on dark backgrounds. The same in both themes.
        public nonisolated static let secondaryOnDark = Color(.sRGB, red: 235 / 255, green: 235 / 255, blue: 245 / 255, opacity: 0.6)
        /// Tertiary text on dark backgrounds. The same in both themes.
        public nonisolated static let tertiaryOnDark = Color(.sRGB, red: 235 / 255, green: 235 / 255, blue: 245 / 255, opacity: 0.3)
        /// Main text on light photos and pale fills. The same in both themes.
        public nonisolated static let primaryOnLight = Color.black
        /// Secondary text on light backgrounds. The same in both themes.
        public nonisolated static let secondaryOnLight = Color(.sRGB, red: 60 / 255, green: 60 / 255, blue: 67 / 255, opacity: 0.6)
        /// Tertiary text on light backgrounds. The same in both themes.
        public nonisolated static let tertiaryOnLight = Color(.sRGB, red: 60 / 255, green: 60 / 255, blue: 67 / 255, opacity: 0.3)
    }

    // MARK: - Background

    /// Screens, surfaces and containers.
    ///
    /// Levels: `base` (the screen) → `elevation1` (sheets, cards on base) → `elevation2` (cards
    /// on elevation 1) → `elevation3` (above everything). In light they are all white and a
    /// shadow tells them apart; in dark each level is a step lighter.
    enum Background {
        /// The screen.
        public nonisolated static let base = Color(.systemBackground)
        /// An alternative screen background (grouped lists): grey in light, black in dark.
        public nonisolated static let baseAlt = Color(.systemGroupedBackground)
        /// Sheets, modal screens, cards on `base`.
        public nonisolated static let elevation1 = AppColors.dynamic(light: .white, dark: UIColor(white: 28 / 255, alpha: 1))
        /// Cards on `elevation1`.
        public nonisolated static let elevation2 = AppColors.dynamic(light: .white, dark: UIColor(white: 44 / 255, alpha: 1))
        /// Elements above everything else (popovers, floating panels).
        public nonisolated static let elevation3 = AppColors.dynamic(light: .white, dark: UIColor(white: 58 / 255, alpha: 1))

        /// An opaque container with minimal contrast on `base`: fields, grouped blocks,
        /// inactive chips.
        public nonisolated static let neutral1 = Color(.secondarySystemBackground)
        /// An opaque container with more contrast: progress tracks, sunken controls, secondary
        /// buttons.
        public nonisolated static let neutral2 = Color(.systemGray5)
        /// A translucent container that works on any surface, glass included.
        public nonisolated static let fill = Color(.tertiarySystemFill)
        /// A translucent container on dark photos and headers. The same in both themes.
        public nonisolated static let fillOnDark = Color.white.opacity(0.15)
        /// A translucent container on light photos and headers. The same in both themes.
        public nonisolated static let fillOnLight = Color.black.opacity(0.05)
        /// Darkens a photo under text or controls. The same in both themes.
        public nonisolated static let overlayOnImage = Color.black.opacity(0.3)
    }

    // MARK: - Status

    /// Status blocks: banners, badges, notices. The solid colour marks the icon or a filled
    /// block; `…Pale` is the tinted container behind status text.
    enum Status {
        /// Information.
        public nonisolated static let info = Color.blue
        /// Success, a positive change.
        public nonisolated static let positive = Color.green
        /// An error, a negative change.
        public nonisolated static let negative = Color.red
        /// A warning.
        public nonisolated static let warning = Color.orange
        /// Neither good nor bad (archived, paused).
        public nonisolated static let neutral = Color.gray

        /// Container of an information block.
        public nonisolated static let infoPale = AppColors.pale(info)
        /// Container of a positive block.
        public nonisolated static let positivePale = AppColors.pale(positive)
        /// Container of a negative block.
        public nonisolated static let negativePale = AppColors.pale(negative)
        /// Container of a warning block.
        public nonisolated static let warningPale = AppColors.pale(warning)
        /// Container of a neutral block.
        public nonisolated static let neutralPale = AppColors.pale(neutral)
    }

    // MARK: - Border

    /// Outlines and separators.
    enum Border {
        /// Separators and outlines on the main backgrounds.
        public nonisolated static let normal = Color(.separator)
        /// `normal` without transparency, for outlines that overlap.
        public nonisolated static let opaque = Color(.opaqueSeparator)
        /// The outline of a selected element.
        public nonisolated static var selected: Color { DesignKitTheme.accent }
        /// A hairline around coloured elements (logos, avatars, images) that only shows in
        /// dark, where they would otherwise blend into the black background.
        public nonisolated static let darkModeOnly = AppColors.dynamic(light: .clear, dark: UIColor(white: 1, alpha: 0.1))
        /// Separates coloured elements from a dark background. The same in both themes.
        public nonisolated static let onDark = Color.white.opacity(0.1)
        /// Separates coloured elements from a light background. The same in both themes.
        public nonisolated static let onLight = Color.black.opacity(0.05)
    }

    // MARK: - Helpers

    /// A pale tint of `color` for containers behind status text, badges and icons: 12% in
    /// light, 24% in dark (where a 12% tint disappears against black).
    ///
    /// ```swift
    /// Text("Paid").padding().background(AppColors.pale(category.color))
    /// ```
    nonisolated static func pale(_ color: Color) -> Color {
        let base = UIColor(color)
        return Color(UIColor { traits in
            base.resolvedColor(with: traits)
                .withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.24 : 0.12)
        })
    }

    /// A colour with its own light and dark values.
    nonisolated static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }
}
