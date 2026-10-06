//
//  CommunityScreen.swift
//  DesignKit Gallery
//
//  People, comments, discussions, reviews and reactions; achievements, checklists, counters,
//  streaks and picture cards (1.12.0, ported from Dalada).
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct CommunityScreen: View {
    @State private var respected = false
    @State private var respects = 12
    @State private var helpful = false
    @State private var packed: Set<String> = ["Tent"]

    private let now = Date()

    var body: some View {
        ShowcasePage(title: "Community & Progress") {
            ShowcaseSection(title: "PersonRow", subtitle: "Avatar, name, @username · a trailing slot") {
                VStack(spacing: AppSpacing.md) {
                    PersonRow(name: "Aida Nurlanovna", subtitle: "@aida") {
                        DisclosureChevron()
                    }
                    PersonRow(name: "Timur", subtitle: "@timur") {
                        Button("Accept") {}
                            .buttonStyle(.borderedProminent)
                    }
                    PersonRow(name: "@askar")
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "CommentRow", subtitle: "A comment · a reply with a quote and actions") {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    CommentRow(
                        author: "Aida",
                        date: now.addingTimeInterval(-600),
                        text: AttributedString("Was anyone on the lake this weekend? How was the ice?")
                    ) {
                        Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                    }
                    CommentRow(
                        author: "Timur",
                        date: now.addingTimeInterval(-120),
                        text: AttributedString("Thin near the north shore, fine in the bay."),
                        quote: MessageQuote(title: "Aida", text: "Was anyone on the lake this weekend? How was the ice?")
                    ) {
                        Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                    } actions: {
                        respectButton
                        Button("Reply") {}.buttonStyle(.borderless)
                        Text("edited").foregroundStyle(AppColors.textTertiary)
                    }
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "ThreadCard", subtitle: "Title, preview, replies, author, last activity") {
                ThreadCard(
                    title: "Ice on Big Almaty Lake",
                    preview: "Heading up on Saturday. Has anyone checked the ice thickness this week?",
                    repliesCount: 14,
                    author: "@aida",
                    lastActivity: now.addingTimeInterval(-3_600)
                )
            }

            ShowcaseSection(title: "ReviewCard", subtitle: "Stars, visit, folded text, actions") {
                ReviewCard(
                    author: "Timur",
                    rating: 4,
                    date: now.addingTimeInterval(-86_400 * 3),
                    subtitle: "Visited in May 2026",
                    text: "Quiet spot, clean water, a good road until the last two kilometres. Bring "
                        + "your own firewood: there is none left near the shore. Pike in the morning."
                ) {
                    Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                } actions: {
                    ReactionButton(
                        systemImage: "lightbulb", selectedSystemImage: "lightbulb.fill",
                        count: helpful ? 4 : 3, isSelected: helpful,
                        title: "Helpful · \(helpful ? 4 : 3)", accessibilityLabel: "Helpful"
                    ) { helpful.toggle() }
                    Label("2", systemImage: "bubble.left")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            ShowcaseSection(title: "ReactionButton", subtitle: "Tap to toggle · own post: the count only") {
                HStack(spacing: AppSpacing.xl) {
                    respectButton
                    ReactionButton(
                        systemImage: "hand.thumbsup", selectedSystemImage: "hand.thumbsup.fill",
                        count: 7, isSelected: false, accessibilityLabel: "7 respects", action: nil
                    )
                }
            }

            ShowcaseSection(title: "AchievementTile", subtitle: "Earned in colour · not yet: grey with progress") {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    AchievementTile(title: "First trip", systemImage: "figure.hiking", color: .green,
                                    isEarned: true, medalSize: 64)
                    AchievementTile(title: "Early bird", systemImage: "sunrise.fill", color: .orange,
                                    isEarned: true, medalSize: 64)
                    AchievementTile(title: "10 trips", systemImage: "map.fill", color: .blue,
                                    isEarned: false, medalSize: 64, progressText: "7 of 10")
                }
            }

            ShowcaseSection(title: "AchievementProgressRow", subtitle: "The closest one, with a bar") {
                AchievementProgressRow(label: "Up next:", title: "10 trips", progressText: "7 of 10",
                                       fraction: 0.7, systemImage: "map.fill", color: .blue)
                    .cardContentPadding()
                    .cardStyle()
            }

            ShowcaseSection(title: "ChecklistRow", subtitle: "Tap to tick off · a mark on the right") {
                VStack(spacing: AppSpacing.md) {
                    ForEach(["Tent", "Sleeping bag", "Headlamp"], id: \.self) { item in
                        ChecklistRow(
                            item,
                            isChecked: packed.contains(item),
                            accessorySystemImage: item == "Tent" ? "backpack" : nil,
                            accessoryLabel: item == "Tent" ? "From gear" : nil
                        ) {
                            if packed.contains(item) { packed.remove(item) } else { packed.insert(item) }
                        }
                    }
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "ChecklistSummaryRow", subtitle: "Progress · complete · empty") {
                VStack(spacing: AppSpacing.md) {
                    ChecklistSummaryRow(title: "Weekend at the lake", subtitle: "Sat, 12 Oct", checked: 12, total: 20)
                    ChecklistSummaryRow(title: "Fishing kit", checked: 8, total: 8)
                    ChecklistSummaryRow(title: "Winter trip", checked: 0, total: 0)
                }
                .cardContentPadding()
                .cardStyle()
            }

            ShowcaseSection(title: "StatsStrip", subtitle: "Counters side by side") {
                StatsStrip(items: [
                    .init(value: "42", title: "days outdoors"),
                    .init(value: "17", title: "trips"),
                    .init(value: "384", title: "km"),
                    .init(value: "9", title: "catches"),
                ])
            }

            ShowcaseSection(title: "StreakCard", subtitle: "Running · stopped") {
                VStack(spacing: AppSpacing.md) {
                    StreakCard(systemImage: "flame.fill", isActive: true, title: "3 weeks in a row",
                               subtitle: "Head out by Sunday to keep it", value: "5", valueCaption: "best")
                    StreakCard(systemImage: "flame.fill", isActive: false, title: "No streak",
                               subtitle: "One trip this week starts it", value: "5", valueCaption: "best")
                }
            }

            ShowcaseSection(title: "ThumbnailCard", subtitle: "Carousel card: picture, seal, bookmark, details") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ThumbnailCard(title: "Big Almaty Lake", isVerified: true, isSaved: true) {
                            ThumbnailPlaceholder(systemImage: "drop.fill")
                        } details: {
                            Text("Lake · 28 km · ★ 4.6")
                        }
                        ThumbnailCard(title: "Kolsai camp") {
                            ThumbnailPlaceholder(systemImage: "tent.fill", tint: .orange)
                        } details: {
                            Text("Camp · 300 km")
                        }
                    }
                }
            }

            ShowcaseSection(title: "ThumbnailRow", subtitle: "The same as a list row") {
                ThumbnailRow(title: "Big Almaty Lake", isVerified: true, isSaved: true) {
                    ThumbnailPlaceholder(systemImage: "drop.fill")
                } details: {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Lake · 28 km · ★ 4.6")
                        Text("Last report 2 days ago")
                    }
                }
                .cardContentPadding()
                .cardStyle()
            }
        }
    }

    private var respectButton: some View {
        ReactionButton(
            systemImage: "hand.thumbsup", selectedSystemImage: "hand.thumbsup.fill",
            count: respects, isSelected: respected, accessibilityLabel: "\(respects) respects"
        ) {
            respected.toggle()
            respects += respected ? 1 : -1
        }
    }
}

#Preview { NavigationStack { CommunityScreen() } }
