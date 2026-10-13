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
/// colour (`.heroBackground`) that reaches up to the screen's top edge and fades into the page
/// below the hero, where the cards that follow may rise over it: a tone deeper with white text
/// in dark mode, a pale tint with black text in light mode (4.5.1). The score shrinks to stay
/// inside the arc (4.5.1).
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
    @Environment(\.colorScheme) private var colorScheme

    /// - Parameters:
    ///   - score: `nil` when it cannot be computed: the gauge stays empty and the number reads "—".
    ///   - maxScore: The end of the scale.
    ///   - zoneTicks: Zone boundaries marked on the arc (e.g. `[40, 70]`).
    ///   - color: Tints the arc, the number and the grade capsule.
    ///   - decodesScore: The number decodes itself as it appears and when it changes
    ///     (`ScrambleText`, 2.7.0).
    ///   - style: `.card` or `.hero` (4.2.0).
    ///   - tone: `.hero` only: on a gradient of `color` (`.onColor`: white text in dark mode,
    ///     black on a pale tint in light mode since 4.5.1) or on the page (`.onSurface`). The
    ///     card is always on its glass.
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

    /// On its gradient (`.hero`, `tone: .onColor`).
    private var onGradient: Bool { style == .hero && tone == .onColor }
    /// White pieces: on the gradient in dark mode, a tone deeper. In light mode the gradient is
    /// a pale tint and the pieces are as on the page, the text in black (4.5.1).
    private var onColor: Bool { onGradient && colorScheme == .dark }

    private var hero: some View {
        VStack(spacing: AppSpacing.md) {
            BleedScoreLayout(lineWidth: ScoreHeroMetrics.lineWidth, span: ScoreHeroMetrics.span) {
                HeroHalfGauge(
                    value: value ?? 0,
                    norm: norm,
                    maxValue: maxScore,
                    zoneTicks: zoneTicks,
                    color: color,
                    style: .bleed,
                    tone: onColor ? .onColor : .onSurface,
                    span: ScoreHeroMetrics.span,
                    lineWidth: ScoreHeroMetrics.lineWidth,
                    entranceDelay: entranceDelay
                )

                scoreLine(font: AppTypography.display, maximumFont: AppTypography.h3.weight(.regular),
                          maximumColor: onColor ? AppColors.Text.secondaryOnDark : AppColors.Text.tertiary,
                          color: heroScoreColor)
                    // Shrinks to the room inside the arc (BleedScoreLayout).
                    .lineLimit(1)
                    .minimumScaleFactor(ScoreHeroMetrics.minimumScoreScale)
                    .materialize(delay: entranceDelay + 0.35)
            }

            // Side by side; one under the other at accessibility sizes (the 1.3.0 rule).
            capsuleLayout {
                Text(grade)
                    .font(AppTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : onGradient ? AppColors.Text.primary : color)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .modifier(HeroCapsule(onColor: onColor, fill: capsuleFill(AppColors.pale(color))))

                if let trend {
                    trendCapsule(trend, onColor: onColor)
                }
            }
            .materialize(delay: entranceDelay + 0.45)

            Text(subtitle)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark
                                 : onGradient ? AppColors.Text.primary : AppColors.Text.secondary)
                .multilineTextAlignment(.center)
                .screenPadding()
        }
        .padding(.bottom, ScoreHeroMetrics.bottomPadding)
        .frame(maxWidth: .infinity)
        .modifier(ScoreHeroBackground(color: color, isOn: onGradient))
    }

    /// A capsule's fill on the page; frosted white on the pale gradient (4.5.1).
    private func capsuleFill(_ fill: Color) -> Color {
        onGradient ? AppColors.staticWhite.opacity(ScoreHeroMetrics.paleCapsuleOpacity) : fill
    }

    private var capsuleLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: AppSpacing.sm))
            : AnyLayout(HStackLayout(spacing: AppSpacing.sm))
    }

    private var heroScoreColor: Color {
        if onColor { return value != nil ? AppColors.Text.primaryOnDark : AppColors.Text.secondaryOnDark }
        if onGradient { return value != nil ? AppColors.Text.primary : AppColors.Text.tertiary }
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
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark
                                 : onGradient ? AppColors.Text.primary : AppColors.Text.secondary)
        }
        .font(AppTypography.bodySmall)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .modifier(HeroCapsule(onColor: onColor, fill: capsuleFill(AppColors.Background.neutral1)))
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
    /// The degrees of the gauge's circle that show (HeroHalfGauge's default).
    static let span: Double = 130
    /// Room under the subtitle before the page's own content.
    static let bottomPadding: CGFloat = AppSpacing.xxl
    /// How small a long score may get to stay inside the arc.
    static let minimumScoreScale: CGFloat = 0.4
    /// The capsules' frosted white on the pale gradient of light mode.
    static let paleCapsuleOpacity: Double = 0.6
}

/// The score at the foot of the bleed gauge (`ZStack(alignment: .bottom)` before 4.5.1),
/// offered only the width inside the arc at the height of its top, so a long amount shrinks
/// (its `minimumScaleFactor`) instead of running onto the arc; the screen's side padding at most.
struct BleedScoreLayout: Layout {
    let lineWidth: CGFloat
    let span: Double

    /// Room between the score and the arc's inner edge (the knob's, which is wider).
    static let gap: CGFloat = AppSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let gauge = subviews.first else { return .zero }
        let size = gauge.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        let scoreHeight = subviews.count > 1 ? subviews[1].sizeThatFits(.unspecified).height : 0
        return CGSize(width: size.width, height: max(size.height, scoreHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let gauge = subviews.first else { return }
        let gaugeSize = gauge.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
        gauge.place(at: CGPoint(x: bounds.minX, y: bounds.maxY - gaugeSize.height), anchor: .topLeading,
                    proposal: ProposedViewSize(width: bounds.width, height: gaugeSize.height))
        guard subviews.count > 1 else { return }
        let score = subviews[1]
        let width = Self.scoreWidth(gauge: gaugeSize, scoreHeight: score.sizeThatFits(.unspecified).height,
                                    lineWidth: lineWidth, span: span)
        score.place(at: CGPoint(x: bounds.midX, y: bounds.maxY), anchor: .bottom,
                    proposal: ProposedViewSize(width: width, height: nil))
    }

    /// The width inside the arc at the score's top, the score's foot on the gauge's.
    static func scoreWidth(gauge: CGSize, scoreHeight: CGFloat, lineWidth: CGFloat, span: Double) -> CGFloat {
        let padded = max(0, gauge.width - 2 * AppSpacing.lg)
        let geometry = BleedGaugeGeometry(width: gauge.width, lineWidth: lineWidth, span: span)
        let inner = geometry.radius - geometry.knobDiameter / 2 - gap
        let rise = geometry.center.y - (gauge.height - scoreHeight)
        guard inner > 0, rise < inner else { return padded }
        let half = (inner * inner - max(rise, 0) * max(rise, 0)).squareRoot()
        return min(padded, max(0, 2 * half))
    }
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
