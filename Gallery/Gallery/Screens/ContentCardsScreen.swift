//
//  ContentCardsScreen.swift
//  DesignKit Gallery
//
//  Cards with content: discussions, reviews, picture cards, advice, an empty section.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ContentCardsScreen: View {
    static let title = "Cards: Content"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        ThreadCardPage()
        ReviewCardPage()
        RatingSummaryPage()
        ThumbnailCardPage()
        RecommendationBoxPage()
        EmptyCardPage()
    }
}

private struct ThreadCardPage: View {
    @State private var showsPreview = true
    @State private var replies = 14
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ThreadCard",
            summary: "A discussion in a list: title, the start of its text, replies, author, last activity.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                ThreadCardSkeleton()
            } else {
                ThreadCard(
                    title: "Ice on Big Almaty Lake",
                    preview: showsPreview ? "Heading up on Saturday. Has anyone checked the ice thickness this week?" : nil,
                    repliesCount: replies,
                    author: "@aida",
                    lastActivity: Date().addingTimeInterval(-3_600)
                )
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Preview", isOn: $showsPreview)
            StepperControl("Replies", value: $replies, in: 0...999)
        }
    }
}

private struct ReviewCardPage: View {
    @State private var rating = 4.0
    @State private var showsVisit = true
    @State private var longText = true
    @State private var showsActions = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ReviewCard",
            summary: "A review: author, stars, time, a menu, when they were there, the text folded to four lines, photos, actions.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                ReviewCardSkeleton()
            } else {
                ReviewCard(
                    author: "Timur",
                    rating: rating,
                    date: Date().addingTimeInterval(-86_400 * 3),
                    subtitle: showsVisit ? "Visited in May 2026" : nil,
                    text: longText
                        ? "Quiet spot, clean water, a good road until the last two kilometres. Bring your own firewood: there is none left near the shore. Pike in the morning, perch in the afternoon. The ranger asks for a fee at the gate."
                        : "Quiet spot, clean water."
                ) {
                    Image(systemName: "ellipsis").foregroundStyle(AppColors.textTertiary)
                } actions: {
                    if showsActions {
                        ReactionButton(systemImage: "lightbulb", selectedSystemImage: "lightbulb.fill",
                                       count: 3, isSelected: false, title: "Helpful · 3", accessibilityLabel: "Helpful") {}
                    }
                }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Stars", value: $rating, in: 1...5, step: 1)
            ToggleControl("Visit line", isOn: $showsVisit)
            ToggleControl("Long text", isOn: $longText)
            ToggleControl("Actions", isOn: $showsActions)
        }
    }
}

private struct RatingSummaryPage: View {
    @State private var spread = 0
    @State private var state: SpecimenState = .content

    /// Reviews per star, one star first.
    private var distribution: [Int] {
        switch spread {
        case 1: [9, 6, 4, 2, 1]
        case 2: [0, 0, 0, 0, 0]
        default: [1, 0, 2, 9, 30]
        }
    }

    private var count: Int { distribution.reduce(0, +) }

    private var average: Double? {
        guard count > 0 else { return nil }
        let total = distribution.enumerated().reduce(0) { $0 + ($1.offset + 1) * $1.element }
        return Double(total) / Double(count)
    }

    var body: some View {
        ComponentPage(
            name: "RatingSummary",
            summary: "How an item is rated at a glance: the average, its stars and the review count, and a bar per star from five down.",
            since: "3.8.0",
            apps: [.dalada],
            canvas: .fill,
            notes: [
                "distribution counts the reviews per star, one star first; each bar is its count over count.",
                "countLabel is the app's own line (\"12 reviews\"), so its plurals stay in its strings.",
                "VoiceOver reads each bar as rating.bar (\"Rating 5: 30 reviews\").",
            ]
        ) {
            if state == .loading {
                RatingSummarySkeleton()
            } else {
                RatingSummary(average: average, count: count, distribution: distribution,
                              countLabel: "\(count) reviews")
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Reviews", selection: $spread, options: [("Mostly good", 0), ("Mostly bad", 1), ("None yet", 2)])
        }
    }
}

private struct ThumbnailCardPage: View {
    @State private var isVerified = true
    @State private var isSaved = true
    @State private var hasPhoto = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ThumbnailCard",
            summary: "A picture card for a carousel: the picture (a photo or a symbol on a pale tint), a seal, a bookmark, details.",
            since: "1.12.0",
            apps: [.dalada],
            notes: ["The app loads the photo and passes it in the picture slot; ThumbnailPlaceholder when there is none."]
        ) {
            if state == .loading {
                ThumbnailCardSkeleton()
            } else {
                ThumbnailCard(title: "Big Almaty Lake", isVerified: isVerified, isSaved: isSaved) {
                    if hasPhoto {
                        LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        ThumbnailPlaceholder(systemImage: "drop.fill")
                    }
                } details: {
                    Text("Lake · 28 km · ★ 4.6")
                }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Photo", isOn: $hasPhoto)
            ToggleControl("Verified", isOn: $isVerified)
            ToggleControl("Saved", isOn: $isSaved)
        }
    }
}

private struct RecommendationBoxPage: View {
    @State private var tone = 0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "RecommendationBox",
            summary: "A piece of advice in a pale box of its colour, with an icon.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            if state == .loading {
                RecommendationBoxSkeleton(lines: 2)
            } else {
                RecommendationBox(text: "You spent 18% less on dining this month. Keep the same pace to reach your goal.",
                                  color: [AppColors.success, AppColors.warning, AppColors.accent][tone],
                                  icon: ["lightbulb.fill", "exclamationmark.triangle.fill", "sparkles"][tone])
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Tone", selection: $tone, options: [("Good", 0), ("Warning", 1), ("Tip", 2)])
        }
    }
}

private struct EmptyCardPage: View {
    @State private var hasAction = true

    var body: some View {
        ComponentPage(
            name: "EmptyCard",
            summary: "A home section with nothing in it yet; a tap can add the first item.",
            apps: [.tenra],
            canvas: .fill
        ) {
            EmptyCard(sectionTitle: "Loans", emptyTitle: "No active loans", action: hasAction ? {} : nil)
        } controls: {
            ToggleControl("Action", isOn: $hasAction)
        }
    }
}

#Preview { NavigationStack { ContentCardsScreen() } }
