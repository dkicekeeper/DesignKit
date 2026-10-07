//
//  EffectsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  The motion components of 2.2.0 in their still state (the harness sets
//  `.designKitMotion(false)`): the aurora's first frame, the typing indicator at rest, symbols
//  that would draw themselves on, shown drawn. Bursts, shine, pulses and tilt draw nothing
//  until triggered, so they have no picture.
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
    }
}
