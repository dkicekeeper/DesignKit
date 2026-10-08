//
//  ProgressOverlay.swift
//  DesignKit
//
//  The screen waits for something it cannot do without (2.9.0): the screen dims, and a panel of
//  material in the middle shows a spinner, what is happening and what it means ("Restoring the
//  backup" / "The app will be ready in a moment"). For a restore, a migration, an import that
//  must finish first. Ported from Tenra's RestoreProgressOverlay.
//

import SwiftUI
import DesignTokens

public extension View {
    /// Dims the view and shows a progress panel while `isPresented`.
    ///
    /// ```swift
    /// SettingsList()
    ///     .disabled(isRestoring)
    ///     .progressOverlay(isPresented: isRestoring, title: "Restoring the backup",
    ///                      message: "Your data will be back in a moment.")
    /// ```
    func progressOverlay(isPresented: Bool, title: String, message: String? = nil) -> some View {
        overlay {
            if isPresented {
                ProgressOverlay(title: title, message: message)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
    }
}

/// The dimmed screen and the progress panel of `.progressOverlay`.
public struct ProgressOverlay: View {
    let title: String
    let message: String?

    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(ProgressOverlayMetrics.dim)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppColors.accent)

                Text(verbatim: title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)

                if let message {
                    Text(verbatim: message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(AppSpacing.xl)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .padding(AppSpacing.xl)
        }
        .accessibilityElement(children: .combine)
    }
}

enum ProgressOverlayMetrics {
    static let dim: Double = 0.45
}
