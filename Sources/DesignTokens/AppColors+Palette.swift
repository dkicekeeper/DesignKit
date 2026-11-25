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
    /// The hues come from the same family as `AppColors.Data` (one tone deeper where the
    /// category colour would not carry a white symbol). Not for text, status or chrome: those
    /// are `AppColors.Text`, `.Status` and the accent.
    enum Palette: String, CaseIterable, Sendable {
        case blue, indigo, violet, purple, pink, red, orange, ochre, green, emerald, teal, cyan, slate

        /// `0xRRGGBB`; white on it: blue 5.2, indigo 6.3, violet 5.7, purple 5.4, pink 4.6,
        /// red 4.8, orange 3.6, ochre 4.9, green 5.0, emerald 5.5, teal 5.5, cyan 5.4, slate 4.8.
        public nonisolated var rgb: UInt32 {
            switch self {
            case .blue: PaletteTable.blue600
            case .indigo: PaletteTable.indigo600
            case .violet: PaletteTable.violet600
            case .purple: PaletteTable.purple600
            case .pink: PaletteTable.pink600
            case .red: PaletteTable.red600
            case .orange: PaletteTable.orange600
            case .ochre: PaletteTable.yellow700
            case .green: PaletteTable.green700
            case .emerald: PaletteTable.emerald700
            case .teal: PaletteTable.teal700
            case .cyan: PaletteTable.cyan700
            case .slate: PaletteTable.slate500
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

/// Every hue DesignKit's palettes use, each defined once (vNext): the hash and picker colours of
/// `AppColors.Data` and the deep `AppColors.Palette` read the same constants. Named after the
/// Tailwind shades they are.
enum PaletteTable {
    static let blue500: UInt32 = 0x3B82F6, violet500: UInt32 = 0x8B5CF6, pink500: UInt32 = 0xEC4899
    static let orange500: UInt32 = 0xF97316, yellow500: UInt32 = 0xEAB308, green500: UInt32 = 0x22C55E
    static let teal500: UInt32 = 0x14B8A6, cyan500: UInt32 = 0x06B6D4, indigo500: UInt32 = 0x6366F1
    static let fuchsia500: UInt32 = 0xD946EF, rose500: UInt32 = 0xF43F5E, purple500: UInt32 = 0xA855F7
    static let emerald500: UInt32 = 0x10B981, amber500: UInt32 = 0xF59E0B, sky500: UInt32 = 0x0EA5E9
    static let violet400: UInt32 = 0xA78BFA, slate500: UInt32 = 0x64748B, stone500: UInt32 = 0x78716C
    static let blue600: UInt32 = 0x2563EB, indigo600: UInt32 = 0x4F46E5, violet600: UInt32 = 0x7C3AED
    static let purple600: UInt32 = 0x9333EA, pink600: UInt32 = 0xDB2777, red600: UInt32 = 0xDC2626
    static let orange600: UInt32 = 0xEA580C, lime600: UInt32 = 0x65A30D
    static let cyan700: UInt32 = 0x0E7490, teal700: UInt32 = 0x0F766E, green700: UInt32 = 0x15803D
    static let lime700: UInt32 = 0x4D7C0F, yellow700: UInt32 = 0xA16207, red700: UInt32 = 0xB91C1C
    static let pink700: UInt32 = 0xBE185D, fuchsia700: UInt32 = 0xA21CAF, violet700: UInt32 = 0x6D28D9
    static let blue700: UInt32 = 0x1D4ED8, emerald700: UInt32 = 0x047857, orange800: UInt32 = 0x9A3412

    /// What names hash into. Size and order frozen (`AppColors.Data.paletteIndex`).
    static let hashed: [UInt32] = [
        blue500, violet500, pink500, orange500, yellow500,
        green500, teal500, cyan500, indigo500, fuchsia500,
        rose500, purple500, emerald500, amber500,
    ]

    /// Offered in the picker only, never hashed into: deeper and neutral shades, as distinct
    /// from each other and from the hash palette as its own closest pairs, at least 2.7:1 on
    /// white and 2.3:1 on a dark card.
    static let pickerExtra: [UInt32] = [
        sky500, cyan700, teal700, green700, lime600, lime700,
        yellow700, orange800, red700, pink700, fuchsia700, violet700,
        violet400, blue700, slate500, stone500,
    ]

    /// A chart's series: neighbours far apart on the wheel.
    static let series: [UInt32] = [blue500, orange500, teal500, pink500, violet500, yellow500, green500, rose500]

    static func color(_ rgb: UInt32) -> Color {
        Color(.sRGB,
              red: Double((rgb >> 16) & 0xFF) / 255,
              green: Double((rgb >> 8) & 0xFF) / 255,
              blue: Double(rgb & 0xFF) / 255)
    }
}
