//
//  FormSection.swift
//  Tenra
//
//  Reusable wrapper for form sections with header/footer support
//  Reduces boilerplate in edit views
//  5.0.0: `style: .glass`, a Liquid Glass card that pads and spaces its rows: content that is
//  not a form (an assistant's reply, a short list). It was `ListCard` in 4.14.0.
//  8.0.0 (the owner's review of the app's screens): one look. Every section is a Liquid Glass
//  card, as in Tenra's Finances and Insights; it pads its rows at the sides and draws the
//  divider between them itself, under each row's text (RowDivider). `style:` is removed.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A titled group of rows on a Liquid Glass card (8.0.0: one look for forms, settings and
/// short lists).
///
/// The card pads its rows at the sides (`AppSpacing.lg`); the rows pad themselves only
/// vertically (`UniversalRow`'s `.standard`, docs/design-system.md §10). Between two rows the
/// section draws a `RowDivider` under the upper row's text, short of the card's trailing edge
/// by its padding; a custom row with something before its text says where with
/// `.rowDividerInset(_:)`. A row that scrolls under the card's edges (chips with their inset)
/// takes the card's whole width with `.fullWidthRow()`.
///
/// ```swift
/// FormSection(header: "Transaction") {
///     UniversalRow(config: .standard) { Text("Title") } trailing: {
///         FormTextField(text: $title, placeholder: "Title", style: .inline)
///     }
///     UniversalRow("Date", icon: "calendar", accessory: .date($date))
/// }
/// ```
public struct FormSection<Content: View>: View {
    let header: String?
    let footer: String?
    @ViewBuilder let content: Content

    public init(
        header: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.footer = footer
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

            DividedRows(padding: AppSpacing.lg) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // 8.0.0: Liquid Glass, drawn behind the rows (`cardStyle()`), as every card of the
            // app. Up to 7.x the form card was Material: iOS 26 took a glass card for the morph
            // source of a menu inside it and collapsed a one-row section into the popover.
            .cardStyle()

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
