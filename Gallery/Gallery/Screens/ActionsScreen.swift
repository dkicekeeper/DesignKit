//
//  ActionsScreen.swift
//  DesignKit Gallery
//
//  Actions: buttons and the controls that run something, ready-made prompts.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct ActionsScreen: View {
    static let title = "Actions"

    var body: some View {
        ShowcasePage(title: Self.title) { Self.pages }
    }

    /// One page per component; the home screen counts them (ShowcaseCount).
    @ViewBuilder static var pages: some View {
        DSButtonPage()
        DSButtonStylePage()
        BounceStylePage()
        ReactionButtonPage()
        GlassActionMenuPage()
        AmountVisibilityTogglePage()
        UniversalFilterButtonPage()
        SuggestionChipsPage()
        VoiceOrbButtonPage()
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

private struct VoiceOrbButtonPage: View {
    @State private var level = 0.3
    @State private var followsLevel = true
    @State private var taps = 0

    var body: some View {
        ComponentPage(
            name: "VoiceOrbButton",
            summary: "The stop button while the voice records: VoiceWave's orb swelling with the voice, a glyph in the middle. Only the resting circle takes the tap.",
            since: "4.13.0",
            apps: [.tenra],
            canvas: .dark(minHeight: 220),
            notes: [
                "Read the level in a small view of its own, so its updates redraw the orb only.",
                "restingDiameter is the circle to anchor a hint (.spotlight) to.",
            ]
        ) {
            VStack(spacing: AppSpacing.sm) {
                VoiceOrbButton(level: followsLevel ? level : nil, accessibilityLabel: "Stop recording") {
                    taps += 1
                }
                Text(verbatim: "Taps: \(taps)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            .frame(maxWidth: .infinity)
        } controls: {
            ToggleControl("Follows the level", isOn: $followsLevel)
            SliderControl("Level", value: $level, in: 0...1)
        }
    }
}

#Preview { NavigationStack { ActionsScreen() } }

/// A Liquid Glass button that flows open into its actions (2.3.0).
private struct GlassActionMenuPage: View {
    @State private var direction: GlassActionMenu.Direction = .up
    @State private var last = "None yet"

    var body: some View {
        ComponentPage(
            name: "GlassActionMenu",
            summary: "A floating glass button that flows open into its actions and melts them back in, the way iOS 26's toolbars morph. For the add button of a screen.",
            since: "2.3.0",
            canvas: .tall(minHeight: 340),
            notes: [
                "The morph is the system's: each glass shape has a glassEffectID in one GlassEffectContainer. Nothing of ours runs per frame.",
                "An action runs, then the menu closes. VoiceOver reads each action's title; the button reads \"Actions\" / \"Close\" (keys menu.open, menu.close).",
                "Under Reduce Motion the actions fade in and out.",
            ]
        ) {
            ZStack(alignment: .bottomTrailing) {
                AuroraBackground(intensity: 0.6)
                    .clipShape(.rect(cornerRadius: AppRadius.xl))
                Text("Last action: \(last)")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(AppSpacing.lg)
                GlassActionMenu(items: [
                    .init("Scan a receipt", systemImage: "doc.viewfinder") { last = "Scan a receipt" },
                    .init("Transfer", systemImage: "arrow.left.arrow.right") { last = "Transfer" },
                    .init("Expense", systemImage: "minus") { last = "Expense" },
                ], direction: direction)
                .padding(AppSpacing.lg)
            }
            .frame(height: 320)
        } controls: {
            ChoiceControl("Direction", selection: $direction, options: [("Up", .up), ("Leading", .leading)])
        }
    }
}

private struct SuggestionChipsPage: View {
    @State private var wrap = false
    @State private var icon = true
    @State private var lastTapped = "—"
    @State private var state: SpecimenState = .content

    private let suggestions = ["Compare with September", "Where can I save?", "Show my subscriptions", "How are my budgets?"]

    var body: some View {
        ComponentPage(
            name: "SuggestionChips",
            summary: "Ready-made things to say: chips under an answer or on an empty chat, each one a prompt sent with a tap. Nothing stays selected.",
            since: "4.6.0",
            apps: [.tenra],
            canvas: .fill,
            notes: [
                "One scrolling row under an answer (inset: keeps the first chip off the edge); wrapped lines for the prompts of an empty chat.",
                "A choice that stays selected is a ChipPicker.",
            ]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if state == .loading {
                    SuggestionChipsSkeleton()
                } else {
                    SuggestionChips(suggestions, systemImage: icon ? "sparkles" : nil, layout: wrap ? .wrap : .scroll) {
                        lastTapped = $0
                    }
                }
                Text("Tapped: \(lastTapped)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Wrap", isOn: $wrap)
            ToggleControl("Icon", isOn: $icon)
        }
    }
}
