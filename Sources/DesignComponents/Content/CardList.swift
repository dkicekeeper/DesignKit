//
//  CardList.swift
//  DesignKit
//
//  8.0.0 (the owner's review of the app's screens): one way to show a list of things a person
//  keeps (accounts, deposits, loans, categories, trips, gear), with one set of actions on all of
//  them: open, select several and delete them, change their order by dragging. A card per item,
//  or every item a row in one card. Built on a lazy stack, so the cards are Liquid Glass like
//  the rest of the app (a system List draws its own grouped rows).
//  What an item is, what opening it shows and what deleting it does stay in the app.
//

import SwiftUI
import UniformTypeIdentifiers
import DesignTokens
import DesignSupport

/// How the items of a `CardList` sit (8.0.0).
public enum CardListLayout: Hashable, Sendable {
    /// A glass card per item, its content padded on every side (a loan, a goal, a trip).
    case cards
    /// Every item a row in one glass card, a divider under each row's text (subcategories, a
    /// short list of options).
    case section
    /// Every item a card of its own already (a `PayoffProgressCard`, a `RecurringPaymentCard`):
    /// the list spaces them, and the circle and the handle of the modes sit beside the card.
    case stack
}

/// What a `CardList` is doing (8.0.0).
public enum CardListMode: Hashable, Sendable {
    /// The items as they are: a tap opens one, a long press shows its menu.
    case browsing
    /// A circle on every item; a tap picks it or leaves it.
    case selecting
    /// A handle on every item; dragging one moves it.
    case reordering
}

/// A list of items on Liquid Glass (8.0.0): a card per item (`.cards`), every item a row
/// in one card with a divider under each row's text (`.section`), or items that are cards
/// already (`.stack`). In `.selecting` a tap picks an
/// item; in `.reordering` an item is dragged to its place (VoiceOver: move up, move down), and
/// `onMove` gets the move as `List`'s `onMove` does.
///
/// ```swift
/// CardList(accounts, mode: mode, selection: $selection, onMove: moveAccounts) { account in
///     NavigationLink(value: account) { AccountCard(account) }
///         .contextMenu { … }
/// }
/// .cardListToolbar(mode: $mode, selection: $selection, allIDs: accounts.map(\.id),
///                  addLabel: "New account", onAdd: addAccount, onDeleteSelected: confirmDelete)
/// ```
public struct CardList<Data: RandomAccessCollection, Card: View>: View where Data.Element: Identifiable {
    let data: Data
    let layout: CardListLayout
    let mode: CardListMode
    @Binding var selection: Set<Data.Element.ID>
    let onMove: ((IndexSet, Int) -> Void)?
    let card: (Data.Element) -> Card

    @State private var dragging: Data.Element.ID?

    /// - Parameters:
    ///   - mode: What the list is doing; the app keeps it (`cardListToolbar` switches it).
    ///   - selection: The picked items in `.selecting`.
    ///   - onMove: Moves items as `List`'s `onMove` does; `nil` when the order is fixed.
    ///   - card: An item's content. In `.browsing` it is the item as it is (a `NavigationLink`, a
    ///     context menu); in the other modes the list takes its taps.
    public init(
        _ data: Data,
        layout: CardListLayout = .cards,
        mode: CardListMode = .browsing,
        selection: Binding<Set<Data.Element.ID>> = .constant([]),
        onMove: ((IndexSet, Int) -> Void)? = nil,
        @ViewBuilder card: @escaping (Data.Element) -> Card
    ) {
        self.data = data
        self.layout = layout
        self.mode = mode
        self._selection = selection
        self.onMove = onMove
        self.card = card
    }

    private var ids: [Data.Element.ID] { data.map(\.id) }

    public var body: some View {
        switch layout {
        case .cards:
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(data) { item in
                    entry(item)
                        .padding(AppSpacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                        .modifier(reorderable(item))
                }
            }
        case .stack:
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(data) { item in
                    entry(item)
                        .modifier(reorderable(item))
                }
            }
        case .section:
            // Each row draws the divider under itself. Splitting the whole list into rows
            // (`DividedRows`) rebuilt every row on a move, and a drag stopped after the first
            // step (the owner's device check of 8.0.0's probe); here a row keeps its identity
            // while it moves, as a card does.
            VStack(spacing: 0) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    SectionRow(showsDivider: index < data.count - 1) {
                        entry(item)
                    }
                    .modifier(reorderable(item))
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    // MARK: - An item in a mode

    @ViewBuilder
    private func entry(_ item: Data.Element) -> some View {
        switch mode {
        case .browsing:
            card(item)
        case .selecting:
            let isSelected = selection.contains(item.id)
            CardListEntry(leading: AppIconSize.lg + AppSpacing.md) {
                SelectionIndicator(isSelected: isSelected)
            } content: {
                card(item).allowsHitTesting(false)
            } trailing: {
                EmptyView()
            }
            .selectableRow(isSelected: isSelected) {
                HapticManager.selection()
                if isSelected {
                    selection.remove(item.id)
                } else {
                    selection.insert(item.id)
                }
            }
        case .reordering:
            CardListEntry(leading: 0) {
                EmptyView()
            } content: {
                card(item).allowsHitTesting(false)
            } trailing: {
                Icon("line.3.horizontal", size: AppIconSize.lg)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        }
    }

    private func reorderable(_ item: Data.Element) -> CardReorderModifier<Data.Element.ID> {
        CardReorderModifier(
            id: item.id,
            ids: ids,
            isEnabled: mode == .reordering && onMove != nil,
            dragging: $dragging,
            onMove: onMove ?? { _, _ in }
        )
    }
}

/// A row of a `.section` list with the divider under it, under the row's text.
private struct SectionRow<Content: View>: View {
    let showsDivider: Bool
    @ViewBuilder let content: Content

    var body: some View {
        Group(subviews: content) { parts in
            let inset = parts.first?.containerValues.rowDividerInset ?? 0
            VStack(spacing: 0) {
                ForEach(parts) { $0 }
                if showsDivider {
                    RowDivider(inset: inset)
                }
            }
        }
    }
}

/// An item with what a mode puts around it: the card's own divider inset is kept and moved by
/// what comes before it.
private struct CardListEntry<Leading: View, Content: View, Trailing: View>: View {
    let leading: CGFloat
    @ViewBuilder let leadingView: Leading
    @ViewBuilder let content: Content
    @ViewBuilder let trailing: Trailing

    init(
        leading: CGFloat,
        @ViewBuilder _ leadingView: () -> Leading,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading
        self.leadingView = leadingView()
        self.content = content()
        self.trailing = trailing()
    }

    var body: some View {
        Group(subviews: content) { parts in
            let inset = parts.first?.containerValues.rowDividerInset ?? 0
            HStack(spacing: AppSpacing.md) {
                leadingView
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(parts) { $0 }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            .rowDividerInset(inset + leading)
        }
    }
}

/// Drag to reorder (8.0.0): a long press lifts the item, moving it over another puts it there.
/// VoiceOver moves it up or down.
private struct CardReorderModifier<ID: Hashable>: ViewModifier {
    let id: ID
    let ids: [ID]
    let isEnabled: Bool
    @Binding var dragging: ID?
    let onMove: (IndexSet, Int) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled, let index = ids.firstIndex(of: id) {
            content
                // The whole item takes the drop: a row of a section has no background, and its
                // content takes no taps while reordering, so only the handle did.
                .contentShape(Rectangle())
                .contentShape(.dragPreview, .rect(cornerRadius: AppRadius.xl))
                .onDrag {
                    dragging = id
                    return NSItemProvider(object: "\(index)" as NSString)
                }
                .onDrop(of: [.text], delegate: CardReorderDropDelegate(
                    target: id, ids: ids, dragging: $dragging, onMove: onMove
                ))
                .accessibilityAction(named: Text(String(localized: "bulk.moveUp"))) {
                    guard index > 0 else { return }
                    onMove(IndexSet(integer: index), index - 1)
                }
                .accessibilityAction(named: Text(String(localized: "bulk.moveDown"))) {
                    guard index < ids.count - 1 else { return }
                    onMove(IndexSet(integer: index), index + 2)
                }
        } else {
            content
        }
    }
}

private struct CardReorderDropDelegate<ID: Hashable>: DropDelegate {
    let target: ID
    let ids: [ID]
    @Binding var dragging: ID?
    let onMove: (IndexSet, Int) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = ids.firstIndex(of: dragging),
              let to = ids.firstIndex(of: target) else { return }
        HapticManager.selection()
        withAnimation(AppAnimation.contentSpring) {
            onMove(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

// MARK: - Toolbar

public extension View {
    /// The toolbar of a `CardList` screen (8.0.0), the same on every list:
    /// - browsing: select, change the order (when `canReorder` and there are two items or
    ///   more) and add (when `onAdd` is given);
    /// - selecting: done, select all or none, and "Delete N" under the list while something
    ///   is picked;
    /// - reordering: done.
    ///
    /// `onDeleteSelected` runs when "Delete N" is tapped: the app asks to confirm and deletes.
    func cardListToolbar<ID: Hashable>(
        mode: Binding<CardListMode>,
        selection: Binding<Set<ID>>,
        allIDs: [ID],
        canReorder: Bool = true,
        addLabel: String? = nil,
        onAdd: (() -> Void)? = nil,
        onDeleteSelected: @escaping () -> Void
    ) -> some View {
        modifier(CardListToolbar(
            mode: mode,
            selection: selection,
            allIDs: allIDs,
            canReorder: canReorder,
            addLabel: addLabel,
            onAdd: onAdd,
            onDeleteSelected: onDeleteSelected
        ))
    }
}

private struct CardListToolbar<ID: Hashable>: ViewModifier {
    @Binding var mode: CardListMode
    @Binding var selection: Set<ID>
    let allIDs: [ID]
    let canReorder: Bool
    let addLabel: String?
    let onAdd: (() -> Void)?
    let onDeleteSelected: () -> Void

    private func switchMode(_ new: CardListMode) {
        HapticManager.light()
        withAnimation(AppAnimation.contentSpring) {
            mode = new
            selection.removeAll()
        }
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                // A system bar's items: iOS draws their symbols (7.0.0, outside the Icon rule).
                if mode == .browsing {
                    if !allIDs.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                switchMode(.selecting)
                            } label: {
                                Image(systemName: "checkmark.circle")
                            }
                            .accessibilityLabel(String(localized: "bulk.select"))
                        }
                    }
                    if canReorder && allIDs.count > 1 {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                switchMode(.reordering)
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .accessibilityLabel(String(localized: "bulk.reorder"))
                        }
                    }
                    if let onAdd {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                HapticManager.light()
                                onAdd()
                            } label: {
                                Image(systemName: "plus")
                            }
                            .dsButton()
                            .accessibilityLabel(addLabel ?? String(localized: "bulk.add"))
                        }
                    }
                } else if mode == .selecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            HapticManager.selection()
                            if selection.count == allIDs.count {
                                selection.removeAll()
                            } else {
                                selection = Set(allIDs)
                            }
                        } label: {
                            Text(selection.count == allIDs.count
                                 ? String(localized: "bulk.deselectAll")
                                 : String(localized: "bulk.selectAll"))
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            switchMode(.browsing)
                        } label: {
                            Text(String(localized: "bulk.done"))
                        }
                        .dsButton()
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            switchMode(.browsing)
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .dsButton()
                        .accessibilityLabel(String(localized: "bulk.done"))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if mode == .selecting && !selection.isEmpty {
                    DSButton(
                        String(format: String(localized: "bulk.deleteCount"), selection.count),
                        role: .destructive,
                        shape: .capsule,
                        fullWidth: true,
                        action: onDeleteSelected
                    )
                    .screenPadding()
                    .padding(.bottom, AppSpacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(AppAnimation.contentSpring, value: selection.isEmpty)
    }
}

// MARK: - Skeleton

/// Placeholder of a `CardList` (8.0.0): its cards, or its one card of rows, with grey rows of
/// an icon, a title and a value.
public struct CardListSkeleton: View {
    let layout: CardListLayout
    let count: Int

    public init(layout: CardListLayout = .cards, count: Int = 3) {
        self.layout = layout
        self.count = count
    }

    public var body: some View {
        Group {
            switch layout {
            case .cards, .stack:
                VStack(spacing: AppSpacing.md) {
                    ForEach(0..<count, id: \.self) { _ in
                        row
                            .padding(AppSpacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    }
                }
            case .section:
                DividedRows {
                    ForEach(0..<count, id: \.self) { _ in
                        row.rowDividerInset(AppIconSize.Tile.sm + AppSpacing.md)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }

    private var row: some View {
        UniversalRowSkeleton(config: .standard, iconStyle: .circle(size: AppIconSize.Tile.sm), trailing: .value)
    }
}
