//
//  PromptSheet.swift
//  DesignKit
//
//  A short question in a small sheet: a symbol, a title, a message, a filled primary button
//  and a plain secondary one; either answer closes the sheet. Ported from Tenra's
//  RatingSurveyView (the "Enjoying Tenra?" pre-prompt); the rating service, the feedback
//  e-mail and the copy stay in Tenra as an adapter.
//
//  1.5.0 moved Tenra's system fonts to AppTypography (owner's decision): the title is h3,
//  the message bodySmall, the buttons bodyEmphasis. The 14 pt button radius is Tenra's as it
//  ships.
//

import SwiftUI
import DesignTokens

/// "✨ / Enjoying the app? / … / [Love it!] / Not really", presented with `.sheet`.
///
/// The sheet sets its own detent (`height`, 340 pt by default) and shows the drag indicator.
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
/// ```
public struct PromptSheet: View {
    let systemImage: String
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let height: CGFloat
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// - Parameters:
    ///   - systemImage: A 44 pt (`AppIconSize.xxl`) symbol in the accent colour at the top.
    ///   - height: The sheet's detent.
    ///   - onPrimary: Runs, then the sheet closes.
    ///   - onSecondary: Runs, then the sheet closes.
    public init(
        systemImage: String,
        title: String,
        message: String,
        primaryTitle: String,
        secondaryTitle: String,
        height: CGFloat = 340,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.height = height
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.xxl))
                .foregroundStyle(AppColors.accent)
                .padding(.top, AppSpacing.xl)

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.sm) {
                Button {
                    onPrimary()
                    dismiss()
                } label: {
                    Text(primaryTitle)
                        .font(AppTypography.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(AppColors.staticWhite)
                }

                Button {
                    onSecondary()
                    dismiss()
                } label: {
                    Text(secondaryTitle)
                        .font(AppTypography.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.bgBase.ignoresSafeArea())
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }
}
