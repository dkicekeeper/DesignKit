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
        // 5.2.0: "archive.circle.fill" is no symbol, the badge drew nothing.
        case .archived: return "archivebox.circle.fill"
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
/// StatusIndicatorBadge(status: .active)
/// StatusIndicatorBadge(status: .paused, size: AppIconSize.lg)
/// ```
public struct StatusIndicatorBadge: View {
    let status: EntityStatus

    /// The symbol's size (7.0.0: an `Icon`).
    let size: CGFloat

    /// - Parameter size: The symbol's size, `AppIconSize.md` by default.
    public init(status: EntityStatus, size: CGFloat = AppIconSize.md) {
        self.status = status
        self.size = size
    }

    public var body: some View {
        Icon(status.iconName, size: size, tint: .monochrome(status.tintColor))
            // A symbol that says something: its own element, with the status as its label.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(status.accessibilityLabel)
    }
}

// The domain bridge (`RecurringSeries.entityStatus`) stays in the host app.

// MARK: - Skeleton

/// Placeholder of a `StatusIndicatorBadge`: a circle the size of its symbol.
public struct StatusIndicatorBadgeSkeleton: View {
    let size: CGFloat

    public init(size: CGFloat = AppIconSize.md) {
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(Skeleton.fill)
            .frame(width: size, height: size)
            .shimmer()
            .skeletonLoadingLabel()
    }
}
