//
//  Changelog.swift
//  DesignKit Gallery
//
//  CHANGELOG.md, bundled with the Gallery (Gallery/project.yml), read into releases, their
//  sections and the blocks of each, for the Updates screen. The format is the one
//  `.github/scripts/changelog.py check` holds the file to in CI: a release is
//  `## X.Y.Z - YYYY-MM-DD`, a summary, then `### Added`, `### Changed`, …; a section has
//  paragraphs, `- ` lists (a line indented by two spaces goes on with the item) and fenced code.
//  Also compiled into GallerySnapshotTests (ChangelogTests).
//

import Foundation

struct Changelog: Equatable, Sendable {
    /// What comes before the first release: what the file is, how a release is laid out.
    var intro: [Block]
    /// Newest first, as in the file.
    var releases: [Release]

    struct Release: Identifiable, Hashable, Sendable {
        var version: String
        /// `YYYY-MM-DD`.
        var date: String
        /// The paragraphs under the heading: what the release is about, its PR and guide links.
        var summary: [String]
        var sections: [Section]

        var id: String { version }

        /// The section of one kind, if the release has it.
        func section(_ kind: Section.Kind) -> Section? {
            sections.first { $0.kind == kind }
        }

        /// `X.0.0` from 1.0.0 on: the release may remove API.
        var isMajor: Bool {
            let parts = version.split(separator: ".")
            return parts.count == 3 && parts[0] != "0" && parts[1] == "0" && parts[2] == "0"
        }

        /// `X.Y.Z` with Z > 0: fixes only.
        var isPatch: Bool {
            let parts = version.split(separator: ".")
            return parts.count == 3 && parts[2] != "0"
        }

        /// The code spans of the summary and the sections' text (not the code blocks), in order,
        /// without repeats: the names a release talks about (`RatingSummary(average:…)`).
        var codeSpans: [String] {
            var seen = Set<String>()
            var spans: [String] = []
            for text in summary + sections.flatMap(\.texts) {
                // Between backticks: the odd pieces of a split on "`".
                for (index, piece) in text.split(separator: "`", omittingEmptySubsequences: false).enumerated()
                where index % 2 == 1 && !piece.isEmpty && seen.insert(String(piece)).inserted {
                    spans.append(String(piece))
                }
            }
            return spans
        }

        /// Every word of the release, for search.
        var searchText: String {
            ([version, date] + summary + sections.flatMap { [$0.title] + $0.texts + $0.code })
                .joined(separator: "\n")
        }
    }

    struct Section: Hashable, Sendable {
        var title: String
        var blocks: [Block]

        enum Kind: String, CaseIterable, Sendable {
            case added = "Added"
            case changed = "Changed"
            case deprecated = "Deprecated"
            case removed = "Removed"
            case fixed = "Fixed"
            case migration = "Migration"
            case tooling = "Gallery and tooling"
        }

        var kind: Kind? { Kind(rawValue: title) }

        /// The section's prose: its paragraphs and list items.
        var texts: [String] {
            blocks.flatMap { block -> [String] in
                switch block {
                case .paragraph(let text): return [text]
                case .bullets(let items): return items
                case .code: return []
                }
            }
        }

        var code: [String] {
            blocks.compactMap { block -> String? in
                if case .code(let code) = block { return code }
                return nil
            }
        }
    }

    enum Block: Hashable, Sendable {
        /// Inline Markdown (code spans, links, bold), its lines joined.
        case paragraph(String)
        /// A list; each item's lines joined.
        case bullets([String])
        /// A fenced code block as it is.
        case code(String)
    }

    /// The release whose version is the first `X.Y.Z` in `text` ("2.4.0", "since 1.12.0").
    func release(mentionedIn text: String) -> Release? {
        let version = text.split(whereSeparator: { !$0.isNumber && $0 != "." })
            .first { $0.split(separator: ".").count == 3 }
        return version.flatMap { version in releases.first { $0.version == version } }
    }
}

// MARK: - Reading the file

extension Changelog {
    /// The CHANGELOG.md bundled with the Gallery; nil if the build left it out.
    static let bundled: Changelog? = {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return parse(text)
    }()

    static func parse(_ text: String) -> Changelog {
        var parser = ChangelogParser()
        for line in text.components(separatedBy: .newlines) {
            parser.read(line)
        }
        return parser.finish()
    }
}

/// Reads CHANGELOG.md a line at a time. Text before the first `### ` of a release is its
/// summary; text before the first release is the intro.
private struct ChangelogParser {
    private var intro: [Changelog.Block] = []
    private var releases: [Changelog.Release] = []
    /// The section being read; nil while reading the intro or a release's summary.
    private var sectionTitle: String?
    private var blocks: [Changelog.Block] = []
    private var paragraph: [String] = []
    private var bullets: [String] = []
    private var code: [String]?

    mutating func read(_ line: String) {
        if code != nil {
            if line.hasPrefix("```") {
                blocks.append(.code(code!.joined(separator: "\n")))
                code = nil
            } else {
                code!.append(line)
            }
            return
        }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("```") {
            endText()
            code = []
        } else if line.hasPrefix("### ") {
            endSection()
            sectionTitle = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("## ") {
            endSection()
            startRelease(String(line.dropFirst(3)))
        } else if line.hasPrefix("# ") {
            // The file's title.
        } else if trimmed.isEmpty {
            endText()
        } else if line.hasPrefix("- ") {
            endParagraph()
            bullets.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        } else if line.hasPrefix("  "), !bullets.isEmpty, paragraph.isEmpty {
            bullets[bullets.count - 1] += " " + trimmed
        } else {
            endBullets()
            paragraph.append(trimmed)
        }
    }

    mutating func finish() -> Changelog {
        if let code {
            blocks.append(.code(code.joined(separator: "\n")))
            self.code = nil
        }
        endSection()
        return Changelog(intro: intro, releases: releases)
    }

    // MARK: Steps

    /// `X.Y.Z - YYYY-MM-DD`.
    private mutating func startRelease(_ heading: String) {
        let parts = heading.components(separatedBy: " - ")
        releases.append(Changelog.Release(
            version: parts[0].trimmingCharacters(in: .whitespaces),
            date: parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : "",
            summary: [],
            sections: []
        ))
    }

    /// Files the blocks read so far: into the current section, the release's summary or the
    /// intro.
    private mutating func endSection() {
        endText()
        defer {
            blocks = []
            sectionTitle = nil
        }
        guard !releases.isEmpty else {
            intro += blocks
            return
        }
        if let sectionTitle {
            releases[releases.count - 1].sections.append(Changelog.Section(title: sectionTitle, blocks: blocks))
        } else {
            releases[releases.count - 1].summary += blocks.compactMap { block -> String? in
                if case .paragraph(let text) = block { return text }
                return nil
            }
        }
    }

    private mutating func endText() {
        endParagraph()
        endBullets()
    }

    private mutating func endParagraph() {
        guard !paragraph.isEmpty else { return }
        blocks.append(.paragraph(paragraph.joined(separator: " ")))
        paragraph = []
    }

    private mutating func endBullets() {
        guard !bullets.isEmpty else { return }
        blocks.append(.bullets(bullets))
        bullets = []
    }
}
