//
//  FeedbackSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Empty states, banners, inline status, tooltips, steps, a permission prompt, onboarding pieces.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Feedback")
    struct Feedback {
        @Test func statusBanners() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.sm) {
                    StatusBanner("Your statement for September is ready", status: .info) {}
                    StatusBanner("Payment sent", status: .positive)
                    StatusBanner("Card expires on 30 Nov", status: .warning)
                    StatusBanner("Transfer failed: try again later", status: .negative) {}
                    StatusBanner("Subscription paused", status: .neutral)
                    StatusBanner("Synced a minute ago", status: .positive, style: .compact)
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func emptyStates() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.xl) {
                    EmptyState(
                        icon: "tray",
                        title: "No transactions",
                        description: "Add the first one with the plus button."
                    )
                    EmptyState(icon: "magnifyingglass", title: "Nothing found", style: .compact)
                    EmptyState(
                        icon: "wifi.slash",
                        title: "Could not load",
                        description: "Check the connection.",
                        actionTitle: "Retry",
                        action: {},
                        style: .error
                    )
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func bannersAndStatus() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    MessageBanner(message: "Saved", type: .success)
                    MessageBanner(message: "Failed to load", type: .error)
                    MessageBanner(message: "Low balance", type: .warning)
                    MessageBanner(message: "Trip deleted", type: .info, actionTitle: "Undo") {}
                    InlineStatusText(message: "Amount must be positive", type: .error)
                    InlineStatusText(message: "Synced a minute ago", type: .success)
                    RecommendationBox(
                        text: "Fishing is banned here until 15 June.",
                        color: AppColors.destructive,
                        icon: "nosign"
                    )
                }
            )
        }

        @Test func stepTracker() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.xl) {
                    StepTracker(steps: ["Place", "Catch", "Photos", "Review"], current: 1)
                    StepTracker(steps: ["One", "Two", "Three"], current: 3, showsLabels: false)
                    OnboardingStepIndicator(currentStep: 2)
                    OnboardingStepIndicator(
                        currentStep: 1,
                        symbols: ["map", "tent.fill", "person.2.fill", "checkmark.seal.fill"]
                    )
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        /// Tooltip (2.0.0) above and below its target, with text and with an amount.
        @Test func tooltips() async {
            await assertComponentSnapshot(
                HStack(alignment: .center, spacing: AppSpacing.xxl) {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.accent)
                        .frame(width: 64, height: 48)
                        .overlay(alignment: .top) {
                            Tooltip {
                                Text(verbatim: "1 250 000 ₸")
                                    .font(AppTypography.numbers(AppTypography.bodySmall.bold()))
                                    .foregroundStyle(AppColors.accent)
                            }
                            .tooltipAnchor(.top)
                        }
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.Text.secondary.opacity(0.25))
                        .frame(width: 64, height: 48)
                        .overlay(alignment: .bottom) {
                            Tooltip("Last month", arrowEdge: .top)
                                .tooltipAnchor(.bottom)
                        }
                }
                // The tooltips are overlays, outside the targets' frames: room for them at
                // large text sizes too, or the picture cuts them.
                .padding(.vertical, AppSpacing.xxxl * 3)
                .frame(maxWidth: .infinity),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// A permission primer is a PromptSheet since 2.0.0 (PermissionPrimerView before).
        @Test func permissionPrimer() async {
            await assertComponentSnapshot(
                PromptSheet(
                    systemImage: "bell.badge",
                    title: "Don't miss replies",
                    message: "We'll tell you when a friend answers or a saved place gets new rules.",
                    primaryTitle: "Turn on",
                    secondaryTitle: "Not now",
                    detent: nil,
                    dismissesOnAnswer: false,
                    onPrimary: {},
                    onSecondary: {}
                ),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func onboardingPage() async {
            await assertComponentSnapshot(
                OnboardingPage(
                    systemImage: "mappin.and.ellipse",
                    title: "Places",
                    message: "Lakes, rivers and camps with reviews from people who were there."
                )
                .frame(height: 440)
            )
        }

        @Test func importProgressSheet() async {
            await assertComponentSnapshot(
                ImportProgressSheet(currentRow: 100, totalRows: 250, progress: 0.4) {},
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}
