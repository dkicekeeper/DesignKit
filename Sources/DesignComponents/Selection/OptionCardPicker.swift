//
//  OptionCardPicker.swift
//  DesignKit
//
//  Options shown as pictures (2.9.0): each option's artwork large, in a phone's shape (a preview
//  of what it does), in a carousel; the centred card is the choice. For a mode with a visible
//  result: a background, a theme, a layout. Ported from Tenra's HomeBackgroundPicker (none /
//  gradient / photo); the previews and the photo picker stay in Tenra.
//
//  6.0.0 (the owner's review): the carousel of large previews is the picker's only look. The list
//  (`OptionCard`, `style: .list`) and 5.2.0's row of small cards under one preview are gone; each
//  option is its own preview, the neighbours peek at the sides (`SnapCardPicker(style:
//  .centered(width:))`), and under the carousel is what the app sets for the chosen option
//  (`settings:`: "Choose a photo" for a photo).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Options as large previews in a carousel; the centred one is the choice, a swipe or a tap on a
/// neighbour changes it. Under the carousel, the chosen option's settings.
///
/// ```swift
/// OptionCardPicker(HomeBackground.allCases, selection: $background, title: { $0.name }) { background in
///     BackgroundPreview(background)                  // fills the frame it is given
/// } settings: { background in
///     if background == .photo {
///         FormSection {
///             PhotosPicker(…) { ActionRowLabel("Choose a photo", systemImage: "photo.on.rectangle") }
///         }
///     }
/// }
/// ```
public struct OptionCardPicker<Option: Hashable, Artwork: View>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    let artwork: (Option) -> Artwork
    let settings: ((Option) -> AnyView)?

    /// - Parameter artwork: An option's picture, filling the frame it is given (a phone's shape,
    ///   2 × 3). Only the centred card's moves (`.designKitMotion`).
    public init(
        _ options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String,
        @ViewBuilder artwork: @escaping (Option) -> Artwork
    ) {
        self.options = options
        self._selection = selection
        self.title = title
        self.artwork = artwork
        self.settings = nil
    }

    /// Options with settings of their own (5.2.0), shown under the carousel for the chosen option.
    ///
    /// - Parameter settings: What the app sets for the chosen option, in DesignKit's form rows
    ///   (a `FormSection` of `ActionRowLabel`, `ToggleSettingsRow`, `SliderRow`,
    ///   `ActionSettingsRow`); empty for one with nothing to set.
    public init<Settings: View>(
        _ options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String,
        @ViewBuilder artwork: @escaping (Option) -> Artwork,
        @ViewBuilder settings: @escaping (Option) -> Settings
    ) {
        self.options = options
        self._selection = selection
        self.title = title
        self.artwork = artwork
        self.settings = { AnyView(settings($0)) }
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            SnapCardPicker(options, id: \.self, selection: carouselSelection,
                           style: .centered(width: OptionCardPickerMetrics.cardWidth)) { option, isSelected, select in
                Button(action: select) {
                    OptionPreviewCard(title: title(option), isSelected: isSelected) {
                        artwork(option)
                    }
                }
                .buttonStyle(.plain)
            }
            settingsView
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

    /// The carousel's selection: a centred card is always one of the options.
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

/// One option in the carousel: its artwork large in a phone's shape, its name under it; the
/// chosen one outlined in the accent with its name in the accent.
private struct OptionPreviewCard<Artwork: View>: View {
    let title: String
    let isSelected: Bool
    @ViewBuilder let artwork: Artwork

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        VStack(spacing: AppSpacing.sm) {
            artwork
                .frame(width: OptionCardPickerMetrics.cardWidth, height: OptionCardPickerMetrics.cardHeight)
                // The neighbours stand still; the chosen one may move.
                .designKitMotion(isSelected)
                .clipShape(shape)
                // A hairline: an artwork the colour of the page (a plain background) still shows
                // its shape.
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
                .selectionOutline(isSelected, cornerRadius: AppRadius.xl)
            Text(verbatim: title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: OptionCardPickerMetrics.cardWidth)
        .animation(AppAnimation.snappy, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}

enum OptionCardPickerMetrics {
    /// A card: the option's preview in a phone's shape (2 × 3).
    static let cardWidth: CGFloat = 180
    static let cardHeight: CGFloat = 270
}

// MARK: - Skeleton

/// Placeholder of an `OptionCardPicker` (6.0.0): three previews in a phone's shape with a name
/// under each, the side ones smaller and paler, as the carousel shows them.
public struct OptionCardPickerSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: SnapCardPickerMetrics.cardSpacing) {
            card.scaleEffect(SnapCardPickerMetrics.sideScale).opacity(SnapCardPickerMetrics.sideOpacity)
            card
            card.scaleEffect(SnapCardPickerMetrics.sideScale).opacity(SnapCardPickerMetrics.sideOpacity)
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .shimmer()
        .skeletonLoadingLabel()
    }

    private var card: some View {
        VStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Skeleton.fill)
                .frame(width: OptionCardPickerMetrics.cardWidth, height: OptionCardPickerMetrics.cardHeight)
            SkeletonText(AppTypography.bodyEmphasis, width: 72)
        }
    }
}
