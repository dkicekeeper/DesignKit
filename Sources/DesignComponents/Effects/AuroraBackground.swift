//
//  AuroraBackground.swift
//  DesignKit
//
//  A slow aurora behind a premium screen, a paywall or an onboarding (2.2.0): a 3×3
//  MeshGradient whose inner points drift on long, out-of-step loops, so the light never
//  repeats in a way the eye catches.
//
//  Weighted spots (2.5.0): colours with weights, each a soft pool of light sized and
//  brightened by its weight, the way GradientOrbsBackground drew its orbs, but sampled into a
//  mesh instead of blurred. Still by default: behind Liquid Glass a moving background
//  makes every glass surface recompute its blur each frame, so a screen's background should
//  hold still. When the spots change, the mesh flows to its new shape in 0.6 s.
//
//  6.1.0 (the owner's review of Tenra's background on a device: dull colours): the pools are
//  denser (55-90 % of their colour at the centre, 30-55 % before), their hues meet in OKLab
//  with their own chroma (an average in RGB turned orange and blue into a grey mauve), on a
//  9×9 mesh (5×5 showed its cells once each pool kept its hue), and the colours are read as
//  linear light (they were read in sRGB and drawn as linear, which paled every one).
//
//  Light: the GPU draws a mesh gradient in one pass, with no blur, plus a still grain (2.5.0)
//  that keeps it from banding on a dark screen. A drifting aurora redraws at 30 fps only while
//  motion is allowed (AmbientMotionGate: Reduce Motion, iOS 27's request to save resources)
//  and `.designKitMotion` is on. Otherwise it is one still frame, the same layout.
//
//  For a screen's background, behind content on materials or glass; not under small text with
//  no surface of its own.
//

import SwiftUI
import UIKit
import DesignTokens

/// A slowly drifting aurora of `colors`, or a still aurora of weighted spots.
///
/// ```swift
/// ZStack {
///     AuroraBackground().ignoresSafeArea()
///     PaywallContent()
/// }
/// AuroraBackground(colors: [.teal, .indigo, .purple], intensity: 0.6)
///
/// // The home screen: the biggest spending categories, still.
/// AuroraBackground([
///     .init(color: .orange, weight: 1.0),
///     .init(color: .blue, weight: 0.6),
///     .init(color: .pink, weight: 0.4),
/// ])
/// ```
public struct AuroraBackground: View {
    /// A colour and how much of the aurora it takes (2.5.0).
    public struct Spot: Equatable {
        public let color: Color
        /// 0…1; the heaviest spot is usually 1. Heavier spots are larger and brighter.
        public let weight: Double

        public init(color: Color, weight: Double) {
            self.color = color
            self.weight = min(max(weight, 0), 1)
        }
    }

    /// Whether the aurora moves.
    public enum Motion: Hashable, Sendable {
        /// The inner points drift on slow loops (30 fps while motion is allowed).
        case drift
        /// One still frame: for a background under Liquid Glass.
        case still
    }

    let colors: [Color]
    let spots: [Spot]?
    let intensity: Double
    let motion: Motion
    let grain: Double

    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.self) private var environment
    /// The spots the mesh shows: they follow `spots`, flowing into a change.
    @State private var shownSpots: [Spot]
    /// Width over height, for round spots on any screen.
    @State private var aspect: Double = 0.5

    /// - Parameters:
    ///   - colors: The aurora's colours, spread over the nine points; by default the accent and
    ///     its neighbours on the colour wheel.
    ///   - intensity: 0…1, how strongly the aurora shows over the screen's background.
    ///   - motion: `.drift` (the default) or `.still` (2.5.0).
    ///   - grain: A fine still grain against banding (2.5.0); 0 turns it off.
    public init(colors: [Color]? = nil, intensity: Double = 1, motion: Motion = .drift, grain: Double = GrainMetrics.amount) {
        let given = colors ?? []
        self.colors = given.isEmpty ? AuroraBackground.palette(around: AppColors.accent) : given
        self.spots = nil
        self.intensity = min(max(intensity, 0), 1)
        self.motion = motion
        self.grain = grain
        self._shownSpots = State(initialValue: [])
    }

    /// An aurora of weighted spots (2.5.0): each colour a soft pool of light, sized and
    /// brightened by its weight. Up to five spots, heaviest first.
    ///
    /// - Parameter motion: `.still` by default: a screen's background under Liquid Glass.
    public init(_ spots: [Spot], intensity: Double = 1, motion: Motion = .still, grain: Double = GrainMetrics.amount) {
        let kept = Array(spots.prefix(AuroraSpots.anchors.count))
        self.colors = kept.map(\.color)
        self.spots = kept
        self.intensity = min(max(intensity, 0), 1)
        self.motion = motion
        self.grain = grain
        self._shownSpots = State(initialValue: kept)
    }

    public var body: some View {
        AmbientMotionGate { allowsAmbientMotion in
            if motion == .drift && allowsAmbientMotion && designKitMotion {
                TimelineView(.periodic(from: .now, by: AuroraMetrics.frameInterval)) { timeline in
                    mesh(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                mesh(at: 0)
            }
        }
        .grain(grain)
        .background(AppColors.Background.base)
        .onGeometryChange(for: Double.self) { proxy in
            proxy.size.width / max(proxy.size.height, 1)
        } action: { newAspect in
            if abs(newAspect - aspect) > 0.01 { aspect = newAspect }
        }
        .onChange(of: spots ?? []) { old, new in
            // The first data arrives at once; later changes flow.
            if old.isEmpty || !designKitMotion {
                shownSpots = new
            } else {
                withAnimation(.smooth(duration: AuroraMetrics.morphDuration)) { shownSpots = new }
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func mesh(at time: Double) -> some View {
        if spots != nil {
            MeshGradient(
                width: AuroraSpots.side,
                height: AuroraSpots.side,
                points: AuroraSpots.points(at: time),
                colors: AuroraSpots.colors(for: shownSpots, aspect: aspect, in: environment)
            )
            .opacity(intensity)
        } else {
            MeshGradient(
                width: 3,
                height: 3,
                points: Self.points(at: time),
                colors: (0..<9).map { colors[$0 % colors.count] }
            )
            .opacity(intensity)
        }
    }

    /// Corners fixed, edge midpoints sliding along their edge, the centre drifting: each on its
    /// own period, so the pattern takes minutes to come round.
    static func points(at time: Double) -> [SIMD2<Float>] {
        func wave(_ period: Double, _ phase: Double, _ amplitude: Double) -> Float {
            Float(sin(time * 2 * .pi / period + phase) * amplitude)
        }
        let a = AuroraMetrics.drift
        return [
            [0, 0], [0.5 + wave(13, 0, a), 0], [1, 0],
            [0, 0.5 + wave(17, 1, a)], [0.5 + wave(11, 2, a), 0.5 + wave(19, 3, a)], [1, 0.5 + wave(15, 4, a)],
            [0, 1], [0.5 + wave(14, 5, a), 1], [1, 1],
        ]
    }

    /// The accent and its neighbours on the colour wheel, lighter and deeper: hues up to
    /// `spread` degrees either side (±30°, ±60° by default). The hero glow passes a narrow
    /// spread, so its light stays one colour in several shades (3.4.0).
    public static func palette(around color: Color, spread: Double = 60) -> [Color] {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let near = CGFloat(spread) / 2
        let far = CGFloat(spread)
        func shifted(_ degrees: CGFloat, brightness b: CGFloat) -> Color {
            var h = hue + degrees / 360
            h -= floor(h)
            return Color(hue: Double(h), saturation: Double(min(1, saturation * 0.9 + 0.1)), brightness: Double(min(1, b)))
        }
        return [
            shifted(0, brightness: brightness),
            shifted(near, brightness: brightness * 1.1),
            shifted(-near, brightness: brightness * 0.9),
            shifted(far, brightness: brightness * 1.05),
            shifted(0, brightness: brightness * 1.15),
            shifted(-far, brightness: brightness),
            shifted(near, brightness: brightness * 0.85),
            shifted(-near, brightness: brightness * 1.1),
            shifted(0, brightness: brightness * 0.95),
        ]
    }
}

enum AuroraMetrics {
    /// 30 fps: the drift is slow, a display-rate redraw would only cost energy.
    static let frameInterval: Double = 1.0 / 30
    /// How far a point drifts from its place, in unit coordinates.
    static let drift: Double = 0.18
    /// How long the mesh takes to flow into changed spots.
    static let morphDuration: Double = 0.6
}

// MARK: - Weighted spots

/// The weighted aurora: a field of soft pools of light, one per spot, sampled at the points of
/// a 9×9 mesh. The mesh interpolates between the samples, so the pools blend with no blur.
enum AuroraSpots {
    /// Points per side of the mesh: dense enough that a change of hue between two points does
    /// not show the mesh's cells (6.1.0; 5 before).
    static let side = 9
    /// How far an inner point drifts, in unit coordinates: under half a cell, so the mesh never
    /// folds.
    static let drift = 0.24 / Double(side - 1)

    /// Where each spot sits, heaviest first, in unit coordinates: the dominant one left of
    /// centre, then top right, bottom, right, top left (GradientOrbsBackground's layout).
    static let anchors: [SIMD2<Double>] = [
        [0.32, 0.58], [0.72, 0.28], [0.55, 0.80], [0.78, 0.62], [0.26, 0.30],
    ]

    /// The grid, with its inner points drifting a little when `time` moves.
    static func points(at time: Double) -> [SIMD2<Float>] {
        var points = [SIMD2<Float>]()
        for row in 0..<side {
            for column in 0..<side {
                var x = Double(column) / Double(side - 1)
                var y = Double(row) / Double(side - 1)
                let inner = row > 0 && row < side - 1 && column > 0 && column < side - 1
                if inner && time != 0 {
                    let seed = Double(row * side + column)
                    x += sin(time * 2 * .pi / (11 + seed.truncatingRemainder(dividingBy: 7)) + seed) * drift
                    y += cos(time * 2 * .pi / (13 + seed.truncatingRemainder(dividingBy: 5)) + seed * 1.3) * drift
                }
                points.append(SIMD2(Float(x), Float(y)))
            }
        }
        return points
    }

    /// The colour at each mesh point: the spots' pools of light combined like light, so two
    /// overlapping pools cover more of the page; transparent where no pool reaches. Where pools
    /// meet, each one's hue counts by its strength squared, so near its centre a pool keeps its
    /// own colour and the hues turn into each other in a band between them.
    static func colors(for spots: [Spot], aspect: Double, in environment: EnvironmentValues) -> [Color] {
        let labs = spots.map { OKLab($0.color.resolve(in: environment)) }
        var colors = [Color]()
        colors.reserveCapacity(side * side)
        for row in 0..<side {
            for column in 0..<side {
                // Distances in units of the height, so pools stay round on a tall screen.
                let point = SIMD2(Double(column) / Double(side - 1) * aspect, Double(row) / Double(side - 1))
                var lightness = 0.0, a = 0.0, b = 0.0, chroma = 0.0, hueWeights = 0.0, clear = 1.0
                for (index, spot) in spots.enumerated() {
                    let anchor = SIMD2(anchors[index].x * aspect, anchors[index].y)
                    let radius = 0.17 + 0.26 * spot.weight
                    let delta = point - anchor
                    let falloff = exp(-(delta.x * delta.x + delta.y * delta.y) / (2 * radius * radius))
                    let strength = (0.55 + 0.35 * spot.weight) * falloff
                    clear *= 1 - strength
                    let hueWeight = strength * strength
                    lightness += labs[index].lightness * hueWeight
                    a += labs[index].a * hueWeight
                    b += labs[index].b * hueWeight
                    chroma += labs[index].chroma * hueWeight
                    hueWeights += hueWeight
                }
                guard hueWeights > 0 else {
                    colors.append(.clear)
                    continue
                }
                // The averaged hue with the pools' own chroma: two hues averaged lose it.
                let mixed = OKLab(lightness: lightness / hueWeights, a: a / hueWeights, b: b / hueWeights)
                    .withChroma(chroma / hueWeights)
                let rgb = mixed.linearSRGB
                colors.append(Color(Color.Resolved(
                    colorSpace: .sRGBLinear,
                    red: Float(rgb.red),
                    green: Float(rgb.green),
                    blue: Float(rgb.blue),
                    opacity: Float(1 - clear)
                )))
            }
        }
        return colors
    }

    typealias Spot = AuroraBackground.Spot
}

/// A colour in OKLab (Björn Ottosson, 2020): its lightness and two opponent axes, green to red
/// (`a`) and blue to yellow (`b`). An average of two colours here is the hue between them at an
/// even lightness, where an average in RGB drifts to grey.
struct OKLab: Equatable {
    var lightness: Double
    var a: Double
    var b: Double

    init(lightness: Double, a: Double, b: Double) {
        self.lightness = lightness
        self.a = a
        self.b = b
    }

    /// From a resolved colour's linear light.
    init(_ color: Color.Resolved) {
        let red = Double(color.linearRed), green = Double(color.linearGreen), blue = Double(color.linearBlue)
        let l = cbrt(0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
        let m = cbrt(0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
        let s = cbrt(0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
        lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    }

    /// How colourful it is: the distance from grey.
    var chroma: Double { (a * a + b * b).squareRoot() }

    /// The same lightness and hue with `chroma`; a grey stays grey.
    func withChroma(_ chroma: Double) -> OKLab {
        let current = self.chroma
        guard current > 1e-6 else { return self }
        return OKLab(lightness: lightness, a: a / current * chroma, b: b / current * chroma)
    }

    /// Linear sRGB, clamped to what sRGB can show.
    var linearSRGB: (red: Double, green: Double, blue: Double) {
        let l = lightness + 0.3963377774 * a + 0.2158037573 * b
        let m = lightness - 0.1055613458 * a - 0.0638541728 * b
        let s = lightness - 0.0894841775 * a - 1.2914855480 * b
        let l3 = l * l * l, m3 = m * m * m, s3 = s * s * s
        func clamped(_ value: Double) -> Double { min(max(value, 0), 1) }
        return (
            clamped(4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3),
            clamped(-1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3),
            clamped(-0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3)
        )
    }
}
