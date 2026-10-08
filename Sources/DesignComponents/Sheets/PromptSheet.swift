//
//  PromptSheet.swift
//  DesignKit
//
//  A short question or request in a sheet: a symbol on a disc, a title, a message, the main
//  answer and a second one (HIG "Requesting permission", a rating pre-prompt). 2.0.0 made it
//  the one sheet of its kind: PermissionPrimerView (the permission primer of both apps since
//  0.7.0) was the same layout with an async "Allow", so the primer's layout, DSButtons and
//  loading state are PromptSheet's now, with a larger title (h2) and message (body).
//  What the answers do, the copy and the presentation stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Symbol, title, message and two buttons.
///
/// ```swift
/// .sheet(isPresented: $showsSurvey) {
///     PromptSheet(
///         systemImage: "sparkles",
///         title: "Enjoying the app?",
///         message: "Your answer helps us decide what to improve next.",
///         primaryTitle: "Love it!",
///         secondaryTitle: "Not really",
///         onPrimary: { requestReview() },
///         onSecondary: { openFeedbackMail() }
///     )
/// }
///
/// // A permission primer: "Allow" shows the system alert, the sheet closes after it.
/// PromptSheet(systemImage: "bell.badge", title: …, message: …,
///             primaryTitle: "Turn on", secondaryTitle: "Not now",
///             onPrimary: { await requestPermission() }, onSecondary: {})
/// ```
///
/// While `onPrimary` runs (a system alert is up, a request is on its way) the main button
/// shows a spinner and both buttons are disabled. With `dismissesOnAnswer` (the default) the
/// sheet closes after either answer; without it, the app closes it. `detent` sets the sheet's
/// height (`.medium` by default); pass `nil` when the app presents it its own way.
public struct PromptSheet: View {
    let systemImage: String
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let detent: PresentationDetent?
    let dismissesOnAnswer: Bool
    let onPrimary: () async -> Void
    let onSecondary: () -> Void

    @State private var isWorking = false
    @Environment(\.dismiss) private var dismiss

    public init(
        systemImage: String,
        title: String,
        message: String,
        primaryTitle: String,
        secondaryTitle: String,
        detent: PresentationDetent? = .medium,
        dismissesOnAnswer: Bool = true,
        onPrimary: @escaping () async -> Void,
        onSecondary: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.detent = detent
        self.dismissesOnAnswer = dismissesOnAnswer
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    public var body: some View {
        content
            .modifier(PromptSheetDetent(detent: detent))
    }

    private var content: some View {
        VStack(spacing: AppSpacing.lg) {
            HeroSymbol(systemImage: systemImage, size: PromptSheetMetrics.symbolSize)
                .padding(.top, AppSpacing.xxl)

            VStack(spacing: AppSpacing.sm) {
                Text(verbatim: title)
                    .font(AppTypography.h2)
                    .foregroundStyle(AppColors.Text.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.sm) {
                DSButton(primaryTitle, fullWidth: true, isLoading: isWorking) {
                    isWorking = true
                    Task {
                        await onPrimary()
                        isWorking = false
                        if dismissesOnAnswer { dismiss() }
                    }
                }
                DSButton(secondaryTitle, appearance: .secondary, fullWidth: true, isDisabled: isWorking) {
                    onSecondary()
                    if dismissesOnAnswer { dismiss() }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .screenPadding()
        .padding(.bottom, AppSpacing.lg)
    }
}

enum PromptSheetMetrics {
    /// The symbol's disc.
    static let symbolSize: CGFloat = 104
}

private struct PromptSheetDetent: ViewModifier {
    let detent: PresentationDetent?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let detent {
            content
                .presentationDetents([detent])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
