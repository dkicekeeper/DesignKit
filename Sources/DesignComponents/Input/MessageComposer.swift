//
//  MessageComposer.swift
//  DesignKit
//
//  The field at the bottom of a conversation: Liquid Glass that grows to five lines, the send
//  button inside it, an optional quote of the message being answered above the text, and the
//  send error over the field. (HIG Messages, Material text field with a trailing action.)
//  Made for Dalada's comments and thread replies; who may write and what sending does stay in
//  the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A message field with a send button.
///
/// ```swift
/// List { … }
///     .safeAreaBar(edge: .bottom) {
///         MessageComposer(text: $text, placeholder: "Add a comment…",
///                         isSending: isSending, errorMessage: sendError) {
///             Task { await send() }
///         }
///         .screenPadding()
///         .padding(.bottom, AppSpacing.sm)
///     }
/// ```
///
/// The glass floats over the content: put it in `safeAreaBar` (the scroll edge blurs under
/// it), not on a `.bar` background, and give it the screen's side margins. `.disabled(true)`
/// greys it out, with the placeholder saying why (e.g. "Sign in to comment").
/// VoiceOver labels: keys `composer.send` (default "Send") and `composer.cancelQuote`
/// (default "Remove quote").
public struct MessageComposer: View {
    /// The message being answered, shown above the text.
    public struct Quote: Equatable, Sendable {
        /// Who is answered, in the accent colour ("Replying to Aida").
        public let title: String
        /// The answered text, on one line.
        public let text: String

        public init(title: String, text: String) {
            self.title = title
            self.text = text
        }
    }

    @Binding var text: String
    let placeholder: String
    let quote: Quote?
    let isSending: Bool
    let canSend: Bool?
    let errorMessage: String?
    let onCancelQuote: (() -> Void)?
    let onSend: () -> Void
    private let externalFocus: FocusState<Bool>.Binding?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - quote: Shown above the text; the × calls `onCancelQuote`.
    ///   - isSending: A spinner replaces the arrow and sending is off.
    ///   - canSend: Whether the text may be sent; by default, when it is not blank.
    ///   - errorMessage: Shown over the field (the last send failed).
    ///   - focus: The host's focus binding, to focus the field from outside (e.g. on "Reply").
    public init(
        text: Binding<String>,
        placeholder: String,
        quote: Quote? = nil,
        isSending: Bool = false,
        canSend: Bool? = nil,
        errorMessage: String? = nil,
        focus: FocusState<Bool>.Binding? = nil,
        onCancelQuote: (() -> Void)? = nil,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.quote = quote
        self.isSending = isSending
        self.canSend = canSend
        self.errorMessage = errorMessage
        self.externalFocus = focus
        self.onCancelQuote = onCancelQuote
        self.onSend = onSend
    }

    private var focusBinding: FocusState<Bool>.Binding { externalFocus ?? $isFocused }

    private var isSendEnabled: Bool {
        guard isEnabled, !isSending else { return false }
        return canSend ?? !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let errorMessage {
                errorLabel(errorMessage)
                    .padding(.horizontal, AppSpacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let quote {
                    quoteView(quote)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(1...5)
                        .focused(focusBinding)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(minHeight: MessageComposerMetrics.buttonSize)

                    sendButton
                }
            }
            .padding(.leading, AppSpacing.lg)
            .padding(.trailing, MessageComposerMetrics.inset)
            .padding(.vertical, MessageComposerMetrics.inset)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: MessageComposerMetrics.cornerRadius))
            .opacity(isEnabled ? 1 : 0.6)
        }
        .animation(AppAnimation.contentSpring, value: quote)
        .animation(AppAnimation.contentSpring, value: errorMessage)
        .animation(AppAnimation.fastAnimation, value: isSendEnabled)
    }

    // MARK: - Parts

    private var sendButton: some View {
        Button {
            HapticManager.light()
            onSend()
        } label: {
            ZStack {
                Circle()
                    .fill(isSendEnabled || isSending ? AppColors.accent : AppColors.bgMuted)
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppColors.staticWhite)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: AppIconSize.sm, weight: .bold))
                        .foregroundStyle(isSendEnabled ? AppColors.staticWhite : AppColors.textTertiary)
                }
            }
            .frame(width: MessageComposerMetrics.buttonSize, height: MessageComposerMetrics.buttonSize)
        }
        .buttonStyle(.plain)
        .disabled(!isSendEnabled)
        .accessibilityLabel(String(localized: "composer.send", defaultValue: "Send"))
    }

    private func quoteView(_ quote: Quote) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Capsule()
                .fill(AppColors.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: quote.title)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.accent)
                    .lineLimit(1)
                Text(verbatim: quote.text)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let onCancelQuote {
                Button {
                    HapticManager.light()
                    onCancelQuote()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: AppIconSize.md))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "composer.cancelQuote", defaultValue: "Remove quote"))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, AppSpacing.sm)
        .padding(.trailing, AppSpacing.sm)
    }

    private func errorLabel(_ message: String) -> some View {
        Label {
            Text(verbatim: message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.destructive)
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.destructive)
        }
    }
}

/// The composer's geometry: the send button sits `inset` from the glass edge, so the glass
/// corner is concentric with the button.
enum MessageComposerMetrics {
    static let buttonSize: CGFloat = AppIconSize.xl
    static let inset: CGFloat = AppSpacing.xs
    static let cornerRadius: CGFloat = buttonSize / 2 + inset
}
