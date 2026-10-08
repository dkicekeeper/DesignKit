//
//  CascadeIn.swift
//  DesignKit
//
//  Cards that arrive together cascade in (2.9.0): each fades in and rises 12 pt into place
//  `index × 80 ms` after it appears, so a batch reads as a sequence instead of popping at once.
//  Removal is left to the container's transition. Ported from Tenra's StaggeredCard (the cards
//  of a voice input with several operations).
//
//  Not `staggeredEntrance`, which scales avatars in (a facepile). Under Reduce Motion the cards
//  fade in on the same cadence without rising; under `.designKitMotion(false)` they are there.
//

import SwiftUI
import DesignTokens

public extension View {
    /// Fades the view in and rises it into place, `index × step` after it appears.
    ///
    /// ```swift
    /// ForEach(Array(previews.enumerated()), id: \.element.id) { index, preview in
    ///     PreviewCard(preview).cascadeIn(index: index)
    /// }
    /// ```
    func cascadeIn(index: Int, step: Double = CascadeInMetrics.step) -> some View {
        modifier(CascadeInModifier(index: index, step: step))
    }
}

public enum CascadeInMetrics {
    /// Between two cards' entrances.
    public static let step: Double = 0.08
    /// How far a card rises.
    static let rise: CGFloat = 12
}

struct CascadeInModifier: ViewModifier {
    let index: Int
    let step: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @State private var visible = false

    func body(content: Content) -> some View {
        let shown = visible || !designKitMotion
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : CascadeInMetrics.rise)
            .task {
                guard designKitMotion else { return }
                try? await Task.sleep(for: .seconds(Double(max(index, 0)) * step))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? .easeInOut(duration: AppAnimation.standard) : AppAnimation.gentleSpring) {
                    visible = true
                }
            }
    }
}
