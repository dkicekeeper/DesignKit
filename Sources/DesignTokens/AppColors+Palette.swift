//
//  AppColors+Palette.swift
//  DesignKit
//
//  Named deep hues for what an app draws over a map, a photo or a chart (3.7.0): marker
//  circles with a white symbol, route and track lines, zone fills. Fixed colours, the same in
//  light and dark, so a marker image drawn once looks the same in both; each carries a white
//  symbol (3:1 at least, the WCAG minimum for a graphic; all but orange 4.5:1). Which thing
//  gets which hue stays in the app (Dalada's place types and map layers).
//

import SwiftUI

public extension AppColors {
    /// A deep hue from the palette: `.color` for SwiftUI, `.uiColor` for UIKit, MapKit,
    /// MapLibre and Core Graphics, `.rgb` for anything else.
    ///
    /// ```swift
    /// markerFill = AppColors.Palette.teal.uiColor
    /// Circle().fill(AppColors.Palette.teal.color)
    /// ```
    ///
    /// The hues come from the same family as `CategoryColors` (one tone deeper where the
    /// category colour would not carry a white symbol). Not for text, status or chrome: those
    /// are `AppColors.Text`, `.Status` and the accent.
    enum Palette: String, CaseIterable, Sendable {
        case blue, indigo, violet, purple, pink, red, orange, ochre, green, emerald, teal, cyan, slate

        /// `0xRRGGBB`; white on it: blue 5.2, indigo 6.3, violet 5.7, purple 5.4, pink 4.6,
        /// red 4.8, orange 3.6, ochre 4.9, green 5.0, emerald 5.5, teal 5.5, cyan 5.4, slate 4.8.
        public nonisolated var rgb: UInt32 {
            switch self {
            case .blue: 0x2563EB
            case .indigo: 0x4F46E5
            case .violet: 0x7C3AED
            case .purple: 0x9333EA
            case .pink: 0xDB2777
            case .red: 0xDC2626
            case .orange: 0xEA580C
            case .ochre: 0xA16207
            case .green: 0x15803D
            case .emerald: 0x047857
            case .teal: 0x0F766E
            case .cyan: 0x0E7490
            case .slate: 0x64748B
            }
        }

        public nonisolated var color: Color {
            Color(.sRGB, red: component(16), green: component(8), blue: component(0))
        }

        public nonisolated var uiColor: UIColor {
            UIColor(red: component(16), green: component(8), blue: component(0), alpha: 1)
        }

        private nonisolated func component(_ shift: UInt32) -> CGFloat {
            CGFloat((rgb >> shift) & 0xFF) / 255
        }
    }
}
