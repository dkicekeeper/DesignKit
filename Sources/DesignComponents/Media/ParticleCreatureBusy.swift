//
//  ParticleCreatureBusy.swift
//  DesignKit
//
//  What the creature is busy with (vNext): four shapes of the swarm for the steps of an
//  assistant's work, so the person sees what it is doing and not only that it is busy, each with
//  the eyes on the work.
//
//  - `.searching`: a beam of light sweeps round the globe like a radar's; the particles it
//    reaches swell and light up, then fade behind it. The eyes follow the beam.
//  - `.calculating`: the sphere's bands turn a quarter at a time, three turns to mix it and three
//    back, then a click of light when it comes out right. The eyes on the band that turns, a
//    smile in them at the click.
//  - `.connecting`: part of the swarm becomes nodes linked by lines of light, pulses hop from
//    node to node along the links and light the node they reach; the rest is a faint sphere.
//    The eyes follow a pulse.
//  - `.writing`: a ribbon of lanes runs round the sphere behind a pen point, its line waving like
//    a hand's and staying where it was written, bright at the pen and fading behind it; the rest
//    is a faint sphere. The eyes on the pen.
//
//  Pure geometry from the time, no SwiftUI: a frame's shape is set up once (a few numbers, the
//  nodes and their links), then each particle's spot is a handful of multiplications. The only
//  state is the pulses' walk from node to node. A spot is in sphere radii from the sphere's
//  centre, y down, with a depth from 0 (far: small and faint) to 1 (near: large and bright), as
//  the rest of the swarm.
//

import Foundation

/// A particle's place in a busy shape: x and y in sphere radii from the sphere's centre (y down)
/// and its depth, 0 (far: small, faint, behind the core) … 1 (near: large, bright).
struct CreatureSpot: Equatable {
    var x: Double
    var y: Double
    var depth: Double
}

/// A turn of the unit sphere for the view: about the vertical axis (yaw), then its top away from
/// the viewer (pitch). x right, y down, z towards the viewer, as the creature's sphere.
struct CreatureTurn {
    let cosYaw: Double
    let sinYaw: Double
    let cosPitch: Double
    let sinPitch: Double

    init(yaw: Double, pitch: Double) {
        cosYaw = cos(yaw)
        sinYaw = sin(yaw)
        cosPitch = cos(pitch)
        sinPitch = sin(pitch)
    }

    /// The yaw alone: x and z after it.
    func yawed(_ x: Double, _ z: Double) -> (x: Double, z: Double) {
        (x * cosYaw + z * sinYaw, -x * sinYaw + z * cosYaw)
    }

    /// The pitch alone, after the yaw: y and z after it.
    func pitched(_ y: Double, _ z: Double) -> (y: Double, z: Double) {
        (y * cosPitch - z * sinPitch, y * sinPitch + z * cosPitch)
    }

    func callAsFunction(_ v: SIMD3<Double>) -> SIMD3<Double> {
        let (x, z1) = yawed(v.x, v.z)
        let (y, z) = pitched(v.y, z1)
        return SIMD3(x, y, z)
    }
}

/// Small numbers shared by the busy shapes.
enum CreatureBusyMath {
    static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }

    static func smooth(_ x: Double) -> Double {
        let c = clamp(x, 0, 1)
        return c * c * (3 - 2 * c)
    }

    /// 0 → 1 with a small overshoot at the end: a part that clicks into place.
    static func click(_ x: Double) -> Double {
        let m = clamp(x, 0, 1) - 1
        let s = 0.9
        return 1 + (s + 1) * m * m * m + s * m * m
    }

    /// A stable number in 0..<1 for two inputs.
    static func hash(_ a: Double, _ b: Double) -> Double {
        let h = sin(a * 127.1 + b * 311.7) * 43_758.545_3
        return h - h.rounded(.down)
    }

    /// An angle in 0..<2π.
    static func wrap(_ angle: Double) -> Double {
        let turn = 2 * Double.pi
        let a = angle.truncatingRemainder(dividingBy: turn)
        return a < 0 ? a + turn : a
    }

    /// The depth of a point on the unit sphere from its z (towards the viewer).
    static func near(_ z: Double) -> Double {
        clamp((z + 1) / 2, 0, 1)
    }

    /// The sphere's breath for one particle: its radius in sphere radii, a little in and out in
    /// its own phase, as the resting sphere's.
    static func breath(_ t: Double, phase: Double) -> Double {
        0.95 + 0.04 * sin(t * 1.3 + phase * 2 * .pi)
    }

    /// Where a point on the sphere sits for the eyes: -1…1 each way, a little past the rim
    /// counted as the edge.
    static func gaze(_ v: SIMD3<Double>) -> (x: Double, y: Double) {
        (clamp(v.x * 1.1, -1, 1), clamp(v.y * 1.1, -1, 1))
    }
}

// MARK: - Globe

/// The swarm laid out as a globe (vNext): rows of particles along its parallels, as many in a row
/// as its length allows, so a beam lights a column of them and a turned band breaks its rows.
/// Searching and calculating stand on it.
enum CreatureGlobe {
    /// Rows for `count` particles: about a third of a particle's spacing apart, five at least.
    static func rows(for count: Int) -> Int {
        max(5, Int((Double(count) / 3.2).squareRoot().rounded()))
    }

    /// A place on the globe for each of `count` particles, in their order. The rows go from the
    /// bottom (y 1) to the top, as the particles of the resting sphere do, and in a row each takes
    /// the place nearest its own longitude, so a change of mood moves them a little sideways only.
    static func places(count: Int) -> [SIMD3<Double>] {
        guard count > 0 else { return [] }
        let rows = min(rows(for: count), count)
        let latitudes = (0..<rows).map { Double.pi / 2 - (Double($0) + 0.5) * Double.pi / Double(rows) }
        let weights = latitudes.map { cos($0) }
        let total = weights.reduce(0, +)
        // Each row's share of the particles by its length, the remainders given to the longest.
        let shares = weights.map { Double(count) * $0 / total }
        var sizes = shares.map { max(1, Int($0.rounded(.down))) }
        var left = count - sizes.reduce(0, +)
        let byRemainder = shares.indices.sorted { shares[$0] - shares[$0].rounded(.down) > shares[$1] - shares[$1].rounded(.down) }
        var k = 0
        while left > 0 {
            sizes[byRemainder[k % rows]] += 1
            left -= 1
            k += 1
        }
        while left < 0, let widest = sizes.indices.max(by: { sizes[$0] < sizes[$1] }), sizes[widest] > 1 {
            sizes[widest] -= 1
            left += 1
        }
        let golden = Double.pi * (3 - 5.0.squareRoot())
        var places = [SIMD3<Double>](repeating: SIMD3(0, 1, 0), count: count)
        var start = 0
        for row in 0..<rows where start < count {
            let size = min(sizes[row], count - start)
            let y = sin(latitudes[row])
            let ring = cos(latitudes[row])
            // The row's particles by their own longitude, each to the next slot round the row.
            let members = (start..<start + size).sorted {
                wrap(Double($0) * golden) < wrap(Double($1) * golden)
            }
            let first = wrap(Double(members.first ?? start) * golden)
            for (slot, index) in members.enumerated() {
                let longitude = first + Double(slot) / Double(size) * 2 * .pi
                // y down on screen: the first rows, y near 1, are at the bottom.
                places[index] = SIMD3(cos(longitude) * ring, y, sin(longitude) * ring)
            }
            start += size
        }
        return places
    }

    private static func wrap(_ angle: Double) -> Double { CreatureBusyMath.wrap(angle) }
}

// MARK: - Searching

/// Searching (vNext): a beam sweeps round the globe; what it reaches swells and lights up, then
/// fades behind it. A size and light ripple, not a shine, so it reads in ink on a white page too.
struct CreatureSearch {
    /// The globe's own slow turn (radians a second) and its tip (radians).
    static let spin = 0.18
    static let pitch = 0.32
    /// The beam's speed round the globe (radians a second: a turn in about 2.7 s).
    static let sweep = 2.3
    /// How far ahead of the beam the particles start to light, and how far behind it the light
    /// has fallen to a third (radians).
    static let lead = 0.22
    static let tail = 0.75
    /// How far a lit particle stands out of the globe, and how much of its light an unlit one
    /// keeps.
    static let swell = 0.12
    static let rest = 0.5

    let t: Double
    let turn: CreatureTurn
    /// The beam's longitude, from the front towards the right.
    let beam: Double

    init(t: Double) {
        self.t = t
        turn = CreatureTurn(yaw: t * Self.spin, pitch: Self.pitch)
        beam = t * Self.sweep
    }

    /// How lit a particle is at `longitude`: 1 under the beam, rising just ahead of it, fading
    /// behind it.
    func light(at longitude: Double) -> Double {
        let passed = CreatureBusyMath.wrap(beam - longitude)
        let ahead = 2 * Double.pi - passed
        return ahead < Self.lead ? CreatureBusyMath.smooth(1 - ahead / Self.lead) : exp(-passed / Self.tail)
    }

    func spot(_ u: SIMD3<Double>, phase: Double) -> CreatureSpot {
        let (x, z1) = turn.yawed(u.x, u.z)
        let lit = light(at: atan2(x, z1))
        let (y, z) = turn.pitched(u.y, z1)
        let r = CreatureBusyMath.breath(t, phase: phase) * (1 + Self.swell * lit)
        let base = CreatureBusyMath.near(z) * Self.rest
        // The beam lights the front; behind the globe it only glimmers.
        let facing = CreatureBusyMath.smooth((z + 0.25) / 0.6)
        return CreatureSpot(x: x * r, y: y * r, depth: base + (1 - base) * lit * (0.25 + 0.75 * facing))
    }

    /// The eyes on the beam where it crosses the equator: left to right across the front, back
    /// while it goes round behind.
    var gaze: (x: Double, y: Double) {
        let (y, _) = turn.pitched(0, cos(beam))
        return (0.9 * sin(beam), 0.9 * y)
    }
}

// MARK: - Calculating

/// Calculating (vNext): rounds of three quarter turns of the sphere's bands, then the same turns
/// undone in reverse, so every round comes out right with a click of light.
struct CreatureSums {
    struct Move: Equatable {
        /// 0 x, 1 y, 2 z: the axis the band turns round.
        let axis: Int
        /// 0, 1, 2: the band across that axis (a third of the sphere each).
        let band: Int
        let sign: Double
        /// How far it has turned, 0…1 of a quarter (a little more in the click).
        let amount: Double
    }

    static let moves = 3
    /// A move's slot and the turn in it (seconds), the pause before the turns back, the rest
    /// after the click.
    static let slot = 0.42
    static let turnTime = 0.3
    static let pause = 0.2
    static let rest = 0.8
    static let round = Double(moves * 2) * slot + pause + rest
    /// When, in a round, the last turn back has clicked into place.
    static let finished = Double(moves * 2 - 1) * slot + pause + turnTime
    /// The sphere's slow turn and its tip, so three sides of it show.
    static let spin = 0.3
    static let pitch = 0.45
    /// How bright the band that turns is at mid-turn, and the click: its light and swell.
    static let turning = 0.3
    static let clickLight = 0.22
    static let clickSwell = 0.04
    static let clickFade = 0.35
    /// The smile in the eyes at the click (a cheek, a share of the eye's height).
    static let smile = 0.4

    let t: Double
    let turn: CreatureTurn
    let moves: [Move]
    /// The move turning now.
    let active: Int?
    /// The click when the round comes out right: 1 at the moment, fading.
    let solved: Double

    init(t: Double) {
        self.t = t
        turn = CreatureTurn(yaw: t * Self.spin, pitch: Self.pitch)
        let k = (t / Self.round).rounded(.down)
        let local = t - k * Self.round
        var moves: [Move] = []
        moves.reserveCapacity(Self.moves)
        var active: Int?
        var axis = min(2, Int(CreatureBusyMath.hash(k, 1.3) * 3))
        for m in 0..<Self.moves {
            let fm = Double(m)
            // A new axis each time, so the turns cross.
            if m > 0 { axis = (axis + 1 + Int(CreatureBusyMath.hash(k, fm + 4.1) * 2)) % 3 }
            let band = min(2, Int(CreatureBusyMath.hash(k, fm + 7.7) * 3))
            let sign: Double = CreatureBusyMath.hash(k, fm + 9.3) < 0.5 ? 1 : -1
            let out = fm * Self.slot
            let back = Double(Self.moves) * Self.slot + Self.pause + Double(Self.moves - 1 - m) * Self.slot
            let amount = CreatureBusyMath.click((local - out) / Self.turnTime)
                - CreatureBusyMath.click((local - back) / Self.turnTime)
            if (local > out && local < out + Self.turnTime) || (local > back && local < back + Self.turnTime) {
                active = m
            }
            moves.append(Move(axis: axis, band: band, sign: sign, amount: amount))
        }
        self.moves = moves
        self.active = active
        solved = local >= Self.finished ? exp(-(local - Self.finished) / Self.clickFade) : 0
    }

    static func band(of coordinate: Double) -> Int {
        coordinate < -1.0 / 3 ? 0 : coordinate < 1.0 / 3 ? 1 : 2
    }

    /// `u` after the round's turns so far, and how bright the turning band makes it.
    func turned(_ u: SIMD3<Double>) -> (point: SIMD3<Double>, glow: Double) {
        var p = u
        var glow = 0.0
        for m in moves.indices where moves[m].amount != 0 {
            let move = moves[m]
            guard Self.band(of: p[move.axis]) == move.band else { continue }
            if m == active { glow = sin(.pi * CreatureBusyMath.clamp(move.amount, 0, 1)) }
            let angle = move.sign * .pi / 2 * move.amount
            let c = cos(angle)
            let s = sin(angle)
            switch move.axis {
            case 0: p = SIMD3(p.x, p.y * c - p.z * s, p.y * s + p.z * c)
            case 1: p = SIMD3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c)
            default: p = SIMD3(p.x * c - p.y * s, p.x * s + p.y * c, p.z)
            }
        }
        return (p, glow)
    }

    func spot(_ u: SIMD3<Double>, phase: Double) -> CreatureSpot {
        let (p, glow) = turned(u)
        let v = turn(p)
        let r = CreatureBusyMath.breath(t, phase: phase) * (1 + Self.clickSwell * solved)
        let near = CreatureBusyMath.near(v.z)
        let depth = near * 0.86 + Self.turning * glow + Self.clickLight * solved * near
        return CreatureSpot(x: v.x * r, y: v.y * r, depth: CreatureBusyMath.clamp(depth, 0, 1))
    }

    /// The eyes on the middle of the band that turns; a little down between turns.
    var gaze: (x: Double, y: Double) {
        guard let active else { return (0, 0.15) }
        let move = moves[active]
        var centre = SIMD3<Double>(repeating: 0)
        centre[move.axis] = Double(move.band - 1) * 2 / 3
        return CreatureBusyMath.gaze(turn(centre))
    }
}

// MARK: - Connecting

/// Connecting (vNext): nodes on the sphere linked by lines of light, pulses hopping along the
/// links. Every `stride`th particle is a node, the one halfway to the next a pulse (the first
/// few), the rest a faint sphere.
final class CreatureNetwork {
    /// The sphere's slow turn and its tip.
    static let spin = 0.14
    static let pitch = 0.3
    /// How far a node wanders from its place (unit sphere).
    static let wander = 0.3
    /// One hop from node to node (seconds), and how long a node glows after a pulse leaves it.
    static let hop = 0.6
    static let glowFade = 0.35
    /// How much light a node, a pulse and a glowing node add, and the faint sphere's depth.
    static let nodeLight = 0.2
    static let pulseLight = 0.4
    static let glowLight = 0.35
    static let ghost = 0.42

    /// The links' reach for `count` nodes (a chord of the unit sphere): about five each.
    static func reach(_ count: Int) -> Double { 4.3 / Double(max(count, 1)).squareRoot() }

    private struct Walk {
        var segment: Int
        var from: Int
        var to: Int
        var previous: Int
    }

    private(set) var stride = 0
    private(set) var nodeCount = 0
    private(set) var pulseCount = 0
    /// The nodes this frame, turned for the view (unit sphere).
    private(set) var nodes: [SIMD3<Double>] = []
    /// How much each node glows, 0…1: a pulse left it or is reaching it.
    private(set) var glows: [Double] = []
    /// The links between nodes (node indices, a < b), strength 1 when they touch, 0 at the reach.
    private(set) var links: [(a: Int, b: Int, strength: Double)] = []
    /// The pulses this frame, turned for the view.
    private(set) var pulses: [SIMD3<Double>] = []

    private var particles = 0
    private var places: [SIMD3<Double>] = []
    private var world: [SIMD3<Double>] = []
    private var neighbours: [[Int]] = []
    private var walks: [Walk] = []
    private var turn = CreatureTurn(yaw: 0, pitch: 0)
    private var t = 0.0

    /// Sizes the network for a swarm of `particles`: about thirty nodes in the hero, twelve in
    /// the avatar.
    func configure(particles: Int, compact: Bool) {
        let stride = max(4, particles / (compact ? 12 : 30))
        guard particles != self.particles || stride != self.stride else { return }
        self.particles = particles
        self.stride = stride
        nodeCount = (particles + stride - 1) / stride
        let pulseSlots = particles > stride / 2 ? (particles - stride / 2 + stride - 1) / stride : 0
        pulseCount = min(compact ? 2 : 5, pulseSlots)
        let golden = Double.pi * (3 - 5.0.squareRoot())
        places = (0..<nodeCount).map { k in
            let y = 1 - 2 * (Double(k) + 0.5) / Double(nodeCount)
            let r = max(0, 1 - y * y).squareRoot()
            let a = Double(k) * golden
            return SIMD3(cos(a) * r, y, sin(a) * r)
        }
        neighbours = Array(repeating: [], count: nodeCount)
        walks = []
    }

    /// Moves the network to `t`: the nodes wander, the links form and break, the pulses hop.
    func update(t: Double) {
        self.t = t
        turn = CreatureTurn(yaw: t * Self.spin, pitch: Self.pitch)
        world.removeAll(keepingCapacity: true)
        for k in 0..<nodeCount {
            let fk = Double(k)
            let drift = SIMD3(sin(t * 0.31 + fk * 2.1), sin(t * 0.23 + fk * 3.7), sin(t * 0.27 + fk * 5.3))
            let v = places[k] + drift * Self.wander
            world.append(v / max((v * v).sum().squareRoot(), 1e-6))
        }
        nodes = world.map { turn($0) }

        let reach = Self.reach(nodeCount)
        links.removeAll(keepingCapacity: true)
        for k in neighbours.indices { neighbours[k].removeAll(keepingCapacity: true) }
        for a in 0..<nodeCount {
            for b in (a + 1)..<max(a + 1, nodeCount) {
                let d = world[a] - world[b]
                let distance = (d * d).sum().squareRoot()
                guard distance < reach else { continue }
                links.append((a, b, 1 - distance / reach))
                neighbours[a].append(b)
                neighbours[b].append(a)
            }
        }

        glows = Array(repeating: 0, count: nodeCount)
        pulses.removeAll(keepingCapacity: true)
        for j in 0..<pulseCount {
            let clock = t / Self.hop + Double(j) * 0.37
            let segment = Int(clock.rounded(.down))
            let f = clock - clock.rounded(.down)
            let walk = step(j, to: segment)
            let along = CreatureBusyMath.smooth(f)
            pulses.append(turn(world[walk.from] + (world[walk.to] - world[walk.from]) * along))
            // The node it left glows and fades; the one it reaches lights as it arrives.
            glows[walk.from] = max(glows[walk.from], exp(-f * Self.hop / Self.glowFade))
            glows[walk.to] = max(glows[walk.to], CreatureBusyMath.smooth((f - 0.8) / 0.2))
        }
    }

    /// Pulse `j`'s hop at `segment`: the next hop goes on from where the last one ended; after a
    /// gap (a still frame, a pause) it starts again from a node of its own.
    private func step(_ j: Int, to segment: Int) -> Walk {
        while walks.count <= j { walks.append(Walk(segment: Int.min, from: 0, to: 0, previous: -1)) }
        var walk = walks[j]
        if walk.segment == segment, walk.from < nodeCount, walk.to < nodeCount { return walk }
        if walk.segment != Int.min, walk.segment + 1 == segment, walk.to < nodeCount {
            walk.previous = walk.from
            walk.from = walk.to
        } else {
            walk.previous = -1
            walk.from = min(nodeCount - 1, Int(CreatureBusyMath.hash(Double(j) * 1.7 + 0.3, Double(segment)) * Double(nodeCount)))
        }
        walk.to = next(from: walk.from, avoiding: walk.previous, seed: CreatureBusyMath.hash(Double(j) + 5.1, Double(segment)))
        walk.segment = segment
        walks[j] = walk
        return walk
    }

    /// A linked node to hop to, not straight back if there is another; the nearest node when
    /// none is linked.
    private func next(from: Int, avoiding previous: Int, seed: Double) -> Int {
        let linked = neighbours[from]
        let onward = linked.count > 1 ? linked.filter { $0 != previous } : linked
        if !onward.isEmpty { return onward[min(onward.count - 1, Int(seed * Double(onward.count)))] }
        var nearest = from
        var best = Double.infinity
        for k in 0..<nodeCount where k != from {
            let d = world[from] - world[k]
            let distance = (d * d).sum()
            if distance < best {
                best = distance
                nearest = k
            }
        }
        return nearest
    }

    /// The node particle `index` is, if it is one.
    func node(of index: Int) -> Int? {
        guard stride > 0, index % stride == 0 else { return nil }
        let k = index / stride
        return k < nodeCount ? k : nil
    }

    /// The pulse particle `index` is, if it is one.
    func pulse(of index: Int) -> Int? {
        guard stride > 0, index % stride == stride / 2 else { return nil }
        let j = index / stride
        return j < pulseCount ? j : nil
    }

    /// The particle a node is drawn with.
    func particle(ofNode k: Int) -> Int { k * stride }

    func spot(index: Int, _ u: SIMD3<Double>, phase: Double) -> CreatureSpot {
        if let k = node(of: index) {
            let v = nodes[k]
            let near = CreatureBusyMath.near(v.z)
            // A node behind the sphere stays behind the core, however much it glows.
            let light = Self.nodeLight + Self.glowLight * glows[k]
            let depth = near < 0.5 ? min(0.49, near + light * 0.5) : min(1, near + light)
            return CreatureSpot(x: v.x, y: v.y, depth: depth)
        }
        if let j = pulse(of: index) {
            let v = pulses[j]
            let near = CreatureBusyMath.near(v.z)
            return CreatureSpot(x: v.x, y: v.y, depth: near < 0.5 ? near : min(1, near + Self.pulseLight))
        }
        let v = turn(u)
        let r = CreatureBusyMath.breath(t, phase: phase)
        return CreatureSpot(x: v.x * r, y: v.y * r, depth: CreatureBusyMath.near(v.z) * Self.ghost)
    }

    /// The eyes on the first pulse as it travels.
    var gaze: (x: Double, y: Double) {
        pulses.first.map { CreatureBusyMath.gaze($0) } ?? (0, 0)
    }
}

// MARK: - Writing

/// Writing (vNext): a ribbon of lanes runs round the sphere behind a pen point. Its line is set
/// by where it is round the sphere, not by the time, so what is written stays in place while the
/// pen moves on: the line appears at the pen and fades behind it. Two particles in three are the
/// ribbon, the rest a faint sphere.
struct CreatureRibbon {
    /// The pen's speed (radians a second: a turn in about 5 s) and how much of the circle the
    /// ribbon covers behind it.
    static let pen = 1.25
    static let length = 0.62
    /// The lanes' spacing across the ribbon (radians of latitude) and the ribbon's radius.
    static let gap = 0.075
    static let radius = 1.05
    /// The ribbon's slope, the sphere's slow turn and its tip.
    static let slope = 0.5
    static let spin = 0.2
    static let pitch = 0.3
    /// How fast the ink fades behind the pen, and the faint sphere's depth.
    static let fade = 2.4
    static let ghost = 0.4

    let t: Double
    let lanes: Int
    let turn: CreatureTurn
    /// The pen's angle round the ribbon.
    let penAngle: Double
    private let across: SIMD3<Double>
    private let up: SIMD3<Double>
    private let normal: SIMD3<Double>

    init(t: Double, compact: Bool) {
        self.t = t
        lanes = compact ? 3 : 4
        turn = CreatureTurn(yaw: t * Self.spin, pitch: Self.pitch)
        penAngle = t * Self.pen
        let slope = Self.slope + 0.12 * sin(t * 0.4)
        across = SIMD3(1, 0, 0)
        up = SIMD3(0, -sin(slope), cos(slope))
        normal = SIMD3(0, -cos(slope), -sin(slope))
    }

    /// Whether particle `index` is in the ribbon (two in three), and its place among them.
    static func rank(of index: Int) -> Int? {
        index % 3 == 0 ? nil : (index / 3) * 2 + index % 3 - 1
    }

    /// How many of `count` particles are in the ribbon.
    static func members(of count: Int) -> Int {
        count - (count + 2) / 3
    }

    /// The written line's height off the ribbon's middle at `angle` round it: a hand's line,
    /// slowly changing from turn to turn.
    func line(at angle: Double) -> Double {
        0.1 * sin(angle * 3 + 0.8 * sin(t * 0.17)) + 0.045 * sin(angle * 8 + 1.3 + 0.6 * sin(t * 0.23))
    }

    /// The point `angle` round the ribbon and `offset` (radians) off its plane, on the unit sphere.
    func point(angle: Double, offset: Double) -> SIMD3<Double> {
        let ring = across * cos(angle) + up * sin(angle)
        return ring * cos(offset) + normal * sin(offset)
    }

    func spot(index: Int, count: Int, _ u: SIMD3<Double>, phase: Double) -> CreatureSpot {
        guard let rank = Self.rank(of: index) else {
            let v = turn(u)
            let r = CreatureBusyMath.breath(t, phase: phase)
            return CreatureSpot(x: v.x * r, y: v.y * r, depth: CreatureBusyMath.near(v.z) * Self.ghost)
        }
        let perLane = max(1, (Self.members(of: count) + lanes - 1) / lanes)
        let lane = rank % lanes
        let behind = Double(rank / lanes) / Double(max(1, perLane - 1))
        let angle = penAngle - behind * Self.length * 2 * .pi
        // The lanes meet at the pen's point, open behind it and narrow again at the tail.
        let width = CreatureBusyMath.smooth(behind / 0.1) * (1 - 0.55 * behind)
        let offset = line(at: angle) + (Double(lane) - Double(lanes - 1) / 2) * Self.gap * width
        let v = turn(point(angle: angle, offset: offset)) * Self.radius
        let ink = exp(-behind * Self.fade)
        let near = CreatureBusyMath.near(v.z / Self.radius)
        let depth = near * (0.55 + 0.45 * ink) + 0.18 * ink * near
        return CreatureSpot(x: v.x, y: v.y, depth: CreatureBusyMath.clamp(depth, 0, 1))
    }

    /// The eyes on the pen, a little lowered: it watches what it writes.
    var gaze: (x: Double, y: Double) {
        let tip = turn(point(angle: penAngle, offset: line(at: penAngle)))
        return (CreatureBusyMath.clamp(0.9 * tip.x, -1, 1), CreatureBusyMath.clamp(0.25 + 0.6 * tip.y, -1, 1))
    }
}
