//
//  Ripple.swift
//  DesignKit
//
//  A ripple through the view itself (2.3.0): the pixels swell out from a point and settle, as
//  if the surface were water. A Metal layer effect (Shaders/Ripple.metal), the most striking
//  effect here and the heaviest, so keep it for a moment that deserves it: a goal reached, a
//  big confirmation, a tap on a hero. Not for every button.
//
//  Light where it can be: the shader runs only while the ripple plays (1.6 s), on the GPU,
//  and the view is not re-rendered. Under Reduce Motion or `.designKitMotion(false)` it does
//  not play. If the compiled shaders are missing it does nothing.
//

import SwiftUI
import DesignTokens

public extension View {
    /// A ripple spreads through the view from `origin` each time `trigger` changes.
    ///
    /// ```swift
    /// GoalCard(goal)
    ///     .ripple(trigger: goal.isReached)
    /// ```
    func ripple<Trigger: Equatable>(trigger: Trigger, at origin: UnitPoint = .center) -> some View {
        modifier(RippleEffectModifier(trigger: trigger, origin: .unit(origin)))
    }

    /// A ripple spreads through the view from wherever it is tapped. The tap still reaches
    /// the view's own buttons.
    func rippleOnTap() -> some View {
        modifier(RippleOnTapModifier())
    }
}

/// The compiled shader library (Shaders/build.sh); `nil` when it is missing.
enum DesignKitShaders {
    static let library: ShaderLibrary? = {
        #if targetEnvironment(simulator)
        let name = "DesignKitShaders-iphonesimulator"
        #else
        let name = "DesignKitShaders-iphoneos"
        #endif
        guard let url = Bundle.module.url(forResource: name, withExtension: "metallib", subdirectory: "Shaders") else {
            return nil
        }
        return ShaderLibrary(url: url)
    }()
}

enum RippleMetrics {
    static let duration: Double = 1.6
    /// How far a pixel moves at the crest.
    static let amplitude: Double = 10
    static let frequency: Double = 14
    /// How fast the wave dies down.
    static let decay: Double = 6
    /// Points per second.
    static let speed: Double = 900
}

enum RippleOrigin: Equatable, Sendable {
    case unit(UnitPoint)
    case point(CGPoint)

    func resolved(in size: CGSize) -> CGPoint {
        switch self {
        case .unit(let unit): CGPoint(x: unit.x * size.width, y: unit.y * size.height)
        case .point(let point): point
        }
    }
}

struct RippleEffectModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let origin: RippleOrigin

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        if let library = DesignKitShaders.library, !reduceMotion, designKitMotion {
            let origin = origin
            content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, elapsed in
                view.modifier(RippleFrame(library: library, origin: origin, elapsed: elapsed))
            } keyframes: { _ in
                MoveKeyframe(0)
                LinearKeyframe(RippleMetrics.duration, duration: RippleMetrics.duration)
            }
        } else {
            content
        }
    }
}

/// One frame of the ripple, `elapsed` seconds in.
struct RippleFrame: ViewModifier {
    let library: ShaderLibrary
    let origin: RippleOrigin
    let elapsed: Double

    func body(content: Content) -> some View {
        let library = library
        let origin = origin
        let elapsed = elapsed
        content.visualEffect { view, proxy in
            view.layerEffect(
                library.Ripple(
                    .float2(origin.resolved(in: proxy.size)),
                    .float(elapsed),
                    .float(RippleMetrics.amplitude),
                    .float(RippleMetrics.frequency),
                    .float(RippleMetrics.decay),
                    .float(RippleMetrics.speed)
                ),
                maxSampleOffset: CGSize(width: RippleMetrics.amplitude, height: RippleMetrics.amplitude),
                // Off at rest, so the view is drawn as usual between ripples.
                isEnabled: elapsed > 0 && elapsed < RippleMetrics.duration
            )
        }
    }
}

struct RippleOnTapModifier: ViewModifier {
    @State private var taps = 0
    @State private var location: CGPoint = .zero

    func body(content: Content) -> some View {
        content
            .modifier(RippleEffectModifier(trigger: taps, origin: .point(location)))
            .simultaneousGesture(
                SpatialTapGesture().onEnded { tap in
                    location = tap.location
                    taps += 1
                }
            )
    }
}
