//
//  MotionScreen.swift
//  DesignKit Gallery
//
//  Motion: the springs by purpose (2.2.0) and the older tokens, each played on a ball you can
//  replay; SF Symbol motion, the transitions, text reveal, scroll reveal; chart draw-in,
//  skeleton reveal, the scroll hero and haptic cues (2.3.0); and the motion modifiers
//  (staggered entrance, chart appear, content reveal, blur-slide).
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct MotionScreen: View {
    var body: some View {
        ShowcasePage(title: "Motion") {
            MotionSpringsPage()
            SymbolMotionPage()
            MotionTransitionsPage()
            TextRevealPage()
            ScrambleTextPage()
            ScrollRevealPage()
            ChartDrawInPage()
            SkeletonRevealPage()
            ScrollHeroPage()
            HapticCuesPage()
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

/// Charts drawn in from left to right (2.3.0).
private struct ChartDrawInPage: View {
    @State private var replay = 0
    @State private var kind = 0

    var body: some View {
        ComponentPage(
            name: ".chartDrawIn",
            summary: "A chart drawn in from its leading edge as it first appears: the line is traced, the bars rise one after another. LineChart, BarChart and HeroSparkline do it on their own.",
            since: "2.3.0",
            apps: [.tenra, .dalada],
            notes: [
                "One mask whose width animates once, with a soft front edge; the chart's marks and data are untouched.",
                "For your own chart: Chart { … }.chartDrawIn(). Under Reduce Motion the chart is simply there.",
            ]
        ) {
            Group {
                if kind == 0 {
                    LineChart(dataPoints: GallerySamples.months, series: [GallerySamples.income, GallerySamples.expenses],
                              valueFormat: .currency("KZT"), todayText: "Today")
                } else {
                    BarChart(dataPoints: GallerySamples.months, series: GallerySamples.distance,
                             valueFormat: .custom({ "\($0.formatted(.number.precision(.fractionLength(0)))) km" }),
                             todayText: "Today")
                }
            }
            .id("\(kind)-\(replay)")
        } controls: {
            ChoiceControl("Chart", selection: $kind, options: [("Line", 0), ("Bars", 1)])
            ActionControl("Replay") { replay += 1 }
        }
    }
}

/// The skeleton turning into the content (2.3.0).
private struct SkeletonRevealPage: View {
    @State private var isLoading = true

    var body: some View {
        ComponentPage(
            name: "SkeletonReveal",
            summary: "Loading ends softly: the skeleton fades out while the content comes into focus from a light blur in the same place, instead of a jump.",
            since: "2.3.0",
            canvas: .fill,
            notes: [
                "SkeletonReveal(isLoading:) { content } skeleton: { <Name>Skeleton() }. Give both the same size; a component and its skeleton already have it.",
                "As a transition on its own: .transition(.skeletonReveal). FinanceCard reveals its amount this way.",
                "Under Reduce Motion the two cross-fade without the blur.",
            ]
        ) {
            SkeletonReveal(isLoading: isLoading) {
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                            amount: 1_250_000, currency: "KZT")
            } skeleton: {
                BalanceCardSkeleton()
            }
        } controls: {
            ToggleControl("Loading", isOn: $isLoading)
        }
    }
}

/// A hero that stretches on pull and drifts away on scroll (2.3.0).
private struct ScrollHeroPage: View {
    @State private var parallax = Double(ScrollHeroMetrics.parallax)
    @State private var fades = true

    var body: some View {
        ComponentPage(
            name: ".scrollHero",
            summary: "The image or header at the top of a detail screen lives with the scroll: pulled down it stretches to fill the gap, scrolled away it drifts slower than the content and fades. Scroll and pull inside the canvas.",
            since: "2.3.0",
            canvas: .tall(minHeight: 380),
            notes: [
                "For the first view in a vertical ScrollView. One visualEffect; nothing re-renders while scrolling.",
                "Under Reduce Motion there is no parallax; the stretch stays, because it follows the finger.",
            ]
        ) {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    ZStack(alignment: .bottomLeading) {
                        AuroraBackground(intensity: 0.9)
                        Text("Weekend at the lake")
                            .font(AppTypography.h3)
                            .foregroundStyle(.white)
                            .padding(AppSpacing.lg)
                    }
                    .frame(height: 200)
                    .clipped()
                    .scrollHero(parallax: parallax, fades: fades)

                    ForEach(0..<8, id: \.self) { index in
                        AmountRow(
                            "Stop \(index + 1)",
                            subtitle: "Day \(index / 3 + 1)",
                            leading: .tinted(.sfSymbol("mappin"), CategoryColors.color(for: "stop\(index)")),
                            value: .amount(Double(2_500 * (index + 1)), caption: nil),
                            currency: "KZT"
                        )
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
            }
            .frame(height: 360)
            .clipShape(.rect(cornerRadius: AppRadius.xl))
        } controls: {
            SliderControl("Parallax", value: $parallax, in: 0...0.8, step: 0.05)
            ToggleControl("Fades", isOn: $fades)
        }
    }
}

/// Haptics named by meaning (2.3.0).
private struct HapticCuesPage: View {
    @State private var segment = 0
    @State private var steps = 3.0
    @State private var level = 0.5

    private let cues: [(HapticCue, String, String)] = [
        (.tap, "tap", "A light press that does something small"),
        (.select, "select", "A choice moved: a segment, a chip"),
        (.tick, "tick", "A step or a detent passed"),
        (.confirm, "confirm", "It worked"),
        (.warn, "warn", "Careful"),
        (.fail, "fail", "It did not work"),
        (.celebrate, "celebrate", "Success, then two rising taps: a goal reached"),
    ]

    var body: some View {
        ComponentPage(
            name: "HapticCue",
            summary: "Haptics named by what they mean, to play with the motion that says the same thing: a selection with the segment that moves, a tick with each step, the celebration pattern with the confetti. Try it on a device.",
            since: "2.3.0",
            apps: [.tenra, .dalada],
            notes: [
                ".hapticCue(.select, trigger: selection) in a view; HapticManager.play(.confirm) in an action.",
                "Built in: SegmentedPicker (select), SliderRow (a tick per step, or at either end), .celebration (celebrate), .completionMoment (confirm).",
                "Haptics are not motion: Reduce Motion leaves them on; the system's haptics switch turns them off.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SegmentedPicker(title: "Period", selection: $segment, options: [("Week", 0), ("Month", 1), ("Year", 2)])
                SliderRow("Stepped", value: $steps, in: 0...10, step: 1, valueText: "\(Int(steps))")
                SliderRow("Smooth (ticks at the ends)", value: $level, in: 0...1, valueText: "\(Int((level * 100).rounded()))%")
            }
        } controls: {
            ForEach(cues, id: \.1) { cue, name, detail in
                ActionControl(".\(name): \(detail)", systemImage: "hand.tap") { HapticManager.play(cue) }
            }
        }
    }
}

/// Text that decodes itself (2.6.0).
private struct ScrambleTextPage: View {
    @State private var score = 78

    var body: some View {
        ComponentPage(
            name: "ScrambleText",
            summary: "Text that decodes itself: each character flickers through random ones of its kind and settles, left to right. For a result just worked out: an analysis total, a code, a score.",
            since: "2.6.0",
            notes: [
                "The final text sets the width, so nothing around it moves; VoiceOver reads the final text.",
                "30 fps only while it decodes (0.7 s); under Reduce Motion the text simply appears.",
            ]
        ) {
            VStack(spacing: AppSpacing.sm) {
                ScrambleText("\(score) / 100")
                    .font(AppTypography.h1)
                ScrambleText("CODE-\(score * 37)")
                    .font(AppTypography.body.monospaced())
                    .foregroundStyle(AppColors.Text.secondary)
            }
            .frame(maxWidth: .infinity)
        } controls: {
            ActionControl("New result", systemImage: "arrow.clockwise") { score = Int.random(in: 40...99) }
        }
    }
}
