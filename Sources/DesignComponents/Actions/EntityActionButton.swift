//
//  EntityActionButton.swift
//  Tenra
//
//  Custom action-bar button used by `EntityDetailScaffold` (Account / Category /
//  Deposit / Loan / Subscription detail). Replaces the native `.borderedProminent`
//  / `.bordered` pair — those don't match the app's visual language (icon-above-text,
//  card background, accent tint).
//
//  Layout: centered icon on top, label below (max 2 lines). Expands to fill its
//  parent HStack so multiple buttons share horizontal space equally.
//

import SwiftUI
import DesignTokens
import DesignSupport

@available(*, deprecated, message: "Use DSButton(title, systemImage:, iconPlacement: .top, role:): the same tile.")
public struct EntityActionButton: View {
    let title: String
    let systemImage: String?
    let role: ButtonRole?
    let action: () -> Void

    public init(
        title: String,
        systemImage: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    private var tint: Color {
        role == .destructive ? AppColors.destructive : AppColors.accent
    }

    public var body: some View {
        Button(role: role, action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: AppIconSize.lg, weight: .semibold))
                        .frame(width: AppIconSize.lg, height: AppIconSize.lg)
                }
                Text(title)
                    .font(AppTypography.bodySmall)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.sm)
        }
        .buttonStyle(.glassProminent)
        .tint(tint)
//        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: AppRadius.lg))
        .accessibilityLabel(title)
    }
}


// MARK: - Previews
