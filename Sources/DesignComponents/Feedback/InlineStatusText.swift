//
//  InlineStatusText.swift
//  Tenra
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Inline static status text for form validation and persistent hints.
/// Use this instead of MessageBanner for non-transient messages embedded in content flow.
public struct InlineStatusText: View {
    let message: String
    let type: StatusType

    public init(message: String, type: StatusType) {
        self.message = message
        self.type = type
    }

    public enum StatusType {
        case error
        case warning
        case info
        case success

        var color: Color {
            switch self {
            case .error:   return AppColors.destructive
            case .warning: return AppColors.warning
            case .info:    return AppColors.accent
            case .success: return AppColors.success
            }
        }
    }

    public var body: some View {
        Text(message)
            .font(AppTypography.caption)
            .foregroundStyle(type.color)
    }
}
