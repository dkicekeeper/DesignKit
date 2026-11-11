//
//  AppColors+Semantic.swift
//  DesignKit
//
//  Semantic colour tokens v2 (1.6.0): grouped by what they colour (Text, Background, Status,
//  Border), named "group / name / modifier". Modifiers:
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
        /// A positive value or label: a rise, money in, "done". Since 8.9.0 the green of
        /// `Status.positive` deep enough to read (`AppColors.readable`): 4.5:1 on the page and on
        /// its pale container.
        public nonisolated static let positive = Status.positiveText
        /// A negative value or label: a fall, an error. Readable red (8.9.0).
        public nonisolated static let negative = Status.negativeText
        /// A warning label or icon. Readable orange (8.9.0).
        public nonisolated static let warning = Status.warningText
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
        /// A card or a list's section on `baseAlt` (7.1.0), as the rows of a grouped `List`:
        /// white in light, a step lighter than `baseAlt` in dark, in a sheet too (iOS raises
        /// both there; the fixed `elevation1` would be the sheet's own colour).
        public nonisolated static let baseAltCard = Color(.secondarySystemGroupedBackground)
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

        /// Status text and icons on the page or on the status's `…Pale` container (8.9.0): the
        /// solid colour made readable (`AppColors.readable`), at least 4.5:1 in both themes. The
        /// solid colours themselves stay for fills, tracks and charts.
        public nonisolated static let infoText = AppColors.readable(info)
        /// Positive text and icons, readable (8.9.0).
        public nonisolated static let positiveText = AppColors.readable(positive)
        /// Negative text and icons, readable (8.9.0).
        public nonisolated static let negativeText = AppColors.readable(negative)
        /// Warning text and icons, readable (8.9.0).
        public nonisolated static let warningText = AppColors.readable(warning)
        /// Neutral text and icons, readable (8.9.0).
        public nonisolated static let neutralText = AppColors.readable(neutral)
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

    // MARK: - Contrast (8.9.0)

    /// `color` as text or an icon that reads: the same hue, a step deeper in light mode or a step
    /// lighter in dark mode, just enough for 4.5:1 (WCAG AA for body text) against its own
    /// `pale(_:)` container on a card, and so against the page too. A colour that already reads
    /// stays as it is (the indigo accent in light mode, the system green in dark mode).
    ///
    /// ```swift
    /// Text("Overdue").foregroundStyle(AppColors.readable(category.color))
    ///     .background(AppColors.pale(category.color), in: Capsule())
    /// ```
    ///
    /// The system orange becomes a deep amber in light mode (2.0:1 → 4.5:1), the green a forest
    /// green, the red a brick red. Fills, progress tracks and chart marks keep the solid colour.
    nonisolated static func readable(_ color: Color) -> Color {
        let base = UIColor(color)
        return Color(UIColor { traits in
            let dark = traits.userInterfaceStyle == .dark
            let solid = base.resolvedColor(with: traits)
            let surface = dark ? ColorContrast.darkCard : UIColor.white
            let container = ColorContrast.composite(solid.withAlphaComponent(dark ? 0.24 : 0.12), over: surface)
            return ColorContrast.adjusted(solid, toward: dark ? .white : .black,
                                          reaching: ColorContrast.textMinimum, against: container)
        })
    }

    /// `color` as a fill white text reads on (`Badge(style: .filled)`): the same hue deepened
    /// until white on it is 4.5:1, in both themes. A deep enough colour stays as it is.
    nonisolated static func readableFill(_ color: Color) -> Color {
        let base = UIColor(color)
        return Color(UIColor { traits in
            ColorContrast.adjusted(base.resolvedColor(with: traits), toward: .black,
                                   reaching: ColorContrast.textMinimum, against: .white)
        })
    }

    /// The WCAG contrast ratio of two colours, from 1 (the same) to 21 (black on white). Both are
    /// resolved for `traits`; a translucent colour is laid over the other one first.
    nonisolated static func contrastRatio(
        _ foreground: Color,
        _ background: Color,
        in traits: UITraitCollection = UITraitCollection(userInterfaceStyle: .light)
    ) -> Double {
        let back = UIColor(background).resolvedColor(with: traits)
        let opaqueBack = ColorContrast.composite(back, over: traits.userInterfaceStyle == .dark ? .black : .white)
        let front = ColorContrast.composite(UIColor(foreground).resolvedColor(with: traits), over: opaqueBack)
        return ColorContrast.ratio(front, opaqueBack)
    }
}

/// The arithmetic behind `AppColors.readable` and `contrastRatio` (WCAG 2.x relative luminance).
enum ColorContrast {
    /// Body text and icons: WCAG AA.
    nonisolated static let textMinimum: Double = 4.5
    /// The card a dark-mode badge sits on (`Background.elevation1`).
    nonisolated static var darkCard: UIColor { UIColor(white: 28 / 255, alpha: 1) }

    nonisolated static func components(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            var white: CGFloat = 0
            color.getWhite(&white, alpha: &a)
            (r, g, b) = (white, white, white)
        }
        // Extended sRGB (a P3 colour) can step outside 0...1.
        return (min(max(r, 0), 1), min(max(g, 0), 1), min(max(b, 0), 1), a)
    }

    nonisolated static func luminance(_ color: UIColor) -> Double {
        let c = components(color)
        func linear(_ channel: CGFloat) -> Double {
            let v = Double(channel)
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    nonisolated static func ratio(_ a: UIColor, _ b: UIColor) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// `foreground` (with its alpha) laid over an opaque `background`.
    nonisolated static func composite(_ foreground: UIColor, over background: UIColor) -> UIColor {
        let f = components(foreground), b = components(background)
        return UIColor(red: f.r * f.a + b.r * (1 - f.a),
                       green: f.g * f.a + b.g * (1 - f.a),
                       blue: f.b * f.a + b.b * (1 - f.a),
                       alpha: 1)
    }

    /// `color` mixed with `target` (black or white) just enough to reach `minimum` against
    /// `background`; unchanged when it already does.
    nonisolated static func adjusted(_ color: UIColor, toward target: UIColor, reaching minimum: Double,
                                     against background: UIColor) -> UIColor {
        let opaque = composite(color, over: background)
        guard ratio(opaque, background) < minimum else { return opaque }
        let c = components(opaque), t = components(target)
        func mixed(_ amount: CGFloat) -> UIColor {
            UIColor(red: c.r + (t.r - c.r) * amount, green: c.g + (t.g - c.g) * amount,
                    blue: c.b + (t.b - c.b) * amount, alpha: 1)
        }
        var low: CGFloat = 0, high: CGFloat = 1
        for _ in 0..<16 {
            let middle = (low + high) / 2
            if ratio(mixed(middle), background) >= minimum { high = middle } else { low = middle }
        }
        return mixed(high)
    }
}
