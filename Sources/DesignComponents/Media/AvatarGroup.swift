//
//  AvatarGroup.swift
//  DesignKit
//
//  Overlapping row of avatars with a "+N" bubble for the rest — who went on a trip, who
//  shares an account. (Fluent Avatar group, Atlassian Avatar group, Polaris stack.) For a
//  loose cluster of icons use PackedCircleIcons.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Up to `maxVisible` avatars overlapping by a third, then "+N".
///
/// ```swift
/// AvatarGroup(names: trip.members.map(\.displayName))
/// AvatarGroup(names: names, maxVisible: 3, size: 28,
///             accessibilityLabel: "Ayan, Dana and 4 more")
/// ```
///
/// Each avatar gets a ring in the background colour so the overlap reads on any surface, and
/// an opaque disc under its pale tint (2.0.0) so the avatar under it does not show through.
public struct AvatarGroup: View {
    let names: [String?]
    let maxVisible: Int
    let size: CGFloat
    let label: String?

    /// - Parameters:
    ///   - names: one entry per person (initials come from `Avatar.initials`).
    ///   - maxVisible: avatars shown before the "+N" bubble.
    ///   - accessibilityLabel: what VoiceOver reads for the whole group; hidden when `nil`.
    public init(
        names: [String?],
        maxVisible: Int = 4,
        size: CGFloat = 32,
        accessibilityLabel: String? = nil
    ) {
        self.names = names
        self.maxVisible = max(1, maxVisible)
        self.size = size
        self.label = accessibilityLabel
    }

    private var visible: ArraySlice<String?> { names.prefix(maxVisible) }
    private var overflow: Int { max(0, names.count - maxVisible) }
    private var ring: CGFloat { max(1.5, size / 16) }

    public var body: some View {
        HStack(spacing: -size / 3) {
            ForEach(Array(visible.enumerated()), id: \.offset) { index, name in
                Avatar(name: name, size: size)
                    .background(AppColors.Background.base, in: Circle())
                    .overlay(Circle().stroke(AppColors.Background.base, lineWidth: ring))
                    .zIndex(Double(visible.count - index))
            }
            if overflow > 0 {
                Text(verbatim: "+\(overflow)")
                    .font(size > 40 ? AppTypography.bodyEmphasis : AppTypography.caption)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.Text.secondary)
                    .frame(width: size, height: size)
                    .background(AppColors.Background.neutral2, in: Circle())
                    .overlay(Circle().stroke(AppColors.Background.base, lineWidth: ring))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label ?? ""))
        .accessibilityHidden(label == nil)
    }
}

// MARK: - Skeleton

/// Placeholder of an `AvatarGroup`: overlapping circles, with the group's overlap.
public struct AvatarGroupSkeleton: View {
    let count: Int
    let size: CGFloat

    public init(count: Int = 3, size: CGFloat = 32) {
        self.count = max(1, count)
        self.size = size
    }

    public var body: some View {
        HStack(spacing: -size / 3) {
            ForEach(0..<count, id: \.self) { index in
                Skeleton.circle(size)
                    // The ring that separates the avatars.
                    .overlay(Circle().stroke(AppColors.Background.base, lineWidth: 2))
                    .zIndex(Double(count - index))
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
