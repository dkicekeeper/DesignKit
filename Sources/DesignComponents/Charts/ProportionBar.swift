//
//  ProportionBar.swift
//  Tenra
//
//  Horizontal bar showing two proportions side by side
//  (e.g. principal vs interest, spent vs remaining, expense vs income).
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct ProportionBar: View {
    let ratio: Double
    let leftColor: Color
    let rightColor: Color
    var height: CGFloat = 8
    /// Sweep-from-zero entrance. Disable in lazy lists/feeds — `onAppear`
    /// re-fires on every row re-materialisation during scroll.
    var animatesOnAppear: Bool = true

    @State private var displayRatio: Double = 0
    /// Reduce-Motion-aware (nil under Reduce Motion → instant jump, no sweep).
    private var fillAnimation: Animation? { AppAnimation.progressFillAnimation }

    public init(ratio: Double, leftColor: Color, rightColor: Color, height: CGFloat = 8, animatesOnAppear: Bool = true) {
        self.animatesOnAppear = animatesOnAppear
        self.ratio = ratio
        self.leftColor = leftColor
        self.rightColor = rightColor
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            HStack(spacing: AppSpacing.xxs) {
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(leftColor)
                    .frame(width: geo.size.width * max(0, min(1, displayRatio)))
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(rightColor)
            }
        }
        .frame(height: height)
        .onAppear {
            if animatesOnAppear {
                withAnimation(fillAnimation) { displayRatio = ratio }
            } else {
                displayRatio = ratio
            }
        }
        .onChange(of: ratio) { _, newValue in
            withAnimation(fillAnimation) { displayRatio = newValue }
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ProportionBar`: one rounded bar of the same height.
public struct ProportionBarSkeleton: View {
    let height: CGFloat

    public init(height: CGFloat = 8) {
        self.height = height
    }

    public var body: some View {
        SkeletonView(height: height, cornerRadius: AppRadius.xl)
            .skeletonLoadingLabel()
    }
}
