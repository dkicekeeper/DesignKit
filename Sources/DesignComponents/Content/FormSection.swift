//
//  FormSection.swift
//  Tenra
//
//  Reusable wrapper for form sections with header/footer support
//  Reduces boilerplate in edit views
//  5.0.0: `style: .glass`, a Liquid Glass card that pads and spaces its rows: content that is
//  not a form (an assistant's reply, a short list). It was `ListCard` in 4.14.0.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Form section container with optional header and footer.
///
/// With `.card` (the default) the card adds no padding: its rows pad themselves (`UniversalRow`,
/// `.standard` by default; docs/design-system.md §10), and the caller puts a
/// `Divider()` between them. A bare field goes in a row's trailing slot:
///
/// ```swift
/// FormSection(header: "Transaction") {
///     UniversalRow(config: .standard) { Text("Title") } trailing: {
///         FormTextField(text: $title, placeholder: "Title", style: .inline)
///     }
///     Divider().padding(.leading, AppSpacing.lg)
///     UniversalRow("Date", icon: "calendar", accessory: .date($date))
/// }
/// ```
///
/// `.glass` (5.0.0) pads its rows on every side and spaces them by `AppSpacing.sm`, no dividers:
///
/// ```swift
/// FormSection(header: "Payments", style: .glass) {
///     ForEach(payments) { payment in
///         TransactionRow(…)
///     }
/// }
/// ```
public struct FormSection<Content: View>: View {
    let header: String?
    let footer: String?
    let style: Style
    @ViewBuilder let content: Content

    public enum Style: Sendable {
        /// A form's card: Material behind rows that pad themselves, the caller's `Divider()`
        /// between them. Material, not Liquid Glass: glass becomes the morph source of a menu
        /// inside and swallows a one-row section at the tap.
        case card
        /// A Liquid Glass card (`cardStyle()`) that pads its rows by `AppSpacing.lg` and spaces
        /// them by `AppSpacing.sm` (5.0.0; `ListCard` in 4.14.0): content that is not a form.
        case glass
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
            // Header; an empty one is left out (5.0.0).
            if let header, !header.isEmpty {
                HStack {
                    SectionHeader(header, style: .default)
                    Spacer()
                }
            }

            // Content
            switch style {
            case .card:
                VStack(spacing: 0) {
                    content
                }
                // `formCardStyle()` (Material on every iOS) instead of `cardStyle()`
                // (`glassEffect` on iOS 26). Liquid Glass becomes the morph-source for
                // any `Picker(.menu)` / `Menu` rendered inside the card — in a single-
                // row section the glass-rect ≈ row, so iOS collapses the whole row
                // into the menu popover at tap. Material has no such interaction.
                .formCardStyle()
            case .glass:
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    content
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }

            // Footer
            if let footer = footer {
                Text(footer)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }
}

// MARK: - Previews




