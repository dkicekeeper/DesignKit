//
//  NotificationPermissionPrompt.swift
//  DesignKit
//
//  Tenra's notification primer (subscription reminders): a `PromptSheet` with the
//  `notification.permission.*` texts that closes itself after either button. Named
//  NotificationPermissionView before 2.0.0.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Notification primer with the `notification.permission.*` keys. For other texts or another
/// permission use `PromptSheet` directly. The app sets the detent.
public struct NotificationPermissionPrompt: View {
    let onAllow: () async -> Void
    let onSkip: () -> Void

    public init(
        onAllow: @escaping () async -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.onAllow = onAllow
        self.onSkip = onSkip
    }

    public var body: some View {
        PromptSheet(
            systemImage: "bell.badge.fill",
            title: String(localized: "notification.permission.title"),
            message: String(localized: "notification.permission.description"),
            primaryTitle: String(localized: "notification.permission.allow"),
            secondaryTitle: String(localized: "notification.permission.skip"),
            detent: nil,
            onPrimary: onAllow,
            onSecondary: onSkip
        )
    }
}
