//
//  EffectsScreen.swift
//  DesignKit Gallery
//
//  Effects: the Siri wave and glow, background orbs, accent glows, the border beam.
//

import SwiftUI
import DesignTokens
import DesignComponents

struct EffectsScreen: View {
    var body: some View {
        ShowcasePage(title: "Effects") {
            SiriWavePage()
            SiriGlowPage()
            GradientOrbsBackgroundPage()
            AccentGlowPage()
            BorderBeamPage()
        }
    }
}

private struct SiriWavePage: View {
    @State private var height = 220.0

    var body: some View {
        ComponentPage(
            name: "SiriWave",
            summary: "The voice input wave while recording, on a dark backdrop like the app's recording screen.",
            apps: [.tenra],
            canvas: .dark(minHeight: 260)
        ) {
            SiriWave()
                .frame(maxWidth: .infinity)
                .frame(height: height)
        } controls: {
            SliderControl("Height", value: $height, in: 120...320, step: 20) { "\(Int($0)) pt" }
        }
    }
}

private struct SiriGlowPage: View {
    var body: some View {
        ComponentPage(
            name: "SiriGlow",
            summary: "An Apple-Intelligence edge glow around a surface while the app is listening or thinking.",
            apps: [.tenra],
            canvas: .dark(minHeight: 300)
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(Color(white: 0.12))
                SiriGlow()
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                Text("Listening…")
                    .font(AppTypography.h4)
                    .foregroundStyle(.white)
            }
            .frame(height: 260)
            .padding(AppSpacing.lg)
        }
    }
}

private struct GradientOrbsBackgroundPage: View {
    @State private var count = 3

    private let orbs: [GradientOrbsBackground.Orb] = [
        .init(color: AppColors.accent, weight: 0.5),
        .init(color: AppColors.success, weight: 0.3),
        .init(color: AppColors.warning, weight: 0.2),
        .init(color: .purple, weight: 0.15),
    ]

    var body: some View {
        ComponentPage(
            name: "GradientOrbsBackground",
            summary: "Soft drifting colour orbs behind a hero, each sized by its weight.",
            since: "1.5.0",
            apps: [.tenra],
            canvas: .bleed
        ) {
            GradientOrbsBackground(Array(orbs.prefix(count)))
                .frame(height: 240)
        } controls: {
            StepperControl("Orbs", value: $count, in: 1...4)
        }
    }
}

private struct AccentGlowPage: View {
    @State private var edge = 0

    var body: some View {
        ComponentPage(
            name: ".accentGlow",
            summary: "A wash of colour from one edge: onboarding backgrounds, a hero's light.",
            apps: [.tenra],
            canvas: .bleed
        ) {
            Color.clear
                .frame(height: 220)
                .accentGlow(AppColors.accent, edge: edge == 0 ? .top : .bottom)
        } controls: {
            ChoiceControl("Edge", selection: $edge, options: [("Top", 0), ("Bottom", 1)])
        }
    }
}

private struct BorderBeamPage: View {
    @State private var beam = true
    @State private var glow = true

    var body: some View {
        ComponentPage(
            name: ".borderBeam · .borderGlow",
            summary: "A light running around a card's border and a soft glow: “working on it”, AI and live states.",
            apps: [.tenra],
            canvas: .fill
        ) {
            Text("Analysing your spending…")
                .font(AppTypography.body)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .cardStyle()
                .borderGlow(isActive: glow)
                .borderBeam(isActive: beam)
        } controls: {
            ToggleControl("Beam", isOn: $beam)
            ToggleControl("Glow", isOn: $glow)
        }
    }
}

#Preview { NavigationStack { EffectsScreen() } }
