//
//  CardListSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  CardList (8.0.0) in its two layouts and three modes: the items as they are, with a circle
//  each while selecting, with a handle each while reordering. A `.cards` list is one card per
//  snapshot (docs/snapshots.md: one Liquid Glass card per snapshot).
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

private struct CardListSample: Identifiable {
    let id: Int
    let name: String
    let symbol: String
    let amount: String

    static let accounts = [
        CardListSample(id: 0, name: "Main card", symbol: "creditcard.fill", amount: "245 300 ₸"),
        CardListSample(id: 1, name: "Cash", symbol: "banknote.fill", amount: "38 000 ₸"),
        CardListSample(id: 2, name: "Savings", symbol: "lock.fill", amount: "1 500 000 ₸"),
    ]
}

extension ComponentSnapshots {
    @MainActor
    @Suite("CardList")
    struct CardLists {
        /// Every item a row in one glass card, the divider under each row's text.
        @Test func section() async {
            await assertComponentSnapshot(sectionList(.browsing), appearances: [.light, .dark, .largeText])
        }

        /// Selecting: a circle before each row, the divider moved past it; one row picked.
        @Test func sectionSelecting() async {
            await assertComponentSnapshot(sectionList(.selecting), appearances: [.light, .dark])
        }

        /// Reordering: a handle after each row.
        @Test func sectionReordering() async {
            await assertComponentSnapshot(sectionList(.reordering), appearances: [.light, .dark])
        }

        /// A card per item, one per snapshot, in each mode.
        @Test func cards() async {
            for (name, mode) in [("browsing", CardListMode.browsing), ("selecting", .selecting), ("reordering", .reordering)] {
                await assertComponentSnapshot(
                    CardList([CardListSample.accounts[2]], mode: mode, selection: .constant([2]), onMove: { _, _ in }) { item in
                        loanCard(item)
                    },
                    named: name,
                    appearances: [.light, .dark]
                )
            }
        }

        /// Items that are cards already (`.stack`): the circle and the handle beside the card.
        @Test func stack() async {
            for (name, mode) in [("selecting", CardListMode.selecting), ("reordering", .reordering)] {
                await assertComponentSnapshot(
                    CardList([CardListSample.accounts[0]], layout: .stack, mode: mode, selection: .constant([0]),
                             onMove: { _, _ in }) { item in
                        loanCard(item)
                            .padding(AppSpacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    },
                    named: name,
                    appearances: [.light, .dark]
                )
            }
        }

        private func sectionList(_ mode: CardListMode) -> some View {
            CardList(CardListSample.accounts, layout: .section, mode: mode, selection: .constant([1]),
                     onMove: { _, _ in }) { item in
                UniversalRow(
                    item.name,
                    leadingIcon: .sfSymbol(item.symbol, color: AppColors.accent, size: AppIconSize.Tile.sm),
                    value: item.amount
                )
            }
        }

        private func loanCard(_ item: CardListSample) -> some View {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(verbatim: item.name)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                Text(verbatim: item.amount)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }
}
