//
//  FeedbackSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Empty states, banners, inline status, steps, permission primer, onboarding pieces,
//  skeletons.
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
        @Test func emptyStates() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.xl) {
                    EmptyStateView(
                        icon: "tray",
                        title: "No transactions",
                        description: "Add the first one with the plus button."
                    )
                    EmptyStateView(icon: "magnifyingglass", title: "Nothing found", style: .compact)
                    EmptyStateView(
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

        @Test func permissionPrimer() async {
            await assertComponentSnapshot(
                PermissionPrimerView(
                    systemImage: "bell.badge",
                    title: "Don't miss replies",
                    message: "We'll tell you when a friend answers or a saved place gets new rules.",
                    allowTitle: "Turn on",
                    laterTitle: "Not now",
                    onAllow: {},
                    onLater: {}
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

        /// Reduce Motion stops the shimmer, which otherwise sweeps on a clock and never
        /// draws the same frame twice: the snapshot is the skeleton's resting look.
        @Test func skeletons() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(spacing: 0) {
                        SkeletonRow()
                        SkeletonRow(showsIcon: false)
                    }
                    .cardContentPadding()
                    .cardStyle()
                    HStack(spacing: AppSpacing.md) {
                        SkeletonView(height: 44, width: 44, cornerRadius: AppRadius.md)
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            SkeletonView(width: 160)
                            SkeletonView(height: 12, width: 96)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.accessibilityReduceMotion, true)
            )
        }
    }
}
