//
//  SuggestionChips.swift
//  DesignKit
//
//  Ready-made things to say (4.6.0): a row of chips under an assistant's answer or on an empty
//  chat, each one a prompt the person can send with a tap ("Compare with September", "Where
//  can I save?"). Unlike `ChipPicker` nothing stays selected: a tap is an action.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Tappable prompts in chips.
///
/// ```swift
/// SuggestionChips(reply.suggestions) { send($0) }                        // one scrolling row
/// SuggestionChips(presets, systemImage: "sparkles", layout: .wrap) { send($0) }
/// ```
///
/// `.scroll` keeps one line that scrolls sideways (under an answer); `inset` keeps the first
/// chip off the edge while the row still scrolls to it. `.wrap` lays every chip out in lines
/// (the prompts of an empty chat). Chips use `filterChipStyle()`.
public struct SuggestionChips: View {
    /// How the chips are laid out.
    public enum Layout: Hashable, Sendable {
        /// One line that scrolls sideways.
        case scroll
        /// Lines that wrap, every chip visible.
        case wrap
    }

    let suggestions: [String]
    let systemImage: String?
    let layout: Layout
    let inset: CGFloat
    let action: (String) -> Void

    /// - Parameters:
    ///   - systemImage: A symbol in front of every chip ("sparkles"), or none.
    ///   - inset: `.scroll` only: the leading and trailing margin of the row.
    public init(
        _ suggestions: [String],
        systemImage: String? = nil,
        layout: Layout = .scroll,
        inset: CGFloat = 0,
        action: @escaping (String) -> Void
    ) {
        self.suggestions = suggestions
        self.systemImage = systemImage
        self.layout = layout
        self.inset = inset
        self.action = action
    }

    public var body: some View {
        switch layout {
        case .scroll:
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.sm) { chips }
                    .padding(.vertical, AppSpacing.xxs)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, inset, for: .scrollContent)
        case .wrap:
            FlowLayout(spacing: AppSpacing.sm) { chips }
        }
    }

    private var chips: some View {
        ForEach(suggestions, id: \.self) { suggestion in
            Button {
                action(suggestion)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(AppColors.accent)
                    }
                    Text(suggestion)
                }
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .filterChipStyle()
        }
    }
}

// MARK: - Skeleton

/// Placeholder of `SuggestionChips`: a row of chips with the chips' corner.
public struct SuggestionChipsSkeleton: View {
    let count: Int

    public init(count: Int = 3) {
        self.count = max(1, count)
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                // A chip's own layout (filterChipStyle), invisible, in its corner.
                Text(verbatim: "Ag")
                    .font(AppTypography.bodySmall.weight(.medium))
                    .hidden()
                    .frame(width: index.isMultiple(of: 2) ? 96 : 128)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Skeleton.fill, in: RoundedRectangle(cornerRadius: AppRadius.xl))
            }
        }
        .padding(.vertical, AppSpacing.xxs)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
