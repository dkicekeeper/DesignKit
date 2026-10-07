//
//  StepTracker.swift
//  DesignKit
//
//  Where the user is in a multi-step flow: numbered circles joined by a line, done steps
//  checked, the current one outlined. (Carbon Progress indicator, Atlassian Progress
//  tracker, Material stepper.) OnboardingStepIndicator stays Tenra's 3-symbol onboarding.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Horizontal step tracker.
///
/// ```swift
/// StepTracker(steps: ["Place", "Catch", "Photos", "Review"], current: 1)
/// StepTracker(steps: ["1", "2", "3"], current: 2, showsLabels: false)
/// ```
///
/// `current` is 0-based; `current == steps.count` shows every step done. VoiceOver reads
/// "Step 2 of 4: Catch" (key `steps.position`, default "Step %lld of %lld").
public struct StepTracker: View {
    let steps: [String]
    let current: Int
    let showsLabels: Bool

    public init(steps: [String], current: Int, showsLabels: Bool = true) {
        self.steps = steps
        self.current = min(max(current, 0), steps.count)
        self.showsLabels = showsLabels
    }

    private let circleSize: CGFloat = 24
    private let lineHeight: CGFloat = 2

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                stepColumn(index)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityText))
    }

    private func stepColumn(_ index: Int) -> some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: 0) {
                connector(visible: index > 0, done: index <= current)
                marker(index)
                connector(visible: index < steps.count - 1, done: index < current)
            }
            if showsLabels {
                Text(verbatim: steps[index])
                    .font(AppTypography.caption)
                    .foregroundStyle(index == current ? AppColors.Text.primary : AppColors.Text.secondary)
                    .fontWeight(index == current ? .semibold : .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, AppSpacing.xxs)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func connector(visible: Bool, done: Bool) -> some View {
        Rectangle()
            .fill(visible ? (done ? AppColors.accent : AppColors.Background.neutral2) : .clear)
            .frame(height: lineHeight)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func marker(_ index: Int) -> some View {
        ZStack {
            if index < current {
                Circle().fill(AppColors.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: circleSize * 0.45, weight: .bold))
                    .foregroundStyle(AppColors.staticWhite)
                    // 2.2.0: a step done draws its checkmark on.
                    .drawOnAppear()
            } else if index == current {
                Circle().fill(AppColors.Background.neutral1)
                Circle().strokeBorder(AppColors.accent, lineWidth: 2)
                Text(verbatim: "\(index + 1)")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.accent)
            } else {
                Circle().fill(AppColors.Background.neutral2)
                Text(verbatim: "\(index + 1)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .frame(width: circleSize, height: circleSize)
        .animation(AppAnimation.contentSpring, value: current)
    }

    private var accessibilityText: String {
        let position = min(current + 1, steps.count)
        let base = String(localized: "steps.position", defaultValue: "Step \(position) of \(steps.count)")
        guard current < steps.count else { return base }
        return "\(base): \(steps[current])"
    }
}
