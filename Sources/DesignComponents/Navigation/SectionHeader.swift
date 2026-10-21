//
//  SectionHeader.swift
//  Tenra
//
//  The title over a section, in three styles, with symbols around the title and an optional
//  action at the end of the line.
//  2.0.0: named SectionHeaderView before; SettingsSectionHeaderView became the `.list` style
//  and DateSectionHeaderView the `.card` style.
//  3.2.0: `.list` is `.compact`, which no longer pads itself; both symbols show in every style.
//  4.0.0: the deprecated `.list` name is removed.
//  8.0.0 (the owner's review of the app's screens): one look for a section's title, bold and in
//  sentence case; `.compact`, the small grey uppercase label, is removed.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// The title over a section:
/// - `.default`: bodyEmphasis, primary colour, in sentence case even in a `List`'s header
///   (8.0.0), no padding of its own. Forms, cards, a screen's sections with `.screenPadding()`.
/// - `.large`: h3, with the screen padding. A screen's own sections.
/// - `.card`: the default title on a glass card with its padding, the action (a day's total)
///   on the trailing edge. A date's header in a transaction list (DateSectionHeaderView
///   before 2.0).
///
/// A symbol before the title (`systemImage`) and one right after it (`trailingSystemImage`,
/// 3.2.0) show in every style, in the title's font: the leading one in the accent, the trailing one in the tertiary grey, `tint` for both. The trailing
/// one says what the header does: `chevron.forward` for one that leads somewhere,
/// `info.circle` for one that explains.
///
/// An action at the end of the line ("All", a button, a spinner) goes in `trailing` (1.15.0):
///
/// ```swift
/// SectionHeader("Trips", systemImage: "map") {
///     NavigationLink("All") { TripsList() }
/// }
/// NavigationLink { TripsList() } label: {
///     SectionHeader("Trips", trailingSystemImage: "chevron.forward")
/// }
/// ```
public struct SectionHeader: View {
    let title: String
    /// SF Symbol before the title.
    let systemImage: String?
    /// SF Symbol right after the title (3.2.0).
    let trailingSystemImage: String?
    /// Colour of both symbols; `nil` keeps the style's.
    let tint: Color?
    let style: Style
    /// The action at the end of the line, set in `bodySmall`; `nil` draws the title alone.
    let trailing: AnyView?

    public enum Style {
        /// Standard section header (bodyEmphasis, primary color); the one style of a section's
        /// title since 8.0.0 (`.compact`, the small uppercase label, is removed)
        case `default`

        /// Page-level section title with horizontal padding (h3, primary color)
        case large

        /// The default title on a glass card, padded (2.0.0)
        case card
    }

    /// - Parameters:
    ///   - systemImage: SF Symbol before the title.
    ///   - trailingSystemImage: SF Symbol right after the title (3.2.0): `chevron.forward`,
    ///     `info.circle`.
    ///   - tint: Colour of both symbols; the accent before the title and the tertiary grey
    ///     after it by default.
    public init(
        _ title: String,
        systemImage: String? = nil,
        trailingSystemImage: String? = nil,
        tint: Color? = nil,
        style: Style = .default
    ) {
        self.title = title
        self.systemImage = systemImage
        self.trailingSystemImage = trailingSystemImage
        self.tint = tint
        self.style = style
        self.trailing = nil
    }

    /// A header with an action at the end of the line: "All" (a `NavigationLink`), a button, a
    /// spinner. The action takes `AppTypography.bodySmall` and sits inside the style's padding.
    public init<Trailing: View>(
        _ title: String,
        systemImage: String? = nil,
        trailingSystemImage: String? = nil,
        tint: Color? = nil,
        style: Style = .default,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.systemImage = systemImage
        self.trailingSystemImage = trailingSystemImage
        self.tint = tint
        self.style = style
        self.trailing = AnyView(trailing())
    }

    public var body: some View {
        switch style {
        case .default:
            line(defaultTitle)
        case .large:
            largeStyle
        case .card:
            cardHeader
        }
    }

    // MARK: - Style Variants

    // With an action, the title and the action share one line in an HStack with the system's
    // spacing: the layout the apps built by hand before 1.15.0, so adopting it moves nothing.

    @ViewBuilder
    private func line(_ title: some View) -> some View {
        if let trailing {
            HStack {
                title
                Spacer(minLength: 0)
                trailing.font(AppTypography.bodySmall)
            }
        } else {
            title
        }
    }

    private var defaultTitle: some View {
        symbols(
            around: Text(title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.Text.primary)
                // A List's header capitalises its text; the title keeps its own case (8.0.0).
                .textCase(nil),
            leadingSize: AppIconSize.md,
            trailingSize: AppIconSize.sm,
            leadingColor: AppColors.accent,
            spacing: AppSpacing.sm
        )
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

    /// The large title's leading symbol keeps the body size it has had since before 3.2.0.
    private var largeTitle: some View {
        symbols(
            around: Text(title)
                .font(AppTypography.h3)
                .foregroundStyle(AppColors.Text.primary),
            leadingSize: AppIconSize.md,
            trailingSize: AppIconSize.md,
            leadingColor: AppColors.accent,
            spacing: AppSpacing.md
        )
    }

    // MARK: - Symbols

    /// The title with its symbols: the leading one `spacing` before it, the trailing one close
    /// after it, both decorative to VoiceOver. Without symbols, the title as it is.
    @ViewBuilder
    private func symbols(
        around text: some View,
        leadingSize: CGFloat,
        trailingSize: CGFloat,
        leadingColor: Color,
        spacing: CGFloat
    ) -> some View {
        if let systemImage {
            HStack(spacing: spacing) {
                // 7.0.0: the symbols are Icons at the title's size (the leading one a step larger).
                Icon(systemImage, size: leadingSize)
                    .foregroundStyle(tint ?? leadingColor)
                withTrailingSymbol(text, size: trailingSize)
            }
        } else {
            withTrailingSymbol(text, size: trailingSize)
        }
    }

    @ViewBuilder
    private func withTrailingSymbol(_ text: some View, size: CGFloat) -> some View {
        if let trailingSystemImage {
            HStack(spacing: AppSpacing.xs) {
                text
                Icon(trailingSystemImage, size: size)
                    .foregroundStyle(tint ?? AppColors.Text.tertiary)
            }
        } else {
            text
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `SectionHeader`: a line of the style's text, with its padding;
/// `showsTrailing` adds a short line for the action, `showsIcon` a grey circle for the symbol
/// before the title (3.2.0).
public struct SectionHeaderSkeleton: View {
    let style: SectionHeader.Style
    let showsTrailing: Bool
    let showsIcon: Bool

    public init(style: SectionHeader.Style = .default, showsTrailing: Bool = false, showsIcon: Bool = false) {
        self.style = style
        self.showsTrailing = showsTrailing
        self.showsIcon = showsIcon
    }

    public var body: some View {
        Group {
            switch style {
            case .default:
                line(SkeletonText(AppTypography.bodyEmphasis, width: 120),
                     iconSize: AppIconSize.md, spacing: AppSpacing.sm)
            case .large:
                line(SkeletonText(AppTypography.h3, width: 160), iconSize: AppIconSize.md, spacing: AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .screenPadding()
            case .card:
                HStack {
                    withIcon(SkeletonText(AppTypography.bodyEmphasis, width: 100),
                             size: AppIconSize.md, spacing: AppSpacing.sm)
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
    private func line(_ title: SkeletonText, iconSize: CGFloat, spacing: CGFloat) -> some View {
        if showsTrailing {
            HStack {
                withIcon(title, size: iconSize, spacing: spacing)
                Spacer(minLength: 0)
                SkeletonText(AppTypography.bodySmall, width: 40)
            }
        } else {
            withIcon(title, size: iconSize, spacing: spacing)
        }
    }

    @ViewBuilder
    private func withIcon(_ title: SkeletonText, size: CGFloat, spacing: CGFloat) -> some View {
        if showsIcon {
            HStack(spacing: spacing) {
                // The symbol's box, drawn as a grey circle.
                Circle()
                    .fill(Skeleton.fill)
                    .frame(width: size, height: size)
                    .shimmer()
                    .accessibilityHidden(true)
                title
            }
        } else {
            title
        }
    }
}
