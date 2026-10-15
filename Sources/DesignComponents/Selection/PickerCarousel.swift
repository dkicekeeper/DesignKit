//
//  PickerCarousel.swift
//  DesignKit
//
//  Options to try on, side by side (4.13.0): the card in the middle is the focused one, full
//  size, the others a little smaller and paler. Each card is a picture, a name kept to two
//  lines, a lock when the option is closed, and an accent outline on the one chosen. Above the
//  cards, the focused option's name and, when it is closed, what opens it, in the accent with a
//  lock, wrapping in full; two lines are kept for it so the cards do not move. Ported from
//  Tenra's wardrobe for Ten (AssistantWardrobeView); what the options are, what opens them and
//  what a focused option does (Ten tries it on) stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Sunglasses / 🔒 7 days in a row in the app" over a row of cards, the focused one in the
/// middle.
///
/// ```swift
/// PickerCarousel(
///     items: hats,
///     focused: $focusedHat,
///     chosen: wornHat,
///     title: { $0.name },
///     condition: { $0.isOpen ? nil : $0.howToOpen }
/// ) { hat in
///     HatPicture(hat)
/// }
/// .onChange(of: focusedHat) { _, id in tryOn(id) }
/// ```
///
/// The pictures are drawn still (`designKitMotion(false)`): a row of animations costs frames,
/// and the focused option belongs in a large preview above, which the app draws.
public struct PickerCarousel<Item: Identifiable, Picture: View>: View {
    let items: [Item]
    @Binding var focused: Item.ID?
    let chosen: Item.ID?
    let title: (Item) -> String
    let condition: (Item) -> String?
    let lockedLabel: String
    let pictureSize: CGFloat
    let picture: (Item) -> Picture

    @State private var width: CGFloat = 0

    /// - Parameters:
    ///   - focused: The card in the middle; scrolling and a tap on a card change it.
    ///   - chosen: The option in use: an accent outline and an accent name.
    ///   - condition: What opens a closed option ("7 days in a row"); nil for an open one.
    ///   - lockedLabel: VoiceOver's word for a closed option ("Locked").
    ///   - pictureSize: The side of each card's picture.
    ///   - picture: An option's picture, filling `pictureSize`; closed ones are dimmed.
    public init(
        items: [Item],
        focused: Binding<Item.ID?>,
        chosen: Item.ID?,
        title: @escaping (Item) -> String,
        condition: @escaping (Item) -> String?,
        lockedLabel: String = String(localized: "common.locked", defaultValue: "Locked"),
        pictureSize: CGFloat = PickerCarouselMetrics.pictureSize,
        @ViewBuilder picture: @escaping (Item) -> Picture
    ) {
        self.items = items
        self._focused = focused
        self.chosen = chosen
        self.title = title
        self.condition = condition
        self.lockedLabel = lockedLabel
        self.pictureSize = pictureSize
        self.picture = picture
    }

    private var focusedItem: Item? {
        items.first { $0.id == focused }
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            details
                .padding(.horizontal, AppSpacing.lg)
            carousel
        }
    }

    /// The focused option's name and, when it is closed, what opens it: large, in the accent,
    /// wrapping in full however long it is. Two lines are kept for it, so a short one does not
    /// move the cards.
    private var details: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(focusedItem.map(title) ?? "")
                .font(AppTypography.h4)
                .foregroundStyle(AppColors.Text.primary)
                .multilineTextAlignment(.center)
            ZStack(alignment: .top) {
                PickerCarouselMetrics.reservedLines(PickerCarouselMetrics.lines, font: AppTypography.bodyEmphasis)
                if let focusedItem, let opensWith = condition(focusedItem) {
                    Label(opensWith, systemImage: "lock.fill")
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.accent)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// The cards side by side, the one in the middle full size, the others a little smaller
    /// and paler.
    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: AppSpacing.md) {
                ForEach(items) { item in
                    card(item)
                        .id(item.id)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : PickerCarouselMetrics.sideScale)
                                .opacity(phase.isIdentity ? 1 : PickerCarouselMetrics.sideOpacity)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, max(0, (width - PickerCarouselMetrics.cardWidth) / 2), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $focused, anchor: .center)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private func card(_ item: Item) -> some View {
        let isChosen = item.id == chosen
        let opensWith = condition(item)
        let isOpen = opensWith == nil
        return Button {
            withAnimation(AppAnimation.contentSpring) { focused = item.id }
        } label: {
            VStack(spacing: AppSpacing.sm) {
                picture(item)
                    .frame(width: pictureSize, height: pictureSize)
                    .designKitMotion(false)
                    .opacity(isOpen ? 1 : PickerCarouselMetrics.lockedOpacity)
                ZStack(alignment: .top) {
                    PickerCarouselMetrics.reservedLines(PickerCarouselMetrics.lines, font: AppTypography.bodyEmphasis)
                    Text(title(item))
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(isChosen ? AppColors.accent : AppColors.Text.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(PickerCarouselMetrics.lines)
                }
            }
            .padding(AppSpacing.md)
            .frame(width: PickerCarouselMetrics.cardWidth)
            .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.Background.elevation1))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(isChosen ? AppColors.accent : Color.clear, lineWidth: PickerCarouselMetrics.outline)
            )
            .overlay(alignment: .topTrailing) {
                if !isOpen {
                    Image(systemName: "lock.fill")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                        .padding(AppSpacing.sm)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title(item))
        .accessibilityValue(opensWith.map { "\(lockedLabel), \($0)" } ?? "")
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
    }
}

/// The sizes of a `PickerCarousel`.
public enum PickerCarouselMetrics {
    /// A card's picture.
    public static let pictureSize: CGFloat = 96
    /// A card's width; two lines kept for its name and for the condition above the cards.
    public static let cardWidth: CGFloat = 150
    static let lines = 2
    /// The cards beside the middle one.
    static let sideScale: CGFloat = 0.9
    static let sideOpacity: Double = 0.75
    /// The chosen card's outline.
    static let outline: CGFloat = 2
    /// A closed option's picture.
    static let lockedOpacity: Double = 0.4

    /// Room for `count` lines of `font`, empty: the text over it never makes its box taller or
    /// shorter than that.
    static func reservedLines(_ count: Int, font: Font) -> some View {
        Text(verbatim: Array(repeating: " ", count: count).joined(separator: "\n"))
            .font(font)
            .hidden()
            .accessibilityHidden(true)
    }
}

// MARK: - Skeleton

/// Placeholder of a `PickerCarousel`: the name's line and the condition's two lines, then three
/// cards (the middle one full size) of a grey picture and two lines of name.
public struct PickerCarouselSkeleton: View {
    let pictureSize: CGFloat

    public init(pictureSize: CGFloat = PickerCarouselMetrics.pictureSize) {
        self.pictureSize = pictureSize
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h4, width: 140)
                ZStack(alignment: .top) {
                    PickerCarouselMetrics.reservedLines(PickerCarouselMetrics.lines, font: AppTypography.bodyEmphasis)
                    SkeletonText(AppTypography.bodyEmphasis, width: 200)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.lg)

            HStack(spacing: AppSpacing.md) {
                card.scaleEffect(PickerCarouselMetrics.sideScale).opacity(PickerCarouselMetrics.sideOpacity)
                card
                card.scaleEffect(PickerCarouselMetrics.sideScale).opacity(PickerCarouselMetrics.sideOpacity)
            }
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .shimmer()
        .skeletonLoadingLabel()
    }

    private var card: some View {
        VStack(spacing: AppSpacing.sm) {
            Skeleton.circle(pictureSize)
            ZStack(alignment: .top) {
                PickerCarouselMetrics.reservedLines(PickerCarouselMetrics.lines, font: AppTypography.bodyEmphasis)
                SkeletonText(AppTypography.bodyEmphasis, width: 90)
            }
        }
        .padding(AppSpacing.md)
        .frame(width: PickerCarouselMetrics.cardWidth)
        .background(RoundedRectangle(cornerRadius: AppRadius.lg).fill(AppColors.Background.elevation1))
    }
}
