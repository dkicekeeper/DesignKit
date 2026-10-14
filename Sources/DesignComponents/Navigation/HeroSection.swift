//
//  HeroSection.swift
//  Tenra
//
//  Unified read-only hero section for entity-detail screens AND simpler
//  icon+title contexts (TransactionAddModal, TransactionEditView, InsightDeepDiveView).
//  - Amount / subtitle / progress / currency-conversion are all optional.
//  - Icon animates in with a spring scale-up on appear.
//  - For edit flows with bindings + IconPicker use `EditableHero` instead.
//  - Inside `.heroBackground(_:)` (4.5.0) its text is white; the subtitle is semibold there,
//    so it reads as large text on the colour.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct HeroSection<Accessory: View>: View {
    let icon: IconSource?
    let iconTint: IconTint?
    /// When `false` the icon block (and its progress ring) is omitted entirely — no
    /// placeholder container. Use when the icon is shown elsewhere (e.g. an orb centre).
    /// This differs from `icon: nil`, which intentionally renders a placeholder.
    let showsIcon: Bool
    let title: String
    let primaryAmount: Double?
    let primaryCurrency: String
    /// Colour for the primary amount; defaults to `AppColors.Text.secondary`.
    let primaryAmountColor: Color?
    /// Non-currency metric fallback (percent, count, composed strings) rendered
    /// in the amount slot's style when there is no `primaryAmount`/currency pair.
    let primaryText: String?
    let subtitle: String?
    let progress: ProgressConfig?
    let showBaseConversion: Bool
    let baseCurrency: String
    /// Optional centered accessory under the amount (e.g. a trend badge).
    @ViewBuilder private let accessory: () -> Accessory

    @State private var iconScale: CGFloat = AppAnimation.heroHiddenScale
    @State private var iconOpacity: Double = 0
    @Environment(\.heroTone) private var heroTone
    @Environment(\.heroOnPale) private var onPale

    private var onColor: Bool { heroTone == .onColor }
    /// The subtitle and the progress line: secondary on the page, white on colour, black on the
    /// pale gradient of light mode (4.5.1).
    private var secondaryColor: Color {
        onColor ? AppColors.Text.primaryOnDark : onPale ? AppColors.Text.primary : AppColors.Text.secondary
    }
    /// The amount and the metric: secondary on the page unless the app sets a colour; white on
    /// colour; black on the pale gradient (4.5.1).
    private var amountColor: Color {
        onColor ? AppColors.Text.primaryOnDark
            : primaryAmountColor ?? (onPale ? AppColors.Text.primary : AppColors.Text.secondary)
    }
    /// Semibold under the title on a gradient, so it reads there.
    private var subtitleFont: Font { onColor || onPale ? AppTypography.bodyEmphasis : AppTypography.body }

    public init(
        icon: IconSource?,
        title: String,
        iconTint: IconTint? = nil,
        showsIcon: Bool = true,
        primaryAmount: Double? = nil,
        primaryCurrency: String = "",
        primaryAmountColor: Color? = nil,
        primaryText: String? = nil,
        subtitle: String? = nil,
        progress: ProgressConfig? = nil,
        showBaseConversion: Bool = false,
        baseCurrency: String = "",
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.showsIcon = showsIcon
        self.title = title
        self.primaryAmount = primaryAmount
        self.primaryCurrency = primaryCurrency
        self.primaryAmountColor = primaryAmountColor
        self.primaryText = primaryText
        self.subtitle = subtitle
        self.progress = progress
        self.showBaseConversion = showBaseConversion
        self.baseCurrency = baseCurrency
        self.accessory = accessory
    }

    /// Diameter of the progress ring that wraps the hero icon.
    /// Icon is `AppIconSize.Tile.xxxl` (80pt); ring sits 6pt outside.
    /// (Computed, not `static let` — the type is generic, which bars stored statics.)
    private static var ringSize: CGFloat { HeroSectionMetrics.ringSize }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            if showsIcon {
                ZStack {
                    if let progress {
                        ProgressRing(
                            progress: progress.fraction,
                            size: Self.ringSize,
                            lineWidth: 4,
                            isOverBudget: progress.fraction > 1.0,
                            overrideColor: progress.color
                        )
                    }
                    Icon(source: icon, style: .glassHero(tint: iconTint ?? .original))
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .onAppear {
                    withAnimation(AppAnimation.heroEntranceAnimation) {
                        iconScale = 1.0
                        iconOpacity = 1.0
                    }
                }
            }

            VStack(alignment: .center, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.h1)
                    .foregroundStyle(onColor ? AnyShapeStyle(AppColors.Text.primaryOnDark) : AnyShapeStyle(.primary))
                    .multilineTextAlignment(.center)

                if let primaryAmount, !primaryCurrency.isEmpty {
                    FormattedAmountText(
                        amount: primaryAmount,
                        currency: primaryCurrency,
                        fontSize: AppTypography.h3,
                        color: amountColor
                    )

                    if showBaseConversion, !baseCurrency.isEmpty, primaryCurrency != baseCurrency {
                        ConvertedAmount(
                            amount: primaryAmount,
                            fromCurrency: primaryCurrency,
                            toCurrency: baseCurrency,
                            fontSize: AppTypography.h3,
                            color: onColor ? AppColors.Text.secondaryOnDark : AppColors.Text.secondary.opacity(0.7)
                        )
                    }
                } else if let primaryText {
                    // Non-currency metric (percent, count, composed string) —
                    // same visual slot/style as the amount.
                    Text(primaryText)
                        .font(AppTypography.h3)
                        .foregroundStyle(amountColor)
                        .multilineTextAlignment(.center)
                }

                accessory()
                    .padding(.top, AppSpacing.xs)

                if let subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundStyle(secondaryColor)
                        .padding(.top, AppSpacing.xs)
                }

                if let progress, let label = progress.label {
                    HStack(spacing: AppSpacing.xs) {
                        Text(label)
                        Text("·")
                        Text("\(Int((progress.fraction * 100).rounded()))%")
                    }
                    .font(subtitleFont)
                    .foregroundStyle(secondaryColor)
                    .padding(.top, AppSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Convenience init (no accessory)

public extension HeroSection where Accessory == EmptyView {
    /// Accessory-free init — keeps the dozens of existing call sites source-compatible.
    init(
        icon: IconSource?,
        title: String,
        iconTint: IconTint? = nil,
        showsIcon: Bool = true,
        primaryAmount: Double? = nil,
        primaryCurrency: String = "",
        primaryAmountColor: Color? = nil,
        primaryText: String? = nil,
        subtitle: String? = nil,
        progress: ProgressConfig? = nil,
        showBaseConversion: Bool = false,
        baseCurrency: String = ""
    ) {
        self.init(
            icon: icon,
            title: title,
            iconTint: iconTint,
            showsIcon: showsIcon,
            primaryAmount: primaryAmount,
            primaryCurrency: primaryCurrency,
            primaryAmountColor: primaryAmountColor,
            primaryText: primaryText,
            subtitle: subtitle,
            progress: progress,
            showBaseConversion: showBaseConversion,
            baseCurrency: baseCurrency,
            accessory: { EmptyView() }
        )
    }
}

/// Sizes `HeroSection` and its skeleton share.
enum HeroSectionMetrics {
    /// The progress ring around the hero icon.
    static let ringSize: CGFloat = AppIconSize.Tile.xxxl + 12
}

// MARK: - Skeleton

/// Placeholder of a `HeroSection`: the round glass icon (in its ring's track when the hero
/// shows progress), the title and the amount, centred.
public struct HeroSectionSkeleton: View {
    let showsIcon: Bool
    let showsProgress: Bool

    public init(showsIcon: Bool = true, showsProgress: Bool = false) {
        self.showsIcon = showsIcon
        self.showsProgress = showsProgress
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            if showsIcon {
                ZStack {
                    if showsProgress {
                        Circle()
                            .stroke(Skeleton.fill, lineWidth: 4)
                            .frame(width: HeroSectionMetrics.ringSize, height: HeroSectionMetrics.ringSize)
                    }
                    Skeleton.circle(AppIconSize.Tile.xxxl)
                }
            }
            VStack(spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h1, width: 180)
                SkeletonText(AppTypography.h3, width: 120)
            }
        }
        .frame(maxWidth: .infinity)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
