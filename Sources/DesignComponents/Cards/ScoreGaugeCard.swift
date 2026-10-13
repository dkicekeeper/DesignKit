//
//  ScoreGaugeCard.swift
//  DesignKit
//
//  A score on a fixed scale as a hero: a half-circle gauge with zone ticks, the score and a
//  grade capsule inside it, a line of text below. Ported from Tenra's HealthScoreHeroCard; the
//  health score model, its grade colour and the grade-band copy stay in Tenra as an adapter.
//  4.2.0: `style: .hero`, the top of a screen edge to edge: a gauge wider than the screen with a
//  knob, the score in display size, "/100", a trend capsule, on a gradient of its colour.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "72" and "Good" inside a 0–100 gauge, "You're on track" under it. `score == nil` shows "—"
/// over an empty gauge (not enough data yet).
///
/// ```swift
/// ScoreGaugeCard(score: 72, zoneTicks: [40, 70], grade: "Good",
///                color: AppColors.success, subtitle: "You're on track")
///
/// // The top of a screen, edge to edge (4.2.0)
/// ScoreGaugeCard(score: 84, zoneTicks: [40, 70], grade: "Excellent", color: AppColors.success,
///                subtitle: "Your financial health", style: .hero, showsMaximum: true,
///                trend: .init(direction: .up, changePercent: 17, caption: "than last month"))
/// ```
///
/// `.hero` is not a card: it fills the width (no `.screenPadding()`), its gauge runs out past
/// both edges (`HeroHalfGauge(style: .bleed)`) and, `.onColor`, it lies on a gradient of its
/// colour, a tone deeper so white text reads, that reaches up under the navigation bar and fades
/// into the page below the hero, where the cards that follow may rise over it.
public struct ScoreGaugeCard: View {
    /// Where the score sits (4.2.0).
    public enum Style: Hashable, Sendable {
        /// A glass card with a 220 pt half gauge, as before 4.2.0.
        case card
        /// The top of a screen, edge to edge: a gauge wider than the screen, the score in
        /// `AppTypography.display`, on a gradient of its colour (`.onColor`) or on the page.
        case hero
    }

    /// A change against an earlier score, shown in a capsule under the score (4.2.0):
    /// "↗ +17.0% than last month", or in the score's own units (4.3.0): "↗ +5 since last month".
    public struct Trend: Hashable, Sendable {
        public let direction: TrendBadge.Direction
        /// Signed percent; nil when the change is given as text, or not at all.
        public let changePercent: Double?
        /// The change as shown: "+17.0%" from `changePercent`, or the app's own ("+5").
        public let changeText: String?
        /// What the change is against ("than last month"); the app's own string.
        public let caption: String

        public init(direction: TrendBadge.Direction, changePercent: Double?, caption: String) {
            self.direction = direction
            self.changePercent = changePercent
            self.changeText = changePercent.map(TrendBadge.format)
            self.caption = caption
        }

        /// A change in the score's own units, formatted by the app (4.3.0): points of a score
        /// ("+5"), percentage points of a rate ("−1.6 pp").
        public init(direction: TrendBadge.Direction, change: String?, caption: String) {
            self.direction = direction
            self.changePercent = nil
            self.changeText = change
            self.caption = caption
        }
    }

    /// The score; nil before it can be computed.
    let value: Double?
    /// Digits after the decimal point (4.3.0; 0 for a whole score).
    let fractionDigits: Int
    /// Set small after the number, as "/100" is: "%" (4.3.0).
    let unit: String?
    /// An amount in this currency, in the app's amount format (4.5.0); `nil` for a number.
    let currency: String?
    /// A reference marked on the arc: an average, a budget (4.5.0).
    let norm: Double?
    let maxScore: Double
    let zoneTicks: [Double]
    let grade: String
    let color: Color
    let subtitle: String
    let decodesScore: Bool
    let style: Style
    let tone: HeroHalfGauge.Tone
    let showsMaximum: Bool
    let trend: Trend?
    let entranceDelay: Double

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - score: `nil` when it cannot be computed: the gauge stays empty and the number reads "—".
    ///   - maxScore: The end of the scale.
    ///   - zoneTicks: Zone boundaries marked on the arc (e.g. `[40, 70]`).
    ///   - color: Tints the arc, the number and the grade capsule.
    ///   - decodesScore: The number decodes itself as it appears and when it changes
    ///     (`ScrambleText`, 2.7.0).
    ///   - style: `.card` or `.hero` (4.2.0).
    ///   - tone: `.hero` only: on a gradient of `color` (`.onColor`, white text) or on the page
    ///     (`.onSurface`). The card is always on its glass.
    ///   - showsMaximum: "/100" after the score.
    ///   - trend: A capsule with the change against an earlier score.
    ///   - entranceDelay: Seconds before the gauge sweeps and the score appears (4.3.0): a screen
    ///     that opens with a zoom transition lets it finish first.
    public init(
        score: Int?,
        maxScore: Double = 100,
        zoneTicks: [Double] = [],
        grade: String,
        color: Color,
        subtitle: String,
        decodesScore: Bool = false,
        style: Style = .card,
        tone: HeroHalfGauge.Tone = .onColor,
        showsMaximum: Bool = false,
        trend: Trend? = nil,
        entranceDelay: Double = 0
    ) {
        self.init(value: score.map(Double.init), fractionDigits: 0, unit: nil, maxScore: maxScore,
                  zoneTicks: zoneTicks, grade: grade, color: color, subtitle: subtitle,
                  decodesScore: decodesScore, style: style, tone: tone, showsMaximum: showsMaximum,
                  trend: trend, entranceDelay: entranceDelay)
    }

    /// A score with a fraction and a unit (4.3.0): a rate, "12.4%" on a scale of `maxScore`.
    ///
    /// ```swift
    /// ScoreGaugeCard(value: 12.4, unit: "%", maxScore: 40, zoneTicks: [10, 20],
    ///                grade: "Below target", color: AppColors.warning,
    ///                subtitle: "Target: 20% of income", decodesScore: true, style: .hero)
    /// ```
    ///
    /// - Parameters:
    ///   - value: `nil` when it cannot be computed. Below 0 the gauge stays empty and the number
    ///     shows the sign; above `maxScore` the gauge is full.
    ///   - fractionDigits: Digits after the decimal point, in the app's locale ("12,4").
    ///   - unit: Set small after the number, as "/100" is.
    public init(
        value: Double?,
        fractionDigits: Int = 1,
        unit: String? = nil,
        maxScore: Double = 100,
        zoneTicks: [Double] = [],
        grade: String,
        color: Color,
        subtitle: String,
        decodesScore: Bool = false,
        style: Style = .card,
        tone: HeroHalfGauge.Tone = .onColor,
        showsMaximum: Bool = false,
        trend: Trend? = nil,
        entranceDelay: Double = 0
    ) {
        self.init(value: value, fractionDigits: fractionDigits, unit: unit, currency: nil, norm: nil,
                  maxScore: maxScore, zoneTicks: zoneTicks, grade: grade, color: color, subtitle: subtitle,
                  decodesScore: decodesScore, style: style, tone: tone, showsMaximum: showsMaximum,
                  trend: trend, entranceDelay: entranceDelay)
    }

    /// An amount (4.5.0): "84 900 ₸" in the app's amount format, hidden with the app's amounts
    /// (`\.amountsHidden`), on a scale of `maxValue`, with `norm` marked on the arc. A long
    /// amount shrinks to fit one line.
    ///
    /// ```swift
    /// // A large expense against the usual one
    /// ScoreGaugeCard(amount: 84_900, currency: "KZT", maxValue: 84_900 * 1.15, norm: 6_100,
    ///                grade: "14× the usual", color: AppColors.destructive,
    ///                subtitle: "Furniture, 3 Oct", style: .hero)
    /// ```
    ///
    /// - Parameters:
    ///   - amount: `nil` when it cannot be computed: the gauge stays empty and the amount reads "—".
    ///   - maxValue: The end of the scale.
    ///   - norm: A reference marked on the arc with a notch (an average, a budget).
    public init(
        amount: Double?,
        currency: String,
        maxValue: Double,
        norm: Double? = nil,
        zoneTicks: [Double] = [],
        grade: String,
        color: Color,
        subtitle: String,
        style: Style = .card,
        tone: HeroHalfGauge.Tone = .onColor,
        trend: Trend? = nil,
        entranceDelay: Double = 0
    ) {
        self.init(value: amount, fractionDigits: 0, unit: nil, currency: currency, norm: norm,
                  maxScore: maxValue, zoneTicks: zoneTicks, grade: grade, color: color, subtitle: subtitle,
                  decodesScore: false, style: style, tone: tone, showsMaximum: false,
                  trend: trend, entranceDelay: entranceDelay)
    }

    private init(
        value: Double?,
        fractionDigits: Int,
        unit: String?,
        currency: String?,
        norm: Double?,
        maxScore: Double,
        zoneTicks: [Double],
        grade: String,
        color: Color,
        subtitle: String,
        decodesScore: Bool,
        style: Style,
        tone: HeroHalfGauge.Tone,
        showsMaximum: Bool,
        trend: Trend?,
        entranceDelay: Double
    ) {
        self.value = value
        self.fractionDigits = max(0, fractionDigits)
        self.unit = unit
        self.currency = currency
        self.norm = norm
        self.maxScore = maxScore
        self.zoneTicks = zoneTicks
        self.grade = grade
        self.color = color
        self.subtitle = subtitle
        self.decodesScore = decodesScore
        self.style = style
        self.tone = tone
        self.showsMaximum = showsMaximum
        self.trend = trend
        self.entranceDelay = max(0, entranceDelay)
    }

    public var body: some View {
        switch style {
        case .card:
            card
        case .hero:
            hero
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack(alignment: .bottom) {
                HeroHalfGauge(
                    value: value ?? 0,
                    norm: norm,
                    maxValue: maxScore,
                    zoneTicks: zoneTicks,
                    color: color,
                    diameter: 220,
                    lineWidth: 16,
                    entranceDelay: entranceDelay
                )

                // Score + grade sit inside the semicircle's interior.
                VStack(spacing: AppSpacing.xs) {
                    scoreLine(font: AppTypography.h1.bold(), maximumFont: AppTypography.h4,
                              maximumColor: AppColors.Text.tertiary,
                              color: value != nil ? color : AppColors.Text.tertiary)
                        .materialize(delay: entranceDelay + 0.35)

                    Text(grade)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(color)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.pale(color))
                        .clipShape(Capsule())
                        .materialize(delay: entranceDelay + 0.45)

                    if let trend {
                        trendCapsule(trend, onColor: false)
                            .materialize(delay: entranceDelay + 0.5)
                    }
                }
            }

            Text(subtitle)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Hero

    private var onColor: Bool { tone == .onColor }

    private var hero: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack(alignment: .bottom) {
                HeroHalfGauge(
                    value: value ?? 0,
                    norm: norm,
                    maxValue: maxScore,
                    zoneTicks: zoneTicks,
                    color: color,
                    style: .bleed,
                    tone: tone,
                    lineWidth: ScoreHeroMetrics.lineWidth,
                    entranceDelay: entranceDelay
                )

                scoreLine(font: AppTypography.display, maximumFont: AppTypography.h3.weight(.regular),
                          maximumColor: onColor ? AppColors.Text.secondaryOnDark : AppColors.Text.tertiary,
                          color: heroScoreColor)
                    .screenPadding()
                    .materialize(delay: entranceDelay + 0.35)
            }

            // Side by side; one under the other at accessibility sizes (the 1.3.0 rule).
            capsuleLayout {
                Text(grade)
                    .font(AppTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : color)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .modifier(HeroCapsule(onColor: onColor, fill: AppColors.pale(color)))

                if let trend {
                    trendCapsule(trend, onColor: onColor)
                }
            }
            .materialize(delay: entranceDelay + 0.45)

            Text(subtitle)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : AppColors.Text.secondary)
                .multilineTextAlignment(.center)
                .screenPadding()
        }
        .padding(.bottom, ScoreHeroMetrics.bottomPadding)
        .frame(maxWidth: .infinity)
        .modifier(ScoreHeroBackground(color: color, isOn: onColor))
    }

    private var capsuleLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: AppSpacing.sm))
            : AnyLayout(HStackLayout(spacing: AppSpacing.sm))
    }

    private var heroScoreColor: Color {
        if onColor { return value != nil ? AppColors.Text.primaryOnDark : AppColors.Text.secondaryOnDark }
        return value != nil ? color : AppColors.Text.tertiary
    }

    // MARK: - Parts

    /// The score, then its unit and "/100" after it, small (`unit`, `showsMaximum`); or the
    /// amount in the app's format (`currency`, 4.5.0).
    @ViewBuilder
    private func scoreLine(font: Font, maximumFont: Font, maximumColor: Color, color: Color) -> some View {
        if let currency {
            if let value {
                FormattedAmountText(amount: value, currency: currency, fontSize: font, color: color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            } else {
                Text(verbatim: "—")
                    .font(font)
                    .foregroundStyle(color)
            }
        } else if showsMaximum || unit != nil {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                scoreText
                    .font(font)
                    .foregroundStyle(color)
                if let unit {
                    Text(verbatim: unit)
                        .font(maximumFont)
                        .foregroundStyle(maximumColor)
                }
                if showsMaximum {
                    Text(verbatim: "/\(Int(maxScore))")
                        .font(maximumFont)
                        .foregroundStyle(maximumColor)
                }
            }
        } else {
            scoreText
                .font(font)
                .foregroundStyle(color)
        }
    }

    /// The number in the app's locale with `fractionDigits` digits ("72", "12,4").
    private var valueText: String? {
        value.map { $0.formatted(.number.precision(.fractionLength(fractionDigits))) }
    }

    @ViewBuilder
    private var scoreText: some View {
        if decodesScore, let valueText {
            ScrambleText(valueText)
        } else {
            Text(verbatim: valueText ?? "—")
        }
    }

    /// "↗ +17.0% than last month" in a capsule: translucent white on colour, neutral on the page.
    private func trendCapsule(_ trend: Trend, onColor: Bool) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: trend.direction.systemImage)
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : trend.direction.color)
            Text(verbatim: [trend.changeText, trend.caption]
                .compactMap { $0 }
                .joined(separator: " "))
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : AppColors.Text.secondary)
        }
        .font(AppTypography.bodySmall)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .modifier(HeroCapsule(onColor: onColor, fill: AppColors.Background.neutral1))
    }
}

/// A capsule behind a label: translucent white on colour (a frosted look without glass, which
/// would reflect the capsule beside it), `fill` on the page.
private struct HeroCapsule: ViewModifier {
    let onColor: Bool
    let fill: Color

    func body(content: Content) -> some View {
        content.background(onColor ? AppColors.staticWhite.opacity(0.2) : fill, in: Capsule())
    }
}

/// The hero's gradient (`.heroBackground`, 4.5.0; drawn here since 4.2.0) when it is on colour.
private struct ScoreHeroBackground: ViewModifier {
    let color: Color
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.heroBackground(color)
        } else {
            content
        }
    }
}

enum ScoreHeroMetrics {
    /// The hero gauge's stroke.
    static let lineWidth: CGFloat = 28
    /// Room under the subtitle before the page's own content.
    static let bottomPadding: CGFloat = AppSpacing.xxl
}

// MARK: - Skeleton

/// Placeholder of a `ScoreGaugeCard`: the gauge's track, the score, the grade capsule and the
/// subtitle, in the card or edge to edge (`style: .hero`, without the gradient).
public struct ScoreGaugeCardSkeleton: View {
    let style: ScoreGaugeCard.Style

    public init(style: ScoreGaugeCard.Style = .card) {
        self.style = style
    }

    public var body: some View {
        switch style {
        case .card:
            card
        case .hero:
            hero
        }
    }

    private var card: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack(alignment: .bottom) {
                HeroHalfGaugeSkeleton(diameter: 220, lineWidth: 16)
                VStack(spacing: AppSpacing.xs) {
                    SkeletonText(AppTypography.h1, width: 72)
                    gradeCapsule
                }
            }
            SkeletonText(AppTypography.bodyEmphasis, width: 180)
        }
        .frame(maxWidth: .infinity)
        .shimmer()
        .padding(AppSpacing.lg)
        .cardStyle()
        .skeletonLoadingLabel()
    }

    private var hero: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack(alignment: .bottom) {
                HeroHalfGaugeSkeleton(style: .bleed, lineWidth: ScoreHeroMetrics.lineWidth)
                SkeletonText(AppTypography.display, width: 120)
            }
            gradeCapsule
            SkeletonText(AppTypography.bodyEmphasis, width: 180)
        }
        .padding(.bottom, ScoreHeroMetrics.bottomPadding)
        .frame(maxWidth: .infinity)
        .shimmer()
        .skeletonLoadingLabel()
    }

    /// The grade's capsule: a line of its text with its padding.
    private var gradeCapsule: some View {
        Text(verbatim: "Grade")
            .font(AppTypography.bodySmall)
            .hidden()
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(Skeleton.fill, in: Capsule())
    }
}
