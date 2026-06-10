//
//  ButtonsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct ButtonsScreen: View {
    var body: some View {
        ShowcasePage(title: "Buttons") {
            ShowcaseSection(title: "Primary", subtitle: "Liquid Glass prominent + accent") {
                VStack(spacing: AppSpacing.md) {
                    Button("Save") {}.primaryButton()
                    Button { } label: { Text("Full width").frame(maxWidth: .infinity) }
                        .primaryButton()
                    Button("Disabled") {}.primaryButton(disabled: true)
                }
            }
            ShowcaseSection(title: "Secondary", subtitle: "Liquid Glass") {
                HStack(spacing: AppSpacing.md) {
                    Button("Cancel") {}.secondaryButton()
                    Button("Back") {}.secondaryButton()
                }
            }
            ShowcaseSection(title: "Bounce style", subtitle: "Press scale + brightness") {
                HStack(spacing: AppSpacing.md) {
                    Button {} label: {
                        Label("Tap me", systemImage: "hand.tap.fill")
                            .font(AppTypography.bodyEmphasis)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.accent.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.bounce)
                }
            }
        }
    }
}

#Preview { NavigationStack { ButtonsScreen() } }
