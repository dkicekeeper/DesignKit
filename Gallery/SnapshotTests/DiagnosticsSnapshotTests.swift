//
//  DiagnosticsSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  TEMPORARY (2.9.0): why HeroHalfGauge's markers look translucent in a glass card. Each
//  variant is recorded once, its pixels read, then this file and its PNGs are deleted.
//

import SwiftUI
import Testing
import DesignTokens
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Diagnostics")
    struct Diagnostics {
        private func gauge(animated: Bool) -> HeroHalfGauge {
            HeroHalfGauge(value: 72, maxValue: 100, zoneTicks: [40, 70], color: AppColors.success,
                          diameter: 220, lineWidth: 16, animatesOnAppear: animated)
        }

        @Test func gaugeVariants() async {
            await assertComponentSnapshot(gauge(animated: true).frame(maxWidth: .infinity), named: "noCardAnimated")
            await assertComponentSnapshot(
                gauge(animated: false).frame(maxWidth: .infinity).padding(AppSpacing.lg).cardStyle(),
                named: "cardStatic"
            )
            await assertComponentSnapshot(
                gauge(animated: true).frame(maxWidth: .infinity).padding(AppSpacing.lg).cardStyle(),
                named: "cardAnimated"
            )
            await assertComponentSnapshot(
                gauge(animated: true).padding(24).drawingGroup().padding(-24)
                    .frame(maxWidth: .infinity).padding(AppSpacing.lg).cardStyle(),
                named: "cardDrawingGroup"
            )
            await assertComponentSnapshot(
                gauge(animated: true).frame(maxWidth: .infinity).padding(AppSpacing.lg)
                    .background {
                        Color.clear.glassEffect(.regular, in: .rect(cornerRadius: AppRadius.xl))
                    },
                named: "glassBehind"
            )
            await assertComponentSnapshot(
                ZStack {
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 80, height: 80)
                    Circle().fill(AppColors.success).frame(width: 50, height: 50).offset(x: 30)
                }
                .frame(maxWidth: .infinity).padding(AppSpacing.lg).cardStyle(),
                named: "overlapInCard"
            )
        }
    }
}
