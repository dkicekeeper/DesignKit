//
//  TargetProgressCard.swift
//  DesignKit
//
//  One metric measured against a target: icon, title and a badge, a summary line, the current
//  value next to the target, a progress bar, an explanation and a recommendation. Ported from
//  Tenra's HealthComponentCard; the health components (their copy, weights and targets) stay in
//  Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Savings rate · Weight 30%", "Current 10.0% ……… Target 20% or more", a bar at 50%, then a
/// note and a recommendation box.
///
/// ```swift
/// TargetProgressCard(
///     systemImage: "banknote.fill",
///     color: AppColors.success,
///     title: "Savings rate",
///     badge: "Weight 30%",
///     summary: "Score 50 of 100",
///     currentLabel: "Current", currentValue: "10.0%",
///     targetLabel: "Target", targetValue: "20% or more",
///     progress: 0.5,
///     explanation: "The share of income left after expenses.",
///     recommendation: "Cut expenses by about 60 000 ₸ a month to reach 20%."
/// )
/// ```
public struct TargetProgressCard: View {
    let systemImage: String
    let color: Color
    let title: String
    let badge: String?
    let summary: String?
    let currentLabel: String
    let currentValue: String
    let targetLabel: String
    let targetValue: String
    let progress: Double
    let progressColor: Color?
    let explanation: String?
    let recommendation: String?
    let isMuted: Bool

    /// - Parameters:
    ///   - color: Tints the icon and the recommendation box.
    ///   - badge: A grey capsule on the trailing edge of the header ("Weight 30%").
    ///   - summary: A line under the header ("Score 50 of 100").
    ///   - progress: 0…1, the share of the target reached.
    ///   - progressColor: The bar's colour; by default red below a third, amber below two
    ///     thirds, green from there.
    ///   - isMuted: Dims the card (the metric is switched off or has no data).
    public init(
        systemImage: String,
        color: Color,
        title: String,
        badge: String? = nil,
        summary: String? = nil,
        currentLabel: String,
        currentValue: String,
        targetLabel: String,
        targetValue: String,
        progress: Double,
        progressColor: Color? = nil,
        explanation: String? = nil,
        recommendation: String? = nil,
        isMuted: Bool = false
    ) {
        self.systemImage = systemImage
        self.color = color
        self.title = title
        self.badge = badge
        self.summary = summary
        self.currentLabel = currentLabel
        self.currentValue = currentValue
        self.targetLabel = targetLabel
        self.targetValue = targetValue
        self.progress = progress
        self.progressColor = progressColor
        self.explanation = explanation
        self.recommendation = recommendation
        self.isMuted = isMuted
    }

    private var barColor: Color {
        if let progressColor { return progressColor }
        switch progress {
        case ..<0.33: return AppColors.destructive
        case ..<0.66: return AppColors.warning
        default:      return AppColors.success
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            headerRow
            if let summary {
                Text(summary)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            valueRow
            LinearProgressBar(
                percentage: progress * 100,
                isOverBudget: false,
                color: barColor
            )
            if let explanation {
                Text(explanation)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let recommendation {
                RecommendationBox(text: recommendation, color: color)
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
        .opacity(isMuted ? 0.6 : 1.0)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.md))
                .foregroundStyle(color)
                .frame(width: 28)

            Text(title)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            if let badge {
                Text(badge)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.pale(AppColors.textSecondary))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Current vs Target

    private var valueRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(currentLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                Text(currentValue)
                    .font(AppTypography.h2.bold())
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(targetLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                Text(targetValue)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
