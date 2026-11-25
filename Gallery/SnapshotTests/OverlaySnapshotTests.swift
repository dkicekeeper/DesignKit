//
//  OverlaySnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  What covers a whole screen (8.18.0): `MomentOverlay` over a screen of an app, with and without
//  its primary button and reward, and `ProgressOverlay` with a hero in its spinner's place. Each
//  hero is a still `HeroSymbol` (the creature moves on a clock); the confetti draws nothing with
//  motion off, so a celebration looks like a quiet moment here.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Overlays")
    struct Overlays {
        /// A phone-sized screen of an app with `overlay` over it.
        private func screen<Overlay: View>(height: CGFloat = 640, @ViewBuilder _ overlay: () -> Overlay) -> some View {
            ZStack {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Goals")
                        .font(AppTypography.h1)
                    ForEach(["New bike", "Holiday", "Laptop"], id: \.self) { name in
                        ItemRow(name, meta: [MetaLine([.text("250 000 ₸"), .text("Due in May")])],
                                leading: .symbol("target"), verticalPadding: 0)
                    }
                    Spacer(minLength: 0)
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                overlay()
            }
            .frame(height: height)
        }

        /// What the moment gives, without glass (one Liquid Glass group per snapshot: the buttons).
        private var reward: some View {
            HStack(spacing: AppSpacing.md) {
                Icon(source: .sfSymbol("crown.fill"), size: AppIconSize.Tile.sm)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("A crown")
                        .font(AppTypography.bodyEmphasis)
                    Text("Earned for the goal")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.Background.fill, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }

        @Test func momentOverlay() async {
            // The primary button, the reward and a celebration.
            await assertComponentSnapshot(
                screen {
                    MomentOverlay(
                        title: "Goal reached",
                        message: "A new bike: 250 000 saved, two months early.",
                        celebrates: true,
                        primary: MomentAction("See the goal") {},
                        dismissTitle: "Later"
                    ) {
                        HeroSymbol(systemImage: "trophy.fill", size: 140, drawsOnAppear: false)
                    } reward: {
                        reward
                    }
                },
                named: "full",
                appearances: [.light, .dark, .largeText]
            )
            // The dismiss button alone, filled; no reward.
            await assertComponentSnapshot(
                screen {
                    MomentOverlay(
                        title: "Debt settled",
                        message: "Everything owed to Aida is paid back.",
                        dismissTitle: "Close"
                    ) {
                        HeroSymbol(systemImage: "checkmark.seal.fill", size: 140, drawsOnAppear: false)
                    }
                },
                named: "plain"
            )
        }

        @Test func progressOverlayHero() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    Text("Settings")
                        .font(AppTypography.h3)
                    Text("Backups")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 360)
                .progressOverlay(
                    isPresented: true,
                    title: "Restoring the backup",
                    message: "Your data will be back in a moment."
                ) {
                    HeroSymbol(systemImage: "arrow.clockwise.icloud", size: AppIconSize.Tile.xxxl, drawsOnAppear: false)
                }
            )
        }
    }
}
