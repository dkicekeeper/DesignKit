//
//  EmptyCardView.swift
//  Tenra
//
//  Universal card component for section empty states.
//  Shows a section title + compact empty message, optionally tappable.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Card with a section header and compact empty state.
///
/// Use when a home-screen section has no data yet.
/// Pass `action` to make the entire card tappable (adds account, category, etc.).
///
/// ```swift
/// EmptyCardView(
///     sectionTitle: String(localized: "accounts.title"),
///     emptyTitle: String(localized: "emptyState.noAccounts"),
///     action: { showingAddAccount = true }
/// )
/// .screenPadding()
/// ```
public struct EmptyCardView: View {

    let sectionTitle: String
    let emptyTitle: String
    var action: (@Sendable () -> Void)? = nil

    public init(sectionTitle: String, emptyTitle: String, action: (@Sendable () -> Void)? = nil) {
        self.sectionTitle = sectionTitle
        self.emptyTitle = emptyTitle
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: {
                HapticManager.light()
                action()
            }) {
                cardContent
            }
            .buttonStyle(.bounce)
            .accessibilityLabel("\(sectionTitle). \(emptyTitle)")
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(sectionTitle)
                .font(AppTypography.h3)
                .foregroundStyle(AppColors.textPrimary)

            EmptyStateView(
                title: emptyTitle,
                style: .compact
            )
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview


