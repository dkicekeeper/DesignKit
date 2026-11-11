//
//  ArticleBody.swift
//  DesignKit
//
//  The text of an article (2.8.0): headings, paragraphs, bulleted and numbered lists, and notes
//  in a card, with **bold**, *italic* and links inside a line. For a guide, a help page, release
//  notes. Ported from Dalada's ArticleBlockView; parsing the article's Markdown into blocks stays
//  in the app (its format, its tests).
//
//  8.9.0: `Block.parse(markdown:)` reads plain Markdown (headings, paragraphs, lists, quotes) into
//  blocks, for text that comes as Markdown and has no format of its own: an assistant's answer
//  (`MessageBubble(markdown:)`), notes from a server.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An article's blocks, one under another.
///
/// ```swift
/// ArticleBody([
///     .heading("Before you go", level: 2),
///     .paragraph("Check the **ice** at the shore first."),
///     .steps(["Pack the kit", "Tell a friend"]),
///     .note("Fishing is closed from 1 April to 31 May."),
/// ])
/// ```
public struct ArticleBody: View {
    /// One block of an article. Text inside a block may carry inline Markdown.
    public enum Block: Hashable, Sendable {
        /// Level 2 (a section) or 3 (a subsection).
        case heading(String, level: Int)
        case paragraph(String)
        /// A bulleted list.
        case bullets([String])
        /// A numbered list, the numbers in the accent.
        case steps([String])
        /// A note in a card, with an info symbol.
        case note(String)
    }

    let blocks: [Block]
    let spacing: CGFloat

    /// - Parameter spacing: Between blocks.
    public init(_ blocks: [Block], spacing: CGFloat = AppSpacing.md) {
        self.blocks = blocks
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                ArticleBlockView(block: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public extension ArticleBody.Block {
    /// Plain Markdown read into blocks (8.9.0):
    ///
    /// - `#` and `##` start a section heading (level 2), `###` and deeper a subsection (level 3);
    /// - `- `, `* ` or `• ` lines make a bulleted list, `1. ` or `1) ` lines a numbered one;
    /// - `> ` lines make a note;
    /// - other lines make paragraphs; a blank line ends one, a single line break stays in it.
    ///
    /// Inline Markdown (`**bold**`, `*italic*`, links, `code`) stays in the text and is drawn by
    /// the block.
    ///
    /// ```swift
    /// ArticleBody(ArticleBody.Block.parse(markdown: answer))
    /// ```
    static func parse(markdown: String) -> [ArticleBody.Block] {
        var blocks: [ArticleBody.Block] = []
        var paragraph: [String] = []
        var bullets: [String] = []
        var steps: [String] = []
        var note: [String] = []

        func flush() {
            if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: "\n"))) }
            if !bullets.isEmpty { blocks.append(.bullets(bullets)) }
            if !steps.isEmpty { blocks.append(.steps(steps)) }
            if !note.isEmpty { blocks.append(.note(note.joined(separator: "\n"))) }
            paragraph = []; bullets = []; steps = []; note = []
        }

        for raw in markdown.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
            } else if let heading = Self.heading(line) {
                flush()
                blocks.append(.heading(heading.text, level: heading.level))
            } else if let item = Self.bullet(line) {
                if bullets.isEmpty { flush() }
                bullets.append(item)
            } else if let item = Self.step(line) {
                if steps.isEmpty { flush() }
                steps.append(item)
            } else if line.hasPrefix(">") {
                if note.isEmpty { flush() }
                note.append(String(line.dropFirst()).trimmingCharacters(in: .whitespaces))
            } else {
                if !bullets.isEmpty || !steps.isEmpty || !note.isEmpty { flush() }
                paragraph.append(line)
            }
        }
        flush()
        return blocks
    }

    /// "## Title" → (2, "Title"); `#` counts as a section too, past `###` a subsection.
    private static func heading(_ line: String) -> (level: Int, text: String)? {
        let hashes = line.prefix { $0 == "#" }.count
        guard hashes > 0, hashes <= 6 else { return nil }
        let rest = line.dropFirst(hashes)
        guard rest.first == " " else { return nil }
        return (hashes <= 2 ? 2 : 3, rest.trimmingCharacters(in: .whitespaces))
    }

    /// "- item", "* item", "• item" → "item".
    private static func bullet(_ line: String) -> String? {
        for marker in ["- ", "* ", "• "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    /// "1. item", "12) item" → "item".
    private static func step(_ line: String) -> String? {
        let digits = line.prefix { $0.isASCII && $0.isNumber }
        guard !digits.isEmpty, digits.count <= 3 else { return nil }
        let rest = line.dropFirst(digits.count)
        guard let mark = rest.first, mark == "." || mark == ")", rest.dropFirst().first == " " else { return nil }
        return String(rest.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }
}

/// Markdown inside a line: **bold**, *italic*, links, `code`; the text as it is when it does not
/// parse.
func inlineMarkdown(_ text: String) -> Text {
    let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    if let attributed = try? AttributedString(markdown: text, options: options) {
        return Text(attributed)
    }
    return Text(verbatim: text)
}

/// One block of `ArticleBody`.
struct ArticleBlockView: View {
    let block: ArticleBody.Block

    var body: some View {
        switch block {
        case .heading(let text, let level):
            inline(text)
                .font(level == 2 ? Font.title3.weight(.semibold) : Font.headline)
                .foregroundStyle(AppColors.Text.primary)
                .padding(.top, AppSpacing.sm)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            inline(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.Text.primary)
        case .bullets(let items):
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        Text(verbatim: "•")
                        inline(item)
                    }
                }
            }
            .font(AppTypography.body)
            .foregroundStyle(AppColors.Text.primary)
        case .steps(let items):
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        Text(verbatim: "\(index + 1).")
                            .monospacedDigit()
                            .foregroundStyle(AppColors.accent)
                        inline(item)
                    }
                }
            }
            .font(AppTypography.body)
            .foregroundStyle(AppColors.Text.primary)
        case .note(let text):
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Icon("info.circle", size: AppIconSize.sm, tint: .monochrome(AppColors.accent))
                inline(text)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.primary)
                Spacer(minLength: 0)
            }
            .cardContentPadding()
            .cardStyle()
        }
    }

    /// Markdown inside a line: **bold**, *italic*, links.
    private func inline(_ text: String) -> Text {
        inlineMarkdown(text)
    }
}

// MARK: - Skeleton

/// Placeholder of an `ArticleBody`: a heading and paragraphs of grey lines.
public struct ArticleBodySkeleton: View {
    let paragraphs: Int

    public init(paragraphs: Int = 3) {
        self.paragraphs = max(1, paragraphs)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SkeletonText(Font.title3, width: 180)
                .padding(.top, AppSpacing.sm)
            ForEach(0..<paragraphs, id: \.self) { _ in
                SkeletonText(AppTypography.body, lines: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
