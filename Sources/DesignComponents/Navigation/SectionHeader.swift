//
//  SectionHeader.swift
//  Tenra
//
//  The title over a section, in five styles, with an optional action at the end of the line.
//  2.0.0: named SectionHeaderView before; SettingsSectionHeaderView became the `.list` style
//  and DateSectionHeaderView the `.card` style.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// The title over a section:
/// - `.default`: bodyEmphasis, primary colour. Forms, cards.
/// - `.compact`: small uppercase, secondary colour, with the screen padding. Filters, pickers.
/// - `.list`: the same label without padding, for a `List` / `Form` section header, where the
///   system insets it (SettingsSectionHeaderView before 2.0).
/// - `.large`: h3 with an accent symbol, with the screen padding. A screen's own sections.
/// - `.card`: the default title on a glass card with its padding, the action (a day's total)
///   on the trailing edge. A date's header in a transaction list (DateSectionHeaderView
///   before 2.0).
///
/// An action at the end of the line ("All", a button, a spinner) goes in `trailing` (1.15.0):
///
/// ```swift
/// SectionHeader("Trips", systemImage: "map") {
///     NavigationLink("All") { TripsList() }
/// }
/// ```
public struct SectionHeader: View {
    let title: String
    /// Optional SF Symbol name shown to the left of the title (accent color).
    /// Currently used only with `.large` style.
    var systemImage: String? = nil
    let style: Style
    /// The action at the end of the line, set in `bodySmall`; `nil` draws the title alone.
    let trailing: AnyView?

    public enum Style {
        /// Standard section header (bodyEmphasis, primary color)
        case `default`

        /// Small uppercase label with horizontal padding (bodySmall, secondary color)
        case compact

        /// Page-level section title with horizontal padding (h3, primary color, optional icon)
        case large

        /// The compact label without padding: a `List` / `Form` section header (2.0.0)
        case list

        /// The default title on a glass card, padded (2.0.0)
        case card
    }

    public init(_ title: String, systemImage: String? = nil, style: Style = .default) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.trailing = nil
    }

    /// A header with an action at the end of the line: "All" (a `NavigationLink`), a button, a
    /// spinner. The action takes `AppTypography.bodySmall` and sits inside the style's padding.
    public init<Trailing: View>(
        _ title: String,
        systemImage: String? = nil,
        style: Style = .default,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.trailing = AnyView(trailing())
    }

    public var body: some View {
        switch style {
        case .default:
            defaultStyle
        case .compact:
            compactStyle
        case .large:
            largeStyle
        case .list:
            compactTitle
        case .card:
            cardHeader
        }
    }

    // MARK: - Style Variants

    // With an action, the title and the action share one line in an HStack with the system's
    // spacing: the layout the apps built by hand before 1.15.0, so adopting it moves nothing.

    @ViewBuilder
    private var defaultStyle: some View {
        if let trailing {
            HStack {
                defaultTitle
                Spacer(minLength: 0)
                trailing.font(AppTypography.bodySmall)
            }
        } else {
            defaultTitle
        }
    }

    private var defaultTitle: some View {
        Text(title)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.Text.primary)
    }

    @ViewBuilder
    private var compactStyle: some View {
        if let trailing {
            HStack {
                compactTitle
                Spacer(minLength: 0)
                trailing.font(AppTypography.bodySmall)
            }
            .screenPadding()
        } else {
            compactTitle
                .frame(maxWidth: .infinity, alignment: .leading)
                .screenPadding()
        }
    }

    private var compactTitle: some View {
        Text(title)
            .font(AppTypography.bodySmall)
            .foregroundStyle(AppColors.Text.secondary)
            .textCase(.uppercase)
    }

    private var cardHeader: some View {
        HStack {
            defaultTitle
            Spacer(minLength: 0)
            if let trailing {
                trailing.font(AppTypography.bodySmall)
            }
        }
        .textCase(nil)
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    @ViewBuilder
    private var largeStyle: some View {
        if let trailing {
            HStack(spacing: AppSpacing.md) {
                largeTitle
                Spacer(minLength: 0)
                trailing.font(AppTypography.bodySmall)
            }
            .screenPadding()
        } else {
            largeTitle
                .frame(maxWidth: .infinity, alignment: .leading)
                .screenPadding()
        }
    }

    @ViewBuilder
    private var largeTitle: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.accent)
            }
            Text(title)
                .font(AppTypography.h3)
                .foregroundStyle(AppColors.Text.primary)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `SectionHeader` (and `SettingsSectionHeaderView`, `.compact`): a line
/// of the style's text, with its padding; `showsTrailing` adds a short line for the action.
public struct SectionHeaderSkeleton: View {
    let style: SectionHeader.Style
    let showsTrailing: Bool

    public init(style: SectionHeader.Style = .default, showsTrailing: Bool = false) {
        self.style = style
        self.showsTrailing = showsTrailing
    }

    public var body: some View {
        Group {
            switch style {
            case .default:
                line(SkeletonText(AppTypography.bodyEmphasis, width: 120))
            case .compact:
                line(SkeletonText(AppTypography.bodySmall, width: 100))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .screenPadding()
            case .large:
                line(SkeletonText(AppTypography.h3, width: 160))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .screenPadding()
            case .list:
                line(SkeletonText(AppTypography.bodySmall, width: 100))
            case .card:
                HStack {
                    SkeletonText(AppTypography.bodyEmphasis, width: 100)
                    Spacer()
                    if showsTrailing {
                        SkeletonText(AppTypography.bodySmall, width: 80)
                    }
                }
                .shimmer()
                .padding(AppSpacing.lg)
                .cardStyle()
            }
        }
        .skeletonLoadingLabel()
    }

    @ViewBuilder
    private func line(_ title: SkeletonText) -> some View {
        if showsTrailing {
            HStack {
                title
                Spacer(minLength: 0)
                SkeletonText(AppTypography.bodySmall, width: 40)
            }
        } else {
            title
        }
    }
}
