//
//  OnboardingStepIndicator.swift
//  Tenra
//
//  Liquid-Glass-capsule step indicator. Shows one SF Symbol per step,
//  with the current step tinted and the rest in a faded state.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct OnboardingStepIndicator: View {
    /// 1-based current step index.
    let currentStep: Int
    /// One SF Symbol per step.
    let symbols: [String]

    /// Tenra's three steps (currency, account, categories).
    public static let tenraSymbols = ["dollarsign.circle.fill", "creditcard.fill", "square.grid.2x2.fill"]

    /// - Parameter symbols: one per step; Tenra's three by default (0.7.0 made it a parameter).
    public init(currentStep: Int, symbols: [String] = OnboardingStepIndicator.tenraSymbols) {
        self.currentStep = currentStep
        self.symbols = symbols
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(symbols.indices, id: \.self) { idx in
                stepIcon(at: idx)
                if idx < symbols.count - 1 {
                    separator(precedingIndex: idx)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .modifier(GlassCapsuleModifier())
        .animation(AppAnimation.contentSpring, value: currentStep)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                format: String(localized: "onboarding.stepIndicator.label"),
                currentStep,
                symbols.count
            )
        )
    }

    /// Thin dash drawn between step icons. Picks up the active accent colour for
    /// the segment immediately before the current step, fades otherwise.
    @ViewBuilder
    private func separator(precedingIndex: Int) -> some View {
        // 1-based step number that the dash *leads into*.
        let nextStep = precedingIndex + 2
        let isCompleted = nextStep <= currentStep
        Capsule()
            .fill(
                isCompleted
                    ? AppColors.accent.opacity(0.6)
                    : AppColors.textSecondary.opacity(0.3)
            )
            .frame(width: 10, height: 1.5)
    }

    @ViewBuilder
    private func stepIcon(at index: Int) -> some View {
        let stepNumber = index + 1
        let isActive = stepNumber == currentStep
        let isCompleted = stepNumber < currentStep

        Image(systemName: symbols[index])
            .font(.system(size: 16, weight: isActive ? .semibold : .regular))
            .foregroundStyle(
                isActive
                    ? AnyShapeStyle(AppColors.accent.gradient)
                    : isCompleted
                        ? AnyShapeStyle(AppColors.accent.opacity(0.55))
                        : AnyShapeStyle(AppColors.textSecondary.opacity(0.4))
            )
            .scaleEffect(isActive ? 1.15 : 1)
            .frame(width: 24, height: 24)
    }
}

private struct GlassCapsuleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.glassEffect(.regular, in: Capsule())
    }
}

