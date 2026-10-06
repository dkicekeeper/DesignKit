//
//  PatternsScreen.swift
//  DesignKit Gallery
//
//  Components added after the comparison with other design systems (0.6.0): skeletons,
//  loading button, step tracker, toggle row, avatar group, multi-select chips,
//  expandable text, banner with an action.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct PatternsScreen: View {
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var step = 1
    @State private var notifications = true
    @State private var sharesLocation = false
    @State private var types: Set<String> = ["Lake"]
    @State private var showsUndo = true

    var body: some View {
        ShowcasePage(title: "Loading, Steps & More") {
            skeletonSection
            loadingButtonSection
            stepsSection
            toggleSection
            avatarGroupSection
            chipsSection
            expandableSection
            bannerSection
            importProgressSection
        }
    }

    @ViewBuilder
    private var skeletonSection: some View {
        ShowcaseSection(title: "SkeletonRow", subtitle: "SkeletonView rows · shimmer stops under Reduce Motion") {
            VStack(spacing: 0) {
                SkeletonRow()
                SkeletonRow()
            }
            .cardContentPadding()
            .cardStyle()
        }

        ShowcaseSection(title: "SkeletonText", subtitle: "A line as tall as its text style · grows with Dynamic Type") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SkeletonText(AppTypography.h3, width: 180)
                SkeletonText(AppTypography.body, lines: 3)
                SkeletonText(AppTypography.caption, width: 120)
            }
            .cardContentPadding()
            .cardStyle()
        }

        ShowcaseSection(title: ".skeleton(isLoading:)", subtitle: "Any view as its own placeholder") {
            Toggle("Loading", isOn: $isLoading)
            HStack(spacing: AppSpacing.md) {
                AvatarView(name: "Ayan Seitkali")
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Big Almaty Lake").font(AppTypography.bodyEmphasis)
                    Text("12.4 km · 2 h 15 min").font(AppTypography.caption).foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }
            .skeleton(isLoading: isLoading)
            .cardContentPadding()
            .cardStyle()
        }
    }

    private var loadingButtonSection: some View {
        ShowcaseSection(title: "LoadingButtonLabel", subtitle: "Spinner in place of the title, same width") {
            Button {
                isSaving = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    isSaving = false
                }
            } label: {
                LoadingButtonLabel("Save", systemImage: "checkmark", isLoading: isSaving)
                    .frame(maxWidth: .infinity)
            }
            .primaryButton(disabled: isSaving)
        }
    }

    private var stepsSection: some View {
        ShowcaseSection(title: "StepTracker", subtitle: "Done · current · upcoming") {
            StepTracker(steps: ["Place", "Catch", "Photos", "Review"], current: step)
            Stepper("Step \(step + 1)", value: $step, in: 0...4)
        }
    }

    private var toggleSection: some View {
        ShowcaseSection(title: "ToggleSettingsRow", subtitle: "Settings row with a switch") {
            VStack(spacing: 0) {
                ToggleSettingsRow(icon: "bell", title: "Reminders", isOn: $notifications)
                Divider()
                ToggleSettingsRow(icon: "location", title: "Share location",
                                  hint: "Friends see your trip on the map", isOn: $sharesLocation)
            }
            .cardContentPadding()
            .cardStyle()
        }
    }

    private var avatarGroupSection: some View {
        ShowcaseSection(title: "AvatarGroup", subtitle: "Overlap + “+N”") {
            AvatarGroup(names: ["Ayan Seitkali", "Dana", "Marat Ospanov", "Aru", "Timur", "Saule"],
                        accessibilityLabel: "Six people")
            AvatarGroup(names: ["Ayan", "Dana"], size: 44)
        }
    }

    private var chipsSection: some View {
        ShowcaseSection(title: "ChipPicker (several)", subtitle: "Set selection, icons") {
            ChipPicker("Place type", options: ["Lake", "River", "Camp", "Viewpoint"], selection: $types,
                       systemImage: { ["Lake": "drop", "River": "water.waves", "Camp": "tent", "Viewpoint": "binoculars"][$0] }) { $0 }
        }
    }

    private var expandableSection: some View {
        ShowcaseSection(title: "ExpandableText", subtitle: "More / Less only when it overflows") {
            ExpandableText("Great spot for pike in the early morning. The road is rough after rain, a 4x4 is better. Camping is allowed on the north shore; bring your own firewood, the rangers check permits at the gate on weekends.")
            ExpandableText("Short note fits in one line.")
        }
    }

    private var importProgressSection: some View {
        ShowcaseSection(title: "ImportProgressSheet", subtitle: "Row-by-row import progress with Cancel (a sheet in Tenra)") {
            ImportProgressSheet(currentRow: 128, totalRows: 412, progress: 128.0 / 412.0, onCancel: {})
                .cardStyle()
        }
    }

    private var bannerSection: some View {
        ShowcaseSection(title: "MessageBanner (action)", subtitle: "Snackbar with Undo / Retry") {
            if showsUndo {
                MessageBanner(message: "Trip deleted", type: .info, actionTitle: "Undo") { showsUndo = false }
            } else {
                Button("Show again") { showsUndo = true }
            }
            MessageBanner(message: "Upload failed", type: .error, actionTitle: "Retry") {}
        }
    }
}

#Preview { NavigationStack { PatternsScreen() } }
