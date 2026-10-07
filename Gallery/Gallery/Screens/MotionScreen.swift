//
//  MotionScreen.swift
//  DesignKit Gallery
//
//  Motion: the animation tokens, each played on a ball you can replay, and the motion
//  modifiers (staggered entrance, chart appear, content reveal, blur-slide).
//

import SwiftUI
import DesignTokens
import DesignComponents

struct MotionScreen: View {
    var body: some View {
        ShowcasePage(title: "Motion") {
            SpringsPage()
            DurationsPage()
            StaggeredEntrancePage()
            ChartAppearPage()
            ContentRevealPage()
            BlurSlidePage()
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
