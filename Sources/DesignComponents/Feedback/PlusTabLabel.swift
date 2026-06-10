//
//  PlusTabLabel.swift
//  Tenra
//
//  Custom label for the action tab (+/×).
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct PlusTabLabel: View {
    let isExpanded: Bool

    public init(isExpanded: Bool) {
        self.isExpanded = isExpanded
    }

    public var body: some View {
        Label(
            isExpanded ? String(localized: "tab.close") : String(localized: "tab.add"),
            systemImage: isExpanded ? "xmark" : "plus"
        )
    }
}
