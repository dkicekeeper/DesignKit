//
//  ButtonsScreen.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens
import DesignComponents

struct ButtonsScreen: View {
    private static let roles: [(AppButtonRole, String)] = [
        (.normal, "normal"), (.destructive, "destructive"), (.neutral, "neutral"),
    ]

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
            ShowcaseSection(title: "appButton", subtitle: "Appearance × role · primary / secondary / flat") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(Self.roles, id: \.1) { role, name in
                        Text(name).font(AppTypography.caption).foregroundStyle(AppColors.Text.secondary)
                        HStack(spacing: AppSpacing.sm) {
                            Button("Primary") {}.appButton(.primary, role: role, size: .medium)
                            Button("Secondary") {}.appButton(.secondary, role: role, size: .medium)
                            Button("Flat") {}.appButton(.flat, role: role, size: .medium)
                        }
                    }
                }
            }
            ShowcaseSection(title: "appButton sizes and states", subtitle: "large · medium · small · disabled · loading") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Button { } label: { Text("Large").frame(maxWidth: .infinity) }.appButton(size: .large)
                    HStack(spacing: AppSpacing.sm) {
                        Button("Medium") {}.appButton(size: .medium)
                        Button("Small") {}.appButton(size: .small)
                        Button("Disabled") {}.appButton(size: .medium, disabled: true)
                    }
                    Button { } label: {
                        LoadingButtonLabel("Pay", isLoading: true).frame(maxWidth: .infinity)
                    }
                    .appButton(disabled: true)
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
