//
//  ParticleCreatureTilt.swift
//  DesignKit
//
//  The creature's eyes on the phone's tilt (5.3.0): with `.creatureFollowsTilt()`, a hero whose
//  eyes no finger holds looks downhill as the phone tilts, as if its eyes rolled, and back to the
//  middle when the phone rests in a new way. Its glances go on on top. One motion manager for all
//  the creatures that follow, running only while one is on screen and moving: off under Reduce
//  Motion, `.designKitMotion(false)` and in the compact style. Device motion needs no permission.
//

import SwiftUI
import CoreMotion

public extension View {
    /// Lets the `ParticleCreature` inside follow the phone's tilt with its eyes when no finger is
    /// on it (5.3.0): it looks to the side the phone dips to. Hero style only; off under Reduce
    /// Motion and `.designKitMotion(false)`. Nothing on a device without motion sensors (the
    /// Simulator).
    ///
    /// ```swift
    /// ParticleCreature(mood: .idle, isInteractive: true)
    ///     .creatureFollowsTilt()
    /// ```
    func creatureFollowsTilt(_ follows: Bool = true) -> some View {
        environment(\.creatureFollowsTilt, follows)
    }
}

extension EnvironmentValues {
    @Entry var creatureFollowsTilt: Bool = false
}

/// The tilt the creatures look along: the in-plane pull of gravity, its slow mean taken away so a
/// new way of holding the phone becomes the middle. Used on the main thread only.
final class CreatureTilt {
    static let shared = CreatureTilt()

    private let manager = CMMotionManager()
    private var users = 0
    private var mean: (x: Double, y: Double)?

    /// Where the eyes look, -1…1 each way; `nil` while nothing follows or there is no sensor.
    private(set) var gaze: (x: Double, y: Double)?

    func start() {
        users += 1
        guard users == 1, manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = CreatureTiltMetrics.interval
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.update(gravity: motion.gravity)
        }
    }

    func stop() {
        users = max(0, users - 1)
        guard users == 0 else { return }
        manager.stopDeviceMotionUpdates()
        mean = nil
        gaze = nil
    }

    private func update(gravity: CMAcceleration) {
        // Downhill on the screen: right is +x, down the screen is -y in the device's frame.
        let raw = (x: gravity.x, y: -gravity.y)
        var mean = self.mean ?? raw
        mean.x += (raw.x - mean.x) * CreatureTiltMetrics.recentre
        mean.y += (raw.y - mean.y) * CreatureTiltMetrics.recentre
        self.mean = mean
        let target = (x: Self.clamp((raw.x - mean.x) / CreatureTiltMetrics.reach),
                      y: Self.clamp((raw.y - mean.y) / CreatureTiltMetrics.reach))
        let last = gaze ?? (x: 0, y: 0)
        gaze = (x: last.x + (target.x - last.x) * CreatureTiltMetrics.smoothing,
                y: last.y + (target.y - last.y) * CreatureTiltMetrics.smoothing)
    }

    private static func clamp(_ value: Double) -> Double { min(max(value, -1), 1) }
}

enum CreatureTiltMetrics {
    /// 30 updates a second, as the creature's frames.
    static let interval: Double = 1.0 / 30
    /// How much tilt (a share of gravity, about 20°) turns the eyes all the way.
    static let reach: Double = 0.35
    /// How fast a new way of holding it becomes the middle (a share a sample: about 3 s), and
    /// how much of the way the eyes go each sample.
    static let recentre: Double = 0.012
    static let smoothing: Double = 0.25
    /// The glances' share on top of the tilt.
    static let glance: Double = 0.4
}
