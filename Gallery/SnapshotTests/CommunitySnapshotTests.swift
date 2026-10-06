//
//  CommunitySnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  People, comments, discussions, reviews, reactions; achievements, checklists, counters,
//  streaks and picture cards (1.12.0, from Dalada). Times are relative to now ("10 minutes
//  ago"), so they render the same on every run.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Community")
    struct Community {
        private let now = Date()

        @Test func personRows() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    PersonRow(name: "Aida Nurlanovna", subtitle: "@aida") { DisclosureChevron() }
                    PersonRow(name: "@askar")
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func commentRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    CommentRow(
                        author: "Aida",
                        date: now.addingTimeInterval(-600),
                        text: AttributedString("Was anyone on the lake this weekend?")
                    )
                    CommentRow(
                        author: "Timur",
                        date: now.addingTimeInterval(-120),
                        text: AttributedString("Thin near the north shore, fine in the bay."),
                        quote: MessageQuote(title: "Aida", text: "Was anyone on the lake this weekend?")
                    ) {
                        Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                    } actions: {
                        ReactionButton(systemImage: "hand.thumbsup", selectedSystemImage: "hand.thumbsup.fill",
                                       count: 12, isSelected: true, accessibilityLabel: "12") {}
                        Text("Reply").foregroundStyle(AppColors.accent)
                    }
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func threadCard() async {
            await assertComponentSnapshot(
                ThreadCard(
                    title: "Ice on Big Almaty Lake",
                    preview: "Heading up on Saturday. Has anyone checked the ice thickness this week?",
                    repliesCount: 14,
                    author: "@aida",
                    lastActivity: now.addingTimeInterval(-3_600)
                ),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func reviewCard() async {
            await assertComponentSnapshot(
                ReviewCard(
                    author: "Timur",
                    rating: 4,
                    date: now.addingTimeInterval(-86_400 * 3),
                    subtitle: "Visited in May 2026",
                    text: "Quiet spot, clean water, a good road until the last two kilometres."
                ) {
                    Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                } actions: {
                    ReactionButton(systemImage: "lightbulb", selectedSystemImage: "lightbulb.fill",
                                   count: 3, isSelected: false, title: "Helpful · 3", accessibilityLabel: "Helpful") {}
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func achievements() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        AchievementTile(title: "First trip", systemImage: "figure.hiking", color: .green,
                                        isEarned: true, medalSize: 64)
                        AchievementTile(title: "10 trips", systemImage: "map.fill", color: .blue,
                                        isEarned: false, medalSize: 64, progressText: "7 of 10")
                    }
                    AchievementProgressRow(label: "Up next:", title: "10 trips", progressText: "7 of 10",
                                           fraction: 0.7, systemImage: "map.fill", color: .blue)
                        .cardContentPadding()
                        .cardStyle()
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func checklistRows() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    ChecklistRow("Tent", isChecked: true, accessorySystemImage: "backpack", accessoryLabel: "From gear") {}
                    ChecklistRow("Headlamp", isChecked: false) {}
                    ChecklistSummaryRow(title: "Weekend at the lake", subtitle: "Sat, 12 Oct", checked: 12, total: 20)
                    ChecklistSummaryRow(title: "Fishing kit", checked: 8, total: 8)
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func statsStrip() async {
            await assertComponentSnapshot(
                StatsStrip(items: [
                    .init(value: "42", title: "days outdoors"),
                    .init(value: "17", title: "trips"),
                    .init(value: "384", title: "km"),
                    .init(value: "9", title: "catches"),
                ]),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func streakCard() async {
            await assertComponentSnapshot(
                StreakCard(systemImage: "flame.fill", isActive: true, title: "3 weeks in a row",
                           subtitle: "Head out by Sunday to keep it", value: "5", valueCaption: "best"),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func thumbnails() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ThumbnailCard(title: "Big Almaty Lake", isVerified: true, isSaved: true) {
                        ThumbnailPlaceholder(systemImage: "drop.fill")
                    } details: {
                        Text("Lake · 28 km · ★ 4.6")
                    }
                    ThumbnailRow(title: "Kolsai camp", isVerified: true, isSaved: true) {
                        ThumbnailPlaceholder(systemImage: "tent.fill", tint: .orange)
                    } details: {
                        Text("Camp · 300 km")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading),
                appearances: [.light, .dark, .largeText]
            )
        }
    }
}
