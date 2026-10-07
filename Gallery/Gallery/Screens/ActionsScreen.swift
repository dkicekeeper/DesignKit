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
            DSButtonPage()
            DSButtonStylePage()
            BounceStylePage()
            ReactionButtonPage()
            AmountVisibilityTogglePage()
            UniversalFilterButtonPage()
        }
    }
}

private struct DSButtonPage: View {
    @State private var title = "Save"
    @State private var showsIcon = true
    @State private var placement: DSButton.IconPlacement = .leading
    @State private var appearance: DSButton.Appearance = .primary
    @State private var role: DSButton.Role = .normal
    @State private var size: DSButton.Size = .large
    @State private var shape: DSButton.Shape = .automatic
    @State private var fullWidth = false
    @State private var loading = false
    @State private var disabled = false

    var body: some View {
        ComponentPage(
            name: "DSButton",
            summary: "The button of the design system: a title with an icon before, after or above it (or the icon alone), appearance × role × size, a loading state, full width or its own.",
            since: "2.0.0",
            apps: [.tenra, .dalada],
            notes: [
                "Loading keeps the button's width, shows a spinner and blocks taps: DSButton(\"Save\", isLoading: saving).",
                "Icon on top draws a tile (the actions under a detail screen's hero; EntityActionButton before 2.0). Give it the width: a row of them in an HStack.",
                "A delete-selected bar: DSButton(\"Delete (3)\", role: .destructive, shape: .capsule, fullWidth: true) (BulkDeleteButton before 2.0).",
                "A press plays a light haptic, a warning one for a destructive button.",
            ]
        ) {
            Group {
                if placement == .top {
                    HStack(spacing: AppSpacing.md) {
                        button
                        DSButton("Share", systemImage: "square.and.arrow.up", iconPlacement: .top,
                                 appearance: appearance) {}
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    button
                }
            }
            .frame(maxWidth: .infinity)
        } controls: {
            ChoiceControl("Icon", selection: $placement, options: [
                ("Leading", .leading), ("Trailing", .trailing), ("Top", .top), ("Only", .only),
            ])
            ToggleControl("Show icon", isOn: $showsIcon)
            ChoiceControl("Appearance", selection: $appearance, options: [
                ("Primary", .primary), ("Secondary", .secondary), ("Flat", .flat),
            ])
            ChoiceControl("Role", selection: $role, options: [
                ("Normal", .normal), ("Destructive", .destructive), ("Neutral", .neutral),
            ])
            ChoiceControl("Size", selection: $size, options: [
                ("Large", .large), ("Medium", .medium), ("Small", .small),
            ])
            ChoiceControl("Shape", selection: $shape, options: [
                ("Automatic", .automatic), ("Capsule", .capsule), ("Rounded", .roundedRectangle),
            ])
            ToggleControl("Full width", isOn: $fullWidth)
            ToggleControl("Loading", isOn: $loading)
            ToggleControl("Disabled", isOn: $disabled)
            TextControl("Title", text: $title)
        }
    }

    private var button: some View {
        DSButton(
            title,
            systemImage: showsIcon || placement == .only ? symbol : nil,
            iconPlacement: placement,
            appearance: appearance,
            role: role,
            size: size,
            shape: shape,
            fullWidth: fullWidth,
            isLoading: loading,
            isDisabled: disabled
        ) {
            loading = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                loading = false
            }
        }
    }

    private var symbol: String {
        switch placement {
        case .trailing: "arrow.right"
        case .only: "xmark"
        default: role == .destructive ? "trash" : "checkmark"
        }
    }
}

private struct DSButtonStylePage: View {
    @State private var appearance: DSButton.Appearance = .primary
    @State private var role: DSButton.Role = .normal
    @State private var size: DSButton.Size = .large
    @State private var disabled = false

    var body: some View {
        ComponentPage(
            name: ".dsButton",
            summary: "DSButton's style for a Button whose label you build yourself: appearance × role × size.",
            since: "2.0.0",
            apps: [.tenra, .dalada],
            notes: [
                "appButton(_:role:size:disabled:) before 2.0; primaryButton() = .dsButton(), secondaryButton() = .dsButton(.secondary).",
                "Prefer DSButton: it adds the icon placement, loading, full width and haptics.",
            ]
        ) {
            Button {} label: {
                VStack(spacing: AppSpacing.xxs) {
                    Text("Pay 12 500 ₸")
                    Text("Kaspi Gold").font(AppTypography.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .dsButton(appearance, role: role, size: size, disabled: disabled)
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
            ToggleControl("Disabled", isOn: $disabled)
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
                "For cards and rows (Tenra: account cards, transaction rows, Finances tiles). A button is a DSButton.",
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
