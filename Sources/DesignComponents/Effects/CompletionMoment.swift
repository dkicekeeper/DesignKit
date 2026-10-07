//
//  CompletionMoment.swift
//  DesignKit
//
//  The moment something is done (2.3.0): when `isComplete` turns true, a soft glow of the
//  shape flares and fades behind it and the success haptic plays. A goal reached, a ring
//  closed, a checklist finished. `ProgressRing(celebratesCompletion: true)` adds a checkmark
//  that draws itself in the ring's centre.
//
//  Only the change plays it: a view that appears already complete stays quiet. Under Reduce
//  Motion or `.designKitMotion(false)` there is no glow; the haptic stays.
//

import SwiftUI
import DesignTokens
import DesignSupport

public extension View {
    /// When `isComplete` turns true: a glow of `shape` flares and fades behind the view, and the
    /// success haptic plays.
    ///
    /// ```swift
    /// TargetProgressCard(…)
    ///     .completionMoment(isComplete: goal.progress >= 1, in: RoundedRectangle(cornerRadius: AppRadius.xl))
    /// ```
    func completionMoment<S: Shape>(
        isComplete: Bool,
        tint: Color = AppColors.Status.positive,
        in shape: S,
        playsHaptic: Bool = true
    ) -> some View {
        modifier(CompletionMomentModifier(isComplete: isComplete, tint: tint, shape: shape, playsHaptic: playsHaptic))
    }
}

struct CompletionMomentModifier<S: Shape>: ViewModifier {
    let isComplete: Bool
    let tint: Color
    let shape: S
    let playsHaptic: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @State private var moments = 0

    func body(content: Content) -> some View {
        content
            .background {
                if !reduceMotion && designKitMotion {
                    shape
                        .fill(tint)
                        .phaseAnimator(CompletionPhase.allCases, trigger: moments) { glow, phase in
                            // An outset, not a scale: a wide bar spreads as far as a small ring.
                            glow
                                .padding(-phase.outset)
                                .blur(radius: CompletionMomentMetrics.blur)
                                .opacity(phase.opacity)
                        } animation: { phase in
                            switch phase {
                            case .rest, .lit: .linear(duration: 0.01)
                            case .spread: .easeOut(duration: CompletionMomentMetrics.duration)
                            }
                        }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .hapticCue(.confirm, trigger: moments) { _, _ in playsHaptic }
            .onChange(of: isComplete) { _, done in
                if done { moments += 1 }
            }
    }
}

private enum CompletionPhase: CaseIterable {
    case rest, lit, spread

    var outset: CGFloat {
        switch self {
        case .rest, .lit: 0
        case .spread: CompletionMomentMetrics.spread
        }
    }

    var opacity: Double {
        switch self {
        case .rest, .spread: 0
        case .lit: CompletionMomentMetrics.peakOpacity
        }
    }
}

enum CompletionMomentMetrics {
    static let duration: Double = 0.8
    /// How far the glow spreads past the shape.
    static let spread: CGFloat = 10
    static let peakOpacity: Double = 0.45
    static let blur: CGFloat = 10
}
