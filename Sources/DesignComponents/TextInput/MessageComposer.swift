//
//  MessageComposer.swift
//  DesignKit
//
//  The field at the bottom of a conversation: Liquid Glass that grows to five lines, the send
//  button inside it, an optional quote of the message being answered above the text, and the
//  send error over the field. (HIG Messages, Material text field with a trailing action.)
//  Made for Dalada's comments and thread replies; who may write and what sending does stay in
//  the app. 4.8.0, for Tenra's assistant: a leading slot inside the glass (an attach menu,
//  `MessageComposerAccessory` as its label) and `onVoice:`, a microphone in the send button's
//  place while the text is blank. 4.9.0: while it is focused the glass fills almost opaque, so
//  what is typed reads over any content scrolling under it.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A quoted message: who wrote it and what. `MessageComposer` shows the one being answered,
/// `CommentRow` the one a reply quotes.
public struct MessageQuote: Equatable, Sendable {
    /// Who is quoted ("Aida", or "Replying to Aida" in the composer).
    public let title: String
    /// The quoted text.
    public let text: String

    public init(title: String, text: String) {
        self.title = title
        self.text = text
    }
}

/// A message field with a send button.
///
/// ```swift
/// List { … }
///     .scrollEdgeEffectStyle(.soft, for: .bottom)
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
/// it), not on a `.bar` background, and give it the screen's side margins. Name the soft edge,
/// `.scrollEdgeEffectStyle(.soft, for: .bottom)` (5.1.0): built with Xcode 27 the style as it
/// comes is hard, a plate with a line under the glass. Focused, it fills
/// with the raised surface colour almost to opaque (4.9.0), so the text never mixes with the
/// content behind it; unfocused it is clear glass again. `.disabled(true)`
/// greys it out, with the placeholder saying why (e.g. "Sign in to comment").
/// VoiceOver labels: keys `composer.send` (default "Send") and `composer.cancelQuote`
/// (default "Remove quote"). With `limit:` (4.1.0) the count shows over the field from 80% of
/// it ("980/1000"), and over the limit it turns red and sending is off.
public struct MessageComposer<Leading: View>: View {
    @Binding var text: String
    let placeholder: String
    let quote: MessageQuote?
    let isSending: Bool
    let canSend: Bool?
    let errorMessage: String?
    let limit: Int?
    let leading: Leading
    let onVoice: (() -> Void)?
    let onCancelQuote: (() -> Void)?
    let onSend: () -> Void
    private let externalFocus: FocusState<Bool>.Binding?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - quote: Shown above the text ("Replying to Aida", their text); the × calls
    ///     `onCancelQuote`.
    ///   - isSending: A spinner replaces the arrow and sending is off.
    ///   - canSend: Whether the text may be sent; by default, when it is not blank.
    ///   - errorMessage: Shown over the field (the last send failed).
    ///   - limit: The most characters a message may have (4.1.0): the count shows from 80% of
    ///     it, over it the count turns red and sending is off.
    ///   - focus: The host's focus binding, to focus the field from outside (e.g. on "Reply").
    ///   - leading: Inside the glass before the text (4.8.0): an attach button or menu, with
    ///     `MessageComposerAccessory` as its label.
    ///   - onVoice: A microphone takes the send button's place while the text is blank
    ///     (4.8.0); a tap calls it.
    public init(
        text: Binding<String>,
        placeholder: String,
        quote: MessageQuote? = nil,
        isSending: Bool = false,
        canSend: Bool? = nil,
        errorMessage: String? = nil,
        limit: Int? = nil,
        focus: FocusState<Bool>.Binding? = nil,
        @ViewBuilder leading: () -> Leading,
        onVoice: (() -> Void)? = nil,
        onCancelQuote: (() -> Void)? = nil,
        onSend: @escaping () -> Void
    ) {
        self.leading = leading()
        self.onVoice = onVoice
        self._text = text
        self.placeholder = placeholder
        self.quote = quote
        self.isSending = isSending
        self.canSend = canSend
        self.errorMessage = errorMessage
        self.limit = limit
        self.externalFocus = focus
        self.onCancelQuote = onCancelQuote
        self.onSend = onSend
    }

    private var focusBinding: FocusState<Bool>.Binding { externalFocus ?? $isFocused }

    private var isOverLimit: Bool {
        guard let limit else { return false }
        return CharacterCount.isOver(count: text.count, limit: limit)
    }

    private var showsCount: Bool {
        guard let limit else { return false }
        return CharacterCount.isVisible(count: text.count, limit: limit)
    }

    private var hasLeading: Bool { Leading.self != EmptyView.self }

    /// The microphone stands where the send button goes while there is nothing to send.
    private var showsVoice: Bool {
        onVoice != nil && !isSending && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isSendEnabled: Bool {
        guard isEnabled, !isSending, !isOverLimit else { return false }
        return canSend ?? !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if errorMessage != nil || showsCount {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    if let errorMessage {
                        errorLabel(errorMessage)
                    }
                    Spacer(minLength: 0)
                    if showsCount, let limit {
                        CharacterCount(count: text.count, limit: limit)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let quote {
                    quoteView(quote)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                    if hasLeading {
                        leading
                    }

                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(1...5)
                        .focused(focusBinding)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)
                        .frame(minHeight: MessageComposerMetrics.buttonSize)

                    trailingButton
                }
            }
            .padding(.leading, hasLeading ? MessageComposerMetrics.inset : AppSpacing.lg)
            .padding(.trailing, MessageComposerMetrics.inset)
            .padding(.vertical, MessageComposerMetrics.inset)
            // Typing over a busy thread: the surface fills in behind the text (4.9.0).
            .background(
                AppColors.Background.elevation1.opacity(focusBinding.wrappedValue ? MessageComposerMetrics.focusedFill : 0),
                in: .rect(cornerRadius: MessageComposerMetrics.cornerRadius)
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: MessageComposerMetrics.cornerRadius))
            .opacity(isEnabled ? 1 : 0.6)
        }
        .animation(AppAnimation.contentSpring, value: quote)
        .animation(AppAnimation.contentSpring, value: errorMessage)
        .animation(AppAnimation.contentSpring, value: showsCount)
        .animation(AppAnimation.fastAnimation, value: isSendEnabled)
        .animation(AppAnimation.fastAnimation, value: focusBinding.wrappedValue)
    }

    // MARK: - Parts

    /// The send button; with `onVoice:`, the microphone in its place while the text is blank.
    /// Without it the view is the send button alone, as before 4.8.0, so composers that do not
    /// dictate lay out exactly as they did.
    @ViewBuilder
    private var trailingButton: some View {
        if let onVoice {
            Group {
                if showsVoice {
                    voiceButton(onVoice)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    sendButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(AppAnimation.fastAnimation, value: showsVoice)
        } else {
            sendButton
        }
    }

    private func voiceButton(_ action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(isEnabled ? AppColors.accent : AppColors.Background.neutral2)
                Image(systemName: "mic.fill")
                    .font(.system(size: AppIconSize.sm, weight: .bold))
                    .foregroundStyle(isEnabled ? AppColors.staticWhite : AppColors.Text.tertiary)
            }
            .frame(width: MessageComposerMetrics.buttonSize, height: MessageComposerMetrics.buttonSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "composer.voice", defaultValue: "Dictate"))
    }

    private var sendButton: some View {
        Button {
            HapticManager.light()
            onSend()
        } label: {
            ZStack {
                Circle()
                    .fill(isSendEnabled || isSending ? AppColors.accent : AppColors.Background.neutral2)
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppColors.staticWhite)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: AppIconSize.sm, weight: .bold))
                        .foregroundStyle(isSendEnabled ? AppColors.staticWhite : AppColors.Text.tertiary)
                }
            }
            .frame(width: MessageComposerMetrics.buttonSize, height: MessageComposerMetrics.buttonSize)
        }
        .buttonStyle(.plain)
        .disabled(!isSendEnabled)
        .accessibilityLabel(String(localized: "composer.send", defaultValue: "Send"))
    }

    private func quoteView(_ quote: MessageQuote) -> some View {
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
                    .foregroundStyle(AppColors.Text.secondary)
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
                        .foregroundStyle(AppColors.Text.tertiary)
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

extension MessageComposer where Leading == EmptyView {
    /// A composer with nothing before the text.
    public init(
        text: Binding<String>,
        placeholder: String,
        quote: MessageQuote? = nil,
        isSending: Bool = false,
        canSend: Bool? = nil,
        errorMessage: String? = nil,
        limit: Int? = nil,
        focus: FocusState<Bool>.Binding? = nil,
        onVoice: (() -> Void)? = nil,
        onCancelQuote: (() -> Void)? = nil,
        onSend: @escaping () -> Void
    ) {
        self.init(
            text: text,
            placeholder: placeholder,
            quote: quote,
            isSending: isSending,
            canSend: canSend,
            errorMessage: errorMessage,
            limit: limit,
            focus: focus,
            leading: { EmptyView() },
            onVoice: onVoice,
            onCancelQuote: onCancelQuote,
            onSend: onSend
        )
    }
}

/// The label of a button or menu in `MessageComposer`'s leading slot (4.8.0): an icon in a
/// circle the size of the send button, so it lines up with it.
///
/// ```swift
/// MessageComposer(text: $text, placeholder: "Ask…", leading: {
///     Menu { … } label: { MessageComposerAccessory(systemImage: "paperclip") }
///         .accessibilityLabel("Attach")
/// }) { send() }
/// ```
public struct MessageComposerAccessory: View {
    let systemImage: String

    @Environment(\.isEnabled) private var isEnabled

    public init(systemImage: String) {
        self.systemImage = systemImage
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: AppIconSize.md, weight: .medium))
            .foregroundStyle(isEnabled ? AppColors.Text.secondary : AppColors.Text.tertiary)
            .frame(width: MessageComposerMetrics.buttonSize, height: MessageComposerMetrics.buttonSize)
            .contentShape(Circle())
    }
}

/// The composer's geometry: the send button sits `inset` from the glass edge, so the glass
/// corner is concentric with the button.
enum MessageComposerMetrics {
    static let buttonSize: CGFloat = AppIconSize.xl
    static let inset: CGFloat = AppSpacing.xs
    static let cornerRadius: CGFloat = buttonSize / 2 + inset
    /// How opaque the surface behind the text is while the field is focused.
    static let focusedFill: Double = 0.94
}
