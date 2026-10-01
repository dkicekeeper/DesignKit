//
//  DisplayScreen.swift
//  DesignKit Gallery
//
//  Badges, avatars, stats, ratings, chips, selection — the small display pieces
//  shared by Tenra and Dalada (0.4.0).
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct DisplayScreen: View {
    @State private var rating = 4
    @State private var weather: String? = "Sunny"
    @State private var checked: Set<String> = ["Tent"]

    var body: some View {
        ShowcasePage(title: "Badges, Stats & Rating") {
            badgesSection
            trendSection
            statsSection
            avatarSection
            ratingSection
            chipsSection
            selectionSection
        }
    }

    // MARK: Badges

    private var badgesSection: some View {
        ShowcaseSection(title: "BadgeView", subtitle: "Status, tag or counter · .tinted / .filled") {
            HStack(spacing: AppSpacing.sm) {
                BadgeView("Open", color: AppColors.success)
                BadgeView("Seasonal ban", color: AppColors.destructive)
                BadgeView("Pending", systemImage: "hourglass", color: AppColors.warning)
            }
            HStack(spacing: AppSpacing.sm) {
                BadgeView("3", systemImage: "person.badge.plus", color: AppColors.destructive, style: .filled)
                BadgeView("New", color: AppColors.accent, style: .filled)
            }
        }
    }

    private var trendSection: some View {
        ShowcaseSection(title: "TrendBadge", subtitle: ".pill · .inline · .changeIndicator; colour overridable") {
            HStack(spacing: AppSpacing.md) {
                TrendBadge(direction: .up, changePercent: 12.4)
                TrendBadge(direction: .down, changePercent: -5.1)
                TrendBadge(direction: .flat, changePercent: 0.8)
            }
            HStack(spacing: AppSpacing.lg) {
                TrendBadge(direction: .up, changePercent: 8, style: .inline, color: AppColors.destructive)
                TrendBadge(direction: .down, changePercent: -3.2, style: .changeIndicator)
            }
        }
    }

    // MARK: Stats

    private var statsSection: some View {
        ShowcaseSection(title: "StatTile", subtitle: "Caption + pre-formatted value") {
            HStack(spacing: AppSpacing.md) {
                StatTile(title: "Distance", value: "12.4 km")
                StatTile(title: "Moving", value: "2 h 15 min")
                StatTile(title: "Elevation", value: "+340 m")
            }
            .cardContentPadding()
            .cardStyle()
            HStack(spacing: AppSpacing.md) {
                StatTile(title: "Catches", value: "7", systemImage: "fish", valueColor: AppColors.accent)
                StatTile(title: "Trips", value: "23", systemImage: "figure.hiking")
            }
        }
    }

    // MARK: Avatars

    private var avatarSection: some View {
        ShowcaseSection(title: "AvatarView", subtitle: "Initials on a tint, or a photo") {
            HStack(spacing: AppSpacing.md) {
                AvatarView(name: "Ayan Seitkali")
                AvatarView(name: "dana")
                AvatarView(name: nil)
                AvatarView(name: "Marat Ospanov", size: 64)
                AvatarView(name: "Image", image: Image(systemName: "person.crop.circle.fill"), size: 48)
            }
        }
    }

    // MARK: Rating

    private var ratingSection: some View {
        ShowcaseSection(title: "RatingView · RatingPicker", subtitle: "Half stars from .25 · tap to rate") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach([4.8, 3.4, 2.0, 0.3], id: \.self) { value in
                    HStack {
                        RatingView(rating: value)
                        TokenLabel(name: value.formatted())
                    }
                }
            }
            RatingPicker(rating: $rating)
        }
    }

    // MARK: Chips

    private var chipsSection: some View {
        ShowcaseSection(title: "ChipPicker", subtitle: "One or none · tap again to clear") {
            ChipPicker("Weather", options: ["Sunny", "Cloudy", "Rain", "Wind", "Snow"], selection: $weather) { $0 }
        }
    }

    // MARK: Selection

    private var selectionSection: some View {
        ShowcaseSection(title: "SelectionIndicator · LinearProgressBar(value:)", subtitle: "Checklist rows · plain progress") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                LinearProgressBar(value: Double(checked.count) / 3, color: AppColors.success, height: 6)
                ForEach(["Tent", "Sleeping bag", "Headlamp"], id: \.self) { item in
                    Button {
                        if checked.contains(item) { checked.remove(item) } else { checked.insert(item) }
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            SelectionIndicator(isSelected: checked.contains(item), tint: AppColors.success)
                            Text(item)
                                .strikethrough(checked.contains(item))
                                .foregroundStyle(checked.contains(item) ? AppColors.textSecondary : AppColors.textPrimary)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview { NavigationStack { DisplayScreen() } }
