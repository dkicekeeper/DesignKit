//
//  IconSizesScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct IconSizesScreen: View {
    private let sizes: [(String, CGFloat)] = [
        ("sm", AppIconSize.sm), ("md", AppIconSize.md), ("lg", AppIconSize.lg),
        ("xl", AppIconSize.xl), ("avatar", AppIconSize.avatar), ("xxl", AppIconSize.xxl),
        ("xxxl", AppIconSize.xxxl), ("categoryIcon", AppIconSize.categoryIcon),
        ("mega", AppIconSize.mega), ("ultra", AppIconSize.ultra),
    ]
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: AppSpacing.lg)]

    var body: some View {
        ShowcasePage(title: "Icon Sizes") {
            ShowcaseSection(title: "AppIconSize") {
                LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                    ForEach(sizes, id: \.0) { name, value in
                        VStack(spacing: AppSpacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.accent.opacity(0.15))
                                    .frame(width: value, height: value)
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: value * 0.5))
                                    .foregroundStyle(AppColors.accent)
                            }
                            .frame(height: AppIconSize.ultra)
                            TokenLabel(name: name, value: "\(Int(value))")
                        }
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { IconSizesScreen() } }
