//
//  CardsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct CardsScreen: View {
    @State private var selectedChip = 0

    var body: some View {
        ShowcasePage(title: "Cards & Surfaces") {
            ShowcaseSection(title: "cardStyle()", subtitle: "Liquid Glass display card (iOS 26)") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Total balance").font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("₸ 1 284 500").font(AppTypography.h2)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .cardContentPadding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }

            ShowcaseSection(title: "formCardStyle()", subtitle: "Container for interactive rows") {
                VStack(spacing: 0) {
                    ForEach(["Currency", "Category", "Account"], id: \.self) { label in
                        HStack {
                            Text(label).font(AppTypography.body)
                            Spacer()
                            Text("Choose").font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption).foregroundStyle(AppColors.textTertiary)
                        }
                        .padding(AppSpacing.lg)
                        if label != "Account" { Divider().padding(.leading, AppSpacing.lg) }
                    }
                }
                .formCardStyle()
            }

            ShowcaseSection(title: "filterChipStyle()", subtitle: "Interactive filter chips") {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(["All", "Income", "Expense"].enumerated()), id: \.offset) { idx, title in
                        Text(title)
                            .filterChipStyle(isSelected: selectedChip == idx)
                            .onTapGesture { selectedChip = idx }
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { CardsScreen() } }
