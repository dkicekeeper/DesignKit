//
//  ReactionButton.swift
//  DesignKit
//
//  A reaction under a post: a symbol and the count ("👍 12", "Helpful · 3"), filled and in the
//  accent colour once the user has reacted. Without an action (one's own post, a guest) it is
//  only the count, and nothing while the count is zero. Ported from Dalada's ReactionButton;
//  the reactions store (what a tap does, the counts) stays in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A reaction toggle with its count.
///
/// ```swift
/// ReactionButton(systemImage: "hand.thumbsup", selectedSystemImage: "hand.thumbsup.fill",
///                count: state.count, isSelected: state.reacted,
///                accessibilityLabel: "12 respects") {
///     Task { await reactions.toggle(key) }
/// }
/// ReactionButton(systemImage: "lightbulb", selectedSystemImage: "lightbulb.fill",
///                count: 3, isSelected: false, title: "Helpful · 3", accessibilityLabel: …) { … }
/// ```
///
/// The tap area is at least 44 pt. Font: `AppTypography.bodySmall`.
public struct ReactionButton: View {
    let systemImage: String
    let selectedSystemImage: String
    let count: Int
    let isSelected: Bool
    let title: String?
    let accessibilityLabel: String
    let action: (() -> Void)?

    /// Counts the times the reaction was added: each one bursts sparkles (2.2.0).
    @State private var additions = 0

    /// - Parameters:
    ///   - title: Replaces the bare count next to the symbol ("Helpful · 3"); the count alone
    ///     shows only when it is above zero.
    ///   - action: What a tap does; `nil` shows the count only (one's own post, a guest).
    public init(
        systemImage: String,
        selectedSystemImage: String,
        count: Int,
        isSelected: Bool,
        title: String? = nil,
        accessibilityLabel: String,
        action: (() -> Void)?
    ) {
        self.systemImage = systemImage
        self.selectedSystemImage = selectedSystemImage
        self.count = count
        self.isSelected = isSelected
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Group {
            if let action {
                Button {
                    HapticManager.selection()
                    action()
                } label: {
                    Label {
                        if let title {
                            Text(verbatim: title)
                        } else if count > 0 {
                            Text(verbatim: "\(count)")
                        }
                    } icon: {
                        Image(systemName: isSelected ? selectedSystemImage : systemImage)
                            // 2.2.0: the fill grows in, the symbol bounces and sparkles
                            // burst around it when the reaction is added.
                            .symbolMagicReplace()
                            .symbolEffect(.bounce, value: isSelected)
                            .sparkleBurst(trigger: additions, tint: AppColors.accent)
                    }
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.secondary)
                    .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text(verbatim: accessibilityLabel))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            } else if count > 0 {
                Label {
                    Text(verbatim: "\(count)")
                } icon: {
                    Image(systemName: systemImage)
                }
                .foregroundStyle(AppColors.Text.secondary)
                .accessibilityLabel(Text(verbatim: accessibilityLabel))
            }
        }
        .font(AppTypography.bodySmall)
        .animation(AppAnimation.snappy, value: isSelected)
        .onChange(of: isSelected) { _, selected in
            if selected { additions += 1 }
        }
    }
}
