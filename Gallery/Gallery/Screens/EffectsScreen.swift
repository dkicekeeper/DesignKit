//
//  EffectsScreen.swift
//  DesignKit Gallery
//
//  Effects: celebrations, sparkles, shine, attention pulse, the aurora, touch tilt (2.2.0);
//  the completion moment and the Metal ripple (2.3.0); the Siri wave and glow, background
//  orbs, accent glows, the border beam.
//

import SwiftUI
import DesignTokens
import DesignComponents

struct EffectsScreen: View {
    var body: some View {
        ShowcasePage(title: "Effects") {
            CelebrationPage()
            CompletionMomentPage()
            RipplePage()
            SparkleBurstPage()
            ShinePage()
            AttentionPulsePage()
            AuroraBackgroundPage()
            InteractiveTiltPage()
            SiriWavePage()
            SiriGlowPage()
            GradientOrbsBackgroundPage()
            AccentGlowPage()
            BorderBeamPage()
        }
    }
}

/// Confetti for a moment that matters.
private struct CelebrationPage: View {
    @State private var celebrations = 0
    @State private var progress = 0.8

    var body: some View {
        ComponentPage(
            name: ".celebration",
            summary: "Confetti bursts from a view with the success haptic: a goal reached, a debt paid off, an achievement, a trip finished.",
            since: "2.2.0",
            apps: [.tenra, .dalada],
            canvas: .tall(minHeight: 260),
            notes: [
                "Rare by design: a burst on every tap stops meaning anything.",
                "1.4 s, one Canvas, paths computed from the time; nothing runs before or after. Under Reduce Motion only the haptic.",
            ]
        ) {
            VStack(spacing: AppSpacing.md) {
                HeroSymbol(systemImage: "flag.checkered", size: 96, tint: AppColors.Status.positive)
                LinearProgressBar(value: progress, color: AppColors.Status.positive, animatesOnAppear: false)
                    .frame(width: 200)
            }
            .frame(maxWidth: .infinity)
            .celebration(trigger: celebrations)
        } controls: {
            ActionControl("Reach the goal", systemImage: "party.popper") {
                withAnimation(AppAnimation.expressive) { progress = 1 }
                celebrations += 1
            }
            ActionControl("Reset", systemImage: "arrow.counterclockwise") { progress = 0.8 }
        }
    }
}

/// Sparkles around a control (ReactionButton has them built in).
private struct SparkleBurstPage: View {
    @State private var isSelected = false

    var body: some View {
        ComponentPage(
            name: ".sparkleBurst",
            summary: "A small ring of sparkles around a control when something is added: a like, a reaction, a favourite. ReactionButton plays it on its own.",
            since: "2.2.0",
            apps: [.dalada],
            canvas: .tall(minHeight: 160)
        ) {
            ReactionButton(systemImage: "heart", selectedSystemImage: "heart.fill", count: isSelected ? 13 : 12,
                           isSelected: isSelected, accessibilityLabel: "Like") {
                isSelected.toggle()
            }
            .font(AppTypography.h3)
            .frame(maxWidth: .infinity)
        } controls: {
            ToggleControl("Liked", isOn: $isSelected)
        }
    }
}

/// A band of light across something new.
private struct ShinePage: View {
    @State private var shines = 0

    var body: some View {
        ComponentPage(
            name: ".shine",
            summary: "A band of light sweeps once across a shape: a card just added, a premium badge, an achievement unlocked.",
            since: "2.2.0",
            canvas: .fill,
            notes: ["0.8 s; clipped to the shape you pass (the card's AppRadius.xl by default). Off under Reduce Motion."]
        ) {
            VStack(spacing: AppSpacing.lg) {
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                            amount: 1_250_000, currency: "KZT")
                    .shine(trigger: shines)
                Badge("Pro", systemImage: "crown.fill", style: .filled)
                    .shine(trigger: shines, in: Capsule())
            }
        } controls: {
            ActionControl("Shine", systemImage: "sparkles") { shines += 1 }
        }
    }
}

/// Rings that point at something to notice.
private struct AttentionPulsePage: View {
    @State private var pulses = 0

    var body: some View {
        ComponentPage(
            name: ".attentionPulse",
            summary: "Two rings spread from a control and fade: a new feature, a button to notice (a coach mark without words).",
            since: "2.2.0",
            canvas: .tall(minHeight: 180)
        ) {
            DSButton("Scan a receipt", systemImage: "doc.viewfinder", iconPlacement: .only) {}
                .attentionPulse(trigger: pulses, in: Circle())
                .frame(maxWidth: .infinity)
        } controls: {
            ActionControl("Pulse", systemImage: "dot.radiowaves.left.and.right") { pulses += 1 }
        }
    }
}

/// A slow aurora behind a premium screen.
private struct AuroraBackgroundPage: View {
    @State private var intensity = 1.0
    @State private var palette = 0

    var body: some View {
        ComponentPage(
            name: "AuroraBackground",
            summary: "A slowly drifting mesh-gradient aurora behind a premium screen, a paywall, an onboarding.",
            since: "2.2.0",
            canvas: .bleed,
            notes: [
                "MeshGradient in one GPU pass, no blur, 30 fps only while AmbientMotionGate allows; otherwise one still frame.",
                "By default the accent and its neighbours on the colour wheel (Dalada's is green).",
            ]
        ) {
            ZStack {
                AuroraBackground(
                    colors: palette == 0 ? nil : [.teal, .indigo, .purple, .pink, .blue],
                    intensity: intensity
                )
                VStack(spacing: AppSpacing.sm) {
                    Text("Tenra Pro")
                        .font(AppTypography.h2)
                    Text("Every insight, every account")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                .padding(AppSpacing.xl)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.xl))
            }
            .frame(height: 280)
        } controls: {
            ChoiceControl("Colours", selection: $palette, options: [("Accent", 0), ("Custom", 1)])
            SliderControl("Intensity", value: $intensity, in: 0.2...1, step: 0.1) { "\(Int($0 * 100))%" }
        }
    }
}

/// An object that tilts towards the finger.
private struct InteractiveTiltPage: View {
    var body: some View {
        ComponentPage(
            name: ".interactiveTilt",
            summary: "Press and drag on the medal: it tilts towards the finger in 3D with a glare, and springs back on release.",
            since: "2.2.0",
            apps: [.dalada],
            canvas: .tall(minHeight: 240),
            notes: ["For an object shown on its own (a medal, a card's detail); in a scrolling list it would fight the scroll."]
        ) {
            AchievementMedal(systemImage: "mountain.2.fill", color: .orange, isEarned: true, size: 140)
                .interactiveTilt(in: Circle())
                .frame(maxWidth: .infinity)
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

/// The moment something is done (2.3.0).
private struct CompletionMomentPage: View {
    @State private var progress = 0.8
    @State private var checked = 4

    var body: some View {
        ComponentPage(
            name: ".completionMoment",
            summary: "When something is done, a soft glow of its shape flares and fades behind it and the success haptic plays. Only the change plays it: a view that appears complete stays quiet.",
            since: "2.3.0",
            apps: [.tenra, .dalada],
            notes: [
                "Built in: ProgressRing(celebratesCompletion: true) also draws a checkmark in; ChecklistSummaryRow's bar and TargetProgressCard's bar glow when they reach the end.",
                "On your own view: .completionMoment(isComplete: goal.progress >= 1, in: RoundedRectangle(cornerRadius: AppRadius.xl)).",
                "For a bigger moment add .celebration(trigger:). Under Reduce Motion there is no glow; the haptic stays.",
            ]
        ) {
            VStack(spacing: AppSpacing.xl) {
                ProgressRing(progress: progress, size: AppIconSize.Tile.xxl, lineWidth: 6,
                             showsTrack: true, celebratesCompletion: true)
                ChecklistSummaryRow(title: "Weekend at the lake", checked: checked, total: 5)
                    .padding(.horizontal, AppSpacing.lg)
                    .cardStyle()
            }
            .frame(maxWidth: .infinity)
        } controls: {
            SliderControl("Goal", value: $progress, in: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
            ActionControl("Complete the goal", systemImage: "checkmark") {
                withAnimation(AppAnimation.smooth) { progress = progress >= 1 ? 0.8 : 1 }
            }
            ActionControl(checked >= 5 ? "Uncheck an item" : "Check the last item", systemImage: "checklist") {
                checked = checked >= 5 ? 4 : 5
            }
        }
    }
}

/// A ripple through the view itself (2.3.0, Metal).
private struct RipplePage: View {
    @State private var ripples = 0
    @State private var origin = 0

    private var unitOrigin: UnitPoint {
        switch origin {
        case 1: .topLeading
        case 2: .bottomTrailing
        default: .center
        }
    }

    var body: some View {
        ComponentPage(
            name: ".ripple · .rippleOnTap",
            summary: "A ripple spreads through the view itself, as if its surface were water: the most striking effect here and the heaviest. Keep it for a moment that deserves it. Tap the card.",
            since: "2.3.0",
            notes: [
                ".ripple(trigger:at:) plays from a point each time the trigger changes; .rippleOnTap() from wherever the view is tapped (its buttons still work).",
                "A Metal layer effect that runs only while the ripple plays (1.6 s). The shaders ship compiled, so apps need no Metal Toolchain.",
                "Under Reduce Motion it does not play.",
            ]
        ) {
            VStack(spacing: AppSpacing.lg) {
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                            amount: 1_250_000, currency: "KZT")
                    .ripple(trigger: ripples, at: unitOrigin)
                AuroraBackground(intensity: 0.8)
                    .frame(height: 140)
                    .clipShape(.rect(cornerRadius: AppRadius.xl))
                    .overlay {
                        Text("Tap anywhere")
                            .font(AppTypography.bodyEmphasis)
                            .foregroundStyle(.white)
                    }
                    .rippleOnTap()
            }
        } controls: {
            ChoiceControl("From", selection: $origin, options: [("Centre", 0), ("Top leading", 1), ("Bottom trailing", 2)])
            ActionControl("Ripple the card", systemImage: "drop") { ripples += 1 }
        }
    }
}
