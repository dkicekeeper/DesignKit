//
//  PayoffProgressCard.swift
//  DesignKit
//
//  Something being paid off (a loan, an instalment plan, a pledge): icon, name and a subtitle
//  with an accessory on the right, what is left of the total over a progress bar, and the next
//  payment with the count left, or a "done" line once it is repaid. Ported from Tenra's
//  LoanCard; the loan model, its payment maths and LoanTypeBadge stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Car loan / Halyk Bank ……… [Credit]", "1 200 000 ₸ ……… 3 000 000 ₸" over a bar,
/// "📅 12 Nov 2026 ……… 18 left".
///
/// ```swift
/// PayoffProgressCard(
///     iconSource: .sfSymbol("car.fill"), title: "Car loan", subtitle: "Halyk Bank",
///     remaining: 1_200_000, total: 3_000_000, currency: "KZT", progress: 0.6,
///     phase: .inProgress(nextDate: "12 Nov 2026", remainingCaption: "18 left")
/// ) {
///     BadgeView("Credit")
/// }
/// ```
public struct PayoffProgressCard<Accessory: View>: View {
    /// The footer line.
    public enum Phase: Equatable {
        /// The next payment date (a calendar mark) and, on the trailing edge, what is left.
        case inProgress(nextDate: String?, remainingCaption: String?)
        /// Repaid: a check mark and a caption ("Closed 15 Jun 2026").
        case done(caption: String)
    }

    let iconSource: IconSource?
    let title: String
    let subtitle: String?
    let remaining: Double
    let total: Double
    let currency: String
    let progress: Double
    let phase: Phase
    let accessory: Accessory

    /// - Parameters:
    ///   - remaining: Left to pay, shown on the leading edge above the bar.
    ///   - total: The original amount, shown on the trailing edge.
    ///   - progress: 0…1, the share already paid.
    ///   - accessory: A view on the trailing edge of the header (a type or status badge).
    public init(
        iconSource: IconSource?,
        title: String,
        subtitle: String? = nil,
        remaining: Double,
        total: Double,
        currency: String,
        progress: Double,
        phase: Phase,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.iconSource = iconSource
        self.title = title
        self.subtitle = subtitle
        self.remaining = remaining
        self.total = total
        self.currency = currency
        self.progress = progress
        self.phase = phase
        self.accessory = accessory()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header: icon + name + subtitle + accessory
            HStack(alignment: .top) {
                IconView(source: iconSource, size: AppIconSize.xxl)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.h4)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer()

                accessory
            }

            // Progress
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    FormattedAmountText(
                        amount: remaining,
                        currency: currency,
                        fontSize: AppTypography.body,
                        fontWeight: .regular,
                        color: AppColors.textSecondary
                    )
                    Spacer()
                    FormattedAmountText(
                        amount: total,
                        currency: currency,
                        fontSize: AppTypography.body,
                        fontWeight: .regular,
                        color: AppColors.textSecondary
                    )
                }
                ProgressView(value: progress)
                    .tint(AppColors.income)
                    .accessibilityValue(String(format: "%.0f%%", progress * 100))
            }

            // Footer: next payment + what is left, or the "done" line.
            HStack {
                switch phase {
                case .done(let caption):
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.income)
                        Text(caption)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                case .inProgress(let nextDate, let remainingCaption):
                    if let nextDate {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "calendar")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(nextDate)
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    if let remainingCaption {
                        Text(remainingCaption)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }
}

public extension PayoffProgressCard where Accessory == EmptyView {
    /// A card with nothing on the trailing edge of the header.
    init(
        iconSource: IconSource?,
        title: String,
        subtitle: String? = nil,
        remaining: Double,
        total: Double,
        currency: String,
        progress: Double,
        phase: Phase
    ) {
        self.init(
            iconSource: iconSource, title: title, subtitle: subtitle,
            remaining: remaining, total: total, currency: currency,
            progress: progress, phase: phase
        ) { EmptyView() }
    }
}
