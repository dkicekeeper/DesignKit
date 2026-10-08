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
/// Each card fills the row's width (`containerRelativeFrame`); `AppSpacing.md` between cards and
/// `AppSpacing.lg` of the neighbours show. A drag selects the card it settles on; a tap on a card
/// calls `select`, which selects it and scrolls it to the centre.
public struct SnapCardPicker<Item, ID: Hashable, Card: View>: View {
    let items: [Item]
    let id: KeyPath<Item, ID>
    @Binding var selection: ID?
    let onSelectionChange: ((ID) -> Void)?
    let card: (Item, Bool, @escaping () -> Void) -> Card

    @State private var scrollPosition: ID?
    /// `false` until the scroll view has a measured container and the first position is written.
    @State private var hasAlignedInitialScroll = false

    /// - Parameters:
    ///   - onSelectionChange: Called when a tap or a drag picks another item.
    ///   - card: The card for an item, whether it is selected, and the action that selects it.
    public init(
        _ items: [Item],
        id: KeyPath<Item, ID>,
        selection: Binding<ID?>,
        onSelectionChange: ((ID) -> Void)? = nil,
        @ViewBuilder card: @escaping (_ item: Item, _ isSelected: Bool, _ select: @escaping () -> Void) -> Card
    ) {
        self.items = items
        self.id = id
        self._selection = selection
        self.onSelectionChange = onSelectionChange
        self.card = card
    }

    public var body: some View {
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
        // A drag selects where it settles; during an animated scroll the position passes over
        // other cards, so only the idle position counts.
        .onScrollPhaseChange { _, newPhase in
            guard newPhase == .idle,
                  let landed = scrollPosition,
                  landed != selection
            else { return }
            selection = landed
            onSelectionChange?(landed)
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
        onSelectionChange: ((ID) -> Void)? = nil,
        @ViewBuilder card: @escaping (_ item: Item, _ isSelected: Bool, _ select: @escaping () -> Void) -> Card
    ) {
        self.init(items, id: \.id, selection: selection, onSelectionChange: onSelectionChange, card: card)
    }
}

enum SnapCardPickerMetrics {
    /// Between two cards.
    static let cardSpacing: CGFloat = AppSpacing.md
    /// How much of a neighbour shows at the edge.
    static let neighborPeek: CGFloat = AppSpacing.lg
    /// The centred card's margin on each side.
    static var contentMargin: CGFloat { cardSpacing + neighborPeek }
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
