//
//  SnapCardPicker.swift
//  DesignKit
//
//  Pick one item by swiping cards (2.9.0): full-width cards in a horizontal row that snaps, the
//  neighbours peeking in at the edges; the centred card is the selection. Swipe to another card
//  or tap it. For choosing an account or a category in a form where each choice has a card of
//  its own. Ported from Tenra's AccountSelectorView and CategoryCardSelectorView; the cards (a
//  `SelectableBalanceCard`, a category card), the empty state and the warning stay with the app.
//
//  The scroll position is written only once the scroll view has measured its container: before
//  that, SwiftUI drops the write while keeping the state, and the carousel never catches up with
//  a selection that arrives after it appears.
//  5.0.0: `style: .centered(width:)`, cards of one width side by side, the centred one full size,
//  the others smaller and paler, the selection following the centre as the row scrolls: the row of
//  `PickerCarousel`, which drew its own carousel in 4.14.0.
//  5.2.0: `.fill` follows the centre during a drag as well (it waited for the row to stop), and
//  `.centered` no longer clips its cards' outline and shadow at the top and bottom.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A snapping row of cards; the centred one is selected.
///
/// ```swift
/// SnapCardPicker(accounts, id: \.id, selection: $accountID) { account, isSelected, select in
///     SelectableBalanceCard(iconSource: account.icon, title: account.name, amount: account.balance,
///                           currency: account.currency, isSelected: isSelected, action: select)
/// }
/// ```
///
/// With `.fill` (the default) each card fills the row's width (`containerRelativeFrame`);
/// `AppSpacing.md` between cards and `AppSpacing.lg` of the neighbours show. In both styles the
/// selection follows the centre while a drag moves the row (5.2.0; `.fill` waited for the row to
/// settle before); a tap on a card calls `select`, which selects it and scrolls it to the centre.
public struct SnapCardPicker<Item, ID: Hashable, Card: View>: View {
    /// How the cards stand in the row.
    public enum Style: Equatable, Sendable {
        /// Each card fills the row, the neighbours peeking in at the edges; the selection follows
        /// the centre while a drag moves the row (5.2.0; 2.9.0 waited for it to settle): an
        /// account or a category in a form.
        case fill
        /// Cards `width` wide side by side, the centred one full size, the others a little smaller
        /// and paler; the selection follows the centre while the row scrolls (5.0.0): options to
        /// try on (`PickerCarousel`).
        case centered(width: CGFloat)
    }

    let items: [Item]
    let id: KeyPath<Item, ID>
    @Binding var selection: ID?
    let style: Style
    let onSelectionChange: ((ID) -> Void)?
    let card: (Item, Bool, @escaping () -> Void) -> Card

    @State private var scrollPosition: ID?
    /// `false` until the scroll view has a measured container and the first position is written.
    @State private var hasAlignedInitialScroll = false
    /// The row's visible width, for `.centered`'s margins.
    @State private var containerWidth: CGFloat = 0
    /// Whether the person is moving the row (a drag and its coast), not an animated scroll.
    @State private var isScrolledByHand = false

    /// - Parameters:
    ///   - style: `.fill` (the default) or `.centered(width:)` (5.0.0).
    ///   - onSelectionChange: Called when a tap or a drag picks another item.
    ///   - card: The card for an item, whether it is selected, and the action that selects it.
    public init(
        _ items: [Item],
        id: KeyPath<Item, ID>,
        selection: Binding<ID?>,
        style: Style = .fill,
        onSelectionChange: ((ID) -> Void)? = nil,
        @ViewBuilder card: @escaping (_ item: Item, _ isSelected: Bool, _ select: @escaping () -> Void) -> Card
    ) {
        self.items = items
        self.id = id
        self._selection = selection
        self.style = style
        self.onSelectionChange = onSelectionChange
        self.card = card
    }

    public var body: some View {
        switch style {
        case .fill: fillRow
        case .centered(let width): centeredRow(width: width)
        }
    }

    /// `.fill`: full-width cards; the selection follows the centre during a drag (5.2.0), and
    /// where the row settles is the backstop.
    private var fillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SnapCardPickerMetrics.cardSpacing) {
                ForEach(items, id: id) { item in
                    let itemID = item[keyPath: id]
                    card(item, selection == itemID) {
                        guard selection != itemID else { return }
                        selection = itemID
                        onSelectionChange?(itemID)
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(itemID)
                }
            }
            .padding(.vertical, AppSpacing.xs)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .contentMargins(.horizontal, SnapCardPickerMetrics.contentMargin, for: .scrollContent)
        .scrollClipDisabled()
        // The first alignment waits for a measured container (before it, cards are zero-wide
        // and the write is dropped); a tick later the cards have sized against it.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width
        } action: { _, containerWidth in
            guard containerWidth > 0 else { return }
            performInitialAlignment()
        }
        // Backstop: a scroll view sized on its first evaluation may never report a change.
        .onAppear {
            performInitialAlignment()
            syncScrollToSelected(animated: false)
        }
        .onChange(of: selection) { _, _ in
            syncScrollToSelected(animated: true)
        }
        // The items can change under the picker (a sibling picker filtered them): re-align only
        // when the selection fell out of the new list, so the user's view does not jump.
        .onChange(of: items.map { $0[keyPath: id] }) { _, newIDs in
            guard let selection, !newIDs.contains(selection) else { return }
            syncScrollToSelected(animated: false)
        }
        // A drag selects the card at the centre as it passes (5.2.0, as `.centered` does). An
        // animated scroll (a tap, a new selection) passes over other cards, so the position
        // counts only while the person moves the row; where it settles is the backstop.
        .onScrollPhaseChange { _, newPhase in
            isScrolledByHand = newPhase == .tracking || newPhase == .interacting || newPhase == .decelerating
            guard newPhase == .idle,
                  let landed = scrollPosition,
                  landed != selection
            else { return }
            selection = landed
            onSelectionChange?(landed)
        }
        .onChange(of: scrollPosition) { _, centred in
            guard isScrolledByHand, let centred, centred != selection else { return }
            selection = centred
            onSelectionChange?(centred)
        }
    }

    /// `.centered` (5.0.0, `PickerCarousel`'s row of 4.14.0 as it was): cards of one width, the
    /// scroll position bound to the selection itself, so the first layout stands on it and the
    /// selection follows the centre as the row scrolls; the side cards smaller and paler. The
    /// cards have their width before the row is measured, so the write the full-width cards lose
    /// does not happen here; the margins centre a card once the row's width is known.
    private func centeredRow(width: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SnapCardPickerMetrics.cardSpacing) {
                    ForEach(items, id: id) { item in
                        let itemID = item[keyPath: id]
                        card(item, selection == itemID) {
                            guard selection != itemID else { return }
                            withAnimation(AppAnimation.contentSpring) { selection = itemID }
                            onSelectionChange?(itemID)
                        }
                        .frame(width: width)
                        .id(itemID)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : SnapCardPickerMetrics.sideScale)
                                .opacity(phase.isIdentity ? 1 : SnapCardPickerMetrics.sideOpacity)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, max(0, (containerWidth - width) / 2), for: .scrollContent)
            // The cards' outline and shadow reach past the row (5.2.0: they were cut at the top and
            // bottom), as in `.fill`.
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selection, anchor: .center)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { measured in
                let isFirstMeasure = containerWidth == 0 && measured > 0
                containerWidth = measured
                // 6.0.0: the margins centre a card only once the row is measured, and a first
                // position taken before that can be lost when the cards overflow the row (an
                // OptionCardPicker opened on its first option). Put the selection back in the
                // middle then, a tick later, once the margins are in.
                guard isFirstMeasure, let selection else { return }
                DispatchQueue.main.async { proxy.scrollTo(selection, anchor: .center) }
            }
            // A drag moves the selection with the centre: tell the app as it lands on each card.
            .onScrollPhaseChange { _, newPhase in
                isScrolledByHand = newPhase == .tracking || newPhase == .interacting || newPhase == .decelerating
            }
            .onChange(of: selection) { _, newValue in
                guard isScrolledByHand, let newValue else { return }
                onSelectionChange?(newValue)
            }
        }
    }

    /// The one first `scrollPosition` write, a tick after the container is measured. Idempotent.
    private func performInitialAlignment() {
        guard !hasAlignedInitialScroll else { return }
        DispatchQueue.main.async {
            guard !hasAlignedInitialScroll else { return }
            hasAlignedInitialScroll = true
            if scrollPosition != selection {
                scrollPosition = selection
            }
        }
    }

    /// Scrolls to the selection; nothing until the first alignment happened.
    private func syncScrollToSelected(animated: Bool) {
        guard hasAlignedInitialScroll else { return }
        if animated {
            guard scrollPosition != selection else { return }
            withAnimation(AppAnimation.carouselScroll) {
                scrollPosition = selection
            }
        } else {
            DispatchQueue.main.async {
                guard scrollPosition != selection else { return }
                scrollPosition = selection
            }
        }
    }
}

public extension SnapCardPicker where Item: Identifiable, ID == Item.ID {
    /// Identifiable items.
    init(
        _ items: [Item],
        selection: Binding<ID?>,
        style: Style = .fill,
        onSelectionChange: ((ID) -> Void)? = nil,
        @ViewBuilder card: @escaping (_ item: Item, _ isSelected: Bool, _ select: @escaping () -> Void) -> Card
    ) {
        self.init(items, id: \.id, selection: selection, style: style, onSelectionChange: onSelectionChange, card: card)
    }
}

enum SnapCardPickerMetrics {
    /// Between two cards.
    static let cardSpacing: CGFloat = AppSpacing.md
    /// How much of a neighbour shows at the edge.
    static let neighborPeek: CGFloat = AppSpacing.lg
    /// The centred card's margin on each side.
    static var contentMargin: CGFloat { cardSpacing + neighborPeek }
    /// `.centered`: the cards beside the middle one (5.0.0, `PickerCarousel`'s in 4.14.0).
    static let sideScale: CGFloat = 0.9
    static let sideOpacity: Double = 0.75
}

// MARK: - Skeleton

/// Placeholder of a `SnapCardPicker`: the centred card's shape (pass the card's own skeleton), with
/// the picker's margins.
public struct SnapCardPickerSkeleton<Card: View>: View {
    let card: Card

    public init(@ViewBuilder card: () -> Card) {
        self.card = card()
    }

    public var body: some View {
        card
            .padding(.vertical, AppSpacing.xs)
            .padding(.horizontal, SnapCardPickerMetrics.contentMargin)
    }
}
