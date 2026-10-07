//
//  Holographic.swift
//  DesignKit
//
//  A holographic foil (2.6.0): rainbow bands run across the surface and slide as the finger
//  moves over it, with a sheen where the light falls; let go and the light settles back. For a
//  medal, a premium card, an achievement. Pairs with `.interactiveTilt()`, which tilts the
//  same surface towards the finger.
//
//  One Metal colour effect (Shaders/Holographic.metal), redrawn only while the finger moves or
//  the light settles. Without the compiled shaders the view is drawn as it is.
//

import SwiftUI
import DesignTokens

public extension View {
    /// A holographic foil whose colours follow the finger.
    ///
    /// ```swift
    /// AchievementMedal(…)
    ///     .holographic()
    ///     .interactiveTilt(in: Circle())
    /// ```
    ///
    /// - Parameter strength: 0…1, how much of the surface turns to foil.
    func holographic(strength: Double = HolographicMetrics.strength) -> some View {
        modifier(HolographicModifier(strength: min(max(strength, 0), 1)))
    }
}

public enum HolographicMetrics {
    /// The default foil: the surface stays readable under it.
    public static let strength: Double = 0.35
}

struct HolographicModifier: ViewModifier {
    let strength: Double

    /// Where the light comes from, −1…1 on each axis; 0 at rest.
    @State private var light: CGPoint = .zero
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        if let library = DesignKitShaders.library {
            content
                .modifier(HolographicFoil(library: library, light: light, strength: strength))
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            guard size.width > 0, size.height > 0 else { return }
                            light = CGPoint(
                                x: min(max(drag.location.x / size.width * 2 - 1, -1), 1),
                                y: min(max(drag.location.y / size.height * 2 - 1, -1), 1)
                            )
                        }
                        .onEnded { _ in
                            withAnimation(AppAnimation.smooth) { light = .zero }
                        }
                )
        } else {
            content
        }
    }
}

/// The foil at one light position; animatable, so the light settles smoothly.
struct HolographicFoil: ViewModifier, Animatable {
    let library: ShaderLibrary
    var light: CGPoint
    let strength: Double

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(light.x, light.y) }
        set { light = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func body(content: Content) -> some View {
        let library = library
        let light = light
        let strength = strength
        return content.visualEffect { view, proxy in
            view.colorEffect(library.Holographic(
                .float2(proxy.size),
                .float2(light),
                .float(strength)
            ))
        }
    }
}
