//
//  CurrencyList.swift
//  DesignKit
//
//  Every currency to pick from: "Popular" on top, then all of them, each a row with the
//  code, the name and the symbol, the chosen one checked, and a search over codes and names.
//  A ScrollView of cards rather than a List, so the screen's own background shows through.
//  Ported from Tenra's CurrencyListContent; the screen around it (title, what a pick does)
//  stays with the caller.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Picks a currency from `CurrencyInfo`'s list. Put it in a navigation container: the search
/// field sits in the navigation bar's drawer.
///
/// ```swift
/// CurrencyList(selection: currency) { code in
///     currency = code
///     dismiss()
/// }
/// .navigationTitle("Currency")
/// ```
public struct CurrencyList: View {
    let selection: String
    let onSelect: (String) -> Void

    @State private var searchText = ""

    /// - Parameters:
    ///   - selection: The ISO code to check.
    ///   - onSelect: A row was tapped (after the selection haptic).
    public init(selection: String, onSelect: @escaping (String) -> Void) {
        self.selection = selection
        self.onSelect = onSelect
    }

    private var filteredCurrencies: [CurrencyInfo] {
        guard !searchText.isEmpty else { return CurrencyInfo.allCurrencies }
        let query = searchText.lowercased()
        return CurrencyInfo.allCurrencies.filter {
            $0.code.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if searchText.isEmpty {
                    section(
                        title: String(localized: "currency.popular", defaultValue: "Popular"),
                        items: CurrencyInfo.popularCurrencies
                    )
                }

                // Empty only while searching: an empty query lists every currency.
                if filteredCurrencies.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: String(localized: "currency.noResults.title", defaultValue: "No currencies found"),
                        description: String(localized: "currency.noResults.description", defaultValue: "Try a different name or code.")
                    )
                    .padding(.top, AppSpacing.xxxl)
                } else {
                    section(
                        title: String(localized: "currency.all", defaultValue: "All Currencies"),
                        items: filteredCurrencies
                    )
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.md)
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: String(localized: "currency.searchPrompt", defaultValue: "Search currency")
        )
    }

    private func section(title: String, items: [CurrencyInfo]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
                .padding(.horizontal, AppSpacing.sm)

            // Lazy: about 150 currencies, built as they scroll in.
            LazyVStack(spacing: 0) {
                ForEach(items) { currency in
                    row(currency)
                    if currency.id != items.last?.id {
                        Divider()
                            .padding(.leading, AppSpacing.lg)
                    }
                }
            }
            .background(
                AppColors.Background.neutral1,
                in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
            )
        }
    }

    private func row(_ currency: CurrencyInfo) -> some View {
        Button {
            HapticManager.selection()
            onSelect(currency.code)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(verbatim: currency.code)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.Text.primary)
                    Text(verbatim: currency.name)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                Spacer()
                Text(verbatim: currency.symbol)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.secondary)
                if currency.code == selection {
                    Image(systemName: "checkmark")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(currency.code == selection ? .isSelected : [])
    }
}
