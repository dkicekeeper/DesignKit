//
//  DataColorsTests.swift
//  DesignKit
//
//  Pins the colours of named things (`AppColors.Data`, `CategoryColors` before vNext): the
//  palette slot must not change between launches (it did while it was based on
//  `String.hashValue`, which is seeded per process), the hash palette is frozen, and the chart
//  series keeps neighbours apart.
//

import SwiftUI
import UIKit
import Testing
import DesignTokens

@Suite("Data colours")
struct DataColorsTests {

    @Test("Palette slot is a fixed FNV-1a hash of the name")
    func paletteIndexIsStable() {
        #expect(AppColors.Data.paletteIndex(for: "Food") == 5)
        #expect(AppColors.Data.paletteIndex(for: "Еда") == 0)
        #expect(AppColors.Data.paletteIndex(for: "Транспорт") == 6)
        #expect(AppColors.Data.paletteIndex(for: "Netflix") == 5)
        #expect(AppColors.Data.paletteIndex(for: "") == 9)
    }

    /// vNext: the new name gives every name the colour it had, or every category re-colours.
    @available(*, deprecated)
    @Test("AppColors.Data gives every name the slot CategoryColors gave it")
    func sameAsCategoryColors() {
        let names = (0..<200).map { "name\($0)" } + ["Food", "Транспорт", "🍕", ""]
        for name in names {
            #expect(AppColors.Data.paletteIndex(for: name) == CategoryColors.paletteIndex(for: name), "\(name)")
        }
        #expect(AppColors.Data.pickerPalette == CategoryColors.pickerPalette)
    }

    @Test("The hash palette keeps its 14 colours: growing it would re-colour every hashed category")
    func hashPaletteFrozen() {
        #expect(AppColors.Data.palette.count == 14)
    }

    @Test("The picker offers the 14 palette colours first, in order, then 16 more")
    func pickerPaletteStartsWithTheHashPalette() {
        let picker = AppColors.Data.pickerPalette
        #expect(picker.count == 30)
        #expect(Array(picker.prefix(14)) == [
            "#3b82f6", "#8b5cf6", "#ec4899", "#f97316", "#eab308",
            "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef",
            "#f43f5e", "#a855f7", "#10b981", "#f59e0b"
        ])
        #expect(Array(picker.suffix(16)) == [
            "#0ea5e9", "#0e7490", "#0f766e", "#15803d", "#65a30d", "#4d7c0f",
            "#a16207", "#9a3412", "#b91c1c", "#be185d", "#a21caf", "#6d28d9",
            "#a78bfa", "#1d4ed8", "#64748b", "#78716c"
        ])
    }

    @Test("Picker colours are unique lowercase #rrggbb strings, as apps store them")
    func pickerPaletteFormat() {
        let picker = AppColors.Data.pickerPalette
        #expect(Set(picker).count == picker.count)
        let hexDigits = Set("0123456789abcdef")
        for hex in picker {
            #expect(hex.count == 7 && hex.hasPrefix("#"), "\(hex)")
            #expect(hex.dropFirst().allSatisfy { hexDigits.contains($0) }, "\(hex)")
        }
    }

    /// The map palette (3.7.0) reads the same table and keeps its values.
    @Test("AppColors.Palette keeps its 13 deep values")
    func deepPaletteUnchanged() {
        #expect(AppColors.Palette.allCases.map(\.rgb) == [
            0x2563EB, 0x4F46E5, 0x7C3AED, 0x9333EA, 0xDB2777, 0xDC2626, 0xEA580C,
            0xA16207, 0x15803D, 0x047857, 0x0F766E, 0x0E7490, 0x64748B,
        ])
    }

    /// vNext: eight colours for a chart's series, each far from the one before it on the wheel.
    @Test("Chart series: eight distinct colours, neighbours at least 45° apart")
    func seriesNeighboursDiffer() {
        let hues = AppColors.Data.series.map { color -> Double in
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            return Double(hue) * 360
        }
        #expect(hues.count == 8)
        #expect(Set(hues.map { Int($0.rounded()) }).count == 8)
        for (a, b) in zip(hues, hues.dropFirst()) {
            let apart = min(abs(a - b), 360 - abs(a - b))
            #expect(apart >= 45, "\(a)° → \(b)°")
        }
    }
}
