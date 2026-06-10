//
//  ProportionBar.swift
//  Tenra
//
//  Horizontal bar showing two proportions side by side
//  (e.g. principal vs interest, spent vs remaining).
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct ProportionBar: View {
    let ratio: Double
    let leftColor: Color
    let rightColor: Color
    var height: CGFloat = 8

    public init(ratio: Double, leftColor: Color, rightColor: Color, height: CGFloat = 8) {
        self.ratio = ratio
        self.leftColor = leftColor
        self.rightColor = rightColor
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            HStack(spacing: AppSpacing.xxs) {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(leftColor)
                    .frame(width: geo.size.width * max(0, min(1, ratio)))
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(rightColor)
            }
        }
        .frame(height: height)
        .animation(AppAnimation.gentleSpring, value: ratio)
    }
}
