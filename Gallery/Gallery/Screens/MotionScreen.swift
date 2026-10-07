//
//  MotionScreen.swift
//  DesignKit Gallery
//
//  Motion: the springs by purpose (2.2.0) and the older tokens, each played on a ball you can
//  replay; SF Symbol motion, the transitions, text reveal, scroll reveal, and the motion
//  modifiers (staggered entrance, chart appear, content reveal, blur-slide).
//

import SwiftUI
import DesignTokens
import DesignComponents

struct MotionScreen: View {
    var body: some View {
        ShowcasePage(title: "Motion") {
            MotionSpringsPage()
            SymbolMotionPage()
            MotionTransitionsPage()
            TextRevealPage()
            ScrollRevealPage()
            SpringsPage()
            DurationsPage()
            StaggeredEntrancePage()
            ChartAppearPage()
            ContentRevealPage()
            BlurSlidePage()
        }
    }
}

/// The four springs by purpose (2.2.0), on balls that run together.
private struct MotionSpringsPage: View {
    @State private var isAtEnd = false

    private let springs: [(String, String, Animation)] = [
        ("snappy", "0.25 s, no bounce — a toggle, a selection, a press", AppAnimation.snappy),
        ("smooth", "0.35 s, no overshoot — a value, a list, a layout", AppAnimation.smooth),
        ("bouncy", "0.4 s, small overshoot — added, liked, done", AppAnimation.bouncy),
        ("expressive", "0.55 s, bounce 0.3 — a goal reached, a hero", AppAnimation.expressive),
    ]

    var body: some View {
        ComponentPage(
            name: "Springs by purpose",
            summary: "Pick a spring by what the motion says: snappy answers a touch, smooth moves content, bouncy confirms, expressive celebrates.",
            since: "2.2.0",
            canvas: .fill,
            notes: [
                "AppAnimation.motion(_:reduceMotion:) returns nil under Reduce Motion: pair movement with a fade so the change still reads.",
                "Budgets (MotionBudget): feedback 0.25 s, entrance 0.35 s, stagger 0.04 s per item, 0.3 s at most.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(springs, id: \.0) { name, detail, animation in
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TokenLabel(name: name, value: detail)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.Background.neutral2)
                                    .frame(height: 4)
                                Circle()
                                    .fill(AppColors.accent)
                                    .frame(width: 20, height: 20)
                                    .offset(x: isAtEnd ? proxy.size.width - 20 : 0)
                                    .animation(animation, value: isAtEnd)
                            }
                            .frame(maxHeight: .infinity)
                        }
                        .frame(height: 24)
                    }
                }
            }
        } controls: {
            ActionControl("Play") { isAtEnd.toggle() }
        }
    }
}

/// SF Symbols' own motion by meaning: draw on, cues, pulses, Magic Replace.
private struct SymbolMotionPage: View {
    @State private var drawReplay = 0
    @State private var bounces = 0
    @State private var wiggles = 0
    @State private var isLive = true
    @State private var isWorking = true
    @State private var isOn = false
    @State private var motion = true

    var body: some View {
        ComponentPage(
            name: "Symbol motion",
            summary: "SF Symbols animate themselves: drawn on as they appear, a bounce or a wiggle when something happens, a loop while a state lasts, Magic Replace between two states.",
            since: "2.2.0",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: [
                ".drawOnAppear() — empty states, heroes, a completed step or checklist (iOS 26 Draw; symbols without draw data just appear).",
                ".symbolCue(.bounce / .wiggle, trigger:) — confirm / ask for attention. DSButton bounces its symbol on every press.",
                ".symbolPulse(.breathe / .working, isActive:) — live / in progress; a loop, so AmbientMotionGate stops it.",
                ".symbolMagicReplace() — eye ↔ eye.slash, circle ↔ checkmark.circle.fill: the slash or the check draws itself.",
                "All of it stands still under Reduce Motion and .designKitMotion(false).",
            ]
        ) {
            VStack(spacing: AppSpacing.xl) {
                HStack(spacing: AppSpacing.xxl) {
                    specimen("drawOnAppear") {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AppColors.Status.positive)
                            .drawOnAppear()
                            .id(drawReplay)
                    }
                    specimen("bounce") {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundStyle(AppColors.accent)
                            .symbolCue(.bounce, trigger: bounces)
                    }
                    specimen("wiggle") {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(AppColors.Status.warning)
                            .symbolCue(.wiggle, trigger: wiggles)
                    }
                }
                HStack(spacing: AppSpacing.xxl) {
                    specimen("breathe") {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(AppColors.Status.negative)
                            .symbolPulse(.breathe, isActive: isLive)
                    }
                    specimen("working") {
                        Image(systemName: "wifi")
                            .foregroundStyle(AppColors.accent)
                            .symbolPulse(.working, isActive: isWorking)
                    }
                    specimen("magicReplace") {
                        Image(systemName: isOn ? "eye.slash" : "eye")
                            .foregroundStyle(AppColors.Text.primary)
                            .symbolMagicReplace()
                            .animation(AppAnimation.snappy, value: isOn)
                    }
                }
            }
            .font(.system(size: AppIconSize.xl))
            .frame(maxWidth: .infinity)
            .designKitMotion(motion)
        } controls: {
            ActionControl("Draw on", systemImage: "pencil.and.scribble") { drawReplay += 1 }
            ActionControl("Bounce", systemImage: "arrow.up.and.down") { bounces += 1 }
            ActionControl("Wiggle", systemImage: "bell") { wiggles += 1 }
            ToggleControl("Live (breathe)", isOn: $isLive)
            ToggleControl("Working", isOn: $isWorking)
            ToggleControl("Eye slashed (Magic Replace)", isOn: $isOn)
            ToggleControl("DesignKit motion", isOn: $motion)
        }
    }

    private func specimen<Content: View>(_ name: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: AppSpacing.sm) {
            content()
                .frame(width: AppIconSize.Tile.lg, height: AppIconSize.Tile.lg)
            Text(name)
                .font(AppTypography.caption2.monospaced())
                .foregroundStyle(AppColors.Text.secondary)
        }
    }
}

/// .popIn and .riseIn: movement plus a fade; under Reduce Motion only the fade.
private struct MotionTransitionsPage: View {
    @State private var isShown = true
    @State private var kind = 0

    var body: some View {
        ComponentPage(
            name: ".popIn · .riseIn",
            summary: "Transitions that know Reduce Motion: they move a little and fade, and under Reduce Motion they only fade.",
            since: "2.2.0",
            canvas: .tall(minHeight: 160),
            notes: [
                ".popIn: grows from 92 % — a chip, a badge, a toast, a tooltip, TypingIndicator.",
                ".riseIn: rises 12 pt and sharpens from a blur — a card, a section, a banner.",
                "Insert with an animation: withAnimation(AppAnimation.bouncy) { isShown = true }.",
            ]
        ) {
            ZStack {
                if isShown {
                    if kind == 0 {
                        Badge("New", systemImage: "sparkles", style: .filled)
                            .transition(.popIn)
                    } else {
                        Text("Spending is 12 % lower than last month")
                            .font(AppTypography.bodySmall)
                            .padding(AppSpacing.lg)
                            .cardStyle()
                            .transition(.riseIn)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
        } controls: {
            ChoiceControl("Transition", selection: $kind, options: [(".popIn", 0), (".riseIn", 1)])
            ActionControl(isShown ? "Hide" : "Show") {
                withAnimation(kind == 0 ? AppAnimation.bouncy : AppAnimation.smooth) { isShown.toggle() }
            }
        }
    }
}

/// Text written in glyph by glyph (TextRenderer).
private struct TextRevealPage: View {
    @State private var replay = 0

    var body: some View {
        ComponentPage(
            name: ".textRevealOnAppear · .textReveal",
            summary: "Text that writes itself in: each glyph rises, sharpens and fades in after the one before. For text that arrives: an insight, an answer, a result.",
            since: "2.2.0",
            canvas: .tall(minHeight: 140),
            notes: [
                "One TextRenderer pass per frame: nothing is split into views, the text has its final size from the first frame.",
                "As a transition: if shown { Text(…).transition(.textReveal) }. Under Reduce Motion the text fades in whole.",
                ".blurSlideHero stays the transition for a block of text that replaces another.",
            ]
        ) {
            Text("You spent 18 % less on food this month. Most of it went on groceries.")
                .font(AppTypography.h4)
                .multilineTextAlignment(.center)
                .textRevealOnAppear()
                .id(replay)
                .frame(maxWidth: .infinity)
        } controls: {
            ActionControl("Replay") { replay += 1 }
        }
    }
}

/// Rows settling in as they scroll into view.
private struct ScrollRevealPage: View {
    var body: some View {
        ComponentPage(
            name: ".scrollReveal",
            summary: "Rows and cards settle in as they scroll into view and recede a little at the edges. Scroll inside the canvas.",
            since: "2.2.0",
            canvas: .tall(minHeight: 320),
            notes: [
                "A scrollTransition: no state, no timers. Under Reduce Motion it keeps a light fade only.",
                "For a ScrollView's rows and cards; a List has its own row behaviour.",
            ]
        ) {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(0..<14, id: \.self) { index in
                        AmountRow(
                            "Item \(index + 1)",
                            subtitle: "Groceries",
                            leading: .tinted(.sfSymbol("cart.fill"), CategoryColors.color(for: "row\(index)")),
                            value: .amount(Double(1_000 * (index + 3)), caption: nil),
                            currency: "KZT"
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .cardStyle()
                        .scrollReveal()
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
            .frame(height: 300)
        }
    }
}

/// A token played on a ball that runs from left to right; one replay button plays them all, so
/// the curves can be compared.
private struct SpringsPage: View {
    @State private var isAtEnd = false

    private let springs: [(String, String, Animation)] = [
        ("contentSpring", "0.3 s · damping 0.7 — content changes, chips", AppAnimation.contentSpring),
        ("gentleSpring", "0.4 s · damping 0.8 — sheets, steps", AppAnimation.gentleSpring),
        ("heroSpring", "0.6 s · damping 0.7 — hero entrances", AppAnimation.heroSpring),
        ("progressBarSpring", "0.55 s · damping 0.72 — bars filling", AppAnimation.progressBarSpring),
        ("facepileSpring", "0.4 s · damping 0.7 — avatars popping in", AppAnimation.facepileSpring),
        ("chartAppearAnimation", "0.55 s · damping 0.82 — charts", AppAnimation.chartAppearAnimation),
        ("carouselScroll", "ease in-out 0.3 s — carousel jumps", AppAnimation.carouselScroll),
    ]

    var body: some View {
        ComponentPage(
            name: "Springs",
            summary: "The named animations: tap Play to run every ball with its own curve and compare them.",
            canvas: .fill,
            notes: [
                "Never a hard-coded spring: pick a token. AppAnimation.adaptiveSpring and fastAnimation respect Reduce Motion.",
                "Continuous motion (orbs, waves, beams) runs only while AmbientMotionGate allows it: off under Reduce Motion and Low Power.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(springs, id: \.0) { name, detail, animation in
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TokenLabel(name: name, value: detail)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.bgMuted)
                                    .frame(height: 4)
                                Circle()
                                    .fill(AppColors.accent)
                                    .frame(width: 20, height: 20)
                                    .offset(x: isAtEnd ? proxy.size.width - 20 : 0)
                                    .animation(animation, value: isAtEnd)
                            }
                            .frame(maxHeight: .infinity)
                        }
                        .frame(height: 24)
                    }
                }
            }
        } controls: {
            ActionControl("Play") { isAtEnd.toggle() }
        }
    }
}

private struct DurationsPage: View {
    @State private var isVisible = true

    private let durations: [(String, Double)] = [
        ("fast", AppAnimation.fast), ("standard", AppAnimation.standard), ("slow", AppAnimation.slow),
    ]

    var body: some View {
        ComponentPage(
            name: "Durations",
            summary: "fast 0.1 s, standard 0.25 s, slow 0.35 s: the same fade at each duration.",
            canvas: .fill
        ) {
            HStack(spacing: AppSpacing.lg) {
                ForEach(durations, id: \.0) { name, duration in
                    VStack(spacing: AppSpacing.xs) {
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(AppColors.accent)
                            .frame(height: 56)
                            .opacity(isVisible ? 1 : 0.1)
                            .animation(.easeInOut(duration: duration), value: isVisible)
                        TokenLabel(name: name, value: "\(duration.formatted()) s")
                    }
                }
            }
        } controls: {
            ActionControl("Play") { isVisible.toggle() }
        }
    }
}

private struct StaggeredEntrancePage: View {
    @State private var replay = 0

    var body: some View {
        ComponentPage(
            name: ".staggeredEntrance",
            summary: "Items popping in one after another (facepileSpring, a 0.06 s stagger).",
            canvas: .tall(minHeight: 120)
        ) {
            HStack(spacing: -AppSpacing.sm) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(CategoryColors.color(for: "icon\(index)"))
                        .frame(width: AppIconSize.xxl, height: AppIconSize.xxl)
                        .overlay(Image(systemName: "person.fill").foregroundStyle(.white))
                        .overlay(Circle().strokeBorder(AppColors.bgBase, lineWidth: 2))
                        .staggeredEntrance(delay: Double(index) * AppAnimation.facepileStagger)
                        .id("\(replay)-\(index)")
                }
            }
        } controls: {
            ActionControl("Replay") { replay += 1 }
        }
    }
}

private struct ChartAppearPage: View {
    @State private var replay = 0

    var body: some View {
        ComponentPage(
            name: ".chartAppear",
            summary: "A chart's entrance: it grows and fades in from the bottom.",
            canvas: .tall(minHeight: 160)
        ) {
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(AppColors.accent.opacity(0.7))
                        .frame(width: 24, height: CGFloat(20 + index * 14))
                        .chartAppear(delay: Double(index) * AppAnimation.chartAppearDelay)
                        .id("\(replay)-\(index)")
                }
            }
            .frame(height: 130, alignment: .bottom)
        } controls: {
            ActionControl("Replay") { replay += 1 }
        }
    }
}

private struct ContentRevealPage: View {
    @State private var isReady = false

    var body: some View {
        ComponentPage(
            name: ".contentReveal",
            summary: "Loaded content fades in once it is ready; a delay staggers sections.",
            canvas: .fill,
            notes: ["Prefer a component's skeleton while it loads; contentReveal is for the moment it is replaced."]
        ) {
            Text("Loaded content")
                .font(AppTypography.body)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .cardStyle()
                .contentReveal(isReady: isReady)
                .id(isReady)
        } controls: {
            ToggleControl("Ready", isOn: $isReady)
        }
    }
}

private struct BlurSlidePage: View {
    @State private var phase = 0

    private let titles = ["Blur-slide reveal", "One transition preset", "For hero text"]

    var body: some View {
        ComponentPage(
            name: ".blurSlideHero",
            summary: "The canonical text change of a hero: the old text slides and blurs out, the new one in.",
            canvas: .tall(minHeight: 120)
        ) {
            Text(titles[phase])
                .font(AppTypography.h3)
                .id(phase)
                .transition(.blurSlideHero)
                .animation(AppAnimation.gentleSpring, value: phase)
        } controls: {
            ActionControl("Next") { withAnimation(AppAnimation.gentleSpring) { phase = (phase + 1) % titles.count } }
        }
    }
}

#Preview { NavigationStack { MotionScreen() } }
