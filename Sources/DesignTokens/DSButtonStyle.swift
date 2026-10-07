//
//  DSButtonStyle.swift
//  DesignKit
//
//  The look of the design system's button — Liquid Glass (iOS 26+): appearance × role × size.
//  `DSButton` (DesignComponents) is the button itself, with its icon and loading state; the
//  `.dsButton(...)` modifier gives the same look to a SwiftUI `Button` with a label of its own.
//

import SwiftUI

/// What kind of button.
public enum DSButtonAppearance: Hashable, Sendable {
    /// The main action of a screen or sheet: a filled Liquid Glass button (`.glassProminent`).
    case primary
    /// A secondary action next to the main one: clear Liquid Glass (`.glass`).
    case secondary
    /// A text button with no container (`.borderless`): an action inside content.
    case flat
}

/// What the action does, which sets the tint.
public enum DSButtonRole: Hashable, Sendable {
    /// The accent (none on a secondary button).
    case normal
    /// Deletes or discards: `AppColors.Status.negative`.
    case destructive
    /// Neither accent nor alarm: `AppColors.Text.primary`.
    case neutral
}

/// How big the button is (the system `controlSize`).
public enum DSButtonSize: Hashable, Sendable {
    case large, medium, small

    public var controlSize: ControlSize {
        switch self {
        case .large: return .large
        case .medium: return .regular
        case .small: return .small
        }
    }
}

public extension View {
    /// The design system's button look on a SwiftUI `Button` with a label of its own:
    ///
    /// ```swift
    /// Button { save() } label: { Text("Save").frame(maxWidth: .infinity) }
    ///     .dsButton()
    /// Button("Not now") { dismiss() }.dsButton(.flat, role: .neutral, size: .medium)
    /// ```
    ///
    /// A button with a title, an icon or a loading state is `DSButton`. `disabled: true` blocks
    /// taps and the glass dims itself.
    func dsButton(
        _ appearance: DSButtonAppearance = .primary,
        role: DSButtonRole = .normal,
        size: DSButtonSize = .large,
        disabled: Bool = false
    ) -> some View {
        modifier(DSButtonStyleModifier(appearance: appearance, role: role, size: size))
            .disabled(disabled)
    }
}

/// The tint of a button of `appearance` and `role`; `nil` keeps the inherited one.
public func dsButtonTint(_ appearance: DSButtonAppearance, role: DSButtonRole) -> Color? {
    switch role {
    case .normal: return appearance == .secondary ? nil : AppColors.accent
    case .destructive: return AppColors.Status.negative
    case .neutral: return AppColors.Text.primary
    }
}

private struct DSButtonStyleModifier: ViewModifier {
    let appearance: DSButtonAppearance
    let role: DSButtonRole
    let size: DSButtonSize

    @ViewBuilder
    func body(content: Content) -> some View {
        let tint = dsButtonTint(appearance, role: role)
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

// MARK: - Before 2.0

@available(*, deprecated, renamed: "DSButtonAppearance")
public typealias AppButtonAppearance = DSButtonAppearance

@available(*, deprecated, renamed: "DSButtonRole")
public typealias AppButtonRole = DSButtonRole

@available(*, deprecated, renamed: "DSButtonSize")
public typealias AppButtonSize = DSButtonSize

public extension View {
    @available(*, deprecated, renamed: "dsButton(_:role:size:disabled:)")
    func appButton(
        _ appearance: DSButtonAppearance = .primary,
        role: DSButtonRole = .normal,
        size: DSButtonSize = .large,
        disabled: Bool = false
    ) -> some View {
        dsButton(appearance, role: role, size: size, disabled: disabled)
    }

    /// The same as `.dsButton(disabled:)`: `.glassProminent`, the accent, `.large`.
    @available(*, deprecated, message: "Use .dsButton(disabled:), or DSButton for a title with an icon or a loading state.")
    func primaryButton(disabled: Bool = false) -> some View {
        self
            .buttonStyle(.glassProminent)
            .tint(AppColors.accent)
            .controlSize(.large)
            .disabled(disabled)
    }

    /// The same as `.dsButton(.secondary)`: `.glass`, `.large`, no tint.
    @available(*, deprecated, message: "Use .dsButton(.secondary), or DSButton(appearance: .secondary).")
    func secondaryButton() -> some View {
        self
            .buttonStyle(.glass)
            .controlSize(.large)
    }
}
