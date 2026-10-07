//
//  SectionHeaderView.swift
//  Tenra
//
//  Unified section header component with consistent styling across the app
//  Replaces: SettingsSectionHeaderView, inline headers, category headers
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Unified section header component with 3 style variants
/// - `.default`: Standard section header (bodyEmphasis, primary color). Used in forms, date groups, cards.
/// - `.compact`: Small uppercase label (bodySmall, secondary color, with horizontal padding). Used in filters, pickers.
/// - `.large`: Page-level section title (h3, primary color, optional icon, with horizontal padding). Used in insights.
///
/// An action at the end of the line ("All", a button, a spinner) goes in `trailing` (1.14.0):
///
/// ```swift
/// SectionHeaderView("Trips", systemImage: "map") {
///     NavigationLink("All") { TripsList() }
/// }
/// ```
public struct SectionHeaderView: View {
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
        }
    }

    // MARK: - Style Variants

    // With an action, the title and the action share one line in an HStack with the system's
    // spacing: the layout the apps built by hand before 1.14.0, so adopting it moves nothing.

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

/// Placeholder of a `SectionHeaderView` (and `SettingsSectionHeaderView`, `.compact`): a line
/// of the style's text, with its padding; `showsTrailing` adds a short line for the action.
public struct SectionHeaderViewSkeleton: View {
    let style: SectionHeaderView.Style
    let showsTrailing: Bool

    public init(style: SectionHeaderView.Style = .default, showsTrailing: Bool = false) {
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
