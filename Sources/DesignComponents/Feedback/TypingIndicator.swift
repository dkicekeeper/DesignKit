//
//  TypingIndicator.swift
//  DesignKit
//
//  "Someone is writing": three dots rising in a wave in a message bubble (2.2.0). Under the
//  last message of a thread while a reply is on its way, in a chat with an assistant while it
//  thinks. (Messages, Atlassian "typing indicator".)
//
//  The wave is computed from the time (no per-dot state) at 30 fps, and only while motion is
//  allowed (AmbientMotionGate, `.designKitMotion`); otherwise the dots stand still in a
//  fading row, which still reads as "…".
//

import SwiftUI
import DesignTokens

/// Three dots in a wave, in a bubble.
///
/// ```swift
/// if replyIsComing {
///     TypingIndicator().transition(.popIn)
/// }
/// ```
///
/// VoiceOver reads "Typing" (`typing.indicator`) or `accessibilityLabel`.
public struct TypingIndicator: View {
    let tint: Color
    let label: String?

    @Environment(\.designKitMotion) private var designKitMotion

    /// - Parameters:
    ///   - tint: The dots' colour (secondary text by default).
    ///   - accessibilityLabel: What VoiceOver reads ("Ayan is typing").
    public init(tint: Color = AppColors.Text.secondary, accessibilityLabel: String? = nil) {
        self.tint = tint
        self.label = accessibilityLabel
    }

    public var body: some View {
        AmbientMotionGate { allowsAmbientMotion in
            if allowsAmbientMotion && designKitMotion {
                TimelineView(.periodic(from: .now, by: TypingIndicatorMetrics.frameInterval)) { timeline in
                    dots(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                dots(at: nil)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.Background.neutral2, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label ?? String(localized: "typing.indicator", defaultValue: "Typing")))
    }

    /// `time == nil`: still, each dot a little fainter than the one before.
    private func dots(at time: Double?) -> some View {
        HStack(spacing: TypingIndicatorMetrics.spacing) {
            ForEach(0..<3, id: \.self) { index in
                let lift = time.map { Self.lift(at: $0, index: index) } ?? 0
                Circle()
                    .fill(tint)
                    .frame(width: TypingIndicatorMetrics.dot, height: TypingIndicatorMetrics.dot)
                    .opacity(time == nil ? 1 - Double(index) * 0.25 : 0.45 + 0.55 * lift)
                    .offset(y: -TypingIndicatorMetrics.rise * lift)
            }
        }
    }

    /// 0…1: how high dot `index` is at `time`; the dots follow each other by a third of a beat.
    static func lift(at time: Double, index: Int) -> Double {
        let phase = time * 2 * .pi / TypingIndicatorMetrics.period - Double(index) * 0.7
        return max(0, sin(phase))
    }
}

enum TypingIndicatorMetrics {
    static let dot: CGFloat = 7
    static let spacing: CGFloat = 4
    static let rise: CGFloat = 3
    /// One wave across the three dots.
    static let period: Double = 1.2
    static let frameInterval: Double = 1.0 / 30
}
