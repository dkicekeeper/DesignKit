//
//  Showcase.swift
//  DesignKit Gallery
//
//  The pieces every Gallery screen is built from (docs/gallery-structure.md):
//  - `ShowcasePage`: a screen whose sections are pages, with chips on top and a swipe;
//  - `ComponentPage`: one component — header, preview on a canvas and its bar, cases, controls,
//    code, parameters, notes;
//  - controls: state, toggles, choices, sliders, steppers, text;
//  - `ShowcaseSection` and `TokenLabel` for the foundation screens.
//

import SwiftUI
import UIKit
import DesignTokens
import DesignSupport
import DesignComponents

// MARK: - Paged screen

/// A showcase screen. Every page in `content` (a `ComponentPage` or a `ShowcaseSection`) is a
/// page of its own: chips under the navigation bar name the pages and switch between them, and
/// a horizontal swipe pages too. A screen with a single page is one scrolling page without chips.
/// A link to a component (the Updates screen's) opens the screen on its page
/// (`showcaseInitialPage`).
struct ShowcasePage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    @State private var selection = 0
    @State private var openedInitialPage = false
    @Environment(\.showcaseInitialPage) private var initialPage

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
                    // The selected chip's tint is the accent (8.22.3: the app switches on a page).
                    .galleryRefreshes()
                }
                .onAppear {
                    guard !openedInitialPage, let initialPage else { return }
                    openedInitialPage = true
                    if let index = pages.indices.first(where: {
                        pages[$0].containerValues.showcaseTitle == initialPage
                    }) {
                        selection = index
                    }
                }
            } else {
                page(ForEach(pages) { $0 })
            }
        }
        // The soft edge under the chips and the navigation bar, named: built with Xcode 27 the
        // style as it comes is hard (docs/gotchas.md).
        .scrollEdgeEffectStyle(.soft, for: .top)
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
            // A wide Mac window or an iPad in landscape: the page keeps to a column (8.22.3).
            .readableWidth(AppLayout.wideWidth)
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

extension EnvironmentValues {
    /// The context a page's canvas opens in (8.21.0): `.screen`; a snapshot sets another.
    @Entry var showcaseCanvasContext: CanvasContext = .screen
}

extension ContainerValues {
    /// The chip title of a showcase page.
    @Entry var showcaseTitle: String = ""
    /// Set by `ComponentPage`: the page shows one component, which the home screen counts.
    @Entry var showcaseIsComponent: Bool = false
    /// The component's purpose, which the home screen's search reads (8.21.0).
    @Entry var showcaseSummary: String = ""
}

/// How many components a screen's pages show: the number on the home screen's row, counted
/// from the pages themselves (each `ComponentPage`), so it never goes stale.
struct ShowcaseCount<Pages: View>: View {
    @ViewBuilder var pages: Pages

    var body: some View {
        Group(subviews: pages) { subviews in
            Text("\(subviews.filter { $0.containerValues.showcaseIsComponent }.count)")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Component page

/// Which app uses a component, shown in its page header.
enum ConsumerApp: String {
    case tenra = "Tenra"
    case dalada = "Dalada"
    /// The third consumer (8.12.0), a PlayStation trophy tracker; its badges since 8.17.1.
    case platina = "Platina"
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

/// What a preview lies on (8.21.0): the page, a card of the app's surfaces, or a hero's colour.
/// The same component reads differently on each (a knockout ring on a grey card, white pieces on
/// colour), so the canvas shows any of them.
enum CanvasContext: String, CaseIterable, Identifiable {
    case screen = "Screen"
    case card = "Card"
    case colour = "On colour"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .screen: "rectangle"
        case .card: "rectangle.inset.filled"
        case .colour: "paintbrush.fill"
        }
    }
}

/// One component on a page of its own:
///
/// 1. **Header** — the name, what it is for, its styles (the values of its `style:`
///    parameter), since which version, which apps use it; a rule under it keeps it apart from
///    the component.
/// 2. **Preview** — the component on a canvas, in the current controls. The canvas switches to
///    light or dark and lies on the page, a card or a colour (8.21.0); its bar (8.22.3) switches
///    the app (Tenra, Dalada, Platina), the text size and the direction, and on a wide screen the
///    width.
/// 3. **Cases** (8.22.3) — ready data from life, one tap each.
/// 4. **Controls** — its state (default, loading = its skeleton, empty, error, disabled) and
///    its parameters.
/// 5. **Code** (8.22.3) — the call as the controls set it, to copy.
/// 6. **Parameters** (8.22.3) — its initialisers from docs/components.json.
/// 7. **Notes** — a rule or two from docs/design-system.md.
/// 8. **Do / Don't** (8.9.0) — how to use it and how not to, side by side; docs/components.md
///    carries them too (`.github/scripts/components_reference.py`).
///
/// On a wide screen (an iPad, a Mac window) the cases and controls stand beside the canvas.
struct ComponentPage<Preview: View, Controls: View>: View {
    let name: String
    let summary: String
    var since: String? = nil
    var apps: [ConsumerApp] = []
    var canvas: CanvasStyle = .standard
    var notes: [String] = []
    /// The values of the component's `style:` parameter, in the API's own names; none when it
    /// has no such parameter.
    var styles: [String] = []
    /// What to do with it, a line each (8.9.0).
    var dos: [String] = []
    /// What not to do with it, a line each (8.9.0).
    var donts: [String] = []
    /// The Swift that draws the preview as the controls set it (8.22.3), built by the page from
    /// its state with `SwiftCode`; nil hides the panel.
    var code: String? = nil
    /// Ready data from life, one tap each (8.22.3): a long name, zero, a huge amount, no photo.
    var cases: [SpecimenCase] = []
    @ViewBuilder var preview: Preview
    @ViewBuilder var controls: Controls

    var body: some View {
        ComponentPageBody(page: self)
            .containerValue(\.showcaseTitle, name)
            .containerValue(\.showcaseIsComponent, true)
            .containerValue(\.showcaseSummary, summary)
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
        styles: [String] = [],
        dos: [String] = [],
        donts: [String] = [],
        code: String? = nil,
        @ViewBuilder preview: () -> Preview
    ) {
        self.name = name
        self.summary = summary
        self.since = since
        self.apps = apps
        self.canvas = canvas
        self.notes = notes
        self.styles = styles
        self.dos = dos
        self.donts = donts
        self.code = code
        self.preview = preview()
        self.controls = EmptyView()
    }
}

/// A component page as it draws. The canvas's light or dark and its context, and the page's
/// width, live here, above the part that draws again when the preset changes
/// (`.galleryRefreshes()`), so switching the app keeps them.
private struct ComponentPageBody<Preview: View, Controls: View>: View {
    let page: ComponentPage<Preview, Controls>

    @State private var scheme: ColorScheme?
    @State private var context: CanvasContext?
    @State private var width: CGFloat = 0

    /// Wide enough for the cases and controls beside the canvas: the canvas at least
    /// `AppLayout.mainColumnMinWidth`, the gap, the controls `AppLayout.sideColumnWidth`.
    private static var wideWidth: CGFloat {
        AppLayout.mainColumnMinWidth + AppSpacing.xxl + AppLayout.sideColumnWidth
    }

    private var hasSide: Bool { Controls.self != EmptyView.self || !page.cases.isEmpty }

    var body: some View {
        Group {
            if hasSide && width >= Self.wideWidth {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    HStack(alignment: .top, spacing: AppSpacing.xxl) {
                        VStack(alignment: .leading, spacing: AppSpacing.xl) {
                            canvas
                            code
                            parameters
                            usage
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: AppSpacing.xl) {
                            cases
                            controls
                        }
                        .frame(width: AppLayout.sideColumnWidth, alignment: .leading)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    canvas
                    cases
                    controls
                    code
                    parameters
                    usage
                }
            }
        }
        .galleryRefreshes()
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
    }

    private var header: some View {
        ComponentHeader(name: page.name, summary: page.summary, styles: page.styles,
                        since: page.since, apps: page.apps)
    }

    private var canvas: some View {
        PreviewCanvas(style: page.canvas, scheme: $scheme, context: $context) { page.preview }
    }

    @ViewBuilder private var cases: some View {
        if !page.cases.isEmpty {
            PanelSection("Cases") {
                CaseChips(cases: page.cases)
            }
        }
    }

    @ViewBuilder private var controls: some View {
        if Controls.self != EmptyView.self {
            PanelSection("Controls") {
                ControlStack { page.controls }
            }
        }
    }

    @ViewBuilder private var code: some View {
        if let code = page.code {
            CodePanel(code: code)
        }
    }

    @ViewBuilder private var parameters: some View {
        let declarations = ComponentReference.bundled?.declarations(forPage: page.name) ?? []
        if !declarations.isEmpty {
            ParametersPanel(declarations: declarations)
        }
    }

    @ViewBuilder private var usage: some View {
        if !page.notes.isEmpty {
            PanelSection("Usage") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(page.notes, id: \.self) { note in
                        Label {
                            Text(note)
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.Text.primary)
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
        if !page.dos.isEmpty || !page.donts.isEmpty {
            PanelSection("Do and don't") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    GuidanceList(lines: page.dos, isDo: true)
                    GuidanceList(lines: page.donts, isDo: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .formCardStyle(radius: AppRadius.lg)
            }
        }
    }
}

/// The lines of "Do" (a green check each) or "Don't" (a red cross), under their word.
private struct GuidanceList: View {
    let lines: [String]
    let isDo: Bool

    var body: some View {
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(isDo ? "Do" : "Don't")
                    .font(AppTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(isDo ? AppColors.Status.positiveText : AppColors.Status.negativeText)
                ForEach(lines, id: \.self) { line in
                    Label {
                        Text(line)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.Text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: isDo ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isDo ? AppColors.Status.positiveText : AppColors.Status.negativeText)
                    }
                }
            }
        }
    }
}

/// The page header: the name in h2, the purpose under it, its styles, version and app badges,
/// a rule.
private struct ComponentHeader: View {
    let name: String
    let summary: String
    let styles: [String]
    let since: String?
    let apps: [ConsumerApp]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(name)
                .font(AppTypography.h2)
                .foregroundStyle(AppColors.Text.primary)
                .textSelection(.enabled)
            Text(summary)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !styles.isEmpty {
                Label {
                    Text(verbatim: "\(styles.count) styles: \(styles.joined(separator: " · "))")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "square.stack.3d.up")
                        .foregroundStyle(AppColors.accent)
                }
            }
            if since != nil || !apps.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    if let since {
                        // The release notes of the version it came in (CHANGELOG.md).
                        if let release = Changelog.bundled?.release(mentionedIn: since) {
                            NavigationLink {
                                UpdateDetailScreen(release: release)
                            } label: {
                                Badge("since \(since)", systemImage: "doc.text", color: AppColors.Status.neutral)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the release notes")
                        } else {
                            Badge("since \(since)", color: AppColors.Status.neutral)
                        }
                    }
                    ForEach(apps, id: \.self) { app in
                        Badge(app.rawValue, color: AppColors.accent)
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
                    .foregroundStyle(AppColors.Text.tertiary)
                    .tracking(0.6)
                Spacer(minLength: 0)
                if let trailing { trailing }
            }
            content
        }
    }
}

/// The light (or dark) surface a preview sits on, with a thin border, so the component never
/// blends into the page around it. A switch on top renders it in light or dark; the bar under it
/// sets the app, the text size, the direction and the width (8.22.3).
private struct PreviewCanvas<Content: View>: View {
    let style: CanvasStyle
    @Binding var scheme: ColorScheme?
    @Binding var context: CanvasContext?
    @ViewBuilder var content: Content

    /// The canvas's own width: a choice of widths shows only where it is wider than a phone.
    @State private var available: CGFloat = 0
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.showcaseCanvasContext) private var initialContext

    /// Wider than this, the bar offers the phone's width and a screen's column.
    private static var widthChoiceMinimum: CGFloat { 500 }

    private var effectiveScheme: ColorScheme { scheme ?? systemScheme }
    private var effectiveContext: CanvasContext { context ?? initialContext }
    private var offersWidths: Bool { available > Self.widthChoiceMinimum }

    var body: some View {
        PanelSection("Preview", trailing: AnyView(HStack(spacing: AppSpacing.sm) { contextMenu; schemeSwitch })) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                canvas
                    .environment(\.colorScheme, effectiveScheme)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { newWidth in
                        available = newWidth
                    }
                CanvasBar(offersWidths: offersWidths)
            }
        }
    }

    /// Where the preview lies (8.21.0): the page, a card, a hero's colour.
    private var contextMenu: some View {
        Menu {
            Picker("Context", selection: Binding(get: { effectiveContext }, set: { context = $0 })) {
                ForEach(CanvasContext.allCases) { context in
                    Label(context.rawValue, systemImage: context.systemImage).tag(context)
                }
            }
        } label: {
            Image(systemName: effectiveContext.systemImage)
                .frame(width: 28, height: 28)
        }
        .accessibilityLabel("Context: \(effectiveContext.rawValue)")
    }

    /// The component in its context: as it is, in a card of the current surfaces, or on the
    /// accent with the hero's white tone.
    @ViewBuilder private var contextual: some View {
        switch effectiveContext {
        case .screen:
            content
        case .card:
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardContentPadding()
                .cardStyle()
        case .colour:
            content
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .background(AppColors.accent, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .environment(\.heroTone, .onColor)
        }
    }

    /// The component in its context, at the bar's text size, direction and width. Nothing chosen,
    /// it follows the device, as the page does.
    private var placed: some View {
        let settings = GallerySettings.shared
        return contextual
            .modifier(CanvasTextSize(size: settings.textSize))
            .modifier(CanvasDirection(isRightToLeft: settings.isRightToLeft))
            .frame(maxWidth: offersWidths ? settings.canvasWidth.maxWidth : nil)
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
            placed
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .background(canvasFill, in: shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        case .fill:
            placed
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .background(canvasFill, in: shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        case .bleed:
            placed
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(canvasFill, in: shape)
                .clipShape(shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        case .dark(let minHeight):
            placed
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(Color.black, in: shape)
                .clipShape(shape)
                .environment(\.colorScheme, .dark)
        case .tall(let minHeight):
            placed
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .padding(AppSpacing.lg)
                .background(canvasFill, in: shape)
                .overlay(shape.strokeBorder(AppColors.Border.normal, lineWidth: 0.5))
        }
    }

    /// Grey, so glass shows; the page itself (white, black) under grey cards (8.12.0), which
    /// would melt into the grey.
    private var canvasFill: Color {
        if surface == .fill { return effectiveScheme == .dark ? .black : .white }
        return effectiveScheme == .dark ? Color(white: 0.11) : Color(white: 0.95)
    }
}

/// The canvas's text size when one is chosen; otherwise the device's.
private struct CanvasTextSize: ViewModifier {
    let size: DynamicTypeSize?

    func body(content: Content) -> some View {
        if let size {
            content.dynamicTypeSize(size)
        } else {
            content
        }
    }
}

/// Right to left when chosen; otherwise the direction around it.
private struct CanvasDirection: ViewModifier {
    let isRightToLeft: Bool

    func body(content: Content) -> some View {
        if isRightToLeft {
            content.environment(\.layoutDirection, .rightToLeft)
        } else {
            content
        }
    }
}

/// The bar under a canvas (8.22.3): the app whose accent and surfaces the Gallery shows (the
/// home screen's preset, one tap), the text size, the direction and, on a wide screen, the
/// width. The size, direction and width hold for every page until they are changed back.
private struct CanvasBar: View {
    let offersWidths: Bool

    var body: some View {
        let settings = GallerySettings.shared
        HStack(spacing: AppSpacing.sm) {
            Picker("App", selection: Binding(get: { settings.theme }, set: { settings.select($0) })) {
                ForEach(themes(settings)) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
            Spacer(minLength: 0)
            Menu {
                Picker("Text size", selection: Binding(get: { settings.textSize }, set: { settings.textSize = $0 })) {
                    Text("Device").tag(DynamicTypeSize?.none)
                    ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                        Text(size.galleryLabel).tag(DynamicTypeSize?.some(size))
                    }
                }
            } label: {
                BarChip(systemImage: "textformat.size", text: settings.textSize?.galleryLabel)
            }
            .accessibilityLabel("Text size")
            .accessibilityValue(settings.textSize?.galleryLabel ?? "Device")
            Button {
                settings.isRightToLeft.toggle()
            } label: {
                BarChip(systemImage: "arrow.left.arrow.right", text: settings.isRightToLeft ? "RTL" : nil)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Right to left")
            .accessibilityValue(settings.isRightToLeft ? "On" : "Off")
            if offersWidths {
                Menu {
                    Picker("Width", selection: Binding(get: { settings.canvasWidth }, set: { settings.canvasWidth = $0 })) {
                        ForEach(CanvasWidth.allCases) { width in
                            Label(width.rawValue, systemImage: width.systemImage).tag(width)
                        }
                    }
                } label: {
                    BarChip(systemImage: settings.canvasWidth.systemImage,
                            text: settings.canvasWidth == .full ? nil : settings.canvasWidth.rawValue)
                }
                .accessibilityLabel("Width")
                .accessibilityValue(settings.canvasWidth.rawValue)
            }
        }
        .controlSize(.small)
    }

    /// The three apps, and the custom preset while it is the one shown.
    private func themes(_ settings: GallerySettings) -> [GalleryTheme] {
        settings.theme == .custom ? GalleryTheme.apps + [.custom] : GalleryTheme.apps
    }
}

/// A button of the canvas's bar: its symbol, and what it is set to when that is not the default.
private struct BarChip: View {
    let systemImage: String
    let text: String?

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: systemImage)
            if let text {
                Text(verbatim: text)
                    .lineLimit(1)
            }
        }
        .font(AppTypography.caption.weight(.semibold))
        .foregroundStyle(AppColors.Text.action)
        .padding(.horizontal, AppSpacing.sm)
        .frame(minWidth: 32, minHeight: 28)
        .background(text == nil ? Color.clear : AppColors.pale(AppColors.accent), in: Capsule())
        .contentShape(Capsule())
    }
}

/// The page's cases (8.22.3): a chip each, which sets the page's data in one tap.
private struct CaseChips: View {
    let cases: [SpecimenCase]

    var body: some View {
        FlowLayout(spacing: AppSpacing.sm) {
            ForEach(cases) { specimen in
                Button {
                    withAnimation(AppAnimation.contentSpring) { specimen.apply() }
                } label: {
                    Text(specimen.title)
                        .lineLimit(1)
                        .filterChipStyle()
                }
                .buttonStyle(.plain)
                .accessibilityHint("Sets the component's data")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The call as the controls set it (8.22.3), with a button that copies it.
private struct CodePanel: View {
    let code: String

    @State private var copied = false

    var body: some View {
        PanelSection("Code", trailing: AnyView(copyButton)) {
            CodeBlock(code: code)
        }
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = code
            AccessibilityAnnouncer.announce("Copied")
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.Text.action)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }
}

/// The component's initialisers (8.22.3), from docs/components.json: a parameter a line, its
/// label, type and default. Folded until opened, so the page stays short.
private struct ParametersPanel: View {
    let declarations: [ComponentReference.Declaration]

    @State private var isExpanded = false

    private var signatureCount: Int { declarations.map(\.initialisers.count).reduce(0, +) }

    var body: some View {
        PanelSection("Parameters") {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(AppAnimation.contentSpring) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text(verbatim: signatureCount == 1 ? "1 initialiser" : "\(signatureCount) initialisers")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.Text.primary)
                        Spacer(minLength: AppSpacing.sm)
                        Image(systemName: "chevron.down")
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppColors.Text.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(AppSpacing.lg)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                if isExpanded {
                    Divider().padding(.leading, AppSpacing.lg)
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        ForEach(declarations, id: \.name) { declaration in
                            DeclarationView(declaration: declaration)
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .formCardStyle(radius: AppRadius.lg)
        }
    }
}

/// One type of the reference: its name, what it is, each initialiser's parameters, its skeleton.
private struct DeclarationView: View {
    let declaration: ComponentReference.Declaration

    private static let mono = Font.system(.footnote, design: .monospaced)

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(verbatim: declaration.name)
                .font(AppTypography.bodySmall.weight(.semibold))
                .foregroundStyle(AppColors.Text.primary)
            if let doc = declaration.doc, !doc.isEmpty {
                Text(verbatim: doc)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(declaration.initialisers, id: \.self) { signature in
                let parameters = ComponentReference.parameters(of: signature)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    if parameters.isEmpty {
                        Text(verbatim: signature)
                            .font(Self.mono)
                            .foregroundStyle(AppColors.Text.secondary)
                    }
                    ForEach(parameters.indices, id: \.self) { index in
                        line(parameters[index])
                    }
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.Background.container, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .textSelection(.enabled)
            }
            if let skeleton = declaration.skeleton {
                Label {
                    Text(verbatim: "Loading: \(skeleton)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.Text.secondary)
                } icon: {
                    Image(systemName: "rectangle.dashed")
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
        }
    }

    /// `label name: Type = default`, the label in bold and the default in grey.
    private func line(_ parameter: ComponentReference.Parameter) -> some View {
        let names = [parameter.label, parameter.name].compactMap { $0 }.joined(separator: " ")
        let label = Text(verbatim: names).bold().foregroundStyle(AppColors.Text.primary)
        let type = Text(verbatim: ": \(parameter.type)").foregroundStyle(AppColors.Text.secondary)
        let value = Text(verbatim: parameter.defaultValue.map { " = \($0)" } ?? "")
            .foregroundStyle(AppColors.Text.tertiary)
        return Text("\(label)\(type)\(value)")
            .font(Self.mono)
            .fixedSize(horizontal: false, vertical: true)
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

/// Ready data for a component page (8.22.3), one tap each: "Long name", "Zero", "No photo". `apply`
/// sets the page's own state, which the preview, the controls and the code all read.
struct SpecimenCase: Identifiable {
    let title: String
    let apply: () -> Void

    var id: String { title }

    init(_ title: String, apply: @escaping () -> Void) {
        self.title = title
        self.apply = apply
    }
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
                    .foregroundStyle(AppColors.Text.primary)
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
                    .foregroundStyle(AppColors.Text.primary)
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
                    .foregroundStyle(AppColors.Text.primary)
                Spacer()
                Text(format(value))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
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
                    .foregroundStyle(AppColors.Text.primary)
                Spacer()
                Text("\(value)")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
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
                .foregroundStyle(AppColors.Text.primary)
            TextField(title, text: $text)
                .font(AppTypography.bodySmall)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppColors.Text.secondary)
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
                    .foregroundStyle(AppColors.Text.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                Divider().padding(.top, AppSpacing.xs)
            }
            content
        }
        // A foundation's swatches read the accent (8.22.3: the app switches with a page open).
        .galleryRefreshes()
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
                .foregroundStyle(AppColors.Text.primary)
            if let value {
                Text(value)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }
}
