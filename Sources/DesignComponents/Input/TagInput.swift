//
//  TagInput.swift
//  DesignKit
//
//  Free-form tags: typed words become removable chips, with optional suggestions to tap.
//  (HIG token field, Material input chips, Carbon / Polaris / Atlassian tag input.)
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Chips for the tags already added, a field for the next one, and matching suggestions.
///
/// ```swift
/// TagInput(String(localized: "gear.tags.placeholder"), tags: $item.tags,
///          suggestions: ["Winter", "Rain", "Kids"])
/// ```
///
/// Return or a comma adds the typed tag. Duplicates (ignoring case) and blanks are dropped.
/// Remove-button VoiceOver label: key `tags.remove` (default "Remove %@").
public struct TagInput: View {
    let placeholder: String
    @Binding var tags: [String]
    let suggestions: [String]
    let maxTags: Int?

    @State private var text = ""
    @FocusState private var isFocused: Bool

    /// - Parameters:
    ///   - suggestions: offered under the field, filtered by what is typed.
    ///   - maxTags: the field hides once this many tags are added.
    public init(
        _ placeholder: String,
        tags: Binding<[String]>,
        suggestions: [String] = [],
        maxTags: Int? = nil
    ) {
        self.placeholder = placeholder
        self._tags = tags
        self.suggestions = suggestions
        self.maxTags = maxTags
    }

    private var canAdd: Bool { maxTags.map { tags.count < $0 } ?? true }

    private var matchingSuggestions: [String] {
        let query = text.trimmingCharacters(in: .whitespaces)
        return suggestions.filter { suggestion in
            !contains(suggestion)
                && (query.isEmpty || suggestion.localizedCaseInsensitiveContains(query))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            FlowLayout(spacing: AppSpacing.xs, lineSpacing: AppSpacing.xs) {
                ForEach(tags, id: \.self) { tag in
                    chip(tag)
                }
                if canAdd {
                    TextField(placeholder, text: $text)
                        .font(AppTypography.body)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(commit)
                        .onChange(of: text) { _, value in
                            if value.contains(",") { commit() }
                        }
                        .frame(minWidth: 120)
                        .padding(.vertical, AppSpacing.xs)
                }
            }

            if canAdd, !matchingSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(matchingSuggestions, id: \.self) { suggestion in
                            Button {
                                add(suggestion)
                                text = ""
                            } label: {
                                Label(suggestion, systemImage: "plus")
                                    .font(AppTypography.bodySmall)
                            }
                            .buttonStyle(.plain)
                            .filterChipStyle(isSelected: false)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }
            }
        }
        .animation(AppAnimation.contentSpring, value: tags)
    }

    private func chip(_ tag: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text(verbatim: tag)
                .font(AppTypography.bodySmall)
                .lineLimit(1)
            Button {
                HapticManager.light()
                tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(String(
                format: String(localized: "tags.remove", defaultValue: "Remove %@"),
                tag
            )))
        }
        .padding(.leading, AppSpacing.md)
        .padding(.trailing, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.accent.opacity(0.12), in: Capsule())
        .foregroundStyle(AppColors.textPrimary)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    /// Adds what is typed (split at commas) and keeps the keyboard up for the next tag.
    /// Return on an empty field just closes the keyboard.
    private func commit() {
        let parts = text.split(separator: ",").map(String.init)
        text = ""
        guard parts.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return }
        for part in parts { add(part) }
        isFocused = canAdd
    }

    private func add(_ raw: String) {
        let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, !contains(tag), canAdd else { return }
        HapticManager.selection()
        tags.append(tag)
    }

    private func contains(_ tag: String) -> Bool {
        tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
    }
}
