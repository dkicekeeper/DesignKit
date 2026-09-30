//
//  MotionScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignComponents

struct MotionScreen: View {
    @State private var animateID = 0
    @State private var phase = 0

    private let phases: [(symbol: String, title: String)] = [
        ("sparkles", "Blur-slide reveal"),
        ("chart.pie.fill", "One transition preset"),
        ("hand.wave.fill", "For hero text")
    ]

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
                Text("contentSpring · gentleSpring · heroEntranceAnimation · progressBarSpring")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            ShowcaseSection(title: "LoopOnboardingHero + .blurSlideHero", subtitle: "Onboarding hero · canonical text reveal") {
                VStack(spacing: AppSpacing.lg) {
                    LoopOnboardingHero(symbol: phases[phase].symbol)
                    Text(phases[phase].title)
                        .font(AppTypography.h3)
                        .id(phase)
                        .transition(.blurSlideHero)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .animation(AppAnimation.gentleSpring, value: phase)

                Button("Next phase") { phase = (phase + 1) % phases.count }
                    .buttonStyle(.bounce)
                    .font(AppTypography.caption.weight(.semibold))
            }

            ShowcaseSection(title: "AccentGlow", subtitle: ".onboardingAccentGlow() · .accentGlow(_:edge:)") {
                HStack(spacing: AppSpacing.md) {
                    Color.clear
                        .frame(height: 160)
                        .onboardingAccentGlow()
                        .clipShape(.rect(cornerRadius: AppRadius.lg))
                    Color.clear
                        .frame(height: 160)
                        .accentGlow(AppColors.success, edge: .top)
                        .clipShape(.rect(cornerRadius: AppRadius.lg))
                }
            }
        }
    }
}

#Preview { NavigationStack { MotionScreen() } }
