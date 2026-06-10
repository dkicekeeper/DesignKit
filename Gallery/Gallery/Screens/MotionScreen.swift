//
//  MotionScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct MotionScreen: View {
    @State private var animateID = 0

    var body: some View {
        ShowcasePage(title: "Motion") {
            ShowcaseSection(title: "Staggered entrance", subtitle: "facepileSpring + stagger") {
                HStack(spacing: -AppSpacing.sm) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(CategoryColors.hexColor(for: "icon\(i)"))
                            .frame(width: AppIconSize.avatar, height: AppIconSize.avatar)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(.white))
                            .overlay(Circle().strokeBorder(AppColors.bgBase, lineWidth: 2))
                            .staggeredEntrance(delay: Double(i) * AppAnimation.facepileStagger)
                            .id("\(animateID)-\(i)")
                    }
                }

                Button("Replay") { animateID += 1 }
                    .buttonStyle(.bounce)
                    .font(AppTypography.caption.weight(.semibold))
            }

            ShowcaseSection(title: "Chart appear", subtitle: "scale + fade from bottom") {
                HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                    ForEach(0..<7, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.accent.opacity(0.7))
                            .frame(width: 24, height: CGFloat(20 + i * 14))
                            .chartAppear(delay: Double(i) * 0.05)
                            .id("\(animateID)-bar-\(i)")
                    }
                }
                .frame(height: 130, alignment: .bottom)
            }

            ShowcaseSection(title: "Springs", subtitle: "Named animation tokens") {
                Text("contentSpring · gentleSpring · heroSpring · progressBarSpring")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview { NavigationStack { MotionScreen() } }
