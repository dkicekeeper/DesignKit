//
//  Grain.swift
//  DesignKit
//
//  A fine, still grain (2.5.0): each point nudged lighter or darker by a fixed hash of its
//  position. It breaks the banding a smooth gradient shows on a dark screen, and gives a
//  background a printed texture. `AuroraBackground` and the aurora `accentGlow` carry it.
//
//  One Metal colour effect (Shaders/Grain.metal), the same on every frame: a still view keeps
//  it as it is drawn. Without the compiled shaders it does nothing.
//

import SwiftUI
import DesignTokens

public extension View {
    /// A fine, still grain over the view.
    ///
    /// ```swift
    /// LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)
    ///     .grain()
    /// ```
    ///
    /// - Parameter amount: How far a point moves lighter or darker, 0…1 of full brightness.
    ///   The default, 0.04, is felt more than seen.
    func grain(_ amount: Double = GrainMetrics.amount) -> some View {
        modifier(GrainModifier(amount: amount))
    }
}

public enum GrainMetrics {
    /// The default grain: enough to break banding, too little to read as noise.
    public static let amount: Double = 0.04
}

struct GrainModifier: ViewModifier {
    let amount: Double

    func body(content: Content) -> some View {
        if let library = DesignKitShaders.library, amount > 0 {
            content.colorEffect(library.Grain(.float(amount)))
        } else {
            content
        }
    }
}
