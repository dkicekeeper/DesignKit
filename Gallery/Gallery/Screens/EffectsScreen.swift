//
//  EffectsScreen.swift
//  DesignKit Gallery
//
//  Effects: celebrations, sparkles, shine, attention pulse, the aurora, touch tilt (2.2.0);
//  the completion moment and the Metal ripple (2.3.0); the voice wave, the edge glow and the
//  thinking shimmer (2.4.0); weighted aurora spots, the aurora accent glow and grain (2.5.0);
//  background orbs (deprecated), the border beam.
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
            VoiceWavePage()
            EdgeGlowPage()
            ThinkingShimmerPage()
            GradientOrbsBackgroundPage()
            GrainPage()
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
    @State private var mode = 0
    @State private var count = 3
    @State private var shuffle = 0
    @State private var grain = true

    private static let categoryColors: [Color] = [.orange, .blue, .pink, .green, .purple]

    /// Weights for the spots; "Change the data" deals new ones, as a filter or a new month would.
    private var spots: [AuroraBackground.Spot] {
        let weights: [[Double]] = [[1, 0.6, 0.4, 0.25, 0.15], [1, 0.85, 0.2, 0.5, 0.3], [1, 0.3, 0.7, 0.15, 0.45]]
        let set = weights[shuffle % weights.count]
        return (0..<count).map { .init(color: Self.categoryColors[($0 + shuffle) % Self.categoryColors.count], weight: set[$0]) }
    }

    var body: some View {
        ComponentPage(
            name: "AuroraBackground",
            summary: "A slowly drifting mesh-gradient aurora behind a premium screen, a paywall, an onboarding; or, still, weighted pools of colour behind a home screen.",
            since: "2.2.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "MeshGradient in one GPU pass, no blur, 30 fps only while AmbientMotionGate allows; otherwise one still frame.",
                "Weighted spots (2.5.0): AuroraBackground([.init(color:weight:)]): each colour a soft pool sized and brightened by its weight, sampled into a 5×5 mesh. Replaces GradientOrbsBackground (deprecated): no blur, no screen blend, no offscreen pass.",
                "Still by default with spots: under Liquid Glass a moving background makes every glass surface redraw each frame. A change of data flows into the new shape in 0.6 s.",
                "A fine still grain (2.5.0) keeps the gradient from banding on a dark screen; grain: 0 turns it off.",
            ]
        ) {
            ZStack {
                if mode == 0 {
                    AuroraBackground(
                        colors: palette == 0 ? nil : [.teal, .indigo, .purple, .pink, .blue],
                        intensity: intensity,
                        grain: grain ? GrainMetrics.amount : 0
                    )
                } else {
                    AuroraBackground(spots, intensity: intensity, grain: grain ? GrainMetrics.amount : 0)
                }
                VStack(spacing: AppSpacing.sm) {
                    Text(mode == 0 ? "Tenra Pro" : "1 250 000 ₸")
                        .font(AppTypography.h2)
                    Text(mode == 0 ? "Every insight, every account" : "Spent this month")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                .padding(AppSpacing.xl)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.xl))
            }
            .frame(height: 280)
        } controls: {
            ChoiceControl("Mode", selection: $mode, options: [("Drifting palette", 0), ("Weighted spots", 1)])
            if mode == 0 {
                ChoiceControl("Colours", selection: $palette, options: [("Accent", 0), ("Custom", 1)])
            } else {
                StepperControl("Spots", value: $count, in: 1...5)
                ActionControl("Change the data", systemImage: "shuffle") { shuffle += 1 }
            }
            SliderControl("Intensity", value: $intensity, in: 0.2...1, step: 0.1) { "\(Int($0 * 100))%" }
            ToggleControl("Grain", isOn: $grain)
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

/// The voice made visible (2.4.0): ribbons or an orb, listening or thinking.
private struct VoiceWavePage: View {
    @State private var style: VoiceWave.Style = .ribbons
    @State private var phase: VoiceWave.Phase = .listening
    @State private var source: VoiceSourceKind = .simulated
    @State private var level = 0.5
    @State private var microphone = GalleryMicrophone()

    var body: some View {
        ComponentPage(
            name: "VoiceWave",
            summary: "The voice made visible by the microphone: ribbons of aurora light that rise with each syllable, or a liquid orb that swells. Choose Microphone and speak.",
            since: "2.4.0",
            canvas: .dark(minHeight: 300),
            notes: [
                "level: 0…1 from the app's microphone (RMS). It is smoothed here: fast up, slow down, so speech swells instead of flickering.",
                "phase: .listening follows the voice; .thinking settles it while the words are understood, with a light running through.",
                "One Canvas at up to 60 fps, only on screen; still under Reduce Motion. Pair it with EdgeGlow(level:).",
            ]
        ) {
            VoiceLevelSource(kind: source, fixed: level, microphone: microphone) { level in
                VoiceWave(level: level, phase: phase, style: style)
                    .frame(height: style == .orb ? 240 : 140)
                    .frame(maxWidth: .infinity)
            }
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Ribbons", .ribbons), ("Orb", .orb)])
            ChoiceControl("Phase", selection: $phase, options: [("Listening", .listening), ("Thinking", .thinking)])
            ChoiceControl("Voice", selection: $source, options: [("Fixed", .fixed), ("Simulated", .simulated), ("Microphone", .microphone)])
            if source == .fixed {
                SliderControl("Level", value: $level, in: 0...1, step: 0.05)
            }
            if microphone.isDenied {
                Text("Microphone access is off for DesignKit Gallery in Settings.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .onChange(of: source) { _, new in
            if new == .microphone { Task { await microphone.start() } } else { microphone.stop() }
        }
        .onDisappear { microphone.stop() }
    }
}

/// Light along the edges while listening (2.4.0, Metal).
private struct EdgeGlowPage: View {
    @State private var source: VoiceSourceKind = .simulated
    @State private var level = 0.4
    @State private var thickness = Double(EdgeGlowMetrics.thickness)
    @State private var microphone = GalleryMicrophone()

    var body: some View {
        ComponentPage(
            name: "EdgeGlow",
            summary: "Light along the edges of the screen while the app listens: aurora colours flow round the rim and the voice makes it wider, brighter and faster.",
            since: "2.4.0",
            apps: [.tenra],
            canvas: .dark(minHeight: 340),
            notes: [
                "Replaces SiriGlow and SiriWave (deprecated names of it): the same full-screen overlay, now following the voice. EdgeGlow(level: voice.level).ignoresSafeArea().",
                "One Metal colour effect, no blur: cheaper than the old blurred mesh. 30 fps while motion is allowed; still otherwise.",
                "Without a level it breathes on its own. It fades in, passes touches through and is hidden from VoiceOver.",
            ]
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color(white: 0.08))
                VoiceLevelSource(kind: source, fixed: level, microphone: microphone) { level in
                    EdgeGlow(level: level, cornerRadius: AppRadius.xl, thickness: CGFloat(thickness))
                }
                Text("Listening…")
                    .font(AppTypography.h4)
                    .foregroundStyle(.white.opacity(0.7))
                    .thinkingShimmer()
            }
            .frame(height: 300)
            .clipShape(.rect(cornerRadius: AppRadius.xl))
            .padding(AppSpacing.lg)
        } controls: {
            ChoiceControl("Voice", selection: $source, options: [("Fixed", .fixed), ("Simulated", .simulated), ("Microphone", .microphone)])
            if source == .fixed {
                SliderControl("Level", value: $level, in: 0...1, step: 0.05)
            }
            SliderControl("Thickness", value: $thickness, in: 12...48, step: 2) { "\(Int($0)) pt" }
            if microphone.isDenied {
                Text("Microphone access is off for DesignKit Gallery in Settings.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .onChange(of: source) { _, new in
            if new == .microphone { Task { await microphone.start() } } else { microphone.stop() }
        }
        .onDisappear { microphone.stop() }
    }
}

/// A band of aurora colour running through text while the app works (2.4.0).
private struct ThinkingShimmerPage: View {
    @State private var isActive = true

    var body: some View {
        ComponentPage(
            name: ".thinkingShimmer",
            summary: "A band of aurora colour runs through the words while the app works on what was asked: “Listening…”, “Analysing…”, an insight on its way.",
            since: "2.4.0",
            notes: [
                "A skeleton's shimmer says content is coming; this one says the app is working on your request.",
                "One gradient masked by the text, 30 fps while active. Under Reduce Motion the text is drawn in the still aurora gradient.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Analysing your spending…")
                    .font(AppTypography.h4)
                    .foregroundStyle(AppColors.Text.secondary)
                    .thinkingShimmer(isActive: isActive)
                Text("Listening…")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.secondary)
                    .thinkingShimmer(isActive: isActive)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } controls: {
            ToggleControl("Active", isOn: $isActive)
        }
    }
}

/// Deprecated in 2.5.0: shown next to its replacement.
private struct GradientOrbsBackgroundPage: View {
    @State private var count = 3

    private let orbs: [(Color, Double)] = [
        (AppColors.accent, 0.5),
        (AppColors.success, 0.3),
        (AppColors.warning, 0.2),
        (.purple, 0.15),
    ]

    var body: some View {
        ComponentPage(
            name: "GradientOrbsBackground",
            summary: "Deprecated in 2.5.0: AuroraBackground(_ spots:) draws the same weighted pools of colour as one still mesh, with no blur. Top: the orbs; bottom: the aurora.",
            since: "1.5.0",
            apps: [.tenra],
            canvas: .bleed
        ) {
            VStack(spacing: 0) {
                legacyOrbs
                    .frame(height: 180)
                AuroraBackground(Array(orbs.prefix(count)).map { .init(color: $0.0, weight: $0.1) })
                    .frame(height: 180)
            }
        } controls: {
            StepperControl("Orbs", value: $count, in: 1...4)
        }
    }

    @available(*, deprecated)
    private var legacyOrbs: some View {
        GradientOrbsBackground(Array(orbs.prefix(count)).map { .init(color: $0.0, weight: $0.1) })
    }
}

/// A fine still grain (2.5.0).
private struct GrainPage: View {
    @State private var amount = GrainMetrics.amount

    var body: some View {
        ComponentPage(
            name: ".grain",
            summary: "A fine, still grain over a surface: it breaks the banding a smooth gradient shows on a dark screen and gives a background a printed texture.",
            since: "2.5.0",
            canvas: .bleed,
            notes: [
                "One Metal colour effect, the same on every frame. AuroraBackground and the aurora accentGlow carry it.",
                "0.04 is felt more than seen; raise it to see what it does.",
            ]
        ) {
            HStack(spacing: 0) {
                LinearGradient(colors: [Color(white: 0.05), AppColors.accent.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [Color(white: 0.05), AppColors.accent.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .grain(amount)
            }
            .frame(height: 220)
        } controls: {
            SliderControl("Amount", value: $amount, in: 0...0.2, step: 0.01) { $0.formatted(.number.precision(.fractionLength(2))) }
        }
    }
}

private struct AccentGlowPage: View {
    @State private var edge = 0
    @State private var style: AccentGlowStyle = .aurora
    @State private var drifts = false
    @State private var tint = 0

    var body: some View {
        ComponentPage(
            name: ".accentGlow",
            summary: "A wash of colour from one edge: onboarding backgrounds, a hero's light.",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "style: .aurora (2.5.0, the default): a band of mesh-gradient light in the tint and its neighbours, fading inwards, with a fine grain. No blur, so lighter than .soft, the blurred circle of before.",
                "drifts: the light moves slowly (onboardingAccentGlow does). Off for heroAccentGlow: under Liquid Glass a still background keeps the glass from redrawing.",
            ]
        ) {
            Color.clear
                .frame(height: 260)
                .accentGlow(
                    [AppColors.accent, AppColors.success, .orange][tint],
                    edge: edge == 0 ? .top : .bottom,
                    style: style,
                    drifts: drifts
                )
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Aurora", .aurora), ("Soft", .soft)])
            ChoiceControl("Edge", selection: $edge, options: [("Top", 0), ("Bottom", 1)])
            ChoiceControl("Tint", selection: $tint, options: [("Accent", 0), ("Green", 1), ("Orange", 2)])
            ToggleControl("Drifts", isOn: $drifts)
        }
    }
}

private struct BorderBeamPage: View {
    @State private var beam = true
    @State private var glow = true
    @State private var beams = 1
    @State private var duration = 3.0

    var body: some View {
        ComponentPage(
            name: ".borderBeam · .borderGlow",
            summary: "A comet of light running around a card's border and a soft glow: “working on it”, AI and live states.",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "2.4.0: the comet runs along the border itself, so it keeps one speed and length on every side and corner. A bright head with a bloom, a fading tail, a faint spill on the edge it passes.",
                "beams: 2 runs a second comet opposite the first. Display rate while active; nothing under Reduce Motion.",
            ]
        ) {
            Text("Analysing your spending…")
                .font(AppTypography.body)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .cardStyle()
                .borderGlow(isActive: glow)
                .borderBeam(isActive: beam, duration: duration, beams: beams)
        } controls: {
            ToggleControl("Beam", isOn: $beam)
            ToggleControl("Glow", isOn: $glow)
            StepperControl("Comets", value: $beams, in: 1...2)
            SliderControl("Revolution", value: $duration, in: 1.5...6, step: 0.5) { "\($0.formatted(.number.precision(.fractionLength(1)))) s" }
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
