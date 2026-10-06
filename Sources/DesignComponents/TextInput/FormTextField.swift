//
//  FormTextField.swift
//  Tenra
//
//  Enhanced text field with error states, help text, and validation
//  Replaces DescriptionTextField with more features
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Enhanced text field for forms with error/help states and multiple styles.
/// Supports single-line, multi-line, and `inline` variants.
///
/// **States supported (standard/multiline only):**
/// - Normal (idle), Focused (accent border + tinted bg), Filled (has text),
///   Error (red border + message), Disabled (dimmed, non-interactive),
///   Help (info text below)
///
/// **Choosing a style:**
/// - `.standard` / `.multiline` — full-width form field used standalone with a
///   separate label above. Padded chrome (`AppSpacing.lg`, `AppRadius.lg`),
///   tinted background, accent border on focus.
/// - `.inline` / `.inlineMultiline` — bare right-aligned text field for the
///   trailing slot of `UniversalRow`. **No chrome** — no background, no border,
///   no padding, no width-stretching — just font + alignment + keyboard so the
///   row's height stays compact and stable while typing. `errorMessage`/
///   `helpText` are intentionally hidden in inline mode; surface validation at
///   form level (`InlineStatusText`).
public struct FormTextField: View {
    @Binding var text: String
    let placeholder: String
    let style: Style
    let keyboardType: UIKeyboardType
    let errorMessage: String?
    let helpText: String?
    let isDisabled: Bool
    /// When true, the field auto-focuses shortly after appearing. Replaces the
    /// ad-hoc `@FocusState … .task { isFocused = true }` pattern at call sites.
    let autofocus: Bool
    /// Optional external focus binding for coordinating with a sibling input (e.g. the
    /// calculator keypad): when provided, the host owns focus and can show/dismiss the
    /// system keyboard. Defaults to the internal state — existing call sites are unchanged.
    private let externalFocus: FocusState<Bool>.Binding?
    @FocusState private var isFocused: Bool

    /// The binding the TextField actually uses — external if the host provided one.
    private var focusBinding: FocusState<Bool>.Binding { externalFocus ?? $isFocused }
    /// Current focus value for styling (reads the external binding when present).
    private var isFieldFocused: Bool { externalFocus?.wrappedValue ?? isFocused }

    public enum Style {
        /// Standard single-line text field with filled background.
        case standard

        /// Multi-line text field with line limits and filled background.
        case multiline(min: Int, max: Int)

        /// Bare right-aligned single-line field for `UniversalRow` trailing.
        /// No background, no border, no padding — keeps the row's height
        /// stable.
        case inline

        /// Bare right-aligned multi-line field for `UniversalRow` trailing
        /// (notes, descriptions). `lineLimit(min...max)` bounds the vertical
        /// growth so the row doesn't snap to many lines on first focus.
        case inlineMultiline(min: Int, max: Int)
    }

    public init(
        text: Binding<String>,
        placeholder: String,
        style: Style = .standard,
        keyboardType: UIKeyboardType = .default,
        errorMessage: String? = nil,
        helpText: String? = nil,
        isDisabled: Bool = false,
        autofocus: Bool = false,
        externalFocus: FocusState<Bool>.Binding? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.keyboardType = keyboardType
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.isDisabled = isDisabled
        self.autofocus = autofocus
        self.externalFocus = externalFocus
    }

    /// True when the active style is one of the compact `.inline*` variants —
    /// gates the chrome (capsule vs rounded rect, padding, alignment) and
    /// suppresses the error/help labels (caller surfaces those at form level).
    private var isInline: Bool {
        switch style {
        case .inline, .inlineMultiline: return true
        case .standard, .multiline: return false
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            fieldArea
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.45 : 1)

            // Inline styles intentionally suppress these — there's no room for
            // an inline help/error label inside a UniversalRow trailing slot.
            // Surface validation at the form level (banner / `InlineStatusText`).
            if !isInline {
                if let error = errorMessage {
                    errorLabel(error)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let help = helpText, errorMessage == nil {
                    Text(help)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .transition(.opacity)
                }
            }
        }
        .animation(AppAnimation.fastAnimation, value: isFieldFocused)
        .animation(AppAnimation.fastAnimation, value: errorMessage != nil)
        .task {
            guard autofocus else { return }
            // One yield so the field is mounted before the keyboard tries to
            // come up — without this the focus is silently dropped on first
            // present (observed in deposit/loan rate-change sheets).
            await Task.yield()
            focusBinding.wrappedValue = true
        }
    }

    // MARK: - Field Area

    @ViewBuilder
    private var fieldArea: some View {
        switch style {
        case .standard:
            standardField
                .padding(AppSpacing.lg)
                .background(backgroundForState)
                .clipShape(.rect(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(borderForState, lineWidth: borderWidth)
                )

        case .multiline(let min, let max):
            multilineField(min: min, max: max)
                .padding(AppSpacing.lg)
                .background(backgroundForState)
                .clipShape(.rect(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(borderForState, lineWidth: borderWidth)
                )

        case .inline:
            inlineField

        case .inlineMultiline(let min, let max):
            inlineMultilineField(min: min, max: max)
        }
    }

    // MARK: - Field Variants

    private var standardField: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .focused(focusBinding)
            .font(AppTypography.body)
    }

    private func multilineField(min: Int, max: Int) -> some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(min...max)
            .focused(focusBinding)
            .font(AppTypography.body)
    }

    /// Bare right-aligned single-line variant for `UniversalRow` trailings.
    /// Native chrome only — no background/border/padding — so the row keeps
    /// its standard height regardless of focus state.
    private var inlineField: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .focused(focusBinding)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.trailing)
    }

    /// Bare right-aligned multi-line variant. `lineLimit(min...max)` bounds the
    /// vertical growth — without it the row would jump to N lines on focus.
    private func inlineMultilineField(min: Int, max: Int) -> some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(min...max)
            .focused(focusBinding)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.trailing)
    }

    // MARK: - Styling Helpers

    private var backgroundForState: Color {
        if isDisabled {
            return AppColors.bgCard.opacity(0.3)
        } else if errorMessage != nil {
            return AppColors.destructive.opacity(0.05)
        } else if isFieldFocused {
            return AppColors.accent.opacity(0.04)
        } else {
            return AppColors.bgCard.opacity(0.5)
        }
    }

    private var borderForState: Color {
        if errorMessage != nil {
            return AppColors.destructive.opacity(0.45)
        } else if isFieldFocused {
            return AppColors.accent.opacity(0.55)
        } else {
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        errorMessage != nil || isFieldFocused ? 1 : 0
    }

    // MARK: - Sub-views

    private func errorLabel(_ message: String) -> some View {
        Label {
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.destructive)
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.destructive)
        }
    }
}

// MARK: - Previews






