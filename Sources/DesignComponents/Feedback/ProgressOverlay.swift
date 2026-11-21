//
//  ProgressOverlay.swift
//  DesignKit
//
//  The screen waits for something it cannot do without (2.9.0): the screen dims, and a panel of
//  material in the middle shows a spinner, what is happening and what it means ("Restoring the
//  backup" / "The app will be ready in a moment"). For a restore, a migration, an import that
//  must finish first. Ported from Tenra's RestoreProgressOverlay. Since 8.12.0 a hero (a mascot
//  at work) can take the spinner's place: it shows the progress itself.
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

    /// Dims the view and shows a progress panel with `hero` in the spinner's place while
    /// `isPresented` (8.12.0): a view that shows the progress itself, sized by the host.
    ///
    /// ```swift
    /// SettingsList()
    ///     .progressOverlay(isPresented: isRestoring, title: "Restoring the backup") {
    ///         ParticleCreature(mood: .working(progress: restore.progress))
    ///             .frame(width: 120, height: 120)
    ///     }
    /// ```
    func progressOverlay<Hero: View>(
        isPresented: Bool,
        title: String,
        message: String? = nil,
        @ViewBuilder hero: () -> Hero
    ) -> some View {
        let hero = hero()
        return overlay {
            if isPresented {
                ProgressOverlay(title: title, message: message) { hero }
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
    /// The view in the spinner's place (8.12.0); `nil` shows the spinner.
    let hero: AnyView?

    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
        self.hero = nil
    }

    /// The panel with `hero` in the spinner's place (8.12.0): a view that shows the progress
    /// itself (a mascot at work), sized by the host.
    public init<Hero: View>(title: String, message: String? = nil, @ViewBuilder hero: () -> Hero) {
        self.title = title
        self.message = message
        self.hero = AnyView(hero())
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(ProgressOverlayMetrics.dim)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                if let hero {
                    hero
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppColors.accent)
                }

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
