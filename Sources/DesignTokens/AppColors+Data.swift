//
//  AppColors+Data.swift
//  DesignKit
//
//  Colours for data (8.21.0): the colour of anything with a name (Tenra's categories, Platina's
//  games, Dalada's place types, a letter avatar) and the colours of a chart's series. Before
//  8.21.0 the first was `CategoryColors`, named for one app's categories.
//

import SwiftUI

public extension AppColors {
    /// Colours for data: things with a name, and a chart's series.
    ///
    /// ```swift
    /// Circle().fill(AppColors.Data.color(for: game.title))
    /// UniversalRow("Colour", accessory: .colors($hex, palette: AppColors.Data.pickerPalette))
    /// ```
    enum Data {
        /// The colour of a name that has none stored, hashed into the 14 palette colours: a
        /// category before the user picks one, an insight's item, a letter avatar. The same on
        /// every launch and device.
        public nonisolated static func color(for name: String, opacity: Double = 1.0) -> Color {
            palette[paletteIndex(for: name)].opacity(opacity)
        }

        /// The palette slot of a name: FNV-1a over its UTF-8 bytes, modulo 14.
        public nonisolated static func paletteIndex(for name: String) -> Int {
            var hash: UInt64 = 0xcbf2_9ce4_8422_2325
            for byte in name.utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x0000_0100_0000_01b3
            }
            return Int(hash % UInt64(PaletteTable.hashed.count))
        }

        /// The 14 colours names hash into, in order. Size and order are frozen: growing or
        /// reordering it would re-colour every name that relies on the hash.
        public nonisolated static var palette: [Color] { hashedColors }

        /// The colours a person can pick (`UniversalRow(accessory: .colors)`'s default), as the
        /// lowercase `#rrggbb` strings apps store: the 14 palette colours first, then 16 deeper
        /// and neutral shades.
        public nonisolated static let pickerPalette: [String] = (PaletteTable.hashed + PaletteTable.pickerExtra).map { rgb in
            let digits = String(rgb, radix: 16)
            return "#" + String(repeating: "0", count: max(0, 6 - digits.count)) + digits
        }

        /// Eight colours for a chart's series, in an order where each is far from the one
        /// before it on the colour wheel: blue, orange, teal, pink, violet, yellow, green, rose.
        public nonisolated static let series: [Color] = PaletteTable.series.map(PaletteTable.color)

        private nonisolated static let hashedColors: [Color] = PaletteTable.hashed.map(PaletteTable.color)
    }
}
