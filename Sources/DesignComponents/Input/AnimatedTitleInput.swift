//
//  AnimatedTitleInput.swift
//  Tenra
//
//  Created: Phase 16 - AnimatedHeroInput
//
//  Hero-style name input with contentTransition interpolate animation.
//  Amount input merged into AmountInput (AnimatedInputComponents.swift).
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - AnimatedTitleInput

/// Hero-style name/title input with soft scale+fade character animations.
/// Renders animated text display over a hidden TextField.
///
/// Usage:
/// ```swift
/// AnimatedTitleInput(text: $title, placeholder: String(localized: "account.namePlaceholder"))
/// AnimatedTitleInput(text: $title, placeholder: "...", font: AppTypography.h2)
/// ```
public struct AnimatedTitleInput: View {
    @Binding var text: String
    let placeholder: String
    var font: Font = AppTypography.h2
    var color: Color = AppColors.textPrimary
    var alignment: TextAlignment = .center
    /// When `true`, the underlying TextField receives focus on first appear.
    var autoFocus: Bool = false

    public init(text: Binding<String>, placeholder: String, font: Font = AppTypography.h2, color: Color = AppColors.textPrimary, alignment: TextAlignment = .center, autoFocus: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self.font = font
        self.color = color
        self.alignment = alignment
        self.autoFocus = autoFocus
    }

    @FocusState private var isFocused: Bool

    // Placeholder скрывается когда есть текст ИЛИ поле сфокусировано
    private var showPlaceholder: Bool {
        text.isEmpty && !isFocused
    }

    // Курсор виден при фокусе (в том числе при пустом тексте)
    private var showCursor: Bool {
        isFocused
    }

    public var body: some View {
        ZStack {
            // Placeholder — hidden when focused or text is present
            if showPlaceholder {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(alignment)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            // Animated text + cursor
            HStack(spacing: 0) {
                if alignment == .center { Spacer() }
                HStack(spacing: 1) {
                    Text(text.isEmpty ? "" : text)
                        .font(font)
                        .foregroundStyle(color)
                        .contentTransition(.interpolate)
                        .animation(AppAnimation.contentSpring, value: text)

                    BlinkingCursor(height: 44)
                        .opacity(showCursor ? 1 : 0)
                        .animation(AppAnimation.fastAnimation, value: showCursor)
                }
                if alignment == .center { Spacer() }
            }
            .allowsHitTesting(false)

            // Hidden TextField — actual input source
            TextField("", text: $text)
                .font(font)
                .multilineTextAlignment(alignment)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .submitLabel(.done)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            isFocused = true
        }
        .animation(AppAnimation.fastAnimation, value: showPlaceholder)
        .animation(AppAnimation.fastAnimation, value: showCursor)
        .onAppear {
            guard autoFocus else { return }
            // Brief delay so the field exists in the responder chain before we
            // request focus — without this the keyboard sometimes refuses to
            // raise on push-driven appearances.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }
}

// MARK: - Previews


