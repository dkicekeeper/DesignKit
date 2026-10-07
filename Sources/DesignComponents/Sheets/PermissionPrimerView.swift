//
//  PermissionPrimerView.swift
//  DesignKit
//
//  Our explanation before the system permission alert (HIG "Requesting permission"): why the
//  app needs it, then "Allow" (shows the system alert) or "Not now". One layout for both apps
//  since 0.7.0: it replaced Tenra's NotificationPermissionView layout and Dalada's
//  NotificationPrimerView. Presentation (sheet, detent, snoozing "Not now") stays in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Symbol, title, explanation, and two buttons. Fits a `.medium` sheet.
///
/// ```swift
/// .sheet(isPresented: $showsPrimer) {
///     PermissionPrimerView(
///         systemImage: "bell.badge",
///         title: String(localized: "push.primer.title"),
///         message: String(localized: "push.primer.body"),
///         allowTitle: String(localized: "push.primer.allow"),
///         laterTitle: String(localized: "push.primer.later"),
///         onAllow: { await PushRegistrar.shared.requestPermission(); showsPrimer = false },
///         onLater: { showsPrimer = false }
///     )
///     .presentationDetents([.medium])
/// }
/// ```
///
/// The view does not dismiss itself: close it in `onAllow` / `onLater`. While `onAllow` runs
/// (the system alert is up) the Allow button shows a spinner and both buttons are disabled.
public struct PermissionPrimerView: View {
    let systemImage: String
    let title: String
    let message: String
    let allowTitle: String
    let laterTitle: String
    let onAllow: () async -> Void
    let onLater: () -> Void

    @State private var isRequesting = false

    public init(
        systemImage: String,
        title: String,
        message: String,
        allowTitle: String,
        laterTitle: String,
        onAllow: @escaping () async -> Void,
        onLater: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.allowTitle = allowTitle
        self.laterTitle = laterTitle
        self.onAllow = onAllow
        self.onLater = onLater
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HeroSymbol(systemImage: systemImage, size: 104)
                .padding(.top, AppSpacing.xxl)

            VStack(spacing: AppSpacing.sm) {
                Text(verbatim: title)
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.sm) {
                Button {
                    HapticManager.light()
                    isRequesting = true
                    Task {
                        await onAllow()
                        isRequesting = false
                    }
                } label: {
                    LoadingButtonLabel(allowTitle, isLoading: isRequesting)
                        .frame(maxWidth: .infinity)
                }
                .primaryButton(disabled: isRequesting)

                Button {
                    HapticManager.light()
                    onLater()
                } label: {
                    Text(verbatim: laterTitle)
                        .frame(maxWidth: .infinity)
                }
                .secondaryButton()
                .disabled(isRequesting)
            }
        }
        .screenPadding()
        .padding(.bottom, AppSpacing.lg)
    }
}
