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
}
