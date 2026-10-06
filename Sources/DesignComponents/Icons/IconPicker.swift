//
//  IconPicker.swift
//  DesignKit
//
//  Picks an icon: an SF Symbol from the catalog (grouped, with a search across eleven
//  languages), or a brand logo from the host's catalog (DesignKitLogoCatalog) or any
//  domain typed in. A sheet with its own navigation bar; picking closes it. Ported from
//  Tenra's IconPickerView: the symbol catalog moved here with it (IconCatalog), the brand
//  list stays in the app behind the hook.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An icon picker sheet.
///
/// ```swift
/// .sheet(isPresented: $showsPicker) {
///     IconPicker(selection: $icon)                     // symbols, and logos if the app has them
///     IconPicker(selection: $icon, allowsLogos: false) // symbols only (e.g. categories)
/// }
/// ```
public struct IconPicker: View {
    @Binding var selection: IconSource?
    let allowsLogos: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .icons

    enum Mode: Hashable, CaseIterable {
        case icons, logos

        var title: String {
            switch self {
            case .icons: return String(localized: "iconPicker.iconsTab", defaultValue: "Icons")
            case .logos: return String(localized: "iconPicker.logosTab", defaultValue: "Logos")
            }
        }
    }

    /// - Parameter allowsLogos: The logos tab, when the app has set `DesignKitLogoCatalog`.
    public init(selection: Binding<IconSource?>, allowsLogos: Bool = true) {
        self._selection = selection
        self.allowsLogos = allowsLogos
    }

    private var showsLogos: Bool {
        allowsLogos && !DesignKitLogoCatalog.sections().isEmpty
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .icons:
                    IconPickerSymbolsTab(selection: $selection)
                case .logos:
                    IconPickerLogosTab(selection: $selection)
                }
            }
            .safeAreaBar(edge: .top) {
                if showsLogos {
                    SegmentedPickerView(
                        title: "",
                        selection: $mode,
                        options: Mode.allCases.map { (label: $0.title, value: $0) }
                    )
                    .screenPadding()
                    .padding(.vertical, AppSpacing.md)
                }
            }
            .navigationTitle(String(localized: "iconPicker.title", defaultValue: "Select Image"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .primaryButton()
                }
            }
        }
    }
}

// MARK: - Symbols

/// Every catalog symbol by group, "Frequently Used" first, with the catalog's search.
private struct IconPickerSymbolsTab: View {
    @Binding var selection: IconSource?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var sections: [(title: String, symbols: [String])] {
        [(String(localized: "iconPicker.frequentlyUsed", defaultValue: "Frequently Used"), IconCatalog.frequentlyUsed)]
            + IconCatalog.groups.map { ($0.localizedTitle, $0.symbols) }
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if query.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.xxl) {
                        ForEach(sections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                                SectionHeaderView(section.title, style: .compact)
                                grid(section.symbols)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            } else {
                let results = IconCatalog.search(query, groupTitles: IconCatalog.groups.map(\.localizedTitle))
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ScrollView {
                        grid(results)
                            .padding(.vertical, AppSpacing.lg)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: String(localized: "iconPicker.searchIcons", defaultValue: "Search icons"))
    }

    private func grid(_ symbols: [String]) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 5),
            spacing: AppSpacing.lg
        ) {
            ForEach(symbols, id: \.self) { symbol in
                let isSelected = selection == .sfSymbol(symbol)
                Button {
                    HapticManager.selection()
                    selection = .sfSymbol(symbol)
                    dismiss()
                } label: {
                    IconView(
                        source: .sfSymbol(symbol),
                        style: .circle(
                            size: AppIconSize.xxxl,
                            tint: .monochrome(isSelected ? AppColors.staticWhite : AppColors.textPrimary)
                        )
                    )
                    .frame(width: AppIconSize.mega, height: AppIconSize.mega)
                    .background(isSelected ? AppColors.accent : AppColors.bgCard)
                    .clipShape(.rect(cornerRadius: AppRadius.lg))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: symbol))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .screenPadding()
    }
}

// MARK: - Logos

/// The host's logo sections; typing searches them and offers the typed domain online.
private struct IconPickerLogosTab: View {
    @Binding var selection: IconSource?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        Group {
            if query.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                        ForEach(DesignKitLogoCatalog.sections()) { section in
                            if !section.entries.isEmpty {
                                sectionView(section)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            } else {
                searchResults
            }
        }
        .searchable(text: $searchText, prompt: String(localized: "iconPicker.searchOnline", defaultValue: "Search brand logo..."))
    }

    private func pick(_ domain: String) {
        HapticManager.selection()
        selection = .brandService(domain)
        dismiss()
    }

    private func sectionView(_ section: DesignKitLogoCatalog.Section) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            SectionHeaderView(section.title, style: .compact)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 5),
                spacing: AppSpacing.lg
            ) {
                ForEach(section.entries) { entry in
                    let isSelected = selection == .brandService(entry.domain)
                    Button { pick(entry.domain) } label: {
                        IconView(source: .brandService(entry.domain), size: AppIconSize.xxxl)
                            .frame(width: AppIconSize.mega, height: AppIconSize.mega)
                            .background(isSelected ? AppColors.pale(AppColors.accent) : AppColors.bgCard)
                            .clipShape(.rect(cornerRadius: AppRadius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: entry.name))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .screenPadding()
        }
    }

    /// Suggestions from the catalog, then the typed text as a domain (or with each of
    /// `DesignKitLogoCatalog.domainSuffixes`).
    private var searchResults: some View {
        let suggestions = Array(DesignKitLogoCatalog.search(query).prefix(8))
        let domains = query.contains(".")
            ? [query]
            : DesignKitLogoCatalog.domainSuffixes.map { "\(query).\($0)" }
        return List {
            if !suggestions.isEmpty {
                Section {
                    ForEach(suggestions) { entry in
                        logoRow(domain: entry.domain, label: entry.name)
                    }
                } header: {
                    Text(String(localized: "iconPicker.suggestions", defaultValue: "Suggestions"))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

            Section {
                ForEach(domains, id: \.self) { domain in
                    logoRow(domain: domain, label: domain)
                }
            } header: {
                Text(String(localized: "iconPicker.onlineSearch", defaultValue: "Online"))
                    .foregroundStyle(AppColors.textPrimary)
            } footer: {
                Text(String(localized: "iconPicker.brandDomainHint", defaultValue: "Enter brand domain (e.g. netflix.com)"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func logoRow(domain: String, label: String) -> some View {
        let isSelected = selection == .brandService(domain)
        return Button { pick(domain) } label: {
            HStack(spacing: AppSpacing.md) {
                IconView(source: .brandService(domain), size: AppIconSize.xxl)

                Text(verbatim: label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
