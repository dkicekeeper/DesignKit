//
//  RowSliderSkeleton.swift
//  DesignKit
//
//  The placeholder of `UniversalRow(accessory: .slider)` (SliderRow's until 7.0.0).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Placeholder of a slider row (`accessory: .slider`): the title and value lines, the slider's
/// track at its height, and the hint line when the row has one.
struct RowSliderSkeleton: View {
    let showsHint: Bool
    let config: RowConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                SkeletonText(AppTypography.body, width: 140)
                Spacer()
                SkeletonText(AppTypography.bodySmall, width: 40)
            }
            Skeleton.capsule(height: SliderRowMetrics.trackHeight)
                .frame(height: SliderRowMetrics.sliderHeight)
            if showsHint {
                SkeletonText(AppTypography.caption, width: 220)
            }
        }
        .shimmer()
        .padding(.vertical, config.verticalPadding)
        .padding(.horizontal, config.horizontalPadding)
        .skeletonLoadingLabel()
    }
}

enum SliderRowMetrics {
    /// The system slider's track.
    static let trackHeight: CGFloat = 4
    /// The system slider's height (its thumb).
    static let sliderHeight: CGFloat = 28
}
