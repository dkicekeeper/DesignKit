//
//  AccessibilityAnnouncer.swift
//  DesignKit
//
//  VoiceOver hears an outcome once, from what finished (8.9.0, benchmark round 4: Astryx's
//  `useAnnounce`). A toast that comes and goes, a message that was not sent, a page that would
//  not load: a sighted person sees the change, VoiceOver says nothing unless something posts an
//  announcement. `MessageBanner`, `MessageBubble`, `MessageComposer`, `LoadMoreFooter` and
//  `PendingItemCard` announce their own; an app announces the outcome of its own actions
//  ("Saved", "3 transactions imported") with `AccessibilityAnnouncer.announce(_:)`.
//
//  A banner that stays on screen (`StatusBanner`, `RecommendationBox`) does not announce: it is
//  read where it stands when the person reaches it.
//

import SwiftUI

/// Speaks a short outcome to VoiceOver.
///
/// ```swift
/// Button("Save") {
///     Task {
///         await store.save()
///         AccessibilityAnnouncer.announce(String(localized: "Saved"))
///     }
/// }
/// ```
///
/// Does nothing while VoiceOver is off. The announcement waits a moment, so VoiceOver finishes
/// what it was saying about the button just pressed and does not cut it off.
public enum AccessibilityAnnouncer {
    /// How long an announcement waits after the change that caused it.
    public static let delay: Duration = .milliseconds(150)

    /// Speaks `message` to VoiceOver; an empty message is skipped.
    public static func announce(_ message: String) {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            AccessibilityNotification.Announcement(text).post()
        }
    }
}

public extension View {
    /// Announces `message` to VoiceOver each time it changes to a non-empty value (a send that
    /// failed, a page that would not load). With `onAppear: true` it is also announced when the
    /// view appears with it: for a view that is itself the event, such as a toast.
    ///
    /// ```swift
    /// MessageComposer(…)
    ///     .voiceOverAnnouncement(sendError)
    /// ```
    func voiceOverAnnouncement(_ message: String?, onAppear: Bool = false) -> some View {
        modifier(VoiceOverAnnouncementModifier(message: message, onAppear: onAppear))
    }
}

private struct VoiceOverAnnouncementModifier: ViewModifier {
    let message: String?
    let onAppear: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard onAppear, let message else { return }
                AccessibilityAnnouncer.announce(message)
            }
            .onChange(of: message) { _, new in
                guard let new else { return }
                AccessibilityAnnouncer.announce(new)
            }
    }
}
