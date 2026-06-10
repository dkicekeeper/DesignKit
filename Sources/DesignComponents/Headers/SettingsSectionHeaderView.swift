//
//  SettingsSectionHeaderView.swift
//  Tenra
//
//  Created on 2026-02-04
//  Settings Refactoring Phase 3 - UI Components
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Props-based section header for Settings
/// Single Responsibility: Display section header with consistent styling
public struct SettingsSectionHeaderView: View {
    // MARK: - Props

    let title: String

    public init(title: String) {
        self.title = title
    }

    // MARK: - Body

    public var body: some View {
        Text(title)
            .font(AppTypography.bodySmall)
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
    }
}

// MARK: - Preview

