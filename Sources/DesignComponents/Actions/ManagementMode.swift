//
//  ManagementMode.swift
//  Tenra
//
//  8.0.0: deprecated. `CardList` takes the same three modes (`CardListMode`) and draws them
//  itself, with `cardListToolbar` for the buttons; a `List` in edit mode is no longer how a
//  list of things is managed.
//

import SwiftUI
import DesignTokens
import DesignSupport

@available(*, deprecated, message: "One set of actions on every list since 8.0.0: use CardList with CardListMode and .cardListToolbar.")
public enum ManagementMode: Equatable {
    case normal
    case selecting
    case reordering

    /// Only reordering needs the system edit mode (it draws the iOS 26 drag handles).
    ///
    /// Selecting deliberately stays `.inactive`: the management rows are `Button`-rooted,
    /// so `List(selection:)` never received their taps — edit mode only produced a list
    /// that looked selectable and was not. Bulk selection is driven by the row action and
    /// shown by `SelectionIndicator` instead.
    public var editMode: EditMode {
        switch self {
        case .normal, .selecting: return .inactive
        case .reordering: return .active
        }
    }

    public var isSelecting: Bool { self == .selecting }
    public var isReordering: Bool { self == .reordering }
}
