//
//  CategoryColorsTests.swift
//  DesignKit
//
//  Pins the fallback category colour: the palette slot must not change between launches
//  (it did while it was based on `String.hashValue`, which is seeded per process).
//

import Testing
import DesignTokens

@Suite("CategoryColors")
struct CategoryColorsTests {

    @Test("Palette slot is a fixed FNV-1a hash of the name")
    func paletteIndexIsStable() {
        #expect(CategoryColors.paletteIndex(for: "Food") == 5)
        #expect(CategoryColors.paletteIndex(for: "Еда") == 0)
        #expect(CategoryColors.paletteIndex(for: "Транспорт") == 6)
        #expect(CategoryColors.paletteIndex(for: "Netflix") == 5)
        #expect(CategoryColors.paletteIndex(for: "") == 9)
    }

    @Test("The hash palette keeps its 14 colours: growing it would re-colour every hashed category")
    func hashPaletteSizeIsFrozen() {
        #expect(CategoryColors.paletteColors.count == 14)
    }

    @Test("The picker offers the 14 palette colours first, in order, then 16 more")
    func pickerPaletteStartsWithTheHashPalette() {
        let picker = CategoryColors.pickerPalette
        #expect(picker.count == 30)
        #expect(Array(picker.prefix(14)) == [
            "#3b82f6", "#8b5cf6", "#ec4899", "#f97316", "#eab308",
            "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef",
            "#f43f5e", "#a855f7", "#10b981", "#f59e0b"
        ])
    }

    @Test("Picker colours are unique lowercase #rrggbb strings, as apps store them")
    func pickerPaletteFormat() {
        let picker = CategoryColors.pickerPalette
        #expect(Set(picker).count == picker.count)
        let hexDigits = Set("0123456789abcdef")
        for hex in picker {
            #expect(hex.count == 7 && hex.hasPrefix("#"), "\(hex)")
            #expect(hex.dropFirst().allSatisfy { hexDigits.contains($0) }, "\(hex)")
        }
    }
}
