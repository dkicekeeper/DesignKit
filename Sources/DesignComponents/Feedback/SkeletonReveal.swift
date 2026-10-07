//
//  SkeletonReveal.swift
//  DesignKit
//
//  The skeleton turns into the content (2.3.0): the placeholder fades out while the content
//  comes into focus from a light blur, in the same place, so loading ends softly instead of
//  with a jump. (Material: "content loading" fade-through; HIG: keep the layout still while
//  content arrives.)
//
//  Under Reduce Motion or `.designKitMotion(false)` the two cross-fade without the blur.
//

import SwiftUI
import DesignTokens

/// Shows `skeleton` while `isLoading`, then reveals `content` from a light blur.
///
/// ```swift
/// SkeletonReveal(isLoading: balances == nil) {
///     BalanceCard(…)
/// } skeleton: {
///     BalanceCardSkeleton()
/// }
/// ```
///
/// Give both the same size (a component and its `<Name>Skeleton` already have it), so nothing
/// around them moves.
public struct SkeletonReveal<Content: View, Placeholder: View>: View {
    let isLoading: Bool
    let content: Content
    let skeleton: Placeholder

    public init(
        isLoading: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder skeleton: () -> Placeholder
    ) {
        self.isLoading = isLoading
        self.content = content()
        self.skeleton = skeleton()
    }

    public var body: some View {
        ZStack {
            if isLoading {
                skeleton
                    .transition(.opacity)
            } else {
                content
                    .transition(.skeletonReveal)
            }
        }
        .animation(.smooth(duration: SkeletonRevealMetrics.duration), value: isLoading)
    }
}

/// Comes into focus from a light blur while fading in; a plain fade under Reduce Motion.
public struct SkeletonRevealTransition: Transition {
    public init() {}

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(SkeletonRevealEffect(phase: phase))
    }
}

public extension Transition where Self == SkeletonRevealTransition {
    /// Comes into focus from a light blur while fading in (content replacing its skeleton);
    /// a fade under Reduce Motion.
    static var skeletonReveal: SkeletonRevealTransition { SkeletonRevealTransition() }
}

enum SkeletonRevealMetrics {
    static let duration: Double = 0.45
    static let blur: CGFloat = 8
    static let scale: CGFloat = 0.98
}

// A transition cannot read the environment; its modifier can.
private struct SkeletonRevealEffect: ViewModifier {
    let phase: TransitionPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        let moves = !reduceMotion && designKitMotion && !phase.isIdentity
        content
            .blur(radius: moves ? SkeletonRevealMetrics.blur : 0)
            .scaleEffect(moves ? SkeletonRevealMetrics.scale : 1)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}
