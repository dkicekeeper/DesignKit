//
//  ActionSettingsRow.swift
//  Tenra
//
//  Created on 2026-02-04
//  Settings Refactoring Phase 3 - UI Components
//  Migrated to UniversalRow architecture - 2026-02-16
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Props-based action row for Settings
/// Single Responsibility: Display action button with icon, title, and optional destructive styling
/// Now built on top of UniversalRow for consistency
@available(*, deprecated, message: "Use UniversalRow(_:icon:role:config:accessory: .action(_:)) (6.2.0).")
public struct ActionSettingsRow: View {
    // MARK: - Props

    let icon: String?
    let title: String
    let iconColor: Color?
    let titleColor: Color?
    let isDestructive: Bool
    let config: RowConfiguration
    let action: () -> Void

    // MARK: - Initializer

    public init(
        icon: String? = nil,
        title: String,
        iconColor: Color? = nil,
        titleColor: Color? = nil,
        isDestructive: Bool = false,
        config: RowConfiguration = .settings,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.titleColor = titleColor
        self.isDestructive = isDestructive
        self.config = config
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        UniversalRow(
            title,
            icon: icon,
            iconColor: iconColor,
            role: isDestructive ? .destructive : .standard,
            titleColor: titleColor,
            config: config,
            accessory: .action(action)
        )
    }
}

// MARK: - Preview

