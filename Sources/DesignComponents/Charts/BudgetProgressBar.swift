//
//  BudgetProgressBar.swift
//  Tenra
//
//  Reusable horizontal budget progress bar with over-budget state.
//  Extracted from InsightsCardView and InsightDetailView (Phase 26).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Horizontal progress bar for budget utilisation.
///
/// Visual model:
/// - `percentage ≤ 100` → single segment in `color`, width = `percentage / 100` of bar.
/// - `percentage > 100` → bar fills full width split into two segments:
///   the leading `100 / percentage` portion in `color` (the original budget),
///   the trailing `(percentage - 100) / percentage` portion in `AppColors.destructive`
///   (the overshoot). Higher overshoot ⇒ larger red zone, so magnitude is visible
///   instead of a flat 100 % red bar at any percentage above 100.
///
/// - Parameter percentage: 0–100+ (raw, not clamped)
/// - Parameter isOverBudget: true → renders the destructive overshoot segment
/// - Parameter color: brand color for the category (the in-budget portion)
/// - Parameter height: bar height in points (default 8; InsightsCardView uses 6)
public struct BudgetProgressBar: View {
    let percentage: Double
    let isOverBudget: Bool
    let color: Color
    var height: CGFloat = 8

    public init(percentage: Double, isOverBudget: Bool, color: Color, height: CGFloat = 8) {
        self.percentage = percentage
        self.isOverBudget = isOverBudget
        self.color = color
        self.height = height
    }

    private var baseRatio: Double {
        if isOverBudget {
            return percentage > 0 ? min(100.0 / percentage, 1.0) : 0.0
        } else {
            return min(max(percentage, 0), 100) / 100.0
        }
    }

    private var overshootRatio: Double {
        guard isOverBudget, percentage > 100 else { return 0 }
        return 1.0 - min(100.0 / percentage, 1.0)
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppRadius.xs)
                .fill(AppColors.bgMuted)
                .frame(maxWidth: .infinity)
                .frame(height: height)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * baseRatio)
                    if overshootRatio > 0 {
                        Rectangle()
                            .fill(AppColors.destructive)
                            .frame(width: geo.size.width * overshootRatio)
                    }
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xs))
        }
        .animation(AppAnimation.gentleSpring, value: percentage)
        .animation(AppAnimation.gentleSpring, value: isOverBudget)
    }
}

// MARK: - Previews


