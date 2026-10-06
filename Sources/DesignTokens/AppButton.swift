//
//  AppButton.swift
//  Tenra
//
//  Consistent button styles — Liquid Glass (iOS 26+).
//

import SwiftUI

// MARK: - Convenience Extensions

public extension View {
    /// The main action: shorthand of `appButton(.primary, disabled:)` — `.glassProminent`,
    /// the accent, `.large`. Save, Add, Confirm.
    ///
    /// Sizing follows the button's label; for a full-width call to action put
    /// `.frame(maxWidth: .infinity)` on the label. `disabled: true` blocks taps and the glass
    /// dims itself. For another role or size use `appButton(_:role:size:disabled:)`.
    func primaryButton(disabled: Bool = false) -> some View {
        self
            .buttonStyle(.glassProminent)
            .tint(AppColors.accent)
            .controlSize(.large)
            .disabled(disabled)
    }

    /// A secondary action: shorthand of `appButton(.secondary)` — `.glass`, `.large`, no tint.
    /// Cancel, Back.
    func secondaryButton() -> some View {
        self
            .buttonStyle(.glass)
            .controlSize(.large)
    }
}

// MARK: - Button matrix (1.7.0)

/// What kind of button.
public enum AppButtonAppearance: Hashable, Sendable {
    /// The main action of a screen or sheet: a filled Liquid Glass button (`.glassProminent`).
    /// With the default role it looks like `primaryButton()`.
    case primary
    /// A secondary action: a clear Liquid Glass button (`.glass`). With the default role it
    /// looks like `secondaryButton()`.
    case secondary
    /// A text button with no container: "Not now", "Show all", an inline action.
    case flat
}

/// What the button does, which picks its colour.
public enum AppButtonRole: Hashable, Sendable {
    /// The app's accent.
    case normal
    /// Deletes or discards something: `AppColors.Status.negative`.
    case destructive
    /// Neutral (`AppColors.Text.primary`): for an action next to one that already has the accent,
    /// or on a screen that should stay calm.
    case neutral
}

/// The button's size: `.large` (full-width calls to action), `.medium`, `.small` (in rows, chips).
public enum AppButtonSize: Hashable, Sendable {
    case large, medium, small

    var controlSize: ControlSize {
        switch self {
        case .large: return .large
        case .medium: return .regular
        case .small: return .small
        }
    }
}

public extension View {
    /// A button of the design system: appearance × role × size, disabled or not.
    ///
    /// ```swift
    /// Button("Pay") { pay() }.appButton()                                  // = primaryButton()
    /// Button("Delete", role: .destructive) { delete() }.appButton(.secondary, role: .destructive)
    /// Button("Not now") { dismiss() }.appButton(.flat, role: .neutral, size: .medium)
    /// ```
    ///
    /// While an action runs, put a `LoadingButtonLabel(_:isLoading:)` in the label and pass
    /// `disabled: isLoading`, so the button keeps its width and cannot be tapped twice.
    func appButton(
        _ appearance: AppButtonAppearance = .primary,
        role: AppButtonRole = .normal,
        size: AppButtonSize = .large,
        disabled: Bool = false
    ) -> some View {
        modifier(AppButtonModifier(appearance: appearance, role: role, size: size))
            .disabled(disabled)
    }
}

private struct AppButtonModifier: ViewModifier {
    let appearance: AppButtonAppearance
    let role: AppButtonRole
    let size: AppButtonSize

    /// The tint. A secondary button with the default role has none, like `secondaryButton()`.
    private var tint: Color? {
        switch role {
        case .normal: return appearance == .secondary ? nil : AppColors.accent
        case .destructive: return AppColors.Status.negative
        case .neutral: return AppColors.Text.primary
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch appearance {
        case .primary:
            content
                .buttonStyle(.glassProminent)
                .tint(tint)
                .controlSize(size.controlSize)
        case .secondary:
            content
                .buttonStyle(.glass)
                .tint(tint)
                .controlSize(size.controlSize)
        case .flat:
            content
                .buttonStyle(.borderless)
                .tint(tint)
                .controlSize(size.controlSize)
        }
    }
}
