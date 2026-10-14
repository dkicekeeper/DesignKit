//
//  PackedCircleIconsOrbit.swift
//  DesignKit
//
//  `PackedCircleIcons(style: .orbit)`: since 4.7.0 a carousel of coins (3.3.0 drew the largest
//  amount as a marble in the middle with the rest on a tilted orbit round it). Coins of one
//  size, the largest amount first, stand on a ring seen from slightly above that turns slowly
//  round its upright axis: the front ones large and sharp, the far ones smaller and out of
//  focus, each a little higher or lower than the next and tilted a few degrees, as if hung by
//  hand. A coin turns its face towards the side it is on, so near the sides it narrows and
//  shows its rim; one in front casts a soft shadow.
//
//  A swipe spins the ring, with inertia and a tick as each coin passes the front, and it slows
//  back to its own pace. On appear the coins come in one after another. Under Reduce Motion,
//  while the system saves resources and under `.designKitMotion(false)` the ring stands still
//  (a swipe still turns it, without the coast).
//
//  A logo fills its coin, as a flag fills a badge; a symbol is white on a coin of its tint;
//  "+N" is a grey coin.
//

import SwiftUI
import DesignTokens
import DesignSupport

enum PackedOrbitMetrics {
    /// A coin's diameter: this share of the box's height, at most `widthShare` of its width.
    static let heightShare: CGFloat = 0.5
    static let widthShare: CGFloat = 0.3
    /// The ring seen from slightly above: the far side is this share of the box's height above
    /// the near side, so the far coins show over the near ones.
    static let rise: CGFloat = 0.38
    /// The far side's scale.
    static let farScale: CGFloat = 0.62
    /// How far a coin at the side turns its face that way.
    static let sideTurn: Double = 55
    static let perspective: CGFloat = 0.5
    /// Out of focus behind `sharpUntil` (depth: 1 in front, −1 at the back), up to this share
    /// of the diameter at the back.
    static let blurShare: CGFloat = 0.07
    static let sharpUntil: Double = 0.25
    /// The ring at rest is turned this far (radians), so no coin stands straight behind
    /// another and the first is still in front.
    static let restTurn: Double = 0.26
    /// The coin's thickness, as a share of its diameter.
    static let thickness: CGFloat = 0.07
    /// The bob, up and down, as a share of the diameter, and one bob in seconds.
    static let bob: CGFloat = 0.05
    static let bobPeriod: Double = 3.4
    /// Each coin's tilt (degrees, clockwise), by position: never two alike side by side.
    static let tilts: [Double] = [-4, 3, -2, 5, -3, 2, -5]
    /// The ring's own pace: one turn in `period` seconds, to the right in front.
    static let period: Double = 24
    /// A swipe: how fast a fling's spin settles back to the pace (seconds), and its cap
    /// (radians a second).
    static let settle: Double = 1.1
    static let maxSpin: Double = 14
    /// A swipe starts after this many points, across rather than up and down.
    static let swipeDistance: CGFloat = 8
    /// The front coin's shadow.
    static let shadowOpacity: Double = 0.18
    static let margin: CGFloat = 3
    /// The entrance: coin after coin.
    static let entranceSpring = Animation.spring(response: 0.55, dampingFraction: 0.75)
    static let entranceStagger: Double = 0.06
    /// 30 fps at its own pace, 60 while a finger or a fling turns it.
    static let frameInterval: Double = 1.0 / 30
    static let spinFrameInterval: Double = 1.0 / 60
}

/// The ring in a box.
struct PackedOrbitGeometry: Equatable {
    /// A coin's diameter in front.
    let diameter: CGFloat
    /// From the box's centre to a coin at the side.
    let radius: CGFloat
    /// How much higher the far side stands than the near side.
    let rise: CGFloat

    init(box: CGSize) {
        let metrics = PackedOrbitMetrics.self
        diameter = max(0, min(box.height * metrics.heightShare, box.width * metrics.widthShare))
        radius = max(0, box.width / 2 - diameter / 2 - metrics.margin)
        rise = box.height * metrics.rise
    }

    /// A coin on the ring.
    struct Place: Equatable {
        /// From the box's centre.
        let offset: CGSize
        /// 1 in front, −1 at the back.
        let depth: Double
        let scale: CGFloat
        /// The face turned towards the side the coin is on.
        let turn: Angle
        let blur: CGFloat
    }

    /// A coin at `angle` on the ring: 0 in front, positive to the right.
    func place(at angle: Double) -> Place {
        let metrics = PackedOrbitMetrics.self
        let depth = cos(angle)
        let near = CGFloat((depth + 1) / 2)
        let unfocus = min(max((metrics.sharpUntil - depth) / (metrics.sharpUntil + 1), 0), 1)
        return Place(
            offset: CGSize(width: Double(radius) * sin(angle), height: Double(rise) * depth / 2),
            depth: depth,
            scale: metrics.farScale + (1 - metrics.farScale) * near,
            // Faces out from the ring at the sides; the back ones face the viewer again, as
            // the front ones do, so no coin shows its back.
            turn: .degrees(-sin(angle) * metrics.sideTurn),
            blur: metrics.blurShare * diameter * CGFloat(unfocus)
        )
    }

    /// Where coin `index` of `count` stands when the ring is at rest: the first in front (a
    /// little to the right, `restTurn`), the next to its left, so the ring, turning right,
    /// brings them forward in order.
    static func angle(_ index: Int, of count: Int) -> Double {
        guard count > 0 else { return 0 }
        return PackedOrbitMetrics.restTurn - 2 * Double.pi * Double(index) / Double(count)
    }
}

/// The ring's turn: its own pace, a finger, a fling settling back. A reference, so a frame
/// can move it on without a state change.
final class PackedOrbitSpin {
    /// The ring's turn, in radians.
    private(set) var angle: Double = 0
    /// Radians a second.
    private(set) var velocity: Double = 0
    private var lastTime: Double?
    private var dragStart: Double?

    var isDragging: Bool { dragStart != nil }

    /// Spun faster than its pace by a finger or a fling.
    func isSpun(pace: Double) -> Bool {
        isDragging || abs(velocity - pace) > 0.6
    }

    /// The angle at `time`: on at the pace, or a fling settling back to it.
    func advance(to time: Double, pace: Double) -> Double {
        let dt = lastTime.map { min(max(time - $0, 0), 0.1) } ?? 0
        lastTime = time
        guard !isDragging else { return angle }
        velocity += (pace - velocity) * (1 - exp(-dt / PackedOrbitMetrics.settle))
        angle += velocity * dt
        return angle
    }

    func drag(by translation: CGFloat, radius: CGFloat) {
        if dragStart == nil { dragStart = angle }
        angle = (dragStart ?? angle) + Double(translation / max(radius, 1))
    }

    /// The finger lifts: the ring coasts with its speed (`coasts`), or stops.
    func release(velocity flick: CGFloat, radius: CGFloat, coasts: Bool) {
        dragStart = nil
        let spin = Double(flick / max(radius, 1))
        velocity = coasts ? min(max(spin, -PackedOrbitMetrics.maxSpin), PackedOrbitMetrics.maxSpin) : 0
    }
}

// MARK: - Carousel

struct PackedOrbit: View {
    let items: [PackedCircleItem]
    let overflowCount: Int
    let size: CGSize

    @Environment(\.designKitMotion) private var designKitMotion
    @State private var spin = PackedOrbitSpin()
    @State private var isTouching = false
    @State private var hasEntered = false

    init(items: [PackedCircleItem], overflowCount: Int, size: CGSize) {
        self.items = items
        self.overflowCount = overflowCount
        self.size = size
    }

    /// The items by amount, the largest first (in front).
    private var ranked: [PackedCircleItem] {
        items.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        let geometry = PackedOrbitGeometry(box: size)
        AmbientMotionGate { allowsAmbientMotion in
            let moves = allowsAmbientMotion && designKitMotion
            TimelineView(.animation(
                minimumInterval: isTouching ? PackedOrbitMetrics.spinFrameInterval : PackedOrbitMetrics.frameInterval,
                paused: !moves && !isTouching
            )) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let pace = moves ? 2 * Double.pi / PackedOrbitMetrics.period : 0
                let angle = spin.advance(to: time, pace: pace)
                ring(angle: angle, geometry: geometry, bobTime: moves ? time : 0)
                    .onChange(of: frontIndex(angle: angle)) {
                        if spin.isSpun(pace: pace) { HapticManager.play(.tick) }
                    }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .simultaneousGesture(swipe(geometry: geometry, coasts: moves))
            .task { hasEntered = true }
        }
    }

    private var count: Int { ranked.count + (overflowCount > 0 ? 1 : 0) }

    private func ring(angle: Double, geometry: PackedOrbitGeometry, bobTime: Double) -> some View {
        let ranked = self.ranked
        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                let place = geometry.place(at: PackedOrbitGeometry.angle(index, of: count) + angle)
                let bob = PackedOrbitMetrics.bob * geometry.diameter
                    * CGFloat(sin(bobTime * 2 * .pi / PackedOrbitMetrics.bobPeriod + Double(index) * 1.3))
                PackedCoin(
                    item: index < ranked.count ? ranked[index] : nil,
                    overflowCount: overflowCount,
                    diameter: geometry.diameter,
                    turn: place.turn,
                    tilt: .degrees(PackedOrbitMetrics.tilts[index % PackedOrbitMetrics.tilts.count]),
                    nearness: max(0, place.depth)
                )
                .blur(radius: place.blur)
                .scaleEffect(place.scale * (hasEntered ? 1 : 0.4))
                .opacity(hasEntered ? 1 : 0)
                .animation(entrance(index), value: hasEntered)
                .offset(x: place.offset.width, y: place.offset.height + bob)
                .zIndex(place.depth)
            }
        }
    }

    /// The coin nearest the front.
    private func frontIndex(angle: Double) -> Int {
        guard count > 0 else { return 0 }
        let step = 2 * Double.pi / Double(count)
        let turns = ((angle + PackedOrbitMetrics.restTurn) / step).rounded()
        return ((Int(turns) % count) + count) % count
    }

    private func swipe(geometry: PackedOrbitGeometry, coasts: Bool) -> some Gesture {
        DragGesture(minimumDistance: PackedOrbitMetrics.swipeDistance)
            .onChanged { value in
                // Across, not up and down: a scroll view keeps its scroll.
                guard spin.isDragging || abs(value.translation.width) > abs(value.translation.height) else { return }
                spin.drag(by: value.translation.width, radius: geometry.radius)
                if !isTouching { isTouching = true }
            }
            .onEnded { value in
                guard spin.isDragging else { return }
                spin.release(velocity: value.velocity.width, radius: geometry.radius, coasts: coasts)
                isTouching = false
            }
    }

    /// Coin `index` coming in; none without DesignKit's motion.
    private func entrance(_ index: Int) -> Animation? {
        guard designKitMotion, !AppAnimation.isReduceMotionEnabled else { return nil }
        return PackedOrbitMetrics.entranceSpring.delay(Double(index) * PackedOrbitMetrics.entranceStagger)
    }
}

// MARK: - Coin

/// A coin of the carousel: its face turned towards its side, the rim showing behind it, a
/// sheen across it and, in front, a soft shadow.
private struct PackedCoin: View {
    /// `nil`: the "+N" coin.
    let item: PackedCircleItem?
    let overflowCount: Int
    let diameter: CGFloat
    let turn: Angle
    let tilt: Angle
    /// 0 at the sides and the back, 1 in front.
    let nearness: Double

    @Environment(\.colorScheme) private var colorScheme

    private var thickness: CGFloat { diameter * PackedOrbitMetrics.thickness }

    var body: some View {
        ZStack {
            // The rim: the coin's side, out from behind the face where it turns away, and
            // along the bottom, seen from slightly above.
            Circle()
                .fill(LinearGradient(colors: rimColors, startPoint: .top, endPoint: .bottom))
                .frame(width: diameter, height: diameter)
                .rotation3DEffect(turn, axis: (x: 0, y: 1, z: 0), perspective: PackedOrbitMetrics.perspective)
                .offset(x: thickness * CGFloat(sin(turn.radians)), y: thickness * 0.55)
            face
                .frame(width: diameter, height: diameter)
                .overlay { sheen }
                .clipShape(Circle())
                .rotation3DEffect(turn, axis: (x: 0, y: 1, z: 0), perspective: PackedOrbitMetrics.perspective)
        }
        .rotationEffect(tilt)
        .shadow(color: .black.opacity(PackedOrbitMetrics.shadowOpacity * nearness),
                radius: diameter * 0.1, y: diameter * 0.08)
    }

    /// The side of the coin: light plastic in light mode, darker in dark mode.
    private var rimColors: [Color] {
        colorScheme == .dark
            ? [Color(white: 0.44), Color(white: 0.24)]
            : [Color(white: 0.93), Color(white: 0.7)]
    }

    @ViewBuilder
    private var face: some View {
        if let item, case .sfSymbol = item.iconSource {
            let tint = item.tint ?? AppColors.accent
            ZStack {
                Circle().fill(LinearGradient(colors: [tint.mix(with: .white, by: 0.12), tint.mix(with: .black, by: 0.18)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Icon(source: item.iconSource, style: .circle(size: diameter, tint: .monochrome(.white),
                                                             padding: PackedCircleMetrics.symbolPadding(for: diameter)))
                    .shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5)
            }
        } else if let item {
            // The logo fills its coin, as a flag fills a badge; white behind one that does not.
            ZStack {
                Circle().fill(.white)
                Icon(source: item.iconSource, style: .circle(size: diameter, tint: .original))
            }
        } else {
            let grey = AppColors.Text.tertiary
            ZStack {
                Circle().fill(LinearGradient(colors: [grey.mix(with: .white, by: 0.15), grey.mix(with: .black, by: 0.2)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                PackedOverflowLabel(count: overflowCount, size: diameter)
                    .foregroundStyle(.white)
            }
        }
    }

    /// Light across the face from the upper left, and an edge catching it at the top.
    private var sheen: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.3), location: 0),
                    .init(color: .white.opacity(0), location: 0.45),
                    .init(color: .white.opacity(0), location: 0.8),
                    .init(color: .white.opacity(0.08), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle().strokeBorder(
                LinearGradient(colors: [.white.opacity(0.55), .black.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                lineWidth: max(1, diameter * 0.025)
            )
        }
        .allowsHitTesting(false)
    }
}
