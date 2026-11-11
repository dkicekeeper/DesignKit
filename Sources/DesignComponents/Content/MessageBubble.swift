//
//  MessageBubble.swift
//  DesignKit
//
//  One message in a conversation (4.6.0): the person's own on the trailing side in the accent,
//  the other side's on the leading side in grey. A message that could not be sent says so under
//  the bubble, with a retry. Rich replies (cards, charts) are the app's own views laid out under
//  an incoming bubble or in its place.
//
//  8.9.0 (benchmark round 4: Astryx's ChatMessage and its metadata): an answer in Markdown
//  (`MessageBubble(markdown:)`: paragraphs, lists, headings, notes, bold and links), and the time
//  and the state of a message under it ("14:20 · Read").
//
//  Motion (5.2.0): `.transition(.messageBubble(role))` on a new message grows the person's own
//  from its bottom trailing corner, where the field is, and brings a reply in from its bottom
//  leading corner. A message that fails shakes once, its failure line rises in under it, and
//  the error haptic plays. Under Reduce Motion or `.designKitMotion(false)` only the fades stay.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A chat message in a bubble.
///
/// ```swift
/// MessageBubble("How much did I spend on cafés?")                              // mine
/// MessageBubble("Here is October so far.", role: .incoming)
/// MessageBubble(text, failure: "No connection") { Task { await retry() } }    // not sent
/// MessageBubble(markdown: answer)                                              // an assistant's reply
/// MessageBubble(text, time: sentAt, status: .read)                             // "14:20 · Read" under it
/// ```
///
/// The bubble grows to about 80% of the width and leaves the rest empty on the far side; the text
/// is selectable. Retry's title: key `common.retry` (default "Retry").
///
/// A new message enters with `.transition(.messageBubble(role))`, the history the chat opens
/// with does not:
///
/// ```swift
/// ForEach(messages) { message in
///     MessageBubble(message.text, role: message.role)
///         .transition(.messageBubble(message.role))
/// }
/// .animation(AppAnimation.bouncy, value: messages.count)
/// ```
public struct MessageBubble: View {
    /// Whose message it is.
    public enum Role: Hashable, Sendable {
        /// The person's own: trailing, in the accent.
        case outgoing
        /// The other side's: leading, in grey.
        case incoming
    }

    /// Where a message the person sent stands (8.9.0), said after its time under the bubble.
    public enum Status: Hashable, Sendable {
        /// On its way: "Sending…".
        case sending
        /// The other side has it: "Sent".
        case sent
        /// The other side has read it: "Read".
        case read

        var title: String {
            switch self {
            case .sending: String(localized: "message.sending", defaultValue: "Sending…")
            case .sent: String(localized: "message.sent", defaultValue: "Sent")
            case .read: String(localized: "message.read", defaultValue: "Read")
            }
        }
    }

    /// Plain text, or Markdown read into blocks once.
    private enum MessageContent {
        case text(String)
        case markdown([ArticleBody.Block])
    }

    private let content: MessageContent
    let role: Role
    let time: Date?
    let status: Status?
    let failure: String?
    let onRetry: (() -> Void)?

    /// - Parameters:
    ///   - time: When it was sent; shown under the bubble on its side (8.9.0).
    ///   - status: Where the person's own message stands, after the time (8.9.0).
    ///   - failure: Why the message was not sent; shown under the bubble in red.
    ///   - onRetry: Adds a Retry button next to the failure.
    public init(
        _ text: String,
        role: Role = .outgoing,
        time: Date? = nil,
        status: Status? = nil,
        failure: String? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.content = .text(text)
        self.role = role
        self.time = time
        self.status = status
        self.failure = failure
        self.onRetry = onRetry
    }

    /// A reply written in Markdown (8.9.0): paragraphs (a single line break kept), `-` and `1.`
    /// lists, `#` headings in the bubble's own size, `>` notes, **bold**, *italic* and links
    /// (`ArticleBody.Block.parse(markdown:)`). An answer is the other side's, so `role` is
    /// `.incoming` by default.
    public init(
        markdown: String,
        role: Role = .incoming,
        time: Date? = nil,
        status: Status? = nil,
        failure: String? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.content = .markdown(ArticleBody.Block.parse(markdown: markdown))
        self.role = role
        self.time = time
        self.status = status
        self.failure = failure
        self.onRetry = onRetry
    }

    /// Each new failure shakes the bubble once.
    @State private var shakes = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    private var isOutgoing: Bool { role == .outgoing }

    public var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 0) {
                if isOutgoing { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
                bubbleContent
                    .font(AppTypography.body)
                    .foregroundStyle(isOutgoing ? AppColors.Text.onAccent : AppColors.Text.primary)
                    // A link in the person's own message is white on the accent, underlined.
                    .tint(isOutgoing ? AppColors.Text.onAccent : AppColors.accent)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        isOutgoing ? AppColors.accent : AppColors.Background.neutral1,
                        in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    )
                    .opacity(failure == nil ? 1 : MessageBubbleMetrics.failedOpacity)
                    .keyframeAnimator(initialValue: 0.0, trigger: shakes) { bubble, offset in
                        bubble.offset(x: offset)
                    } keyframes: { _ in
                        let step = MessageBubbleMetrics.shakeStep
                        let shake = MessageBubbleMetrics.shake
                        CubicKeyframe(-shake, duration: step)
                        CubicKeyframe(shake * 0.85, duration: step)
                        CubicKeyframe(-shake * 0.55, duration: step)
                        CubicKeyframe(shake * 0.3, duration: step)
                        CubicKeyframe(0, duration: step)
                    }
                if !isOutgoing { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
            }
            if failure == nil, let meta = metaLine {
                Text(verbatim: meta)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.Text.tertiary)
                    .padding(.horizontal, AppSpacing.xs)
                    .contentTransition(.opacity)
            }
            if let failure {
                HStack(spacing: AppSpacing.xs) {
                    Icon("exclamationmark.circle.fill", size: AppIconSize.xs, tint: .monochrome(AppColors.Status.negativeText))
                    Text(failure)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Status.negativeText)
                    if let onRetry {
                        Button(String(localized: "common.retry", defaultValue: "Retry"), action: onRetry)
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppColors.accent)
                    }
                }
                .transition(.riseIn)
            }
        }
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
        .animation(AppAnimation.smooth, value: failure)
        .hapticCue(.fail, trigger: failure != nil) { _, failed in failed }
        // 8.9.0: a failure that arrives is spoken; one the conversation opens with is not.
        .voiceOverAnnouncement(failure)
        .onChange(of: failure != nil) { _, failed in
            if failed, !reduceMotion, designKitMotion { shakes += 1 }
        }
        .animation(AppAnimation.smooth, value: status)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch content {
        case .text(let text):
            Text(text)
        case .markdown(let blocks):
            MessageMarkdown(blocks: blocks, isOutgoing: isOutgoing)
        }
    }

    /// "14:20 · Read", "14:20", "Sending…"; nil with neither.
    private var metaLine: String? {
        let parts = [time.map { $0.formatted(date: .omitted, time: .shortened) }, status?.title].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// The blocks of a Markdown reply in a bubble: in the bubble's own size and colour (headings only
/// bolder), lists with their markers, a note behind a bar.
private struct MessageMarkdown: View {
    let blocks: [ArticleBody.Block]
    let isOutgoing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                view(of: block)
            }
        }
    }

    @ViewBuilder
    private func view(of block: ArticleBody.Block) -> some View {
        switch block {
        case .heading(let text, _):
            inlineMarkdown(text)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            inlineMarkdown(text)
        case .bullets(let items):
            list(items) { _ in "•" }
        case .steps(let items):
            list(items) { index in "\(index + 1)." }
        case .note(let text):
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Capsule()
                    .fill(isOutgoing ? AppColors.Text.onAccent.opacity(0.6) : AppColors.accent)
                    .frame(width: MessageBubbleMetrics.noteBar)
                inlineMarkdown(text)
                    .opacity(0.85)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func list(_ items: [String], marker: @escaping (Int) -> String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Text(verbatim: marker(index))
                        .monospacedDigit()
                    inlineMarkdown(item)
                }
            }
        }
    }
}

/// A message entering a conversation (5.2.0): the person's own grows from its bottom trailing
/// corner with a light spring, a reply comes into focus from its bottom leading corner. Leaves
/// with a fade. Under Reduce Motion (or `.designKitMotion(false)`) it only fades.
public struct MessageBubbleTransition: Transition {
    let role: MessageBubble.Role

    public init(_ role: MessageBubble.Role) {
        self.role = role
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(MessageBubbleEntrance(role: role, phase: phase))
    }
}

public extension Transition where Self == MessageBubbleTransition {
    /// A new message: grows from the field (`.outgoing`), or comes into focus from the other
    /// side (`.incoming`); a fade under Reduce Motion.
    static func messageBubble(_ role: MessageBubble.Role) -> MessageBubbleTransition {
        MessageBubbleTransition(role)
    }
}

// A transition cannot read the environment; its modifier can.
private struct MessageBubbleEntrance: ViewModifier {
    let role: MessageBubble.Role
    let phase: TransitionPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        // Only an entrance moves: a message that leaves fades where it is.
        let enters = !reduceMotion && designKitMotion && phase == .willAppear
        let isOutgoing = role == .outgoing
        content
            .scaleEffect(
                enters ? (isOutgoing ? MessageBubbleMetrics.outgoingScale : MessageBubbleMetrics.incomingScale) : 1,
                anchor: isOutgoing ? .bottomTrailing : .bottomLeading
            )
            .offset(y: enters && isOutgoing ? MessageBubbleMetrics.outgoingRise : 0)
            .blur(radius: enters && !isOutgoing ? MessageBubbleMetrics.incomingBlur : 0)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

public enum MessageBubbleMetrics {
    /// The empty side: the bubble never reaches the far edge.
    public static let farSideMargin: CGFloat = 56
    /// The bar beside a note in a Markdown reply.
    static let noteBar: CGFloat = 3
    /// A message that was not sent is drawn faded.
    static let failedOpacity: Double = 0.6
    /// The shake of a failed message: how far the bubble swings (then less each way), and how
    /// long each swing takes.
    static let shake: Double = 7
    static let shakeStep: Double = 0.07
    /// The person's own message starts this small at its corner, this far down (by the field).
    static let outgoingScale: CGFloat = 0.5
    static let outgoingRise: CGFloat = 12
    /// A reply starts this small at its corner, this blurred.
    static let incomingScale: CGFloat = 0.85
    static let incomingBlur: CGFloat = 6
}

// MARK: - Skeleton

/// Placeholder of a `MessageBubble`: a grey bubble of two lines on its side.
public struct MessageBubbleSkeleton: View {
    let role: MessageBubble.Role

    public init(role: MessageBubble.Role = .incoming) {
        self.role = role
    }

    public var body: some View {
        HStack(spacing: 0) {
            if role == .outgoing { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.body, width: 200)
                SkeletonText(AppTypography.body, width: 120)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.Background.neutral1, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            if role == .incoming { Spacer(minLength: MessageBubbleMetrics.farSideMargin) }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
