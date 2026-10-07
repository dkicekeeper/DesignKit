//
//  ImportProgressSheet.swift
//  Tenra
//
//  Created on 2026-02-04
//  Settings Refactoring Phase 3 - UI Components
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Props-based import progress sheet for Settings
/// Single Responsibility: Display import progress with cancellation
public struct ImportProgressSheet: View {
    public init(
        currentRow: Int,
        totalRows: Int,
        progress: Double,
        onCancel: @escaping () -> Void
    ) {
        self.currentRow = currentRow
        self.totalRows = totalRows
        self.progress = progress
        self.onCancel = onCancel
    }

    // MARK: - Props

    let currentRow: Int
    let totalRows: Int
    let progress: Double
    let onCancel: () -> Void

    // MARK: - Body

    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text(String(localized: "progress.importing"))
                .font(AppTypography.h4)
                .foregroundStyle(AppColors.Text.primary)

            VStack(spacing: AppSpacing.sm) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(AppColors.accent)
                    .scaleEffect(y: 2.0)

                HStack {
                    Text("\(currentRow) / \(totalRows)")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.primary)
                        .fontWeight(.semibold)
                }
            }

            Button(String(localized: "button.cancel")) {
                onCancel()
            }
            .buttonStyle(.bordered)
            .tint(AppColors.destructive)
        }
        .padding(AppSpacing.xxl)
        .interactiveDismissDisabled()
    }
}

// MARK: - Preview

