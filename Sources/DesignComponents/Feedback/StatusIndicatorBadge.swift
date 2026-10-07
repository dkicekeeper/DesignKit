//
//  StatusIndicatorBadge.swift
//  Tenra
//
//  Phase 33.2: Extracted from SubscriptionCard to be reusable across the app.
//  Shows a coloured SF Symbol icon for a given entity status.
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - EntityStatus

/// Unified status model for entities that have an active / paused / archived lifecycle.
/// Add new cases here as the domain grows — the badge adapts automatically.
public enum EntityStatus {
    case active
    case paused
    case archived
    case pending

    // MARK: Display

    public var iconName: String {
        switch self {
        case .active:   return "checkmark.circle.fill"
        case .paused:   return "pause.circle.fill"
        case .archived: return "archive.circle.fill"
        case .pending:  return "clock.badge.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .active:   return AppColors.success
        case .paused:   return AppColors.warning
        case .archived: return Color(.systemGray)
        case .pending:  return AppColors.accent
        }
    }

    public var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .active:   return "status.active"
        case .paused:   return "status.paused"
        case .archived: return "status.archived"
        case .pending:  return "status.pending"
        }
    }
}

// MARK: - StatusIndicatorBadge

/// A single SF Symbol icon that communicates entity status through colour and shape.
///
/// Use inside a row, card, or chip where you need a compact visual status signal.
///
/// ```swift
/// StatusIndicatorBadge(status: .active, font: AppTypography.h4)
/// StatusIndicatorBadge(status: .paused, iconSize: AppIconSize.md)
/// ```
public struct StatusIndicatorBadge: View {
    let status: EntityStatus

    /// Font size applied to the SF Symbol via `.font()`.
    /// Provide either `font` (semantic) or `iconSize` (explicit points), not both.
    var font: Font = AppTypography.h4

    public init(
        status: EntityStatus,
        font: Font = AppTypography.h4
    ) {
        self.status = status
        self.font = font
    }

    public var body: some View {
        Image(systemName: status.iconName)
            .font(font)
            .foregroundStyle(status.tintColor)
            .accessibilityLabel(status.accessibilityLabel)
    }
}

// The domain bridge (`RecurringSeries.entityStatus`) stays in the host app.

// MARK: - Skeleton

/// Placeholder of a `StatusIndicatorBadge`: a circle the size of its symbol.
public struct StatusIndicatorBadgeSkeleton: View {
    let font: Font

    public init(font: Font = AppTypography.body) {
        self.font = font
    }

    public var body: some View {
        // The symbol's own size, invisible, under a grey circle.
        Image(systemName: "circle.fill")
            .font(font)
            .hidden()
            .background(Skeleton.fill, in: Circle())
            .shimmer()
            .skeletonLoadingLabel()
    }
}
