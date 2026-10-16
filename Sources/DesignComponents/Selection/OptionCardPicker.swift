//
//  OptionCardPicker.swift
//  DesignKit
//
//  Options shown as pictures (2.9.0): each option a card with its artwork (a preview of what it
//  does), its name beside it; the chosen one has an accent outline, a check on its artwork and its
//  name in the accent. For a mode with a visible result: a background, a theme, a layout. Ported
//  from Tenra's HomeBackgroundPicker (none / gradient / photo); the previews and the photo picker
//  stay in Tenra.
//
//  `OptionCard` is one card, for a list that mixes plain options with one that opens a picker
//  (wrap that card in a `PhotosPicker`); `OptionCardPicker` lays out a list of plain options.
//  5.2.0: `OptionCardPicker(style: .carousel)`, as Ten's wardrobe: the chosen option's artwork
//  large on top, in a phone's shape, the options in a row of cards under it (the centred one is
//  the choice, `SnapCardPicker(style: .centered(width:))`), and under the row what the app sets
//  for the chosen option (`settings:`: "Choose a photo" for a photo).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One option as a card: the artwork, the title, the selection.
///
/// ```swift
/// Button { mode = .gradient } label: {
///     OptionCard(title: "Gradient", isSelected: mode == .gradient) { GradientPreview() }
/// }
/// .buttonStyle(.plain)
/// ```
public struct OptionCard<Artwork: View>: View {
    let title: String
    let isSelected: Bool
    let artwork: Artwork

    /// - Parameter artwork: The option's preview, filling an 80 × 120 frame (a phone's shape).
    public init(title: String, isSelected: Bool, @ViewBuilder artwork: () -> Artwork) {
        self.title = title
        self.isSelected = isSelected
        self.artwork = artwork()
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack(alignment: .topTrailing) {
                artwork
                    .frame(width: OptionCardMetrics.artworkWidth, height: OptionCardMetrics.artworkHeight)
                    .clipShape(.rect(cornerRadius: AppRadius.lg))

                if isSelected {
                    OptionCardCheck()
                }
            }

            Text(verbatim: title)
                .font(AppTypography.body)
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)

            Spacer()
        }
        .padding(AppSpacing.md)
        .background {
            // The grouped-list card colour: white in light, a raised grey in dark.
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        // 2 pt since 5.0.0 (3 pt before), as every option a person picks from.
        .selectionOutline(isSelected, cornerRadius: AppRadius.xl)
        .animation(AppAnimation.contentSpring, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}

/// How `OptionCardPicker` lays its options out.
public enum OptionCardPickerStyle: Hashable, Sendable {
    /// Cards one under another, the artwork beside the name (2.9.0).
    case list
    /// The chosen option's artwork large on top, the options in a row of cards under it, the
    /// centred one the choice, and the chosen option's settings under the row (5.2.0).
    case carousel
}

/// Plain options as cards, one under another; a tap selects. With `style: .carousel` (5.2.0) the
/// chosen option's artwork is large on top, the options a row of cards under it, and its settings
/// under the row.
///
/// ```swift
/// OptionCardPicker(Theme.allCases, selection: $theme, title: { $0.name }) { theme in
///     ThemePreview(theme)
/// }
///
/// OptionCardPicker(HomeBackground.allCases, selection: $background, style: .carousel,
///                  title: { $0.name }) { background in
///     BackgroundPreview(background)                  // fills the frame it is given
/// } settings: { background in
///     if background == .photo { PhotosPicker(…) { Text("Choose a photo") } }
/// }
/// ```
public struct OptionCardPicker<Option: Hashable, Artwork: View>: View {
    public typealias Style = OptionCardPickerStyle

    let options: [Option]
    @Binding var selection: Option
    let style: Style
    let title: (Option) -> String
    let artwork: (Option) -> Artwork
    let settings: ((Option) -> AnyView)?

    /// - Parameters:
    ///   - style: `.list` (the default) or `.carousel` (5.2.0).
    ///   - artwork: An option's picture, filling the frame it is given (a phone's shape: 2 × 3).
    public init(
        _ options: [Option],
        selection: Binding<Option>,
        style: Style = .list,
        title: @escaping (Option) -> String,
        @ViewBuilder artwork: @escaping (Option) -> Artwork
    ) {
        self.options = options
        self._selection = selection
        self.style = style
        self.title = title
        self.artwork = artwork
        self.settings = nil
    }

    /// Options with settings of their own (5.2.0), shown for the chosen option: under the row of
    /// `.carousel`, under the cards of `.list`.
    ///
    /// - Parameter settings: What the app sets for the chosen option ("Choose a photo"); empty
    ///   for one with nothing to set.
    public init<Settings: View>(
        _ options: [Option],
        selection: Binding<Option>,
        style: Style = .list,
        title: @escaping (Option) -> String,
        @ViewBuilder artwork: @escaping (Option) -> Artwork,
        @ViewBuilder settings: @escaping (Option) -> Settings
    ) {
        self.options = options
        self._selection = selection
        self.style = style
        self.title = title
        self.artwork = artwork
        self.settings = { AnyView(settings($0)) }
    }

    public var body: some View {
        switch style {
        case .list:
            VStack(spacing: AppSpacing.lg) {
                list
                settingsView
            }
        case .carousel:
            carousel
        }
    }

    @ViewBuilder
    private var settingsView: some View {
        if let settings {
            // The next option's settings fade in over the last one's.
            ZStack {
                settings(selection)
                    .id(selection)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .animation(AppAnimation.smooth, value: selection)
        }
    }

    // MARK: List

    private var list: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    OptionCard(title: title(option), isSelected: selection == option) {
                        artwork(option)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .animation(AppAnimation.gentleSpring, value: selection)
    }

    // MARK: Carousel

    /// The chosen option large, the row of options, the chosen option's settings.
    private var carousel: some View {
        VStack(spacing: AppSpacing.lg) {
            preview
            SnapCardPicker(options, id: \.self, selection: carouselSelection,
                           style: .centered(width: OptionCardMetrics.carouselCardWidth)) { option, isSelected, select in
                Button(action: select) {
                    OptionCarouselCard(title: title(option), isSelected: isSelected) {
                        artwork(option)
                    }
                }
                .buttonStyle(.plain)
            }
            settingsView
        }
    }

    /// The chosen option's artwork in a phone's shape; the next one fades in over it.
    private var preview: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        return ZStack {
            artwork(selection)
                .id(selection)
                .transition(.opacity)
        }
        .frame(width: OptionCardMetrics.previewWidth, height: OptionCardMetrics.previewHeight)
        .clipShape(shape)
        .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        .animation(AppAnimation.smooth, value: selection)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    /// The row's selection: a centred card is always one of the options.
    private var carouselSelection: Binding<Option?> {
        Binding(
            get: { selection },
            set: { option in
                guard let option, option != selection else { return }
                HapticManager.selection()
                selection = option
            }
        )
    }
}

/// An option in `OptionCardPicker`'s carousel: its artwork over its name, the chosen one outlined
/// in the accent with a check on the artwork and its name in the accent.
private struct OptionCarouselCard<Artwork: View>: View {
    let title: String
    let isSelected: Bool
    @ViewBuilder let artwork: Artwork

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            artwork
                .frame(width: OptionCardMetrics.carouselArtworkWidth, height: OptionCardMetrics.carouselArtworkHeight)
                .designKitMotion(false)
                .clipShape(.rect(cornerRadius: AppRadius.md))
                // A hairline, as the preview's: an artwork the colour of the card (a plain
                // background) still shows its shape.
                .overlay(RoundedRectangle(cornerRadius: AppRadius.md).strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        OptionCardCheck()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            Text(verbatim: title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(AppSpacing.sm)
        .frame(width: OptionCardMetrics.carouselCardWidth)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(Color(.secondarySystemGroupedBackground)))
        .selectionOutline(isSelected, cornerRadius: AppRadius.lg)
        .animation(AppAnimation.snappy, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}

/// The check on a chosen option's artwork.
private struct OptionCardCheck: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: AppIconSize.sm, weight: .semibold))
            .foregroundStyle(.white)
            .background(Circle().fill(AppColors.accent).padding(-2))
            .padding(AppSpacing.xs)
    }
}

enum OptionCardMetrics {
    /// The artwork: a phone's shape.
    static let artworkWidth: CGFloat = 80
    static let artworkHeight: CGFloat = 120
    /// `.carousel` (5.2.0): the chosen option's preview, a card in the row and its artwork, all
    /// in a phone's shape (2 × 3).
    static let previewWidth: CGFloat = 160
    static let previewHeight: CGFloat = 240
    static let carouselCardWidth: CGFloat = 112
    static let carouselArtworkWidth: CGFloat = 64
    static let carouselArtworkHeight: CGFloat = 96
}

// MARK: - Skeleton

/// Placeholder of an `OptionCard`: the card, the artwork's shape and the title.
public struct OptionCardSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(Skeleton.fill)
                .frame(width: OptionCardMetrics.artworkWidth, height: OptionCardMetrics.artworkHeight)
            SkeletonText(AppTypography.body, width: 100)
            Spacer()
        }
        .shimmer()
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .skeletonLoadingLabel()
    }
}

/// Placeholder of an `OptionCardPicker(style: .carousel)` (5.2.0): the preview's phone shape and
/// a row of three cards, the side ones smaller and paler.
public struct OptionCardCarouselSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Skeleton.fill)
                .frame(width: OptionCardMetrics.previewWidth, height: OptionCardMetrics.previewHeight)
            HStack(spacing: AppSpacing.md) {
                card.scaleEffect(SnapCardPickerMetrics.sideScale).opacity(SnapCardPickerMetrics.sideOpacity)
                card
                card.scaleEffect(SnapCardPickerMetrics.sideScale).opacity(SnapCardPickerMetrics.sideOpacity)
            }
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .shimmer()
        .skeletonLoadingLabel()
    }

    private var card: some View {
        VStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Skeleton.fill)
                .frame(width: OptionCardMetrics.carouselArtworkWidth, height: OptionCardMetrics.carouselArtworkHeight)
            SkeletonText(AppTypography.bodyEmphasis, width: 64)
        }
        .padding(AppSpacing.sm)
        .frame(width: OptionCardMetrics.carouselCardWidth)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(Color(.secondarySystemGroupedBackground)))
    }
}
