//
//  FinanceCard.swift
//  Tenra
//
//  Shared shell for the home-screen finance-product entry cards (accounts,
//  deposits, loans, subscriptions, categories, subcategories). Each concrete
//  card supplies its own title, empty-state copy, hero value, subtitle and
//  trailing icon facepile; the shell owns the identical layout, empty-state
//  swap, padding and glass styling.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Home-screen finance section card: title + (hero value + subtitle) on the
/// left, an icon facepile on the right, with a compact empty state swapped in
/// when there's no data. Container owns layout/padding/`.cardStyle()`.
public struct FinanceCard<Hero: View, Trailing: View>: View {
    let title: String
    let isEmpty: Bool
    let emptyTitle: String
    /// Localized count / context line shown under the hero value.
    let subtitle: String
    @ViewBuilder let hero: () -> Hero
    @ViewBuilder let trailing: () -> Trailing

    public init(
        title: String,
        isEmpty: Bool,
        emptyTitle: String,
        subtitle: String,
        @ViewBuilder hero: @escaping () -> Hero,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.isEmpty = isEmpty
        self.emptyTitle = emptyTitle
        self.subtitle = subtitle
        self.hero = hero
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(title)
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.textPrimary)

                if isEmpty {
                    EmptyStateView(title: emptyTitle, style: .compact)
                        .transition(.opacity)
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        hero()
                        Text(subtitle)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isEmpty {
                trailing()
            }
        }
        .animation(AppAnimation.gentleSpring, value: isEmpty)
        .padding(AppSpacing.lg)
        .cardStyle()
    }
}

/// Hero amount that shows a redacted placeholder while an async total is being
/// computed, then cross-fades to the formatted value. Used by the finance cards
/// whose total requires FX conversion (accounts, deposits, subscriptions).
public struct RedactableAmount: View {
    let amount: Double
    let currency: String
    let isLoading: Bool
    var fontSize: Font = AppTypography.h2

    public init(amount: Double, currency: String, isLoading: Bool, fontSize: Font = AppTypography.h2) {
        self.amount = amount
        self.currency = currency
        self.isLoading = isLoading
        self.fontSize = fontSize
    }

    public var body: some View {
        ZStack {
            if isLoading {
                Text("0000.00")
                    .font(fontSize)
                    .fontWeight(.bold)
                    .redacted(reason: .placeholder)
                    .transition(.opacity)
            } else {
                FormattedAmountText(
                    amount: amount,
                    currency: currency,
                    fontSize: fontSize,
                    fontWeight: .bold,
                    color: AppColors.textPrimary
                )
                .transition(.opacity)
            }
        }
        .animation(AppAnimation.gentleSpring, value: isLoading)
    }
}





