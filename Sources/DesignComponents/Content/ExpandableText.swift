//
//  ExpandableText.swift
//  DesignKit
//
//  Long text clamped to a few lines with a "More" / "Less" toggle — reviews, notes,
//  descriptions. The toggle appears only when the text really is longer than the limit.
//  (Atlassian / Polaris "Show more", App Store "more".)
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Text clamped to `lineLimit` lines with a More / Less button when it overflows.
///
/// ```swift
/// ExpandableText(review.body)
/// ExpandableText(place.description, lineLimit: 5, font: AppTypography.bodySmall)
/// ```
///
/// Button keys: `text.more` / `text.less` (defaults "More" / "Less").
public struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    let font: Font
    let color: Color

    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var clampedHeight: CGFloat = 0

    public init(
        _ text: String,
        lineLimit: Int = 3,
        font: Font = AppTypography.body,
        color: Color = AppColors.textPrimary
    ) {
        self.text = text
        self.lineLimit = max(1, lineLimit)
        self.font = font
        self.color = color
    }

    /// Overflows when the unclamped text is taller than the clamped one.
    private var isTruncated: Bool { fullHeight > clampedHeight + 1 }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(verbatim: text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(measurements)

            if isTruncated {
                Button {
                    withAnimation(AppAnimation.contentSpring) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded
                         ? String(localized: "text.less", defaultValue: "Less")
                         : String(localized: "text.more", defaultValue: "More"))
                        .font(AppTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Two hidden copies measure the clamped and the full height at the same width.
    private var measurements: some View {
        ZStack {
            Text(verbatim: text)
                .font(font)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { clampedHeight = $0 }
            Text(verbatim: text)
                .font(font)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
        }
        .hidden()
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton

/// Placeholder of an `ExpandableText`: `lines` lines of its text, the last one shorter.
public struct ExpandableTextSkeleton: View {
    let font: Font
    let lines: Int

    public init(font: Font = AppTypography.body, lines: Int = 3) {
        self.font = font
        self.lines = max(1, lines)
    }

    public var body: some View {
        SkeletonText(font, lines: lines)
            .skeletonLoadingLabel()
    }
}
