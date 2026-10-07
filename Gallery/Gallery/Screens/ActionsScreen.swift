//
//  ActionsScreen.swift
//  DesignKit Gallery
//
//  Actions: buttons and the controls that run something.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ActionsScreen: View {
    var body: some View {
        ShowcasePage(title: "Actions") {
            AppButtonPage()
            BounceStylePage()
            LoadingButtonLabelPage()
            EntityActionButtonPage()
            BulkDeleteButtonPage()
            ReactionButtonPage()
            AmountVisibilityTogglePage()
            UniversalFilterButtonPage()
        }
    }
}

private struct AppButtonPage: View {
    @State private var appearance: AppButtonAppearance = .primary
    @State private var role: AppButtonRole = .normal
    @State private var size: AppButtonSize = .large
    @State private var fullWidth = true
    @State private var disabled = false
    @State private var loading = false
    @State private var title = "Save"

    var body: some View {
        ComponentPage(
            name: "appButton",
            summary: "The button of the design system: appearance × role × size. primaryButton() and secondaryButton() are its shorthands.",
            since: "1.7.0",
            apps: [.tenra, .dalada],
            notes: [
                ".primaryButton() = .appButton(), .secondaryButton() = .appButton(.secondary).",
                "Destructive: .appButton(role: .destructive), never .primaryButton() (its accent tint overrides the role).",
                "While an action runs: LoadingButtonLabel in the label and disabled: isLoading.",
            ]
        ) {
            Button {} label: {
                LoadingButtonLabel(title, systemImage: nil, isLoading: loading)
                    .frame(maxWidth: fullWidth ? .infinity : nil)
            }
            .appButton(appearance, role: role, size: size, disabled: disabled || loading)
        } controls: {
            ChoiceControl("Appearance", selection: $appearance, options: [
                ("Primary", .primary), ("Secondary", .secondary), ("Flat", .flat),
            ])
            ChoiceControl("Role", selection: $role, options: [
                ("Normal", .normal), ("Destructive", .destructive), ("Neutral", .neutral),
            ])
            ChoiceControl("Size", selection: $size, options: [
                ("Large", .large), ("Medium", .medium), ("Small", .small),
            ])
            ToggleControl("Full width", isOn: $fullWidth)
            ToggleControl("Disabled", isOn: $disabled)
            ToggleControl("Loading", isOn: $loading)
            TextControl("Title", text: $title)
        }
    }
}

private struct BounceStylePage: View {
    @State private var taps = 0

    var body: some View {
        ComponentPage(
            name: ".bounce",
            summary: "Press feedback for something tappable that is not a button: it shrinks to 96% and darkens a little. Press and hold the card.",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "For cards and rows (Tenra: account cards, transaction rows, Finances tiles). A button uses appButton.",
            ]
        ) {
            Button { taps += 1 } label: {
                BalanceCard(iconSource: .sfSymbol("creditcard.fill"), title: "Kaspi Gold",
                            amount: 1_250_000, currency: "KZT")
            }
            .buttonStyle(.bounce)
        } controls: {
            HStack {
                Text("Taps").font(AppTypography.bodySmall)
                Spacer()
                Text("\(taps)").font(AppTypography.bodySmall).monospacedDigit()
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

private struct LoadingButtonLabelPage: View {
    @State private var isLoading = false
    @State private var showsIcon = true

    var body: some View {
        ComponentPage(
            name: "LoadingButtonLabel",
            summary: "A button's label that turns into a spinner while its action runs, keeping the button's width.",
            since: "0.6.0",
            notes: ["Pass disabled: isLoading to the button so it cannot be tapped twice."]
        ) {
            Button {
                isLoading = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    isLoading = false
                }
            } label: {
                LoadingButtonLabel("Save", systemImage: showsIcon ? "checkmark" : nil, isLoading: isLoading)
                    .frame(maxWidth: .infinity)
            }
            .appButton(disabled: isLoading)
        } controls: {
            ToggleControl("Loading", isOn: $isLoading)
            ToggleControl("Icon", isOn: $showsIcon)
        }
    }
}

private struct EntityActionButtonPage: View {
    @State private var destructive = false
    @State private var showsIcon = true

    var body: some View {
        ComponentPage(
            name: "EntityActionButton",
            summary: "An action under a detail screen's hero: edit, archive, delete.",
            apps: [.tenra]
        ) {
            EntityActionButton(
                title: destructive ? "Delete" : "Edit",
                systemImage: showsIcon ? (destructive ? "trash" : "pencil") : nil,
                role: destructive ? .destructive : nil
            ) {}
        } controls: {
            ToggleControl("Destructive", isOn: $destructive)
            ToggleControl("Icon", isOn: $showsIcon)
        }
    }
}

private struct BulkDeleteButtonPage: View {
    @State private var count = 3

    var body: some View {
        ComponentPage(
            name: "BulkDeleteButton",
            summary: "Deletes the items selected in a list's selection mode; shows how many.",
            apps: [.tenra]
        ) {
            BulkDeleteButton(count: count) {}
        } controls: {
            StepperControl("Selected", value: $count, in: 0...99)
        }
    }
}

private struct ReactionButtonPage: View {
    @State private var count = 12
    @State private var isSelected = false
    @State private var interactive = true
    @State private var kind = 0

    var body: some View {
        ComponentPage(
            name: "ReactionButton",
            summary: "A reaction under a post: symbol and count, filled in the accent once the user reacted. Without an action (own post, guest) only the count.",
            since: "1.12.0",
            apps: [.dalada]
        ) {
            ReactionButton(
                systemImage: kind == 0 ? "hand.thumbsup" : "lightbulb",
                selectedSystemImage: kind == 0 ? "hand.thumbsup.fill" : "lightbulb.fill",
                count: count,
                isSelected: isSelected,
                title: kind == 1 ? "Helpful · \(count)" : nil,
                accessibilityLabel: "\(count)",
                action: interactive ? {
                    isSelected.toggle()
                    count += isSelected ? 1 : -1
                } : nil
            )
        } controls: {
            ChoiceControl("Kind", selection: $kind, options: [("Respect", 0), ("Helpful", 1)])
            StepperControl("Count", value: $count, in: 0...999)
            ToggleControl("Reacted", isOn: $isSelected)
            ToggleControl("Can react", isOn: $interactive)
        }
    }
}

private struct AmountVisibilityTogglePage: View {
    @State private var isHidden = false

    var body: some View {
        ComponentPage(
            name: "AmountVisibilityToggle",
            summary: "The eye that hides every amount below it (.amountsHidden). Tenra puts it in the Home toolbar.",
            since: "1.7.0",
            apps: [.tenra]
        ) {
            HStack(spacing: AppSpacing.md) {
                FormattedAmountText(amount: 1_284_500, currency: "KZT", fontSize: AppTypography.h2,
                                    fontWeight: .bold, color: AppColors.textPrimary)
                AmountVisibilityToggle(isHidden: $isHidden)
            }
            .amountsHidden(isHidden)
        } controls: {
            ToggleControl("Hidden", isOn: $isHidden)
        }
    }
}

private struct UniversalFilterButtonPage: View {
    @State private var isSelected = false
    @State private var showsChevron = true
    @State private var asMenu = false
    @State private var period = "Month"

    var body: some View {
        ComponentPage(
            name: "UniversalFilterButton",
            summary: "A filter chip on Liquid Glass: a tap or a menu, with an optional icon and chevron.",
            apps: [.tenra]
        ) {
            if asMenu {
                UniversalFilterButton(title: period, isSelected: isSelected, showChevron: showsChevron) {
                    Image(systemName: "calendar")
                } menuContent: {
                    ForEach(["Week", "Month", "Year"], id: \.self) { value in
                        Button(value) { period = value }
                    }
                }
            } else {
                UniversalFilterButton(title: "All accounts", isSelected: isSelected, showChevron: showsChevron,
                                      onTap: { isSelected.toggle() }) {
                    Image(systemName: "creditcard")
                }
            }
        } controls: {
            ToggleControl("Selected", isOn: $isSelected)
            ToggleControl("Chevron", isOn: $showsChevron)
            ToggleControl("Menu", isOn: $asMenu)
        }
    }
}

#Preview { NavigationStack { ActionsScreen() } }
