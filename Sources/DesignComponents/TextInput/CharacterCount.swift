//
//  CharacterCount.swift
//  DesignKit
//
//  The "980/1000" under a field with a length limit (4.1.0, benchmark round 3: M3, Fluent,
//  Carbon, Polaris and Atlassian fields count characters). `MessageComposer(limit:)` and
//  `FormTextField(limit:)` show it from 80% of the limit; over it, in the destructive colour.
//

import SwiftUI
import DesignTokens

/// "count/limit", shown once the text reaches 80% of the limit.
struct CharacterCount: View {
    let count: Int
    let limit: Int

    /// The share of the limit from which the count shows.
    static let threshold = 0.8

    static func isVisible(count: Int, limit: Int) -> Bool {
        limit > 0 && Double(count) >= Double(limit) * threshold
    }

    static func isOver(count: Int, limit: Int) -> Bool {
        limit > 0 && count > limit
    }

    var body: some View {
        Text(verbatim: "\(count)/\(limit)")
            .font(AppTypography.caption)
            .monospacedDigit()
            .foregroundStyle(Self.isOver(count: count, limit: limit) ? AppColors.destructive : AppColors.Text.secondary)
            .contentTransition(.numericText())
            .accessibilityLabel(Text(String(localized: "textInput.characterCount",
                                            defaultValue: "\(count) of \(limit) characters")))
    }
}
