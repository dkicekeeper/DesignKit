//
//  FlowsScreen.swift
//  DesignKit Gallery
//
//  Components of 0.7.0: permission primer, onboarding pager, month calendar, activity
//  timeline, tag input, flow layout, hero symbol.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct FlowsScreen: View {
    @State private var showsPrimer = false
    @State private var showsOnboarding = false
    @State private var showsPageContainer = false
    @State private var range = CalendarRange()
    @State private var tripsByDay: [Date: [SampleTrip]] = [:]
    @State private var tags = ["Pike", "Early morning"]

    var body: some View {
        ShowcasePage(title: "Onboarding, Calendar & More") {
            primerSection
            onboardingSection
            calendarSection
            timelineSection
            tagSection
            flowSection
        }
        .sheet(isPresented: $showsPrimer) {
            PermissionPrimerView(
                systemImage: "bell.badge",
                title: "Don't miss replies",
                message: "We'll tell you when a friend answers or a place you saved gets new rules.",
                allowTitle: "Turn on",
                laterTitle: "Not now",
                onAllow: {
                    try? await Task.sleep(for: .seconds(1))
                    showsPrimer = false
                },
                onLater: { showsPrimer = false }
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            SampleOnboarding { showsOnboarding = false }
        }
        .fullScreenCover(isPresented: $showsPageContainer) {
            OnboardingPageContainer(
                progressStep: 1,
                title: "Main currency",
                subtitle: "Totals and charts are shown in it. You can change it later.",
                primaryButtonTitle: "Continue",
                onPrimaryTap: { showsPageContainer = false },
                onSkip: { showsPageContainer = false }
            ) {
                FlowLayout {
                    ForEach(["KZT", "USD", "EUR", "RUB"], id: \.self) {
                        BadgeView($0, color: AppColors.accent)
                    }
                }
            }
        }
        .onAppear {
            tripsByDay = range.itemsByDay(SampleTrip.samples) { trip, _ in trip.days }
        }
    }

    private var primerSection: some View {
        ShowcaseSection(title: "PermissionPrimerView", subtitle: "Before the system alert · .medium sheet") {
            HStack(spacing: AppSpacing.lg) {
                HeroSymbol(systemImage: "bell.badge", size: 72)
                HeroSymbol(systemImage: "location", size: 72, tint: AppColors.success)
                HeroSymbol(systemImage: "camera", size: 72, tint: AppColors.warning)
            }
            Button {
                showsPrimer = true
            } label: {
                Text("Show primer").frame(maxWidth: .infinity)
            }
            .secondaryButton()
        }
    }

    private var onboardingSection: some View {
        ShowcaseSection(title: "OnboardingPager · OnboardingPage", subtitle: "Pages, dots, Skip, per-page buttons") {
            Button {
                showsOnboarding = true
            } label: {
                Text("Show onboarding").frame(maxWidth: .infinity)
            }
            .secondaryButton()
            OnboardingStepIndicator(currentStep: 2, symbols: ["map", "tent.fill", "person.2.fill", "checkmark.seal.fill"])
            Button {
                showsPageContainer = true
            } label: {
                Text("Show OnboardingPageContainer").frame(maxWidth: .infinity)
            }
            .secondaryButton()
        }
    }

    private var calendarSection: some View {
        ShowcaseSection(title: "MonthCalendar", subtitle: "Tap the header for the month; swipe weeks / months") {
            MonthCalendar(range: range, itemsByDay: tripsByDay, itemName: \.name) { trip in
                Image(systemName: trip.symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.staticWhite)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(trip.color)
            } accessory: { period in
                let count = SampleTrip.samples.filter { trip in trip.days.contains { period.interval.contains($0) } }.count
                if count > 0 {
                    BadgeView("\(count) trips", color: AppColors.accent)
                }
            }
        }
    }

    private var timelineSection: some View {
        ShowcaseSection(title: "ActivityTimeline", subtitle: "Events on a line; dot or symbol markers") {
            ActivityTimeline(SampleEvent.samples) { event in
                TimelineMarker(systemImage: event.symbol, color: event.color)
            } content: { event in
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(event.title).font(AppTypography.bodyEmphasis)
                    Text(event.detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .cardContentPadding()
            .cardStyle()
            ActivityTimeline(Array(SampleEvent.samples.prefix(3))) { event in
                Text(event.title).font(AppTypography.body)
            }
        }
    }

    private var tagSection: some View {
        ShowcaseSection(title: "TagInput", subtitle: "Return or comma adds; tap × to remove") {
            TagInput("Add a tag", tags: $tags, suggestions: ["Pike", "Perch", "Night", "Kids", "4x4 only"])
                .cardContentPadding()
                .cardStyle()
        }
    }

    private var flowSection: some View {
        ShowcaseSection(title: "FlowLayout", subtitle: "Wraps like text") {
            FlowLayout {
                ForEach(["Lake", "Free camping", "Fire allowed", "No motorboats", "Pike", "Road: 4x4", "Toilets"], id: \.self) {
                    BadgeView($0, color: AppColors.accent)
                }
            }
        }
    }
}

// MARK: - Sample data

private struct SampleTrip: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let color: Color
    let days: [Date]

    static let samples: [SampleTrip] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        func days(_ from: Int, _ count: Int) -> [Date] {
            (0..<count).compactMap { calendar.date(byAdding: .day, value: from + $0, to: today) }
        }
        return [
            SampleTrip(name: "Big Almaty Lake", symbol: "tent.fill", color: .green, days: days(2, 2)),
            SampleTrip(name: "Charyn", symbol: "car.fill", color: .orange, days: days(9, 3)),
            SampleTrip(name: "Spawning ban", symbol: "nosign", color: .red, days: days(0, 14)),
            SampleTrip(name: "Kolsai", symbol: "figure.hiking", color: .blue, days: days(3, 1)),
            SampleTrip(name: "Kapchagay", symbol: "fish.fill", color: .teal, days: days(3, 1)),
        ]
    }()
}

private struct SampleEvent: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String?
    let color: Color?

    static let samples = [
        SampleEvent(title: "Left Almaty", detail: "06:10", symbol: "car.fill", color: nil),
        SampleEvent(title: "Check-in: Big Almaty Lake", detail: "08:45 · clear, 12 °C, calm", symbol: "mappin", color: .green),
        SampleEvent(title: "Caught a pike, 2.1 kg", detail: "10:20 · released", symbol: "fish.fill", color: .teal),
        SampleEvent(title: "Back home", detail: "19:30", symbol: nil, color: .gray),
    ]
}

private struct SampleOnboarding: View {
    enum Page: Hashable, CaseIterable { case welcome, places, location, done }

    let onFinish: () -> Void
    @State private var page: Page = .welcome

    var body: some View {
        OnboardingPager(
            pages: Page.allCases,
            selection: $page,
            canSkip: { $0 != .location && $0 != .done },
            onSkip: onFinish
        ) { page in
            switch page {
            case .welcome:
                OnboardingPage(systemImage: "figure.fishing", title: "Welcome",
                               message: "Places, rules and trips for anglers and hikers.")
            case .places:
                OnboardingPage(systemImage: "mappin.and.ellipse", title: "Places",
                               message: "Lakes, rivers and camps with reviews from people who were there.") {
                    FlowLayout {
                        ForEach(["Lake", "River", "Camp"], id: \.self) { BadgeView($0) }
                    }
                }
            case .location:
                OnboardingPage(systemImage: "location.circle", title: "Your location",
                               message: "To show what is near you. Only while you use the app.")
            case .done:
                OnboardingPage(systemImage: "checkmark.seal", title: "All set", message: "Have a good trip.")
            }
        } actions: { page in
            VStack(spacing: AppSpacing.sm) {
                Button {
                    next()
                } label: {
                    Text(page == .location ? "Allow" : page == .done ? "Start" : "Next")
                        .frame(maxWidth: .infinity)
                }
                .primaryButton()
                if page == .location {
                    Button { next() } label: { Text("Later").frame(maxWidth: .infinity) }
                        .secondaryButton()
                }
            }
        }
        .background(AppColors.bgCard.ignoresSafeArea())
    }

    private func next() {
        let all = Page.allCases
        guard let index = all.firstIndex(of: page), index + 1 < all.count else { return onFinish() }
        withAnimation { page = all[index + 1] }
    }
}

#Preview { NavigationStack { FlowsScreen() } }
