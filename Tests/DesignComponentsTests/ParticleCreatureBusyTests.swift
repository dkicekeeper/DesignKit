//
//  ParticleCreatureBusyTests.swift
//  DesignComponentsTests
//
//  Pins the busy moods' geometry (vNext, ParticleCreatureBusy.swift): the globe of rows holds
//  every particle on the sphere, a round of sums comes out right, the pulses travel without
//  jumps, the ribbon and every spot stay in the creature's square.
//

import Testing
import Foundation
@testable import DesignComponents

struct ParticleCreatureBusyTests {

    private static func length(_ v: SIMD3<Double>) -> Double { (v * v).sum().squareRoot() }

    /// The resting sphere's particles, as the engine builds them.
    private static func sphere(_ count: Int) -> [SIMD3<Double>] {
        let golden = Double.pi * (3 - 5.0.squareRoot())
        return (0..<count).map { i in
            let y = 1 - Double(i) / Double(count - 1) * 2
            let r = max(0, 1 - y * y).squareRoot()
            let theta = Double(i) * golden
            return SIMD3(cos(theta) * r, y, sin(theta) * r)
        }
    }

    @Test("The globe gives every particle its own place on the sphere, in rows, near where it was", arguments: [48, 90, 150, 238, 400])
    func globe(count: Int) {
        let places = CreatureGlobe.places(count: count)
        #expect(places.count == count)
        for place in places { #expect(abs(Self.length(place) - 1) < 1e-9) }
        let rows = Set(places.map { ($0.y * 1e6).rounded() })
        #expect(rows.count == CreatureGlobe.rows(for: count))
        let distinct = Set(places.map { "\(($0.x * 1e6).rounded()),\(($0.y * 1e6).rounded()),\(($0.z * 1e6).rounded())" })
        #expect(distinct.count == count)
        // A change of mood moves a particle a little, never across the sphere.
        let sphere = Self.sphere(count)
        let farthest = zip(places, sphere).map { Self.length($0 - $1) }.max() ?? 0
        #expect(farthest < 1.2)
    }

    @Test("A round of sums turns three bands and turns them back: the globe comes out as it was")
    func sumsComeOutRight() {
        let places = CreatureGlobe.places(count: 238)
        for round in 0..<6 {
            let start = Double(round) * CreatureSums.round
            let mixed = CreatureSums(t: start + CreatureSums.slot * 2.9)
            #expect(mixed.moves.contains { $0.amount > 0.5 })
            let moved = places.map { Self.length(mixed.turned($0).point - $0) }.max() ?? 0
            #expect(moved > 0.5)

            let solved = CreatureSums(t: start + CreatureSums.finished + 0.05)
            #expect(solved.moves.allSatisfy { $0.amount == 0 })
            #expect(solved.solved > 0.8)
            let error = places.map { Self.length(solved.turned($0).point - $0) }.max() ?? 1
            #expect(error < 1e-12)
        }
    }

    @Test("Each turn crosses the one before it")
    func turnsCross() {
        for k in 0..<20 {
            let sums = CreatureSums(t: Double(k) * CreatureSums.round + 0.1)
            for m in 1..<sums.moves.count { #expect(sums.moves[m].axis != sums.moves[m - 1].axis) }
        }
    }

    @Test("Pulses hop along the network without jumps, from node to node", arguments: [false, true])
    func pulsesTravel(compact: Bool) {
        let network = CreatureNetwork()
        let count = compact ? 60 : 238
        network.configure(particles: count, compact: compact)
        #expect(network.nodeCount >= (compact ? 10 : 25))
        #expect(network.pulseCount == (compact ? 2 : 5))
        var last: [SIMD3<Double>] = []
        var linked = 0
        for frame in 0..<(30 * 12) {
            network.update(t: Double(frame) / 30)
            if !network.links.isEmpty { linked += 1 }
            for link in network.links {
                #expect(link.a < link.b)
                #expect(link.strength > 0 && link.strength <= 1)
            }
            if !last.isEmpty {
                // At most a hop's length in one frame's share of it, with room for the turn.
                for (a, b) in zip(last, network.pulses) { #expect(Self.length(a - b) < 0.25) }
            }
            last = network.pulses
        }
        #expect(linked == 30 * 12)
    }

    @Test("Nodes, pulses and the faint sphere take every particle once")
    func networkRoles() {
        let network = CreatureNetwork()
        network.configure(particles: 238, compact: false)
        network.update(t: 1)
        let nodes = (0..<238).compactMap { network.node(of: $0) }
        let pulses = (0..<238).compactMap { network.pulse(of: $0) }
        #expect(nodes == Array(0..<network.nodeCount))
        #expect(pulses == Array(0..<network.pulseCount))
        for k in 0..<network.nodeCount { #expect(network.node(of: network.particle(ofNode: k)) == k) }
    }

    @Test("Every busy spot stays in the creature's square, its depth 0…1")
    func spotsStayInside() {
        let count = 238
        let sphere = Self.sphere(count)
        let globe = CreatureGlobe.places(count: count)
        let network = CreatureNetwork()
        network.configure(particles: count, compact: false)
        for step in 0..<90 {
            let t = Double(step) * 0.137
            let search = CreatureSearch(t: t)
            let sums = CreatureSums(t: t)
            let ribbon = CreatureRibbon(t: t, compact: false)
            network.update(t: t)
            for i in 0..<count {
                let phase = Double((i * 9301 + 49297) % 233_280) / 233_280
                let spots = [
                    search.spot(globe[i], phase: phase),
                    sums.spot(globe[i], phase: phase),
                    network.spot(index: i, sphere[i], phase: phase),
                    ribbon.spot(index: i, count: count, sphere[i], phase: phase),
                ]
                for spot in spots {
                    #expect(hypot(spot.x, spot.y) < 1.25)
                    #expect(spot.depth >= 0 && spot.depth <= 1)
                }
            }
            for gaze in [search.gaze, sums.gaze, network.gaze, ribbon.gaze] {
                #expect(abs(gaze.x) <= 1 && abs(gaze.y) <= 1)
            }
        }
    }

    @Test("The beam lights what it reaches and leaves the far side of the globe dim")
    func beam() {
        let search = CreatureSearch(t: 0)
        #expect(search.light(at: 0) == 1)
        #expect(search.light(at: -0.3) > 0.5)
        #expect(search.light(at: .pi) < 0.02)
        #expect(search.light(at: 0.1) > 0 && search.light(at: 0.1) < 1)
    }

    @Test("Two particles in three are the ribbon, its lanes meeting at the pen")
    func ribbon() {
        #expect(CreatureRibbon.members(of: 238) == (0..<238).filter { CreatureRibbon.rank(of: $0) != nil }.count)
        let ranks = (0..<238).compactMap { CreatureRibbon.rank(of: $0) }
        #expect(ranks == Array(0..<ranks.count))
        let ribbon = CreatureRibbon(t: 2, compact: false)
        let sphere = Self.sphere(238)
        // The first particle of each lane is at the pen: the lanes meet there.
        let tips = (0..<ribbon.lanes).map { lane -> CreatureSpot in
            let index = (0..<238).first { CreatureRibbon.rank(of: $0) == lane } ?? 0
            return ribbon.spot(index: index, count: 238, sphere[index], phase: 0)
        }
        for tip in tips { #expect(hypot(tip.x - tips[0].x, tip.y - tips[0].y) < 1e-9) }
    }
}
