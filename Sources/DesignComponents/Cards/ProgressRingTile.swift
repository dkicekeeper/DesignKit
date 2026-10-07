//
//  ProgressRingTile.swift
//  DesignKit
//
//  A tile of a picker grid: the name over a Liquid Glass circle with a symbol, tinted when
//  selected, with an optional progress ring around it. Ported from Tenra's CategoryChip; the
//  category style lookup and the VoiceOver copy stay in Tenra as an adapter.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Food" over a glass 🍴 circle, the ring around it at 74%.
///
/// The tile is as tall with a ring as without one, so names and anything under the tiles line
/// up across a grid row. Add the VoiceOver label and hint at the call site.
///
/// ```swift
/// LazyVGrid(columns: columns) {
///     ProgressRingTile(title: "Food", systemImage: "fork.knife", color: .orange,
///                      progress: LimitProgress(spent: 185_000, limit: 250_000),
///                      isSelected: selected == "Food") { selected = "Food" }
/// }
/// ```
public struct ProgressRingTile: View {
    let title: String
    let systemImage: String
    let color: Color
    let progress: LimitProgress?
    let isSelected: Bool
    let action: () -> Void
    let transitionSourceID: String?
    let transitionNamespace: Namespace.ID?

    /// - Parameters:
    ///   - color: The symbol's colour; the glass is tinted with it at 30% when selected.
    ///   - progress: Draws the ring around the circle; `nil` hides it.
    ///   - transitionSourceID: With `transitionNamespace`, makes the circle (with its ring)
    ///     the source of a `.navigationTransition(.zoom(sourceID:in:))`.
    public init(
        title: String,
        systemImage: String,
        color: Color,
        progress: LimitProgress? = nil,
        isSelected: Bool = false,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.progress = progress
        self.isSelected = isSelected
        self.action = action
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                ZStack {
                    if let progress {
                        ProgressRing(
                            progress: progress.percentage / 100,
                            size: AppIconSize.Tile.xxl,
                            lineWidth: 4,
                            isOverBudget: progress.isOverLimit,
                            animatesOnAppear: false // lazy grid — onAppear re-fires on scroll
                        )
                    }

                    Image(systemName: systemImage)
                        .font(AppTypography.h2)
                        .foregroundStyle(color)
                        .frame(width: AppIconSize.Tile.xl, height: AppIconSize.Tile.xl)
                        .glassEffect(
                            isSelected
                                ? .regular.tint(color.opacity(0.3)).interactive()
                                : .regular.interactive(),
                            in: .circle
                        )
                }
                .matchedTransitionSourceIfPresent(
                    id: transitionSourceID,
                    namespace: transitionNamespace
                )
                // Same height with or without the ring (72 vs 64 pt), so whatever sits under
                // tiles without a ring lines up with their neighbours.
                .frame(height: AppIconSize.Tile.xxl)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Skeleton

/// Placeholder of a `ProgressRingTile`: the title, the ring's track and the round glass
/// button inside it.
public struct ProgressRingTileSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            SkeletonText(AppTypography.bodyEmphasis, width: 70)
            ZStack {
                Circle()
                    .stroke(Skeleton.fill, lineWidth: 4)
                    .frame(width: AppIconSize.Tile.xxl, height: AppIconSize.Tile.xxl)
                Skeleton.circle(AppIconSize.Tile.xl)
            }
            .frame(height: AppIconSize.Tile.xxl)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
