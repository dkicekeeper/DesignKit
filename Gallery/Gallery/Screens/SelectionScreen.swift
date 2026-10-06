//
//  SelectionScreen.swift
//  DesignKit Gallery
//
//  Selection: segments, chips, rating, the check circle, quick dates, the icon picker.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct SelectionScreen: View {
    var body: some View {
        ShowcasePage(title: "Selection") {
            SegmentedPickerViewPage()
            ChipPickerPage()
            RatingPage()
            SelectionIndicatorPage()
            DateButtonsViewPage()
            IconPickerPage()
        }
    }
}

private struct SegmentedPickerViewPage: View {
    @State private var selection = 0
    @State private var count = 3

    var body: some View {
        ComponentPage(
            name: "SegmentedPickerView",
            summary: "Two to four exclusive modes on Liquid Glass.",
            apps: [.tenra, .dalada],
            canvas: .fill
        ) {
            SegmentedPickerView(
                title: "Type",
                selection: $selection,
                options: Array([("Expense", 0), ("Income", 1), ("Transfer", 2), ("Debt", 3)].prefix(count))
                    .map { (label: $0.0, value: $0.1) }
            )
        } controls: {
            StepperControl("Options", value: $count, in: 2...4)
        }
    }
}

private struct ChipPickerPage: View {
    @State private var single: String? = "Cloudy"
    @State private var several: Set<String> = ["Lake", "Camp"]
    @State private var multiple = false
    @State private var showsIcons = true
    @State private var showsTitle = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "ChipPicker",
            summary: "Chips to pick one option, or several (a filter); with icons and a title.",
            since: "0.4.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                ChipPickerSkeleton(count: 4, showsTitle: showsTitle)
            } else if multiple {
                ChipPicker(showsTitle ? "Place" : nil, options: ["Lake", "River", "Camp", "Forest"],
                           selection: $several, systemImage: placeIcon) { $0 }
            } else {
                ChipPicker(showsTitle ? "Weather" : nil, options: ["Sunny", "Cloudy", "Rain", "Snow"],
                           selection: $single, systemImage: weatherIcon) { $0 }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Several", isOn: $multiple)
            ToggleControl("Icons", isOn: $showsIcons)
            ToggleControl("Title", isOn: $showsTitle)
        }
    }

    private var weatherIcon: ((String) -> String?)? {
        guard showsIcons else { return nil }
        return { ["Sunny": "sun.max", "Cloudy": "cloud", "Rain": "cloud.rain", "Snow": "snowflake"][$0] }
    }

    private var placeIcon: ((String) -> String?)? {
        guard showsIcons else { return nil }
        return { _ in "mappin" }
    }
}

private struct RatingPage: View {
    @State private var rating = 3
    @State private var shown = 3.5
    @State private var size = 32.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "RatingView · RatingPicker",
            summary: "Stars: RatingView shows a rating with half stars, RatingPicker is the tap-to-rate input.",
            since: "0.4.0",
            apps: [.dalada]
        ) {
            VStack(spacing: AppSpacing.lg) {
                if state == .loading {
                    RatingViewSkeleton(size: 14)
                } else {
                    RatingView(rating: shown, size: 14)
                }
                RatingPicker(rating: $rating, size: size)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Shown rating", value: $shown, in: 0...5, step: 0.25)
            SliderControl("Picker size", value: $size, in: 20...44, step: 2)
        }
    }
}

private struct SelectionIndicatorPage: View {
    @State private var isSelected = true
    @State private var tint = 0

    var body: some View {
        ComponentPage(
            name: "SelectionIndicator",
            summary: "The check circle of a selectable row: empty, or filled in its tint.",
            apps: [.tenra, .dalada]
        ) {
            SelectionIndicator(isSelected: isSelected,
                               tint: [AppColors.accent, AppColors.success, AppColors.textTertiary][tint])
                .onTapGesture { isSelected.toggle() }
        } controls: {
            ToggleControl("Selected", isOn: $isSelected)
            ChoiceControl("Tint", selection: $tint, options: [("Accent", 0), ("Success", 1), ("Muted", 2)])
        }
    }
}

private struct DateButtonsViewPage: View {
    @State private var date = Date()
    @State private var disabled = false

    var body: some View {
        ComponentPage(
            name: "DateButtonsView",
            summary: "Yesterday · Today · a past date: the date of a new transaction, above the keyboard.",
            apps: [.tenra],
            canvas: .fill,
            notes: ["No future dates. .dateButtonsSafeArea() pins it above the keyboard."]
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DateButtonsView(selectedDate: $date, isDisabled: disabled) { _ in }
                Text(date, format: .dateTime.day().month().year())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        } controls: {
            ToggleControl("Disabled", isOn: $disabled)
        }
    }
}

private struct IconPickerPage: View {
    @State private var icon: IconSource? = .sfSymbol("cart.fill")
    @State private var showsPicker = false
    @State private var allowsLogos = true

    var body: some View {
        ComponentPage(
            name: "IconPicker",
            summary: "A sheet to pick an SF Symbol (grouped, searchable in 11 languages) or a brand logo from the app's catalog.",
            since: "1.10.0",
            apps: [.tenra],
            notes: ["The logos tab shows when the app sets DesignKitLogoCatalog and allowsLogos is on."]
        ) {
            Button { showsPicker = true } label: {
                IconView(source: icon, style: .glassHero(size: AppIconSize.Tile.xl))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showsPicker) {
                IconPicker(selection: $icon, allowsLogos: allowsLogos)
            }
        } controls: {
            ToggleControl("Logos tab", isOn: $allowsLogos)
            ActionControl("Open the picker", systemImage: "square.grid.3x3") { showsPicker = true }
        }
    }
}

#Preview { NavigationStack { SelectionScreen() } }
