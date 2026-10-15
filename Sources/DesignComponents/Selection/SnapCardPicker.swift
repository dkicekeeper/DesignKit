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
/// `AppSpacing.md` between cards and `AppSpacing.lg` of the neighbours show. A drag selects the
/// card it settles on; a tap on a card calls `select`, which selects it and scrolls it to the
/// centre.
public struct SnapCardPicker<Item, ID: Hashable, Card: View>: View {
    /// How the cards stand in the row.
    public enum Style: Equatable, Sendable {
        /// Each card fills the row, the neighbours peeking in at the edges; the selection is the
        /// card a drag settles on (2.9.0): an account or a category in a form.
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
        // `.centered`'s cards have their width before the row is measured, so the first layout
        // can stand on the selection: the side cards are smaller and paler from the start (an
        // alignment after it left them full until the first scroll). `.fill`'s cards are
        // zero-wide until then, so it waits (`performInitialAlignment`).
        if case .centered = style {
            _scrollPosition = State(initialValue: selection.wrappedValue)
        }
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SnapCardPickerMetrics.cardSpacing) {
                ForEach(items, id: id) { item in
                    let itemID = item[keyPath: id]
                    sized(card(item, selection == itemID) {
                        guard selection != itemID else { return }
                        selection = itemID
                        onSelectionChange?(itemID)
                    })
                    .id(itemID)
                }
            }
            // Room for the cards' shadows; the centred cards keep their own height.
            .padding(.vertical, style == .fill ? AppSpacing.xs : 0)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .contentMargins(.horizontal, margin, for: .scrollContent)
        .scrollClipDisabled(style == .fill)
        // The first alignment waits for a measured container (before it, cards are zero-wide
        // and the write is dropped); a tick later the cards have sized against it.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width
        } action: { _, width in
            containerWidth = width
            guard width > 0 else { return }
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
        // `.centered`: the selection follows the centre while the person moves the row, so what
        // a focused option shows changes as it passes.
        .onChange(of: scrollPosition) { _, position in
            guard case .centered = style, isScrolledByHand,
                  let position, position != selection
            else { return }
            selection = position
            onSelectionChange?(position)
        }
        // A drag selects where it settles; during an animated scroll the position passes over
        // other cards, so only the idle position counts.
        .onScrollPhaseChange { _, newPhase in
            isScrolledByHand = newPhase == .tracking || newPhase == .interacting || newPhase == .decelerating
            guard newPhase == .idle,
                  let landed = scrollPosition,
                  landed != selection
            else { return }
            selection = landed
            onSelectionChange?(landed)
        }
    }

    /// A card at its style's width: the row's, or `.centered`'s with the neighbours smaller and paler.
    @ViewBuilder
    private func sized(_ card: Card) -> some View {
        switch style {
        case .fill:
            card.containerRelativeFrame(.horizontal)
        case .centered(let width):
            card
                .frame(width: width)
                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : SnapCardPickerMetrics.sideScale)
                        .opacity(phase.isIdentity ? 1 : SnapCardPickerMetrics.sideOpacity)
                }
        }
    }

    /// The row's margin on each side: the neighbours' peek, or what centres a `.centered` card.
    private var margin: CGFloat {
        switch style {
        case .fill: SnapCardPickerMetrics.contentMargin
        case .centered(let width): max(0, (containerWidth - width) / 2)
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
