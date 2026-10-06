//
//  Showcase.swift
//  DesignKit Gallery
//
//  The pieces every Gallery screen is built from (docs/gallery-structure.md):
//  - `ShowcasePage`: a screen whose sections are pages, with chips on top and a swipe;
//  - `ComponentPage`: one component — header, preview on a canvas, controls, notes;
//  - controls: state, toggles, choices, sliders, steppers, text;
//  - `ShowcaseSection` and `TokenLabel` for the foundation screens.
//

import SwiftUI
import DesignTokens
import DesignComponents

// MARK: - Paged screen

/// A showcase screen. Every page in `content` (a `ComponentPage` or a `ShowcaseSection`) is a
/// page of its own: chips under the navigation bar name the pages and switch between them, and
/// a horizontal swipe pages too. A screen with a single page is one scrolling page without chips.
struct ShowcasePage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    @State private var selection = 0

    var body: some View {
        Group(subviews: content) { pages in
            if pages.count > 1 {
                TabView(selection: $selection) {
                    ForEach(pages.indices, id: \.self) { index in
                        page(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .safeAreaBar(edge: .top) {
                    ShowcaseChips(
                        titles: pages.indices.map { index in
                            let title = pages[index].containerValues.showcaseTitle
                            return title.isEmpty ? "\(index + 1)" : title
                        },
                        selection: $selection
                    )
                }
            } else {
                page(ForEach(pages) { $0 })
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func page(_ content: some View) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                content
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

/// The page switcher of a `ShowcasePage`: one chip per page, the current one selected and
/// scrolled into view.
private struct ShowcaseChips: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(titles.indices, id: \.self) { index in
                        Button {
                            withAnimation(AppAnimation.contentSpring) { selection = index }
                        } label: {
                            Text(titles[index])
                                .lineLimit(1)
                                .filterChipStyle(isSelected: index == selection)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(index == selection ? .isSelected : [])
                        .id(index)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xs)
            }
            .scrollIndicators(.hidden)
            .onChange(of: selection) { _, index in
                withAnimation(AppAnimation.contentSpring) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
        }
    }
}

extension ContainerValues {
    /// The chip title of a showcase page.
    @Entry var showcaseTitle: String = ""
}

// MARK: - Component page

/// Which app uses a component, shown in its page header.
enum ConsumerApp: String {
    case tenra = "Tenra"
    case dalada = "Dalada"
}

/// How a preview sits on its canvas.
enum CanvasStyle {
    /// Centred, padded, on the light canvas.
    case standard
    /// Leading-aligned and full width (rows, cards, lists).
    case fill
    /// Edge to edge, no padding (carousels, backgrounds).
    case bleed
    /// A dark canvas, at least `minHeight` tall (glows, waves, effects).
    case dark(minHeight: CGFloat)
    /// The light canvas, at least `minHeight` tall (motion, things that move).
    case tall(minHeight: CGFloat)
}

/// One component on a page of its own:
///
/// 1. **Header** — the name, what it is for, since which version, which apps use it; a rule
///    under it keeps it apart from the component.
/// 2. **Preview** — the component on a canvas, in the current controls; the canvas can be
///    switched to light or dark.
/// 3. **Controls** — its state (default, loading = its skeleton, empty, error, disabled) and
///    its parameters.
/// 4. **Notes** — a rule or two from docs/design-system.md.
struct ComponentPage<Preview: View, Controls: View>: View {
    let name: String
    let summary: String
    var since: String? = nil
    var apps: [ConsumerApp] = []
    var canvas: CanvasStyle = .standard
    var notes: [String] = []
    @ViewBuilder var preview: Preview
    @ViewBuilder var controls: Controls

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            ComponentHeader(name: name, summary: summary, since: since, apps: apps)
            PreviewCanvas(style: canvas) { preview }
            if Controls.self != EmptyView.self {
                PanelSection("Controls") {
                    ControlStack { controls }
                }
            }
            if !notes.isEmpty {
                PanelSection("Usage") {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(notes, id: \.self) { note in
                            Label {
                                Text(note)
                                    .font(AppTypography.bodySmall)
                                    .foregroundStyle(AppColors.textPrimary)
                            } icon: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.lg)
                    .formCardStyle(radius: AppRadius.lg)
                }
            }
        }
        .containerValue(\.showcaseTitle, name)
    }
}

extension ComponentPage where Controls == EmptyView {
    init(
        name: String,
        summary: String,
        since: String? = nil,
        apps: [ConsumerApp] = [],
        canvas: CanvasStyle = .standard,
        notes: [String] = [],
        @ViewBuilder preview: () -> Preview
    ) {
        self.name = name
        self.summary = summary
        self.since = since
        self.apps = apps
        self.canvas = canvas
        self.notes = notes
        self.preview = preview()
        self.controls = EmptyView()
    }
}

/// The page header: the name in h2, the purpose under it, version and app badges, a rule.
private struct ComponentHeader: View {
    let name: String
    let summary: String
    let since: String?
    let apps: [ConsumerApp]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(name)
                .font(AppTypography.h2)
                .foregroundStyle(AppColors.textPrimary)
                .textSelection(.enabled)
            Text(summary)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if since != nil || !apps.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    if let since {
                        BadgeView("since \(since)", color: AppColors.Status.neutral)
                    }
                    ForEach(apps, id: \.self) { app in
                        BadgeView(app.rawValue, color: AppColors.accent)
                    }
                }
            }
            Divider()
                .padding(.top, AppSpacing.sm)
        }
    }
}

/// A caption over a panel ("PREVIEW", "CONTROLS").
private struct PanelSection<Content: View>: View {
    let title: String
    let trailing: AnyView?
    @ViewBuilder var content: Content

    init(_ title: String, trailing: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(title.uppercased())
                    .font(AppTypography.caption2.weight(.semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .tracking(0.6)
                Spacer(minLength: 0)
                if let trailing { trailing }
            }
            content
        }
    }
}

/// The light (or dark) surface a preview sits on, with a thin border, so the component never
/// blends into the page around it. A switch on top renders it in light or dark.
private struct PreviewCanvas<Content: View>: View {
    let style: CanvasStyle
    @ViewBuilder var content: Content

    @State private var scheme: ColorScheme?
    @Environment(\.colorScheme) private var systemScheme

    private var effectiveScheme: ColorScheme { scheme ?? systemScheme }

    var body: some View {
        PanelSection("Preview", trailing: AnyView(schemeSwitch)) {
            canvas
                .environment(\.colorScheme, effectiveScheme)
        }
    }

    private var schemeSwitch: some View {
        Picker("Appearance", selection: $scheme) {
            Image(systemName: "circle.lefthalf.filled").tag(ColorScheme?.none)
            Image(systemName: "sun.max").tag(ColorScheme?.some(.light))
            Image(systemName: "moon").tag(ColorScheme?.some(.dark))
        }
        .pickerStyle(.segmented)
        .frame(width: 132)
        .controlSize(.small)
    }

    @ViewBuilder
    private var canvas: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        switch style {
        case .standard:
            content
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .background(canvasFill, in: shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        case .fill:
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .background(canvasFill, in: shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        case .bleed:
            content
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(canvasFill, in: shape)
                .clipShape(shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        case .dark(let minHeight):
            content
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(Color.black, in: shape)
                .clipShape(shape)
                .environment(\.colorScheme, .dark)
        case .tall(let minHeight):
            content
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .padding(AppSpacing.lg)
                .background(canvasFill, in: shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        }
    }

    private var canvasFill: Color {
        effectiveScheme == .dark ? Color(white: 0.11) : Color(white: 0.95)
    }
}

// MARK: - Controls

/// The rows of a controls panel, divided by hairlines, on a form card.
private struct ControlStack<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Group(subviews: content) { rows in
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    rows[index]
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    if index < rows.count - 1 {
                        Divider().padding(.leading, AppSpacing.lg)
                    }
                }
            }
            .formCardStyle(radius: AppRadius.lg)
        }
    }
}

/// The states a component page can show. A page offers the ones its component has.
enum SpecimenState: String, CaseIterable, Identifiable {
    case content = "Default"
    case loading = "Loading"
    case empty = "Empty"
    case error = "Error"
    case disabled = "Disabled"

    var id: String { rawValue }
}

/// The first control of most pages: which state the component is in. "Loading" shows the
/// component's skeleton.
struct StateControl: View {
    @Binding var state: SpecimenState
    var states: [SpecimenState] = [.content, .loading]

    var body: some View {
        ChoiceControl("State", selection: $state, options: states.map { ($0.rawValue, $0) })
    }
}

/// A switch.
struct ToggleControl: View {
    let title: String
    @Binding var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(AppTypography.bodySmall)
            .tint(AppColors.accent)
    }
}

/// One of a few options: segments when there are up to four short ones, a menu otherwise.
struct ChoiceControl<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(String, Value)]

    init(_ title: String, selection: Binding<Value>, options: [(String, Value)]) {
        self.title = title
        self._selection = selection
        self.options = options
    }

    private var usesSegments: Bool {
        options.count <= 4 && options.map { $0.0.count }.reduce(0, +) <= 30
    }

    var body: some View {
        if usesSegments {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textPrimary)
                Picker(title, selection: $selection) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index].0).tag(options[index].1)
                    }
                }
                .pickerStyle(.segmented)
            }
        } else {
            HStack {
                Text(title)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer(minLength: AppSpacing.sm)
                Picker(title, selection: $selection) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index].0).tag(options[index].1)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.accent)
            }
        }
    }
}

/// A number on a slider, its value on the right.
struct SliderControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var format: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...2))) }

    init(
        _ title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        format: @escaping (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...2))) }
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(format(value))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
            }
            if let step {
                Slider(value: $value, in: range, step: step)
                    .tint(AppColors.accent)
            } else {
                Slider(value: $value, in: range)
                    .tint(AppColors.accent)
            }
        }
    }
}

/// A whole number with − and +.
struct StepperControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    init(_ title: String, value: Binding<Int>, in range: ClosedRange<Int>) {
        self.title = title
        self._value = value
        self.range = range
    }

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(value)")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}

/// A line of text.
struct TextControl: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textPrimary)
            TextField(title, text: $text)
                .font(AppTypography.bodySmall)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

/// A button in the controls panel ("Replay", "Show").
struct ActionControl: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String = "play.fill", action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.bodySmall.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .tint(AppColors.accent)
    }
}

// MARK: - Foundation screens

/// A labelled group of specimens (the foundation screens: colours, type, spacing).
struct ShowcaseSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Divider().padding(.top, AppSpacing.xs)
            }
            content
        }
        .containerValue(\.showcaseTitle, title)
    }
}

/// Caption used to annotate a token's name/value.
struct TokenLabel: View {
    let name: String
    var value: String? = nil
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(name)
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            if let value {
                Text(value)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
