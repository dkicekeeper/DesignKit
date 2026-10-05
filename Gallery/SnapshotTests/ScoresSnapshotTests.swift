//
//  ScoresSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Score and target cards ported from Tenra in 1.2.0: ScoreGaugeCard, ScoreCard,
//  TargetProgressCard.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Scores")
    struct Scores {
        @Test func scoreGaugeCards() async {
            await assertComponentSnapshot(
                ScoreGaugeCard(score: 72, zoneTicks: [40, 70], grade: "Good",
                               color: AppColors.success, subtitle: "You're on track"),
                named: "score"
            )
            await assertComponentSnapshot(
                ScoreGaugeCard(score: nil, zoneTicks: [40, 70], grade: "Not enough data",
                               color: AppColors.textSecondary,
                               subtitle: "Add a month of income to see your score"),
                named: "noScore"
            )
        }

        @Test func scoreCards() async {
            await assertComponentSnapshot(
                ScoreCard(title: "Health score", grade: "Good", score: 72, color: AppColors.success),
                named: "good",
                appearances: [.light, .dark, .largeText]
            )
            await assertComponentSnapshot(
                ScoreCard(title: "Health score", grade: "Needs attention", score: 34,
                          color: AppColors.destructive),
                named: "needsAttention",
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func targetProgressCards() async {
            await assertComponentSnapshot(
                TargetProgressCard(
                    systemImage: "banknote.fill",
                    color: AppColors.success,
                    title: "Savings rate",
                    badge: "Weight 30%",
                    summary: "Score 50 of 100",
                    currentLabel: "Current", currentValue: "10.0%",
                    targetLabel: "Target", targetValue: "20% or more",
                    progress: 0.5,
                    explanation: "The share of income left after expenses.",
                    recommendation: "Cut expenses by about 60 000 ₸ a month to reach 20%."
                ),
                named: "full"
            )
            await assertComponentSnapshot(
                TargetProgressCard(
                    systemImage: "gauge.with.dots.needle.33percent",
                    color: AppColors.warning,
                    title: "Budgets",
                    badge: "Weight 25%",
                    currentLabel: "Current", currentValue: "—",
                    targetLabel: "Target", targetValue: "Within budget",
                    progress: 0,
                    isMuted: true
                ),
                named: "muted"
            )
        }
    }
}
