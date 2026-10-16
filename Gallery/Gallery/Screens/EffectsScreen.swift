//
//  EffectsScreen.swift
//  DesignKit Gallery
//
//  Effects: celebrations, sparkles, shine, attention pulse, the aurora, touch tilt (2.2.0);
//  the completion moment and the Metal ripple (2.3.0); the voice wave, the edge glow and the
//  thinking shimmer (2.4.0); weighted aurora spots, the aurora accent glow and grain (2.5.0);
//  holographic foil and dissolve (2.6.0); the border beam; the hero background (4.5.0).
//

import SwiftUI
import DesignTokens
import DesignComponents

struct EffectsScreen: View {
    static let title = "Effects"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        CelebrationPage()
        CompletionMomentPage()
        RipplePage()
        SparkleBurstPage()
        ShinePage()
        AttentionPulsePage()
        AuroraBackgroundPage()
        InteractiveTiltPage()
        HolographicPage()
        DissolvePage()
        VoiceWavePage()
        EdgeGlowPage()
        ThinkingShimmerPage()
        GrainPage()
        AccentGlowPage()
        BorderBeamPage()
        HeroBackgroundPage()
        EdgeBackdropPage()
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
                "Weighted spots (2.5.0): AuroraBackground([.init(color:weight:)]): each colour a soft pool sized and brightened by its weight, sampled into a 5×5 mesh. Replaced GradientOrbsBackground (removed in 3.0.0): no blur, no screen blend, no offscreen pass.",
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
            ],
            styles: ["ribbons", "orb"]
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
                "Replaces SiriGlow and SiriWave (removed in 3.0.0): the same full-screen overlay, now following the voice. EdgeGlow(level: voice.level).ignoresSafeArea().",
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
            ],
            styles: ["aurora", "soft"]
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

private struct EdgeBackdropPage: View {
    @State private var bottom = false
    @State private var colorOpacity = EdgeBackdropMetrics.colorOpacity
    @Environment(\.presentShowcaseScreen) private var presentScreen

    private let rows = ["How much did I spend on cafés?", "Groceries went up 12% this month.", "Your next payment is the internet, tomorrow.",
                        "You put 50 000 ₸ towards the car.", "The savings rate is 18%.", "Taxi: 14 trips, 42 000 ₸.",
                        "Coffee House is your most frequent place.", "Spending is below last month."]

    var body: some View {
        ComponentPage(
            name: "EdgeBackdrop",
            summary: "A bar's backing over scrolling content: the content blurs and the page's colour lies over it, strongest at the screen's edge and fading out towards the content.",
            since: "4.14.0",
            apps: [.tenra],
            canvas: .tall(minHeight: 360),
            notes: [
                "For a bar the system's scroll edge effect is too faint to carry (a large header over a chat).",
                "Put it behind the bar's content with .edgeBackdrop(edge); it reaches to the screen's edge, takes no touches, and VoiceOver skips it.",
                "colorOpacity: the page's colour at the edge (10% by default, 5.0.0): lower is more see-through, higher reads as a plate. The blur stays the same.",
                "Hide the system's scroll edge effect on that edge, .scrollEdgeEffectHidden(true, for: edge) (5.0.0): on iOS 26 it fades the content out under the bar before the backing blurs it; built with Xcode 27 it is a hard plate as it comes. On iOS 27 the soft one is reported to stop below a bar's text and controls.",
                "A bar on a scroll view inside another (this preview in the page) is a safeAreaInset: a safeAreaBar there draws the outer scroll view's edge effect down to itself.",
                "Compare on a screen: a chat under Ten, 120 pt, in a safeAreaBar as an app holds it, with EdgeBackdrop or the system's scroll edge effect (soft, hard). The preview here cannot show the system's effect: its scroll view is inside the page's.",
            ]
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(rows, id: \.self) { row in
                        Text(row)
                            .font(AppTypography.body)
                            .padding(AppSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.accent.opacity(0.15), in: .rect(cornerRadius: AppRadius.lg))
                    }
                }
                .padding(AppSpacing.md)
            }
            .scrollEdgeEffectHidden(true, for: bottom ? .bottom : .top)
            // An app's screen holds the bar in a safeAreaBar. Here the preview's scroll view is
            // inside the page's, where a safeAreaBar draws the page's edge effect down to itself
            // and the page above blurs (docs/gotchas.md); with the edge effect hidden, an inset
            // looks the same.
            .safeAreaInset(edge: bottom ? .bottom : .top, spacing: 0) {
                ParticleCreature(mood: .happy, style: .compact)
                    .frame(width: AppIconSize.Tile.xxxl, height: AppIconSize.Tile.xxxl)
                    .padding(.vertical, AppSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .edgeBackdrop(bottom ? .bottom : .top, colorOpacity: colorOpacity)
            }
            .frame(height: 340)
            .clipShape(.rect(cornerRadius: AppRadius.lg))
        } controls: {
            ToggleControl("Bottom edge", isOn: $bottom)
            SliderControl("Colour opacity", value: $colorOpacity, in: 0...1, step: 0.05) { "\(Int(($0 * 100).rounded()))%" }
            // Presented by the showcase screen, outside the page's scroll view: presented from
            // the page, the comparison's bar drew no system edge effect (docs/gotchas.md).
            ActionControl("Compare on a screen", systemImage: "rectangle.on.rectangle") {
                presentScreen?(EdgeBackdropComparison(colorOpacity: $colorOpacity))
            }
        }
    }
}

/// EdgeBackdrop next to the system's scroll edge effect, on a screen of its own as Tenra's chat
/// holds it: a thread under Ten, 120 pt, in a top `safeAreaBar` (5.0.0, the owner asked to
/// compare). The page's preview cannot show the system's effect: its scroll view is inside the
/// page's (docs/gotchas.md).
struct EdgeBackdropComparison: View {
    enum Backing: String, CaseIterable, Hashable {
        case edgeBackdrop = "EdgeBackdrop"
        case soft = "Soft"
        case hard = "Hard"
    }

    @State var backing: Backing = .edgeBackdrop
    @Binding var colorOpacity: Double
    /// A title and a button under Ten: on iOS 27 the system's soft effect is reported to follow a
    /// bar's text and controls, so it can be seen with and without them.
    @State var showsTitleRow = false

    @Environment(\.dismiss) private var dismiss

    private let rows = [
        "How much did I spend on cafés?", "18 400 ₸ this week: Coffee House four times, a lunch on Friday.",
        "And groceries?", "Groceries went up 12% this month, mostly the weekend shops.",
        "When is my next payment?", "The internet, tomorrow: 7 990 ₸ from the card.",
        "How is the car fund?", "You put 50 000 ₸ towards the car. 62% of the goal is there.",
        "What about taxis?", "Taxi: 14 trips, 42 000 ₸. Most of them in the evening.",
        "Am I spending less than last month?", "Yes: spending is below last month by 9%.",
        "What is my savings rate?", "The savings rate is 18%, two points above September.",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(rows.indices, id: \.self) { index in
                    let question = index.isMultiple(of: 2)
                    Text(rows[index])
                        .font(AppTypography.body)
                        .foregroundStyle(question ? AppColors.staticWhite : AppColors.Text.primary)
                        .padding(AppSpacing.md)
                        .background(question ? AppColors.accent : AppColors.accent.opacity(0.15),
                                    in: .rect(cornerRadius: AppRadius.lg))
                        .frame(maxWidth: .infinity, alignment: question ? .trailing : .leading)
                }
            }
            .padding(AppSpacing.lg)
        }
        .defaultScrollAnchor(.bottom)
        .background(AppColors.bgBase)
        // EdgeBackdrop hides the system's effect (5.0.0); the others are the system's own.
        .scrollEdgeEffectHidden(backing == .edgeBackdrop, for: .top)
        .scrollEdgeEffectStyle(backing == .hard ? .hard : .soft, for: .top)
        .safeAreaBar(edge: .top) {
            VStack(spacing: AppSpacing.sm) {
                ParticleCreature(mood: .happy)
                    .frame(width: 120, height: 120)
                if showsTitleRow {
                    HStack {
                        Text(verbatim: "Ten")
                            .font(AppTypography.h4)
                            .foregroundStyle(AppColors.Text.primary)
                        Spacer()
                        Button {} label: {
                            Image(systemName: "ellipsis")
                                .font(AppTypography.bodyEmphasis)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel("More")
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity)
            .background {
                if backing == .edgeBackdrop {
                    EdgeBackdrop(edge: .top, colorOpacity: colorOpacity)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            panel
        }
    }

    /// What is compared, the colour's opacity for EdgeBackdrop, and the way back.
    private var panel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Picker("Backing", selection: $backing) {
                    ForEach(Backing.allCases, id: \.self) { backing in
                        Text(backing.rawValue).tag(backing)
                    }
                }
                .pickerStyle(.segmented)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(AppTypography.bodyEmphasis)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Close")
            }
            if backing == .edgeBackdrop {
                SliderControl("Colour opacity", value: $colorOpacity, in: 0...1, step: 0.05) { "\(Int(($0 * 100).rounded()))%" }
            } else {
                Text(verbatim: "The system's scroll edge effect, .scrollEdgeEffectStyle(.\(backing.rawValue.lowercased()), for: .top): no colour of its own to set.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Toggle(isOn: $showsTitleRow) {
                Text(verbatim: "Title and button under Ten")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.accent)
        }
        .padding(AppSpacing.lg)
        .cardStyle()
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
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

/// A holographic foil that follows the finger (2.6.0, Metal).
private struct HolographicPage: View {
    @State private var strength = HolographicMetrics.strength
    @State private var tilts = true

    var body: some View {
        ComponentPage(
            name: ".holographic",
            summary: "A holographic foil: rainbow bands slide across the surface as your finger moves over it, with a sheen where the light falls. Drag over the medal and the card.",
            since: "2.6.0",
            apps: [.dalada],
            notes: [
                "Pairs with .interactiveTilt(in:), which tilts the same surface towards the finger.",
                "One Metal colour effect, redrawn only while the finger moves or the light settles back.",
            ]
        ) {
            HStack(spacing: AppSpacing.xl) {
                medal
                card
            }
            .frame(maxWidth: .infinity)
        } controls: {
            SliderControl("Strength", value: $strength, in: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
            ToggleControl("With interactiveTilt", isOn: $tilts)
        }
    }

    @ViewBuilder
    private var medal: some View {
        let foil = AchievementMedal(systemImage: "mountain.2.fill", color: .orange, isEarned: true, size: 120)
            .holographic(strength: strength)
        if tilts { foil.interactiveTilt(in: Circle()) } else { foil }
    }

    @ViewBuilder
    private var card: some View {
        let foil = VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Tenra Pro").font(AppTypography.bodyEmphasis)
            Text("Member since 2026").font(AppTypography.caption).foregroundStyle(AppColors.Text.secondary)
        }
        .frame(width: 150, height: 96, alignment: .bottomLeading)
        .padding(AppSpacing.md)
        .background(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.65)], startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: AppRadius.lg))
        .holographic(strength: strength)
        if tilts { foil.interactiveTilt(in: RoundedRectangle(cornerRadius: AppRadius.lg)) } else { foil }
    }
}

/// A view breaking into dust as it is removed (2.6.0, Metal).
private struct DissolvePage: View {
    @State private var items = ["Coffee · 1 200 ₸", "Taxi · 2 400 ₸", "Groceries · 8 900 ₸"]
    @State private var removed = 0

    var body: some View {
        ComponentPage(
            name: ".dissolve",
            summary: "A view breaks into dust as it is removed: the edge of what remains glows and loose grains drift up. Inserted, the dust gathers. Keep it for deleting something the person owned.",
            since: "2.6.0",
            notes: [
                "Remove with .transition(.dissolve) and an animation of about 0.6 s: withAnimation(.easeIn(duration: 0.6)) { … }.",
                "One Metal layer effect, only while the transition plays; a fade under Reduce Motion.",
            ]
        ) {
            VStack(spacing: AppSpacing.sm) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(AppTypography.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.lg)
                        .cardStyle()
                        .transition(.dissolve)
                }
            }
            .frame(minHeight: 200, alignment: .top)
        } controls: {
            ActionControl("Delete the first", systemImage: "trash") {
                guard !items.isEmpty else { return }
                withAnimation(.easeIn(duration: 0.6)) { _ = items.removeFirst() }
            }
            ActionControl("Add one back", systemImage: "plus") {
                removed += 1
                withAnimation(.easeOut(duration: 0.6)) { items.append("Lunch \(removed) · 3 500 ₸") }
            }
        }
    }
}

// MARK: - Hero background (4.5.0)

/// The top of a detail screen on colour: a hero, its chart and its trend on a gradient of the
/// insight's colour (white on a deep one in dark mode, black on a pale one in light mode), the
/// cards below rising over its fade.
private struct HeroBackgroundPage: View {
    @State private var tone = 2
    @State private var chart = 0

    private static let tones: [(String, Color)] = [
        ("Positive", AppColors.success), ("Neutral", AppColors.accent),
        ("Warning", AppColors.warning), ("Critical", AppColors.destructive),
    ]

    private var color: Color { Self.tones[tone].1 }

    var body: some View {
        ComponentPage(
            name: ".heroBackground",
            summary: "The top of a detail screen on colour: a gradient of the colour from the screen's top edge, behind the navigation bar and the hero, fading into the page. In dark mode a tone deeper with the hero pieces in white; in light mode a pale tint with them in black.",
            since: "4.5.0",
            apps: [.tenra],
            canvas: .bleed,
            notes: [
                "Dark mode: sets \\.heroTone to .onColor, so HeroSection, TrendBadge, HeroHalfGauge, HeroBarPair, HeroSparkline, HeroMilestoneGauge and HeroProportionBar draw in white. Light mode (4.5.1): a pale tint, the tone stays .onSurface and the pieces draw as on the page, the text in black. ScoreGaugeCard(style: .hero) lies on it.",
                "Edge to edge at the top of a scroll view; the cards that follow rise over its 96 pt fade (.padding(.top, -AppSpacing.xxl)).",
                ".heroScrollEdge() on the scroll view keeps the bar's soft scroll edge off while the colour is under the bar, and starts the gradient at the screen's top edge, not under the bar (4.5.1). “Open as a screen” shows both.",
            ]
        ) {
            VStack(spacing: AppSpacing.xl) {
                HeroBackgroundSample(chart: chart)
                    .heroBackground(color)
                Text(verbatim: "A card rises over the fade")
                    .font(AppTypography.bodyEmphasis)
                    .frame(maxWidth: .infinity)
                    .cardContentPadding()
                    .cardStyle()
                    .screenPadding()
                    .padding(.top, -AppSpacing.xxl)
            }
        } controls: {
            ChoiceControl("Tone", selection: $tone, options: Self.tones.indices.map { (Self.tones[$0].0, $0) })
            ChoiceControl("Hero chart", selection: $chart, options: [("Bars", 0), ("Line", 1), ("Shares", 2)])
            NavigationLink {
                HeroBackgroundScreen(color: color, chart: chart)
            } label: {
                Label("Open as a screen", systemImage: "iphone")
                    .font(AppTypography.bodySmall.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(AppColors.accent)
        }
    }
}

/// An insight's hero: the header, its trend and a chart.
private struct HeroBackgroundSample: View {
    let chart: Int

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            HeroSection(icon: nil, title: "Spending", showsIcon: false, primaryAmount: 284_000,
                        primaryCurrency: "KZT", subtitle: "September against August") {
                TrendBadge(direction: .up, changePercent: 12.4)
            }
            switch chart {
            case 0:
                HeroBarPair(previous: 252_000, current: 284_000, color: AppColors.warning, currency: "KZT")
            case 1:
                HeroSparkline(dataPoints: Array(GallerySamples.months.suffix(8)), series: GallerySamples.distance,
                              markExtremes: true)
            default:
                HeroProportionBar(segments: GallerySamples.slices, currency: "KZT")
                    .screenPadding()
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xxl)
    }
}

/// The hero where it lives: the top of a screen under an inline navigation bar.
private struct HeroBackgroundScreen: View {
    let color: Color
    let chart: Int

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                HeroBackgroundSample(chart: chart)
                    .heroBackground(color)
                VStack(spacing: AppSpacing.lg) {
                    ForEach(["August", "July", "June", "May"], id: \.self) { month in
                        Text(verbatim: month)
                            .font(AppTypography.bodyEmphasis)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardContentPadding()
                            .cardStyle()
                    }
                }
                .screenPadding()
                // The cards rise over the fading end of the gradient.
                .padding(.top, -AppSpacing.xxl)
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .heroScrollEdge()
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.inline)
    }
}
