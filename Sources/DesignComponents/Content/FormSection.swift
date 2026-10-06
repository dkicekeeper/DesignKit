//
//  FormSection.swift
//  Tenra
//
//  Reusable wrapper for form sections with header/footer support
//  Reduces boilerplate in edit views
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Form section container with optional header and footer
/// Provides consistent styling for form groups with automatic dividers
public struct FormSection<Content: View>: View {
    let header: String?
    let footer: String?
    let style: Style
    @ViewBuilder let content: Content

    public enum Style {
        /// Card style with background and rounded corners
        case card
    }

    public init(
        header: String? = nil,
        footer: String? = nil,
        style: Style = .card,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.style = style
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header
            if let header = header {
                HStack {
                    SectionHeaderView(header, style: .default)
                    Spacer()
                }
            }

            // Content
            VStack(spacing: 0) {
                content
            }
            // `formCardStyle()` (Material on every iOS) instead of `cardStyle()`
            // (`glassEffect` on iOS 26). Liquid Glass becomes the morph-source for
            // any `Picker(.menu)` / `Menu` rendered inside the card — in a single-
            // row section the glass-rect ≈ row, so iOS collapses the whole row
            // into the menu popover at tap. Material has no such interaction.
            .formCardStyle()

            // Footer
            if let footer = footer {
                Text(footer)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }
}

// MARK: - Previews




