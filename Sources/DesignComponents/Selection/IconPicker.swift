//
//  IconPicker.swift
//  DesignKit
//
//  Picks an icon: an SF Symbol from the catalog (grouped, with a search across eleven
//  languages), or a brand logo from the host's catalog (DesignKitLogoCatalog) or any
//  domain typed in, or (8.5.0) the person's own picture cropped to a square, when the app keeps
//  pictures (DesignKitIconPhotos). A sheet with its own navigation bar; picking closes it. Ported from
//  Tenra's IconPickerView: the symbol catalog moved here with it (IconCatalog), the brand
//  list stays in the app behind the hook.
//

import SwiftUI
import PhotosUI
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
        case icons, logos, photo

        var title: String {
            switch self {
            case .icons: return String(localized: "iconPicker.iconsTab", defaultValue: "Icons")
            case .logos: return String(localized: "iconPicker.logosTab", defaultValue: "Logos")
            case .photo: return String(localized: "iconPicker.photoTab", defaultValue: "Photo")
            }
        }
    }

    /// - Parameter allowsLogos: The logos tab, when the app has set `DesignKitLogoCatalog`, and
    ///   the photo tab, when it has set `DesignKitIconPhotos.save` (8.5.0).
    public init(selection: Binding<IconSource?>, allowsLogos: Bool = true) {
        self._selection = selection
        self.allowsLogos = allowsLogos
    }

    private var showsLogos: Bool {
        allowsLogos && !DesignKitLogoCatalog.sections().isEmpty
    }

    private var showsPhoto: Bool {
        allowsLogos && DesignKitIconPhotos.save != nil
    }

    private var modes: [Mode] {
        Mode.allCases.filter { mode in
            switch mode {
            case .icons: return true
            case .logos: return showsLogos
            case .photo: return showsPhoto
            }
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .icons:
                    IconPickerSymbolsTab(selection: $selection)
                case .logos:
                    IconPickerLogosTab(selection: $selection)
                case .photo:
                    IconPickerPhotoTab(selection: $selection)
                }
            }
            // The soft edge under the tabs and the navigation bar, named (5.1.0): built with
            // Xcode 27 the style as it comes is hard (docs/gotchas.md).
            .scrollEdgeEffectStyle(.soft, for: .top)
            .safeAreaBar(edge: .top) {
                if modes.count > 1 {
                    SegmentedPicker(
                        title: "",
                        selection: $mode,
                        options: modes.map { (label: $0.title, value: $0) }
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
                        // A system bar's item: iOS draws its symbol (7.0.0, outside the Icon rule).
                        Image(systemName: "checkmark")
                    }
                    .dsButton()
                }
            }
        }
        .softScrollEdges()
        .onAppear {
            // A picture the person picked before opens on its tab.
            if let selection, showsPhoto, DesignKitIconPhotos.isPhoto(selection) { mode = .photo }
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
                                SectionHeader(section.title)
                                    .screenPadding()
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
                    Icon(
                        source: .sfSymbol(symbol),
                        style: .circle(
                            size: AppIconSize.Tile.md,
                            tint: .monochrome(isSelected ? AppColors.staticWhite : AppColors.Text.primary)
                        )
                    )
                    .frame(width: AppIconSize.Tile.xl, height: AppIconSize.Tile.xl)
                    .background(isSelected ? AppColors.accent : AppColors.Background.neutral1)
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
            SectionHeader(section.title)
                .screenPadding()

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 5),
                spacing: AppSpacing.lg
            ) {
                ForEach(section.entries) { entry in
                    let isSelected = selection == .brandService(entry.domain)
                    Button { pick(entry.domain) } label: {
                        Icon(source: .brandService(entry.domain), size: AppIconSize.Tile.md)
                            .frame(width: AppIconSize.Tile.xl, height: AppIconSize.Tile.xl)
                            .background(isSelected ? AppColors.pale(AppColors.accent) : AppColors.Background.neutral1)
                            .clipShape(.rect(cornerRadius: AppRadius.lg))
                            .selectionOutline(isSelected, cornerRadius: AppRadius.lg)
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
                        .foregroundStyle(AppColors.Text.primary)
                }
            }

            Section {
                ForEach(domains, id: \.self) { domain in
                    logoRow(domain: domain, label: domain)
                }
            } header: {
                Text(String(localized: "iconPicker.onlineSearch", defaultValue: "Online"))
                    .foregroundStyle(AppColors.Text.primary)
            } footer: {
                Text(String(localized: "iconPicker.brandDomainHint", defaultValue: "Enter brand domain (e.g. netflix.com)"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }

    private func logoRow(domain: String, label: String) -> some View {
        let isSelected = selection == .brandService(domain)
        return Button { pick(domain) } label: {
            HStack(spacing: AppSpacing.md) {
                Icon(source: .brandService(domain), size: AppIconSize.Tile.sm)

                Text(verbatim: label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.primary)

                Spacer()

                if isSelected {
                    Icon("checkmark.circle.fill", size: AppIconSize.md, tint: .monochrome(AppColors.accent))
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Photo

/// The person's own picture (8.5.0): pick one from the library, crop it to a square
/// (`SquareImageCropper`), the app keeps it (`DesignKitIconPhotos.save`).
private struct IconPickerPhotoTab: View {
    @Binding var selection: IconSource?
    @Environment(\.dismiss) private var dismiss
    @State private var item: PhotosPickerItem?
    @State private var picked: PickedPhoto?
    @State private var isWorking = false
    @State private var failed = false

    private struct PickedPhoto: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    private var currentPhoto: IconSource? {
        selection.flatMap { DesignKitIconPhotos.isPhoto($0) ? $0 : nil }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                if let currentPhoto {
                    Icon(source: currentPhoto, size: AppIconSize.Tile.xxl)
                        .frame(width: AppIconSize.Tile.xxl, height: AppIconSize.Tile.xxl)
                        .clipShape(.rect(cornerRadius: AppRadius.lg))
                } else {
                    Icon("photo.on.rectangle", size: AppIconSize.Tile.lg, tint: .monochrome(AppColors.Text.secondary))
                }
                Text(String(localized: "iconPicker.photoHint", defaultValue: "Your own logo from a picture, cropped to a square."))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.Text.secondary)
                    .multilineTextAlignment(.center)
                if failed {
                    Text(String(localized: "iconPicker.photoFailed", defaultValue: "The picture could not be used. Try another one."))
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.Status.negativeText)
                        .multilineTextAlignment(.center)
                }
                PhotosPicker(selection: $item, matching: .images) {
                    Group {
                        if isWorking {
                            ProgressView()
                        } else {
                            Text(String(localized: "iconPicker.choosePhoto", defaultValue: "Choose photo"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .dsButton(disabled: isWorking)
                .disabled(isWorking)
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.xxl)
        }
        .onChange(of: item) { _, newItem in
            guard let newItem else { return }
            load(newItem)
        }
        .fullScreenCover(item: $picked) { photo in
            SquareImageCropper(image: photo.image) { cropped in
                keep(cropped)
            } onCancel: {
                picked = nil
                item = nil
            }
        }
    }

    private func load(_ newItem: PhotosPickerItem) {
        isWorking = true
        failed = false
        Task {
            let data = try? await newItem.loadTransferable(type: Data.self)
            let image = await Task.detached(priority: .userInitiated) {
                data.flatMap { SquareImageCropper.downsampled($0) }
            }.value
            isWorking = false
            if let image {
                picked = PickedPhoto(image: image)
            } else {
                failed = true
                item = nil
            }
        }
    }

    private func keep(_ cropped: UIImage) {
        picked = nil
        item = nil
        isWorking = true
        Task {
            let source = await DesignKitIconPhotos.save?(cropped)
            isWorking = false
            if let source {
                HapticManager.selection()
                selection = source
                dismiss()
            } else {
                failed = true
            }
        }
    }
}
