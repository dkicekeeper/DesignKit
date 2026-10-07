//
//  SliderRow.swift
//  DesignKit
//
//  A settings row with a slider: the title (with an optional symbol), the current value on the
//  trailing edge, the slider under them, an optional hint. (HIG: sliders in a list; Material:
//  Slider with a label and value.) Ported from Tenra's background-intensity row (1.15.0);
//  what the value means and how it is formatted stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Title + value + slider (+ hint).
///
/// ```swift
/// SliderRow("Colour intensity", systemImage: "circle.lefthalf.filled",
///           value: $opacity, in: 0.05...1, valueText: "\(Int((opacity * 100).rounded()))%")
/// SliderRow("Radius", value: $radius, in: 100...2_000, step: 100,
///           valueText: "\(Int(radius)) m", hint: "Trips hide their track inside this circle")
/// ```
///
/// A row pads only vertically (docs/design-system.md §10); put it in a form card or a list.
public struct SliderRow: View {
    let title: String
    let systemImage: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let valueText: String
    let hint: String?

    public init(
        _ title: String,
        systemImage: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        valueText: String,
        hint: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self._value = value
        self.range = range
        self.step = step
        self.valueText = valueText
        self.hint = hint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                titleLabel
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.primary)

                Spacer()

                Text(valueText)
                    .font(AppTypography.bodySmall.monospacedDigit())
                    .foregroundStyle(AppColors.Text.secondary)
            }

            slider
                .tint(AppColors.accent)
                // 2.3.0: a tick on every step of a stepped slider, and at either end of a smooth one.
                .hapticCue(.tick, trigger: value) { _, _ in step != nil }
                .hapticCue(.tick, trigger: isAtEnd) { _, atEnd in step == nil && atEnd }
                .accessibilityLabel(Text(title))
                .accessibilityValue(Text(valueText))

            if let hint {
                Text(hint)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var isAtEnd: Bool { value <= range.lowerBound || value >= range.upperBound }

    @ViewBuilder
    private var titleLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }

    @ViewBuilder
    private var slider: some View {
        if let step {
            Slider(value: $value, in: range, step: step)
        } else {
            Slider(value: $value, in: range)
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `SliderRow`: the title and value lines, the slider's track at its height,
/// and the hint line when the row has one.
public struct SliderRowSkeleton: View {
    let showsHint: Bool

    public init(showsHint: Bool = false) {
        self.showsHint = showsHint
    }

    public var body: some View {
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
        .padding(.vertical, AppSpacing.xs)
        .skeletonLoadingLabel()
    }
}

enum SliderRowMetrics {
    /// The system slider's track.
    static let trackHeight: CGFloat = 4
    /// The system slider's height (its thumb).
    static let sliderHeight: CGFloat = 28
}
