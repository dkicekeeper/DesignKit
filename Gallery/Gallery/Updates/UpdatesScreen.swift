//
//  UpdatesScreen.swift
//  DesignKit Gallery
//
//  Updates: every DesignKit release, newest first, from CHANGELOG.md (the same text as the
//  GitHub Release notes). A release opens on what it added, changed, deprecated, removed and
//  fixed, how to move an app to it, and links to the pages of the components it names. A
//  component page's "since" badge opens the release it came in.
//

import SwiftUI
import DesignTokens
import DesignComponents

struct UpdatesScreen: View {
    static let title = "Updates"

    @State private var query = ""
    private let changelog = Changelog.bundled

    var body: some View {
        Group {
            if let changelog {
                list(changelog)
            } else {
                ContentUnavailableView(
                    "No changelog",
                    systemImage: "doc.questionmark",
                    description: Text("This build has no CHANGELOG.md (Gallery/project.yml bundles it).")
                )
            }
        }
        .navigationTitle(Self.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func list(_ changelog: Changelog) -> some View {
        let releases = changelog.releases.filter {
            query.isEmpty || $0.searchText.localizedCaseInsensitiveContains(query)
        }
        return List {
            if query.isEmpty, case .paragraph(let intro)? = changelog.intro.first {
                Text(inlineMarkdown: intro)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
                    .listRowBackground(Color.clear)
            }
            ForEach(ReleaseLine.lines(of: releases)) { line in
                Section {
                    ForEach(line.releases) { release in
                        NavigationLink {
                            UpdateDetailScreen(release: release)
                        } label: {
                            ReleaseRow(release: release)
                        }
                    }
                } header: {
                    SectionHeader(line.title)
                }
            }
        }
        .searchable(text: $query, prompt: "A component or a change")
        .overlay {
            if releases.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}

/// The releases of one major version ("4.x"), newest first.
private struct ReleaseLine: Identifiable {
    let major: String
    let releases: [Changelog.Release]

    var id: String { major }
    var title: String { "\(major).x" }

    static func lines(of releases: [Changelog.Release]) -> [ReleaseLine] {
        var lines: [ReleaseLine] = []
        for release in releases {
            let major = String(release.version.prefix { $0 != "." })
            if lines.last?.major == major {
                lines[lines.count - 1] = ReleaseLine(major: major, releases: lines[lines.count - 1].releases + [release])
            } else {
                lines.append(ReleaseLine(major: major, releases: [release]))
            }
        }
        return lines
    }
}

/// A release in the list: its version, what it is about, its date, and what to look out for.
private struct ReleaseRow: View {
    let release: Changelog.Release

    var body: some View {
        ItemRow(
            release.version,
            badge: release.isMajor ? "Major" : nil,
            detail: release.summary.first.map(Self.plainText),
            meta: [MetaLine(facts)],
            leading: .symbol(release.kindSymbol, tint: release.kindTint)
        )
    }

    private var facts: [MetaItem] {
        var facts: [MetaItem] = [.text(release.dateText)]
        if release.section(.removed) != nil {
            facts.append(.label("Removals", systemImage: "minus.circle"))
        }
        if release.section(.changed) != nil {
            facts.append(.label("Visual changes", systemImage: "paintbrush"))
        }
        if release.section(.migration) != nil {
            facts.append(.label("Migration", systemImage: "arrow.right.circle"))
        }
        return facts
    }

    /// The summary without links and code marks: the list's two lines.
    private static func plainText(_ markdown: String) -> String {
        let withoutLinks = markdown.replacingOccurrences(
            of: #"\[[^\]]*\]\([^)]*\)"#, with: "", options: .regularExpression
        )
        return withoutLinks
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
    }
}

// MARK: - A release

/// One release: its summary, then each section, then the Gallery pages of the components it
/// names.
struct UpdateDetailScreen: View {
    let release: Changelog.Release

    @Environment(\.componentIndex) private var index

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                header
                ForEach(Array(release.sections.enumerated()), id: \.offset) { _, section in
                    ReleaseSectionView(section: section)
                }
                let links = index.links(for: release)
                if !links.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeader("In the Gallery", systemImage: "square.grid.2x2")
                        FlowLayout {
                            ForEach(links) { link in
                                NavigationLink {
                                    link.screen.destination(page: link.page)
                                } label: {
                                    Text(verbatim: link.page)
                                        .lineLimit(1)
                                        .filterChipStyle()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(release.version)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(verbatim: release.version)
                .font(AppTypography.h1)
                .foregroundStyle(AppColors.Text.primary)
            HStack(spacing: AppSpacing.sm) {
                Badge(release.kindTitle, systemImage: release.kindSymbol, color: release.kindTint)
                Text(verbatim: release.dateText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            if !release.summary.isEmpty {
                ArticleBody(release.summary.map { .paragraph($0) }, spacing: AppSpacing.sm)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }
}

/// A section of a release: its header, then its text and code in order.
private struct ReleaseSectionView: View {
    let section: Changelog.Section

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(section.title, systemImage: section.kind?.symbol ?? "circle", tint: section.kind?.tint)
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                switch run {
                case .text(let blocks):
                    ArticleBody(blocks, spacing: AppSpacing.sm)
                case .code(let code):
                    CodeBlock(code: code)
                }
            }
        }
    }

    private enum Run {
        case text([ArticleBody.Block])
        case code(String)
    }

    /// Text blocks run together into one `ArticleBody`; a code block stands between them.
    private var runs: [Run] {
        var runs: [Run] = []
        var text: [ArticleBody.Block] = []
        for block in section.blocks {
            switch block {
            case .paragraph(let paragraph):
                text.append(.paragraph(paragraph))
            case .bullets(let items):
                text.append(.bullets(items))
            case .code(let code):
                if !text.isEmpty { runs.append(.text(text)) }
                text = []
                runs.append(.code(code))
            }
        }
        if !text.isEmpty { runs.append(.text(text)) }
        return runs
    }
}

/// Swift (or a shell line) as it is: monospaced, scrolling sideways, selectable.
private struct CodeBlock: View {
    let code: String

    var body: some View {
        ScrollView(.horizontal) {
            Text(verbatim: code)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(AppColors.Text.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: true)
                .padding(AppSpacing.md)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.Background.neutral1, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

// MARK: - Labels

extension Changelog.Release {
    var kindTitle: String {
        isMajor ? "Major release" : isPatch ? "Patch release" : "Minor release"
    }

    var kindSymbol: String {
        isMajor ? "exclamationmark.triangle.fill" : isPatch ? "wrench.adjustable.fill" : "sparkles"
    }

    var kindTint: Color {
        isMajor ? AppColors.warning : isPatch ? AppColors.Status.neutral : AppColors.accent
    }

    /// "13 Oct 2026".
    var dateText: String {
        guard let day = Self.dayFormat.date(from: date) else { return date }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    private static let dayFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Changelog.Section.Kind {
    var symbol: String {
        switch self {
        case .added: "plus.circle.fill"
        case .changed: "paintbrush.fill"
        case .deprecated: "clock.badge.exclamationmark.fill"
        case .removed: "minus.circle.fill"
        case .fixed: "checkmark.seal.fill"
        case .migration: "arrow.right.circle.fill"
        case .tooling: "hammer.fill"
        }
    }

    var tint: Color {
        switch self {
        case .added: AppColors.success
        case .changed, .deprecated: AppColors.warning
        case .removed: AppColors.destructive
        case .fixed, .migration: AppColors.accent
        case .tooling: AppColors.Status.neutral
        }
    }
}

private extension Text {
    /// Inline Markdown (code spans, links, bold), as `ArticleBody` reads it.
    init(inlineMarkdown markdown: String) {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attributed = try? AttributedString(markdown: markdown, options: options) {
            self.init(attributed)
        } else {
            self.init(verbatim: markdown)
        }
    }
}
