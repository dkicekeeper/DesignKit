//
//  HeroHalfGauge.swift
//  Tenra
//
//  Full-size half-circle gauge for insight detail screens (2026-07 visual
//  refresh) — the hero sibling of the feed's MiniHalfGauge, sharing its
//  geometry rules (relative scale, norm marker, cap-aligned arc start)
//  and adding the OrbChart-derived wow layer: colour-matched glow underlay,
//  spring sweep-in, materialising tick markers.
//
//  Two scale modes:
//  - relative (norm != nil): scale = max(value × 1.15, norm × 2), radial norm tick
//  - absolute (maxValue != nil): 0…maxValue, optional zone ticks (health 40/70)
//
//  Text-free — the detail header / hero card carries the numbers. Callers can
//  overlay center content into the semicircle's interior (health score).
//
//  Two styles (4.2.0):
//  - standard: the half circle of `diameter` above;
//  - bleed: a circle wider than the view, only its top `span` degrees visible, the arc running
//    out past both edges, a knob on the value and the zones as notches. Place it edge to edge.
//  And two tones: on the page (the arc in its colour, a glow) or on colour (a white arc on a
//  tinted background, `ScoreGaugeCard(style: .hero)`).
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct HeroHalfGauge: View {
    /// How the gauge is laid out (4.2.0).
    public enum Style: Hashable, Sendable {
        /// A half circle of `diameter`, as before 4.2.0.
        case standard
        /// A circle wider than the view: only its top `span` degrees show, the arc runs out past
        /// both edges, and a knob marks the value. Takes the width it is offered (edge to edge,
        /// without `.screenPadding()`); its height follows from that width.
        case bleed
    }

    /// What the gauge is drawn on (4.2.0).
    public enum Tone: Hashable, Sendable {
        /// The page's background: the arc in its colour with a glow, a grey track.
        case onSurface
        /// A coloured background: a white arc and a translucent white track.
        case onColor
    }

    /// The measured value.
    let value: Double
    /// Relative mode: the reference the norm tick marks.
    var norm: Double? = nil
    /// Absolute mode: fixed scale end (e.g. 100 for the health score).
    var maxValue: Double? = nil
    /// Absolute-mode zone boundaries (e.g. [40, 70]) — knockout dot markers.
    var zoneTicks: [Double] = []
    /// Semantic tint of the value arc.
    let color: Color
    var style: Style = .standard
    var tone: Tone = .onSurface
    /// `.bleed`: the degrees of the circle that show, edge to edge.
    var span: Double = 130

    var diameter: CGFloat = 240
    var lineWidth: CGFloat = 20
    /// Replay guard for re-mounts; also disables the sweep under Reduce Motion.
    var animatesOnAppear: Bool = true
    /// Extra delay before the entrance sweep — pass the nav-transition duration
    /// so the gauge animates after the push settles (animating during the zoom
    /// transition made the hero visibly jump at its end).
    var entranceDelay: Double = 0

    @State private var displayFraction: Double = 0
    private var fillAnimation: Animation? { AppAnimation.progressFillAnimation }

    static let tickOvershoot: CGFloat = 8
    /// Room round the gauge for its glow inside the drawing group (the glow's blur and offset).
    static let glowMargin: CGFloat = 64

    private var scale: Double {
        if let maxValue { return max(maxValue, .leastNonzeroMagnitude) }
        if let norm { return max(value * 1.15, norm * 2) }
        return max(value * 1.15, .leastNonzeroMagnitude)
    }

    private var targetFraction: Double { min(max(value / scale, 0), 1) }

    public init(
        value: Double,
        norm: Double? = nil,
        maxValue: Double? = nil,
        zoneTicks: [Double] = [],
        color: Color,
        style: Style = .standard,
        tone: Tone = .onSurface,
        span: Double = 130,
        diameter: CGFloat = 240,
        lineWidth: CGFloat = 20,
        animatesOnAppear: Bool = true,
        entranceDelay: Double = 0
    ) {
        self.value = value
        self.norm = norm
        self.maxValue = maxValue
        self.zoneTicks = zoneTicks
        self.color = color
        self.style = style
        self.tone = tone
        self.span = min(max(span, 60), 170)
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.animatesOnAppear = animatesOnAppear
        self.entranceDelay = entranceDelay
    }

    /// The arc's colour: its tint on the page, white on colour.
    private var arcColor: Color { tone == .onColor ? AppColors.staticWhite : color }
    /// The track's colour, the full scale under the arc.
    private var trackColor: Color {
        tone == .onColor ? AppColors.staticWhite.opacity(0.3) : AppColors.Text.secondary.opacity(0.15)
    }

    public var body: some View {
        Group {
            switch style {
            case .standard:
                standardGauge
            case .bleed:
                BleedGaugeLayout(lineWidth: lineWidth, span: span, margin: Self.glowMargin) {
                    BleedGaugeCanvas(
                        fraction: displayFraction,
                        ticks: zoneTicks.map { $0 / scale } + (norm.map { [$0 / scale] } ?? []),
                        color: color,
                        arcColor: arcColor,
                        trackColor: trackColor,
                        glows: tone == .onSurface,
                        lineWidth: lineWidth,
                        span: span,
                        margin: Self.glowMargin
                    )
                }
            }
        }
        .contentShape(Rectangle())
        // Tap replays the sweep — the same light interactivity the other hero
        // charts have (no delay on replays; the entrance delay is one-shot).
        .onTapGesture {
            guard !AppAnimation.isReduceMotionEnabled else { return }
            HapticManager.light()
            startSweep(delay: 0, from: 0)
        }
        .onAppear {
            if animatesOnAppear {
                startSweep(delay: entranceDelay, from: 0)
            } else {
                displayFraction = targetFraction
            }
        }
        .onChange(of: value) { _, _ in
            withAnimation(fillAnimation) { displayFraction = targetFraction }
        }
    }

    /// The half circle of `diameter` (the standard style).
    private var standardGauge: some View {
        ZStack {
            // Track — the full scale.
            halfArc(from: 0, to: 0.5)
                .stroke(
                    trackColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Value arc + colour-matched glow (the glow is a blurred copy of the
            // arc itself, so it sweeps in together with the trim animation).
            // Starts at 0 like the track so both round caps coincide exactly —
            // an inset start makes the fill sit half a lineWidth above the
            // track's cap on the left.
            halfArc(from: 0, to: 0.5 * displayFraction)
                .stroke(arcColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .chartGlow(radius: lineWidth * 1.1, yOffset: 8, opacity: tone == .onColor ? 0.25 : 0.55)

            // Zone boundaries (absolute mode) — land staggered after the sweep.
            ForEach(zoneTicks.indices, id: \.self) { i in
                tickMarker(at: zoneTicks[i] / scale)
                    .materialize(delay: entranceDelay + 0.55 + Double(i) * 0.1, animatesOnAppear: animatesOnAppear)
            }

            // Norm marker (relative mode) — lands after the sweep.
            if let norm {
                tickMarker(at: norm / scale)
                    .materialize(delay: entranceDelay + 0.55, animatesOnAppear: animatesOnAppear)
            }
        }
        .frame(width: diameter, height: diameter)
        // One picture (2.9.0). On a Liquid Glass card (`cardStyle()`, as in `ScoreGaugeCard`) the
        // glass blends each layer of its content with the layers under it: the markers looked
        // translucent over the arc, the arc darker over its glow. A drawing group is one layer;
        // the margin keeps the glow inside it. (`.compositingGroup()` does not help.)
        .padding(Self.glowMargin)
        .drawingGroup()
        .padding(-Self.glowMargin)
        // The semicircle only occupies the square's top half (plus cap/tick
        // overshoot below the equator) — trim the layout to it.
        .frame(
            width: diameter + Self.tickOvershoot * 2,
            height: diameter / 2 + lineWidth / 2 + Self.tickOvershoot,
            alignment: .top
        )
    }

    /// Resets the arc and sweeps it in after `delay`.
    private func startSweep(delay: Double, from: Double) {
        displayFraction = from
        withAnimation(fillAnimation?.delay(delay)) { displayFraction = targetFraction }
    }

    /// Fractions 0…0.5 map left → top → right over the square's top half.
    private func halfArc(from: CGFloat, to: CGFloat) -> some Shape {
        Circle()
            .inset(by: lineWidth / 2)
            .trim(from: from, to: max(to, from))
            .rotation(.degrees(180))
    }

    /// Knockout dot marker centred on the stroke at `fraction` (0 = left,
    /// 1 = right) — a background-coloured disc punching a gap in the arc,
    /// with an arc-tinted dot inside (Activity-ring-style marker).
    private func tickMarker(at fraction: Double) -> some View {
        let clamped = min(max(fraction, 0), 1)
        let radius = diameter / 2 - lineWidth / 2
        let markerDiameter = lineWidth + 16
        return ZStack {
            Circle()
                .fill(arcColor)
            Circle()
                .fill(tone == .onColor ? color : AppColors.Background.base)
                .frame(width: markerDiameter / 1.6, height: markerDiameter / 1.6)
        }
        .frame(width: markerDiameter, height: markerDiameter)
        .offset(y: -radius)
        .rotationEffect(.degrees(-90 + clamped * 180))
    }
}

// MARK: - Bleed style

/// The bleed gauge's geometry for a width: a circle whose top `span` degrees cross the view from
/// edge to edge. Angles are from the top of the circle, positive to the right.
struct BleedGaugeGeometry {
    let width: CGFloat
    let lineWidth: CGFloat
    /// Degrees of the circle that show.
    let span: Double

    /// Wider than this (an iPad), the arc stops growing and no longer reaches the edges.
    static let maxArcWidth: CGFloat = 560
    /// The width when none is offered (a phone's).
    static let defaultWidth: CGFloat = 390

    /// Half the visible angle, in radians.
    var half: Double { span * .pi / 360 }
    /// The knob's outer diameter: a white disc a little wider than the stroke.
    var knobDiameter: CGFloat { lineWidth + 8 }
    /// The radius of the stroke's centre line.
    var radius: CGFloat { min(width, Self.maxArcWidth) / (2 * CGFloat(sin(half))) }
    /// Room above the apex for the knob and its shadow.
    var top: CGFloat { knobDiameter / 2 + 4 }
    var center: CGPoint { CGPoint(x: width / 2, y: top + radius) }
    /// From the top of the knob at the apex to below the arc where it meets the edges.
    var height: CGFloat { top + radius * CGFloat(1 - cos(half)) + max(lineWidth, knobDiameter) / 2 + 4 }

    /// The value's angle: 0 and 1 sit just inside the edges, so the knob shows whole.
    func angle(for fraction: Double) -> Double {
        let reach = Double(min(width, Self.maxArcWidth) / 2 - knobDiameter / 2 - 2)
        let limit = asin(min(max(reach / Double(radius), 0), 1))
        return -limit + 2 * limit * min(max(fraction, 0), 1)
    }

    func point(at angle: Double, radius r: CGFloat? = nil) -> CGPoint {
        let r = r ?? radius
        return CGPoint(x: center.x + r * CGFloat(sin(angle)), y: center.y - r * CGFloat(cos(angle)))
    }

    /// The arc between two angles, as short straight steps (2° or less).
    func arc(from start: Double, to end: Double) -> Path {
        var path = Path()
        guard end > start else { return path }
        let steps = max(Int((end - start) / (2 * .pi / 180)), 2)
        path.move(to: point(at: start))
        for step in 1...steps {
            path.addLine(to: point(at: start + (end - start) * Double(step) / Double(steps)))
        }
        return path
    }
}

/// Sizes the bleed gauge from the width it is offered and gives its canvas `margin` more above
/// and below, for the glow; the sides stay at the view's edges, where the arc is cut.
struct BleedGaugeLayout: Layout {
    let lineWidth: CGFloat
    let span: Double
    let margin: CGFloat

    private func width(for proposal: ProposedViewSize) -> CGFloat {
        guard let width = proposal.width, width.isFinite, width > 0 else { return BleedGaugeGeometry.defaultWidth }
        return width
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = width(for: proposal)
        return CGSize(width: width, height: BleedGaugeGeometry(width: width, lineWidth: lineWidth, span: span).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            subview.place(
                at: CGPoint(x: bounds.minX, y: bounds.minY - margin),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: bounds.height + 2 * margin)
            )
        }
    }
}

/// The bleed gauge in one `Canvas`, so a glass card around it cannot blend its layers (2.9.0's
/// lesson), and the arc is cut cleanly at the edges. Animatable: the sweep moves the knob along
/// the arc.
struct BleedGaugeCanvas: View, Animatable {
    var fraction: Double
    /// Notches, as fractions of the scale.
    let ticks: [Double]
    /// The knob's inner disc.
    let color: Color
    let arcColor: Color
    let trackColor: Color
    let glows: Bool
    let lineWidth: CGFloat
    let span: Double
    /// The canvas's extra height above and below the gauge (`BleedGaugeLayout`).
    let margin: CGFloat

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let geometry = BleedGaugeGeometry(width: size.width, lineWidth: lineWidth, span: span)
            context.translateBy(x: 0, y: margin)
            let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            // Past the edges, so the ends are cut there, not rounded.
            let start = -geometry.half - 0.3
            let end = geometry.half + 0.3
            let value = geometry.angle(for: fraction)
            let progress = geometry.arc(from: start, to: value)

            context.stroke(geometry.arc(from: value, to: end), with: .color(trackColor), style: stroke)
            if glows {
                // The colour-matched glow of the standard style (chartGlow), under the arc.
                context.drawLayer { glow in
                    glow.addFilter(.blur(radius: lineWidth * 1.1))
                    glow.opacity = 0.55
                    glow.translateBy(x: 0, y: 8)
                    glow.stroke(progress, with: .color(arcColor), style: stroke)
                }
            }
            context.stroke(progress, with: .color(arcColor), style: stroke)

            // Zones: thin gaps through the track and the arc, showing what is behind.
            var cut = context
            cut.blendMode = .destinationOut
            for tick in ticks {
                let angle = geometry.angle(for: tick)
                var notch = Path()
                notch.move(to: geometry.point(at: angle, radius: geometry.radius - lineWidth / 2 - 1))
                notch.addLine(to: geometry.point(at: angle, radius: geometry.radius + lineWidth / 2 + 1))
                cut.stroke(notch, with: .color(.black), style: StrokeStyle(lineWidth: 2.5, lineCap: .butt))
            }

            // The knob: a white disc with a soft shadow, the colour inside it.
            let center = geometry.point(at: value)
            let outer = geometry.knobDiameter
            let inner = outer - 8
            context.drawLayer { knob in
                knob.addFilter(.shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3))
                knob.fill(
                    Path(ellipseIn: CGRect(x: center.x - outer / 2, y: center.y - outer / 2, width: outer, height: outer)),
                    with: .color(AppColors.staticWhite)
                )
            }
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - inner / 2, y: center.y - inner / 2, width: inner, height: inner)),
                with: .color(color)
            )
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton

/// Placeholder of a `HeroHalfGauge`: its track, the same style, diameter (or span), line width
/// and frame.
public struct HeroHalfGaugeSkeleton: View {
    let style: HeroHalfGauge.Style
    let diameter: CGFloat
    let lineWidth: CGFloat
    let span: Double

    public init(style: HeroHalfGauge.Style = .standard, diameter: CGFloat = 240, lineWidth: CGFloat = 20, span: Double = 130) {
        self.style = style
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.span = min(max(span, 60), 170)
    }

    public var body: some View {
        switch style {
        case .standard:
            standardTrack
        case .bleed:
            // The bleed gauge's track, edge to edge, without a knob.
            BleedGaugeLayout(lineWidth: lineWidth, span: span, margin: 0) {
                Canvas { context, size in
                    let geometry = BleedGaugeGeometry(width: size.width, lineWidth: lineWidth, span: span)
                    context.stroke(
                        geometry.arc(from: -geometry.half - 0.3, to: geometry.half + 0.3),
                        with: .color(Skeleton.fill),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                }
            }
            .shimmer()
            .skeletonLoadingLabel()
        }
    }

    private var standardTrack: some View {
        // The gauge's track (see HeroHalfGauge.halfArc).
        Circle()
            .inset(by: lineWidth / 2)
            .trim(from: 0, to: 0.5)
            .rotation(.degrees(180))
            .stroke(Skeleton.fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: diameter, height: diameter)
            .frame(
                width: diameter + HeroHalfGauge.tickOvershoot * 2,
                height: diameter / 2 + lineWidth / 2 + HeroHalfGauge.tickOvershoot,
                alignment: .top
            )
            .shimmer()
            .skeletonLoadingLabel()
    }
}
