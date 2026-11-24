//
//  AppLayoutTests.swift
//  DesignKit
//
//  8.13.0: a screen on a large screen. A phone stays as it was (narrower than the column, one
//  card in a row); an iPad gets a readable column and two or three cards side by side.
//

import SwiftUI
import Testing
import DesignTokens

@Suite("Layout on a large screen")
struct AppLayoutTests {
    /// How many columns an adaptive grid item lays out in `width` (SwiftUI's rule: as many
    /// minimum-wide columns as fit with the spacing between them).
    private func columns(in width: CGFloat) -> Int {
        guard let item = AppLayout.cardColumns().first, case .adaptive(let minimum, _) = item.size else {
            return 0
        }
        let spacing = item.spacing ?? 0
        return max(1, Int((width + spacing) / (minimum + spacing)))
    }

    /// The width a screen gives its content: the screen less `screenPadding()`, no more than the
    /// column it sits in.
    private func content(on screen: CGFloat, column: CGFloat) -> CGFloat {
        min(screen, column) - 2 * AppSpacing.lg
    }

    @Test("A grid of cards is one adaptive column of cardMinWidth, spaced like cards in a column")
    func cardColumns() {
        let items = AppLayout.cardColumns()
        #expect(items.count == 1)
        guard case .adaptive(let minimum, _) = items.first?.size else {
            Issue.record("cardColumns() is not adaptive")
            return
        }
        #expect(minimum == AppLayout.cardMinWidth)
        #expect(items.first?.spacing == AppSpacing.lg)

        let custom = AppLayout.cardColumns(minimum: 200, spacing: AppSpacing.sm)
        guard case .adaptive(let customMinimum, _) = custom.first?.size else {
            Issue.record("cardColumns(minimum:spacing:) is not adaptive")
            return
        }
        #expect(customMinimum == 200)
        #expect(custom.first?.spacing == AppSpacing.sm)
    }

    @Test("A phone keeps its screens: wider than none of its screens, one card in a row")
    func phone() {
        // iPhone SE (320), mini (375), standard (402), Pro Max (440).
        for screen: CGFloat in [320, 375, 402, 440] {
            #expect(screen < AppLayout.readableWidth)
            #expect(columns(in: content(on: screen, column: AppLayout.wideWidth)) == 1)
        }
    }

    @Test("An iPad and a Mac window get the column, and two or three cards side by side")
    func largeScreens() {
        // iPad mini portrait, iPad 11-inch portrait and landscape, iPad 13-inch landscape.
        #expect(744 > AppLayout.readableWidth)
        #expect(columns(in: content(on: 744, column: AppLayout.wideWidth)) == 2)
        #expect(columns(in: content(on: 834, column: AppLayout.wideWidth)) == 2)
        #expect(columns(in: content(on: 1194, column: AppLayout.wideWidth)) == 3)
        // The wide column holds three cards and stops there, however wide the window.
        #expect(columns(in: content(on: 1366, column: AppLayout.wideWidth)) == 3)
        #expect(columns(in: content(on: 2560, column: AppLayout.wideWidth)) == 3)
        // The readable column holds two cards.
        #expect(columns(in: content(on: 1366, column: AppLayout.readableWidth)) == 2)
    }
}
