//
//  EffectsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  The motion components of 2.2.0 to 2.6.0 in their still state (the harness sets
//  `.designKitMotion(false)`): the aurora's first frame, the typing indicator at rest, symbols
//  that would draw themselves on, shown drawn; a goal ring at 100 %, the closed glass menu, a
//  live amount at its value; the voice wave, the edge glow and the thinking shimmer at a fixed
//  level; weighted aurora spots and the aurora accent glow; the foil at rest, decoded text and a
//  spotlight. Bursts, shine, pulses, tilt, glows, ripples and dissolves draw nothing until
//  triggered, so they have no picture.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Effects")
    struct Effects {
        /// One still frame: the mesh at time 0, the accent's palette.
        @Test func auroraBackground() async {
            await assertComponentSnapshot(
                AuroraBackground()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl)),
                appearances: [.light, .dark]
            )
        }

        @Test func typingIndicator() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.lg) {
                    TypingIndicator()
                    TypingIndicator(tint: AppColors.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// Symbols with motion, drawn still and complete: a hero, a step done, a seal, a cue.
        @Test func symbolMotionStill() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.xl) {
                    HeroSymbol(systemImage: "checkmark.seal.fill", size: 72, tint: AppColors.Status.positive)
                    Image(systemName: "bell.fill")
                        .font(.system(size: AppIconSize.xl))
                        .foregroundStyle(AppColors.Status.warning)
                        .symbolCue(.wiggle, trigger: 1)
                    Image(systemName: "mic.fill")
                        .font(.system(size: AppIconSize.xl))
                        .foregroundStyle(AppColors.Status.negative)
                        .symbolPulse(.breathe)
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: AppIconSize.xl))
                        .foregroundStyle(AppColors.accent)
                        .drawOnAppear()
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        /// 2.3.0: a goal ring below and at 100 %: the complete one carries its checkmark.
        @Test func progressRingCompletion() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.xl) {
                    ProgressRing(progress: 0.6, size: AppIconSize.Tile.xxl, lineWidth: 6,
                                 animatesOnAppear: false, showsTrack: true, celebratesCompletion: true)
                    ProgressRing(progress: 1, size: AppIconSize.Tile.xxl, lineWidth: 6,
                                 animatesOnAppear: false, showsTrack: true, celebratesCompletion: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        /// 2.3.0: the closed menu, one glass button.
        @Test func glassActionMenu() async {
            await assertComponentSnapshot(
                GlassActionMenu(items: [
                    .init("Transfer", systemImage: "arrow.left.arrow.right") {},
                    .init("Expense", systemImage: "minus") {},
                ])
                .frame(maxWidth: .infinity, alignment: .trailing),
                appearances: [.light, .dark]
            )
        }

        /// 2.3.0: without motion the amount is shown at its value from the first frame.
        @Test func liveAmountText() async {
            await assertComponentSnapshot(
                LiveAmountText(amount: 1_284_500, currency: "KZT", fontSize: AppTypography.h1, fontWeight: .bold)
                    .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 2.4.0: the voice wave at a fixed level, still: ribbons, the orb, ribbons thinking.
        @Test func voiceWave() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    VoiceWave(level: 0.7).frame(height: 120)
                    HStack(spacing: AppSpacing.lg) {
                        VoiceWave(level: 0.7, style: .orb).frame(width: 140, height: 140)
                        VoiceWave(level: 0.7, phase: .thinking, style: .orb).frame(width: 140, height: 140)
                    }
                    VoiceWave(level: 0.7, phase: .thinking).frame(height: 60)
                }
                .padding(AppSpacing.lg)
                .background(Color(white: 0.08), in: .rect(cornerRadius: AppRadius.xl)),
                appearances: [.light, .dark]
            )
        }

        /// 2.4.0: the edge glow at a fixed level, still (a Metal colour effect).
        @Test func edgeGlow() async {
            await assertComponentSnapshot(
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.xl).fill(Color(white: 0.08))
                    EdgeGlow(level: 0.6, cornerRadius: AppRadius.xl)
                }
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: AppRadius.xl)),
                appearances: [.light, .dark]
            )
        }

        /// 2.4.0: without motion the text is drawn in the still aurora gradient.
        @Test func thinkingShimmer() async {
            await assertComponentSnapshot(
                Text("Analysing your spending…")
                    .font(AppTypography.h4)
                    .foregroundStyle(AppColors.Text.secondary)
                    .thinkingShimmer()
                    .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 2.5.0: weighted spots, still: the home screen's background.
        @Test func auroraSpots() async {
            await assertComponentSnapshot(
                AuroraBackground([
                    .init(color: .orange, weight: 1),
                    .init(color: .blue, weight: 0.6),
                    .init(color: .pink, weight: 0.4),
                ])
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl)),
                appearances: [.light, .dark]
            )
        }

        /// 2.5.0: the aurora accent glow from the top and from the bottom, still.
        @Test func accentGlowAurora() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Color.clear.frame(height: 160).accentGlow(AppColors.accent, edge: .top)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                    Color.clear.frame(height: 160).accentGlow(.orange, edge: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                },
                appearances: [.light, .dark]
            )
        }

        /// 2.6.0: the foil at rest, a medal and a card.
        @Test func holographic() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.xl) {
                    AchievementMedal(systemImage: "mountain.2.fill", color: .orange, isEarned: true, size: 100)
                        .holographic()
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(Color(white: 0.75))
                        .frame(width: 150, height: 96)
                        .holographic()
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark]
            )
        }

        /// 2.6.0: without motion the text is there at once.
        @Test func scrambleText() async {
            await assertComponentSnapshot(
                ScrambleText("78 / 100")
                    .font(AppTypography.h1)
                    .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 2.6.0: a spotlight on the second of two cards, its message below.
        @Test func spotlight() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Text("Balance").frame(maxWidth: .infinity).padding(AppSpacing.lg).cardStyle()
                    Text("Add").frame(maxWidth: .infinity).padding(AppSpacing.lg).cardStyle()
                        .spotlightAnchor("add")
                    Color.clear.frame(height: 90)
                }
                .padding(AppSpacing.md)
                .spotlight(.constant(Optional("add")), message: { _ in "Add an expense or an income here." }),
                appearances: [.light, .dark]
            )
        }
    }
}
