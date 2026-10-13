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
    /// "↗ +17.0% than last month".
    public struct Trend: Hashable, Sendable {
        public let direction: TrendBadge.Direction
        /// Signed percent; nil shows the arrow and the caption only.
        public let changePercent: Double?
        /// What the change is against ("than last month"); the app's own string.
        public let caption: String

        public init(direction: TrendBadge.Direction, changePercent: Double?, caption: String) {
            self.direction = direction
            self.changePercent = changePercent
            self.caption = caption
        }
    }

    let score: Int?
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
        trend: Trend? = nil
    ) {
        self.score = score
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
                    value: score.map(Double.init) ?? 0,
                    maxValue: maxScore,
                    zoneTicks: zoneTicks,
                    color: color,
                    diameter: 220,
                    lineWidth: 16
                )

                // Score + grade sit inside the semicircle's interior.
                VStack(spacing: AppSpacing.xs) {
                    scoreLine(font: AppTypography.h1.bold(), maximumFont: AppTypography.h4,
                              maximumColor: AppColors.Text.tertiary)
                        .foregroundStyle(score != nil ? color : AppColors.Text.tertiary)
                        .materialize(delay: 0.35)

                    Text(grade)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(color)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.pale(color))
                        .clipShape(Capsule())
                        .materialize(delay: 0.45)

                    if let trend {
                        trendCapsule(trend, onColor: false)
                            .materialize(delay: 0.5)
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
                    value: score.map(Double.init) ?? 0,
                    maxValue: maxScore,
                    zoneTicks: zoneTicks,
                    color: color,
                    style: .bleed,
                    tone: tone,
                    lineWidth: ScoreHeroMetrics.lineWidth
                )

                scoreLine(font: AppTypography.display, maximumFont: AppTypography.h3.weight(.regular),
                          maximumColor: onColor ? AppColors.Text.secondaryOnDark : AppColors.Text.tertiary)
                    .foregroundStyle(heroScoreColor)
                    .materialize(delay: 0.35)
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
            .materialize(delay: 0.45)

            Text(subtitle)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : AppColors.Text.secondary)
                .multilineTextAlignment(.center)
                .screenPadding()
        }
        .padding(.bottom, ScoreHeroMetrics.bottomPadding)
        .frame(maxWidth: .infinity)
        .background {
            if onColor {
                ScoreHeroBackground(color: color)
            }
        }
    }

    private var capsuleLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: AppSpacing.sm))
            : AnyLayout(HStackLayout(spacing: AppSpacing.sm))
    }

    private var heroScoreColor: Color {
        if onColor { return score != nil ? AppColors.Text.primaryOnDark : AppColors.Text.secondaryOnDark }
        return score != nil ? color : AppColors.Text.tertiary
    }

    // MARK: - Parts

    /// The score, and "/100" after it with `showsMaximum`.
    @ViewBuilder
    private func scoreLine(font: Font, maximumFont: Font, maximumColor: Color) -> some View {
        if showsMaximum {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                scoreText
                    .font(font)
                Text(verbatim: "/\(Int(maxScore))")
                    .font(maximumFont)
                    .foregroundStyle(maximumColor)
            }
        } else {
            scoreText
                .font(font)
        }
    }

    @ViewBuilder
    private var scoreText: some View {
        if decodesScore, let score {
            ScrambleText("\(score)")
        } else {
            Text(verbatim: score.map { "\($0)" } ?? "—")
        }
    }

    /// "↗ +17.0% than last month" in a capsule: translucent white on colour, neutral on the page.
    private func trendCapsule(_ trend: Trend, onColor: Bool) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: trend.direction.systemImage)
                .foregroundStyle(onColor ? AppColors.Text.primaryOnDark : trend.direction.color)
            Text(verbatim: [trend.changePercent.map(TrendBadge.format), trend.caption]
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

/// The hero's gradient: mesh light in shades of the score's colour, a tone deeper so white text
/// reads on it, opaque behind the whole hero (and up under the navigation bar), then fading into
/// the page below it, where the cards that follow rise over it. A fine grain against banding.
private struct ScoreHeroBackground: View {
    let color: Color

    var body: some View {
        mesh
            .grain()
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: ScoreHeroMetrics.fade)
                }
            }
            .padding(.bottom, -ScoreHeroMetrics.fade)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// The score's colour a tone deeper: white on the deepened success, warning and destructive
    /// colours is at least 3:1, the minimum for large text (the plain colours give about 2:1).
    private var base: Color {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: Double(hue), saturation: Double(min(1, saturation * 1.05)),
                     brightness: Double(brightness * ScoreHeroMetrics.depth))
    }

    /// Three columns of shades in three rows (as `.accentGlow`'s aurora), all opaque.
    private var mesh: MeshGradient {
        let palette = AuroraBackground.palette(around: base, spread: ScoreHeroMetrics.hueSpread)
        let columns = [palette[0], palette[1], palette[5]]
        var points = [SIMD2<Float>]()
        var colors = [Color]()
        for row in 0..<3 {
            for column in 0..<3 {
                points.append(SIMD2(Float(column) / 2, Float(row) / 2))
                colors.append(columns[(column + row) % columns.count])
            }
        }
        return MeshGradient(width: 3, height: 3, points: points, colors: colors)
    }
}

enum ScoreHeroMetrics {
    /// The hero gauge's stroke.
    static let lineWidth: CGFloat = 28
    /// Room under the subtitle before the page's own content.
    static let bottomPadding: CGFloat = AppSpacing.xxl
    /// Shades of one colour, as the hero glow (`.accentGlow`, 3.4.0).
    static let hueSpread: Double = 12
    /// How far below the hero its gradient fades out (under the cards that rise over it).
    static let fade: CGFloat = 96
    /// The score's colour is deepened to this share of its brightness behind white text.
    static let depth: CGFloat = 0.78
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
