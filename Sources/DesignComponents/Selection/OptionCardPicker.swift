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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: AppIconSize.sm, weight: .semibold))
                        .foregroundStyle(.white)
                        .background(Circle().fill(AppColors.accent).padding(-2))
                        .padding(AppSpacing.xs)
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
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: OptionCardMetrics.outline)
        )
        .animation(AppAnimation.contentSpring, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}

/// Plain options as cards, one under another; a tap selects.
///
/// ```swift
/// OptionCardPicker(Theme.allCases, selection: $theme, title: { $0.name }) { theme in
///     ThemePreview(theme)
/// }
/// ```
public struct OptionCardPicker<Option: Hashable, Artwork: View>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    let artwork: (Option) -> Artwork

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
    }

    public var body: some View {
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
}

enum OptionCardMetrics {
    /// The artwork: a phone's shape.
    static let artworkWidth: CGFloat = 80
    static let artworkHeight: CGFloat = 120
    /// The selected card's outline.
    static let outline: CGFloat = 3
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
