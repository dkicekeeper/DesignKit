//
//  BulkDeleteButton.swift
//  Tenra
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct BulkDeleteButton: View {
    let count: Int
    let action: () -> Void

    public init(count: Int, action: @escaping () -> Void) {
        self.count = count
        self.action = action
    }

    public var body: some View {
        Button(role: .destructive, action: {
            HapticManager.warning()
            action()
        }) {
            Text(String(format: String(localized: "bulk.deleteCount"), count))
                .font(AppTypography.bodyEmphasis)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.glassProminent)
        .tint(AppColors.destructive)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .screenPadding()
        .padding(.bottom, AppSpacing.lg)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
