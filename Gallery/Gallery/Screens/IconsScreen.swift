//
//  IconsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignSupport

struct IconsScreen: View {
    private let columns = [GridItem(.adaptive(minimum: 80), spacing: AppSpacing.lg)]

    var body: some View {
        ShowcasePage(title: "Icons") {
            ShowcaseSection(title: "IconView styles", subtitle: "Unified icon + logo component") {
                LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                    specimen("categoryIcon") {
                        IconView(source: .sfSymbol("fork.knife"),
                                 style: .categoryIcon(size: AppIconSize.xxl,
                                                      backgroundColor: AppColors.accent.opacity(0.15)))
                    }
                    specimen("circle / tint") {
                        IconView(source: .sfSymbol("heart.fill"),
                                 style: .circle(size: AppIconSize.xxl,
                                                tint: .monochrome(AppColors.destructive),
                                                backgroundColor: AppColors.destructive.opacity(0.15)))
                    }
                    specimen("roundedSquare") {
                        IconView(source: .sfSymbol("bolt.fill"),
                                 style: .roundedSquare(size: AppIconSize.xxl,
                                                       tint: .monochrome(AppColors.warning),
                                                       backgroundColor: AppColors.warning.opacity(0.15)))
                    }
                    specimen("glass hero") {
                        IconView(source: .sfSymbol("creditcard.fill"),
                                 style: .glassHero(size: AppIconSize.xxl,
                                                   tint: .monochrome(AppColors.accent)))
                    }
                    specimen("placeholder") {
                        IconView(source: nil, style: .placeholder(size: AppIconSize.xxl))
                    }
                    specimen("brand (fallback)") {
                        IconView(source: .brandService("netflix.com"),
                                 style: .serviceLogo(size: AppIconSize.xxl))
                    }
                }
            }

            ShowcaseSection(title: "Tints") {
                HStack(spacing: AppSpacing.lg) {
                    ForEach(tintSamples, id: \.0) { name, tint in
                        VStack(spacing: AppSpacing.xs) {
                            IconView(source: .sfSymbol("star.fill"),
                                     style: .circle(size: AppIconSize.xl, tint: tint,
                                                    backgroundColor: AppColors.bgMuted))
                            Text(name).font(AppTypography.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var tintSamples: [(String, IconTint)] {
        [("accent", .accentMonochrome), ("primary", .primaryMonochrome),
         ("secondary", .secondaryMonochrome), ("success", .successMonochrome)]
    }

    private func specimen<V: View>(_ name: String, @ViewBuilder _ icon: () -> V) -> some View {
        VStack(spacing: AppSpacing.xs) {
            icon()
            Text(name).font(AppTypography.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview { NavigationStack { IconsScreen() } }
