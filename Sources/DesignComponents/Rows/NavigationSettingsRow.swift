//
//  NavigationSettingsRow.swift
//  Tenra
//
//  Created on 2026-02-04
//  Settings Refactoring Phase 3 - UI Components
//  Migrated to UniversalRow architecture - 2026-02-16
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Props-based navigation row for Settings
/// Single Responsibility: Display navigation link with icon and title
/// Now built on top of UniversalRow for consistency
///
/// 5.0.0: `value:`, what is set, before the list's chevron ("Language  English ›"), and the icon
/// may be left out; `NavigationPickerRow(style: .list)` is this row.
public struct NavigationSettingsRow<Destination: View>: View {
    // MARK: - Props

    let icon: String?
    let title: String
    let value: String?
    let iconColor: Color
    let destination: Destination

    // MARK: - Initializer

    /// - Parameters:
    ///   - icon: An SF Symbol before the title; none leaves the room out (5.0.0).
    ///   - value: What is set, in the small grey type before the chevron (5.0.0).
    public init(
        icon: String?,
        title: String,
        value: String? = nil,
        iconColor: Color = AppColors.accent,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.iconColor = iconColor
        self.destination = destination()
    }

    // MARK: - Body

    public var body: some View {
        UniversalRow(
            config: .settings,
            leadingIcon: icon.map { .sfSymbol($0, color: iconColor, size: AppIconSize.md) },
            title: title
        ) {
            // The NavigationLink adds the chevron after it.
            if let value {
                Text(value)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
                    .lineLimit(1)
            }
        }
        .navigationRow {
            destination
        }
    }
}

// MARK: - Preview

