//
//  RefreshDropletGeometry.swift
//  DesignKit
//
//  8.21.0: the shape of `.dsRefreshable`'s mercury as a pure function of its phase and the
//  source it runs out of (the Dynamic Island, or the top edge). `RefreshIndicator` draws the
//  circles; a blur and an alpha threshold melt them into one liquid. Foundation only, so it is
//  tested without a screen.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Where a pull to refresh is (8.21.0): `RefreshIndicator(phase:)` draws it, `.dsRefreshable`
/// drives it.
public enum RefreshPhase: Equatable, Sendable {
    /// Nothing pulled, nothing loading: nothing drawn.
    case idle
    /// Being pulled: `progress` 0…1 of the distance that starts a refresh, `elapsed` seconds since
    /// the pull began (the drips fall in time).
    case pulling(progress: Double, elapsed: TimeInterval = 0)
    /// Loading, `elapsed` seconds since it started: six beads circle under the source.
    case refreshing(elapsed: TimeInterval)
    /// Done, `elapsed` seconds since: the beads merge and flow back into the source.
    case finishing(elapsed: TimeInterval)
}

/// The numbers of the mercury, in points (from the proposals' prototype, × 1.34 for a 402 pt
/// iPhone). Tuned on a device.
enum RefreshMetrics {
    /// The pull that starts a refresh, about where the system's refresh control triggers.
    static let triggerDistance: CGFloat = 110
    /// The least time the beads circle, so a fast answer does not blink.
    static let minimumShowing: TimeInterval = 0.6
    /// How long the beads take to flow back into the source.
    static let finishing: TimeInterval = 1.0
    /// Black down to the island's bottom, the accent from this far below it.
    static let gradientRun: CGFloat = 18
    /// The shadow of the beads on a coloured hero.
    static let shadowOpacity = 0.3
    static let shadowRadius: CGFloat = 4
    static let shadowY: CGFloat = 2
    /// How much of the scroll view's top the indicator covers (from the screen's top).
    static let overlayHeight: CGFloat = 240
    /// Reduce Motion's ring.
    static let reduceMotionRing: CGFloat = 18
    /// The blur that melts the circles into one liquid.
    static let blur: CGFloat = 6
    /// The thinnest the thread gets before the refresh starts: still a thread under the blur.
    static let unbrokenNeck: CGFloat = 4

    static let islandSize = CGSize(width: 126, height: 37)
    /// The island's top is this far above the safe area's top (59 → 11, 62 → 14).
    static let islandTopAboveSafeArea: CGFloat = 48
    /// A safe area this tall at the top means an island (a notch's is 44–50).
    static let islandSafeAreaMinimum: CGFloat = 54
    /// Without an island the liquid comes from above the top edge, out of a rect this size.
    static let edgeSource = CGSize(width: 150, height: 40)

    static let neckCount = 8
    static let beadCount = 6
    static let beadRadius: CGFloat = 7
    static let ringRadius: CGFloat = 16
    static let ringBreath = 0.24
    /// The beads circle this far under the source's bottom.
    static let ringDepth: CGFloat = 40
    static let dripInterval: TimeInterval = 0.21
    static let firstDrip: TimeInterval = 0.25
}

/// The Dynamic Island's frame, estimated (8.21.0): there is no API for it. An iPhone in
/// portrait whose top safe area is at least 54 pt has one, 126 × 37 pt, centred, 48 pt above the
/// safe area's top. Nil without one, and when the scroll view does not start at the screen's top
/// (a sheet, under a header): the liquid then runs from the top edge.
enum DynamicIslandFrame {
    static func frame(safeAreaTop: CGFloat, screenWidth: CGFloat, isPhone: Bool, isPortrait: Bool,
                      overlayMinY: CGFloat) -> CGRect? {
        guard isPhone, isPortrait, safeAreaTop >= RefreshMetrics.islandSafeAreaMinimum, overlayMinY <= 1 else {
            return nil
        }
        let size = RefreshMetrics.islandSize
        return CGRect(x: (screenWidth - size.width) / 2, y: safeAreaTop - RefreshMetrics.islandTopAboveSafeArea,
                      width: size.width, height: size.height)
    }

    /// The source without an island: a rect just above the top edge, centred.
    static func edge(width: CGFloat) -> CGRect {
        let size = RefreshMetrics.edgeSource
        return CGRect(x: (width - size.width) / 2, y: -size.height, width: size.width, height: size.height)
    }
}

/// A circle of the liquid.
struct DropletCircle: Equatable {
    var center: CGPoint
    var radius: CGFloat
}

/// The circles of one frame of the mercury.
struct DropletFrame: Equatable {
    /// The thread from the source, wide at the top, with a waist.
    var neck: [DropletCircle] = []
    /// Drops falling from the source while pulling.
    var drips: [DropletCircle] = []
    /// The pool at the thread's end (pulling) or the core the beads leave and return to.
    var drop = DropletCircle(center: .zero, radius: 0)
    /// The six beads that circle while loading.
    var beads: [DropletCircle] = []
    /// The source blob's width, × this: it springs when the mercury flows back in.
    var sourceScale: CGFloat = 1

    var all: [DropletCircle] { neck + drips + [drop] + beads }
}

enum RefreshDropletGeometry {
    static func frame(for phase: RefreshPhase, source: CGRect) -> DropletFrame {
        switch phase {
        case .idle:
            return DropletFrame()
        case .pulling(let progress, let elapsed):
            return pulling(min(max(progress, 0), 1), elapsed: max(elapsed, 0), source: source)
        case .refreshing(let elapsed):
            return refreshing(max(elapsed, 0), source: source)
        case .finishing(let elapsed):
            return finishing(max(elapsed, 0), source: source)
        }
    }

    // MARK: Pulling

    private static func pulling(_ p: Double, elapsed: TimeInterval, source: CGRect) -> DropletFrame {
        var frame = DropletFrame()
        let (neck, dropY, dropRadius) = thread(p, source: source)
        frame.neck = neck

        // Drips: one every 0.21 s once the pull is past 15 %; each falls and joins the pool.
        var landed = 0
        var drips: [DropletCircle] = []
        if p > 0.15, elapsed >= RefreshMetrics.firstDrip {
            let spawned = Int((elapsed - RefreshMetrics.firstDrip) / RefreshMetrics.dripInterval) + 1
            for k in max(0, spawned - 2)..<spawned {
                let age = elapsed - RefreshMetrics.firstDrip - Double(k) * RefreshMetrics.dripInterval
                let radius = 5.2 + 1.5 * fract(sin(Double(k) * 12.9898) * 43758.5453)
                let y = source.maxY + 3 + 54 * age + 938 * age * age
                if y + radius >= dropY - dropRadius * 0.75 * 0.4 {
                    landed += 1
                } else {
                    drips.append(DropletCircle(center: CGPoint(x: source.midX, y: y), radius: radius))
                }
            }
            landed += max(0, spawned - 2)
        }
        frame.drips = drips + Array(repeating: DropletCircle(center: CGPoint(x: source.midX, y: source.maxY), radius: 0),
                                    count: 2 - drips.count)
        let pool = dropRadius * 0.75 + min(4, 0.47 * CGFloat(landed))
        frame.drop = DropletCircle(center: CGPoint(x: source.midX, y: dropY), radius: dropRadius == 0 ? 0 : pool)
        frame.beads = idleBeads(source)
        return frame
    }

    /// The thread at a pull of `p`: its circles, the pool's centre and its radius.
    private static func thread(_ p: Double, source: CGRect) -> ([DropletCircle], CGFloat, CGFloat) {
        let dropY = source.maxY + 5 + CGFloat(p) * 59
        let dropRadius: CGFloat = p < 0.02 ? 0 : 4 + CGFloat(p) * 14
        let count = RefreshMetrics.neckCount
        let neck = (0..<count).map { k -> DropletCircle in
            let f = CGFloat(k) / CGFloat(count - 1)
            let y = lerp(source.maxY - 8, dropY - dropRadius * 0.3, f)
            let top = lerp(12, 8, CGFloat(p)) * 0.72
            let bottom = dropRadius * 0.8
            let waist = 1 - CGFloat(p * p) * 0.55 * sin(.pi * f)
            return DropletCircle(center: CGPoint(x: source.midX, y: y),
                                 radius: p < 0.02 ? 0 : lerp(top, bottom, f) * waist)
        }
        return (neck, dropY, dropRadius)
    }

    // MARK: Refreshing

    private static func refreshing(_ t: TimeInterval, source: CGRect) -> DropletFrame {
        var frame = DropletFrame()
        // The thread snaps back into the source over 0.3 s.
        let (fullNeck, fullDropY, _) = thread(1, source: source)
        let k = smoothstep(t / 0.3)
        frame.neck = fullNeck.map {
            DropletCircle(center: CGPoint(x: $0.center.x, y: lerp($0.center.y, source.maxY - 13, k)),
                          radius: $0.radius * (1 - k))
        }
        frame.drips = Array(repeating: DropletCircle(center: CGPoint(x: source.midX, y: source.maxY), radius: 0), count: 2)

        let centre = CGPoint(x: source.midX,
                             y: lerp(fullDropY, source.maxY + RefreshMetrics.ringDepth, smoothstep(t / 0.35)))
        let spring = 1 - exp(-6.5 * t) * (cos(10.4 * t) + 0.625 * sin(10.4 * t))
        let ring = RefreshMetrics.ringRadius * CGFloat(spring) * CGFloat(1 + RefreshMetrics.ringBreath * sin(t / 0.26))
        frame.beads = beads(around: centre, ring: ring, angle: t / 0.36, radius: RefreshMetrics.beadRadius)
        frame.drop = DropletCircle(center: centre, radius: max(0, 10.7 - ring * 0.7))
        return frame
    }

    // MARK: Finishing

    private static func finishing(_ e: TimeInterval, source: CGRect) -> DropletFrame {
        var frame = DropletFrame()
        frame.neck = Array(repeating: DropletCircle(center: CGPoint(x: source.midX, y: source.maxY), radius: 0),
                           count: RefreshMetrics.neckCount)
        frame.drips = Array(repeating: DropletCircle(center: CGPoint(x: source.midX, y: source.maxY), radius: 0), count: 2)

        let centre = CGPoint(x: source.midX,
                             y: lerp(source.maxY + RefreshMetrics.ringDepth, source.midY, smoothstep((e - 0.3) / 0.4)))
        let ring = RefreshMetrics.ringRadius * (1 - smoothstep(e / 0.3))
        frame.beads = beads(around: centre, ring: ring, angle: e / 0.36,
                            radius: RefreshMetrics.beadRadius * (1 - smoothstep(e / 0.42)))
        let core = 12 * smoothstep(e / 0.3) * (1 - smoothstep((e - 0.6) / 0.4))
        frame.drop = DropletCircle(center: centre, radius: core)
        if e > 0.7 {
            let s = e - 0.7
            frame.sourceScale = 1 + CGFloat(0.12 * exp(-8 * s) * sin(14 * s))
        }
        return frame
    }

    // MARK: Helpers

    private static func beads(around centre: CGPoint, ring: CGFloat, angle: Double, radius: CGFloat) -> [DropletCircle] {
        (0..<RefreshMetrics.beadCount).map { i in
            let a = angle + Double(i) * 2 * .pi / Double(RefreshMetrics.beadCount)
            return DropletCircle(center: CGPoint(x: centre.x + CGFloat(cos(a)) * ring, y: centre.y + CGFloat(sin(a)) * ring),
                                 radius: max(0, radius))
        }
    }

    private static func idleBeads(_ source: CGRect) -> [DropletCircle] {
        Array(repeating: DropletCircle(center: CGPoint(x: source.midX, y: source.maxY), radius: 0),
              count: RefreshMetrics.beadCount)
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private static func smoothstep(_ x: Double) -> CGFloat {
        let t = min(max(x, 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }

    private static func fract(_ x: Double) -> Double { x - floor(x) }
}
