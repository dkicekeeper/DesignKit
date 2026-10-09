//
//  PackedCircleIconsOrbit.swift
//  DesignKit
//
//  `PackedCircleIcons(style: .orbit)` (3.3.0): the largest amount as a marble in the middle,
//  the rest as smaller marbles on a tilted orbit around it, seen from slightly above. The
//  orbit turns slowly (once in `period`); a marble on the far side is smaller and darker and
//  passes behind the middle one, a near one passes in front. On appear the marbles fly out
//  of the middle onto the orbit one after another. Under Reduce Motion, while the system
//  saves resources and under `.designKitMotion(false)`, the orbit stands still.
//

import SwiftUI
import DesignTokens
import DesignSupport

enum PackedOrbitMetrics {
    /// The middle marble, as a share of the box's shorter side.
    static let centreShare: CGFloat = 0.42
    /// The largest satellite, as a share of the middle marble.
    static let satelliteShare: CGFloat = 0.56
    /// The smallest satellite next to the largest, and the "+N" one.
    static let smallestSatellite: CGFloat = 0.62
    static let overflowSatellite: CGFloat = 0.56
    /// The orbit seen at a slant: its height to its width, and its tilt in degrees.
    static let flatness: CGFloat = 0.4
    static let tilt: Double = -12
    /// The far side: smaller and darker.
    static let farScale: CGFloat = 0.72
    static let farDarkening: Double = 0.2
    /// One turn, in seconds.
    static let period: Double = 28
    /// Room for the shadows inside the box.
    static let margin: CGFloat = 3
    /// The flight onto the orbit: marble after marble, then the orbit starts to turn.
    static let burstSpring = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let burstStagger: Double = 0.07
    static let entranceDuration: Double = 0.9
}

/// The orbit in a box: the middle marble, the largest satellite and the ellipse they turn on.
struct PackedOrbitGeometry: Equatable {
    let centreDiameter: CGFloat
    let satelliteDiameter: CGFloat
    let radiusX: CGFloat
    let radiusY: CGFloat

    init(box: CGSize) {
        centreDiameter = min(box.width, box.height) * PackedOrbitMetrics.centreShare
        satelliteDiameter = centreDiameter * PackedOrbitMetrics.satelliteShare
        radiusX = max(0, box.width / 2 - satelliteDiameter / 2 - PackedOrbitMetrics.margin)
        radiusY = radiusX * PackedOrbitMetrics.flatness
    }

    /// Where a satellite at `angle` (radians: 0 on the right, π/2 nearest) is, from the
    /// middle, and how near it is: 0 on the far side, 1 on the near one.
    func place(at angle: Double) -> (offset: CGSize, nearness: CGFloat) {
        let x = Double(radiusX) * cos(angle)
        let y = Double(radiusY) * sin(angle)
        let tilt = PackedOrbitMetrics.tilt * .pi / 180
        return (
            CGSize(width: x * cos(tilt) - y * sin(tilt), height: x * sin(tilt) + y * cos(tilt)),
            CGFloat((sin(angle) + 1) / 2)
        )
    }

    /// Where satellite `index` of `count` stands in the still picture: evenly round the orbit,
    /// none straight behind or in front of the middle marble.
    static func startAngle(_ index: Int, of count: Int) -> Double {
        guard count > 0 else { return 0 }
        let step = 2 * Double.pi / Double(count)
        return (count % 4 == 0 ? step / 2 : 0) + step * Double(index)
    }

    /// A satellite's scale at `nearness`: smaller on the far side.
    static func depthScale(_ nearness: CGFloat) -> CGFloat {
        PackedOrbitMetrics.farScale + (1 - PackedOrbitMetrics.farScale) * nearness
    }
}

// MARK: - Orbit

struct PackedOrbit: View {
    let items: [PackedCircleItem]
    let overflowCount: Int
    let size: CGSize

    @Environment(\.designKitMotion) private var designKitMotion
    /// 0 with every satellite in the middle, 1 on the orbit.
    @State private var spread: Double = 0
    /// How far the orbit has turned, in radians.
    @State private var phase: Double = 0

    init(items: [PackedCircleItem], overflowCount: Int, size: CGSize) {
        self.items = items
        self.overflowCount = overflowCount
        self.size = size
    }

    /// The items by amount, the largest first.
    private var ranked: [PackedCircleItem] {
        items.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        let ranked = self.ranked
        let satellites = Array(ranked.dropFirst())
        let count = satellites.count + (overflowCount > 0 ? 1 : 0)
        let geometry = PackedOrbitGeometry(box: size)
        AmbientMotionGate { allowsAmbientMotion in
            ZStack {
                if count > 0 {
                    PackedOrbitPath(geometry: geometry)
                        .opacity(spread)
                        .animation(entrance(0), value: spread)
                        .zIndex(-2)
                }
                if let centre = ranked.first {
                    PackedMarble(iconSource: centre.iconSource, tint: centre.tint,
                                 diameter: geometry.centreDiameter, index: 0, sways: false)
                        .scaleEffect(0.3 + 0.7 * spread)
                        .opacity(min(1, spread * 2))
                        .animation(entrance(0), value: spread)
                }
                ForEach(Array(satellites.enumerated()), id: \.element.id) { index, item in
                    PackedMarble(iconSource: item.iconSource, tint: item.tint,
                                 diameter: diameter(of: item, largest: satellites.first?.amount ?? 0, geometry: geometry),
                                 index: index + 1, sways: false)
                        .modifier(PackedOrbitPlacement(geometry: geometry,
                                                       startAngle: PackedOrbitGeometry.startAngle(index, of: count),
                                                       phase: phase, spread: spread))
                        .animation(entrance(index + 1), value: spread)
                }
                if overflowCount > 0 {
                    PackedOverflowMarble(count: overflowCount,
                                         diameter: geometry.satelliteDiameter * PackedOrbitMetrics.overflowSatellite,
                                         index: count, sways: false)
                        .modifier(PackedOrbitPlacement(geometry: geometry,
                                                       startAngle: PackedOrbitGeometry.startAngle(count - 1, of: count),
                                                       phase: phase, spread: spread))
                        .animation(entrance(count), value: spread)
                }
            }
            .frame(width: size.width, height: size.height)
            .task { spread = 1 }
            .task(id: allowsAmbientMotion && designKitMotion) {
                // From the start without animation, so a new turn always has somewhere to go.
                var still = Transaction()
                still.disablesAnimations = true
                withTransaction(still) { phase = 0 }
                guard allowsAmbientMotion && designKitMotion else { return }
                try? await Task.sleep(for: .seconds(PackedOrbitMetrics.entranceDuration))
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: PackedOrbitMetrics.period).repeatForever(autoreverses: false)) {
                    phase = 2 * .pi
                }
            }
        }
    }

    /// The flight of marble `index` onto the orbit; none without DesignKit's motion.
    private func entrance(_ index: Int) -> Animation? {
        guard designKitMotion, !AppAnimation.isReduceMotionEnabled else { return nil }
        return PackedOrbitMetrics.burstSpring.delay(Double(index) * PackedOrbitMetrics.burstStagger)
    }

    /// A satellite's diameter: the largest satellite's, down to `smallestSatellite` of it by the
    /// square root of its share.
    private func diameter(of item: PackedCircleItem, largest: Double, geometry: PackedOrbitGeometry) -> CGFloat {
        let base = geometry.satelliteDiameter
        guard largest > 0 else { return base }
        let smallest = PackedOrbitMetrics.smallestSatellite
        return base * (smallest + (1 - smallest) * CGFloat((max(item.amount, 0) / largest).squareRoot()))
    }
}

/// A satellite on the orbit at one moment: its place, size and shade for the orbit's turn and
/// the flight out of the middle. Animatable, so both run smoothly; the near half of the orbit
/// lies in front of the middle marble, the far half behind it.
private struct PackedOrbitPlacement: ViewModifier, Animatable {
    let geometry: PackedOrbitGeometry
    let startAngle: Double
    var phase: Double
    var spread: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(phase, spread) }
        set {
            phase = newValue.first
            spread = newValue.second
        }
    }

    func body(content: Content) -> some View {
        let place = geometry.place(at: startAngle + phase)
        content
            .scaleEffect(PackedOrbitGeometry.depthScale(place.nearness) * (0.3 + 0.7 * spread))
            .brightness(-PackedOrbitMetrics.farDarkening * Double(1 - place.nearness))
            .offset(x: place.offset.width * spread, y: place.offset.height * spread)
            .opacity(min(1, spread * 2))
            .zIndex(Double(place.nearness) * 2 - 1)
    }
}

/// The orbit's line: faint on the far side, clearer on the near one.
struct PackedOrbitPath: View {
    let geometry: PackedOrbitGeometry

    var body: some View {
        Ellipse()
            .stroke(
                LinearGradient(
                    colors: [AppColors.Text.tertiary.opacity(0.18), AppColors.Text.tertiary.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.2
            )
            .frame(width: geometry.radiusX * 2, height: geometry.radiusY * 2)
            .rotationEffect(.degrees(PackedOrbitMetrics.tilt))
            .accessibilityHidden(true)
    }
}
