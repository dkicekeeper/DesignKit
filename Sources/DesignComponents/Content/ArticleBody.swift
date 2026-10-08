//
//  ArticleBody.swift
//  DesignKit
//
//  The text of an article (2.8.0): headings, paragraphs, bulleted and numbered lists, and notes
//  in a card, with **bold**, *italic* and links inside a line. For a guide, a help page, release
//  notes. Ported from Dalada's ArticleBlockView; parsing the article's Markdown into blocks stays
//  in the app (its format, its tests).
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
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.accent)
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
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attributed = try? AttributedString(markdown: text, options: options) {
            return Text(attributed)
        }
        return Text(verbatim: text)
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
