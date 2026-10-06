//
//  NotificationPermissionView.swift
//  DesignKit
//
//  Tenra's notification primer (subscription reminders): `PermissionPrimerView` with the
//  `notification.permission.*` texts, dismissing itself after either button. Since 0.7.0 it
//  has the shared primer layout (symbol on a disc, glass buttons) instead of its own.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Notification primer with the `notification.permission.*` keys. For other texts or another
/// permission use `PermissionPrimerView` directly.
public struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
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
        PermissionPrimerView(
            systemImage: "bell.badge.fill",
            title: String(localized: "notification.permission.title"),
            message: String(localized: "notification.permission.description"),
            allowTitle: String(localized: "notification.permission.allow"),
            laterTitle: String(localized: "notification.permission.skip"),
            onAllow: {
                await onAllow()
                dismiss()
            },
            onLater: {
                onSkip()
                dismiss()
            }
        )
    }
}
