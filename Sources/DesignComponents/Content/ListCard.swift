//
//  ListCard.swift
//  DesignKit
//
//  A card of rows under an optional section title (4.13.0): what an assistant's reply shows (a
//  list of payments, a draft to confirm, an attachment), a short list on a screen. The rows pad
//  themselves vertically (docs/design-system.md §10); the card pads them on every side and
//  spaces them by `AppSpacing.sm`. Ported from Tenra's AssistantCard.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "Payments" over a glass card of rows.
///
/// ```swift
/// ListCard(title: "Payments") {
///     ForEach(payments) { payment in
///         TransactionRow(…)
///     }
/// }
/// ```
public struct ListCard<Content: View>: View {
    let title: String?
    let content: Content

    /// - Parameters:
    ///   - title: A `SectionHeader` above the card; none (or empty) leaves the card alone.
    ///   - content: The rows, top to bottom.
    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let title, !title.isEmpty {
                SectionHeader(title)
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                content
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `ListCard`: the title's line (or none) and the card with `rows` rows of a
/// grey circle, a title and a shorter line.
public struct ListCardSkeleton: View {
    let showsTitle: Bool
    let rows: Int

    public init(showsTitle: Bool = true, rows: Int = 3) {
        self.showsTitle = showsTitle
        self.rows = max(1, rows)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if showsTitle {
                SkeletonText(AppTypography.bodyEmphasis, width: 120)
                    .shimmer()
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(0..<rows, id: \.self) { _ in
                    HStack(spacing: AppSpacing.md) {
                        Skeleton.circle(AppIconSize.Tile.sm)
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            SkeletonText(AppTypography.bodyEmphasis, width: 160)
                            SkeletonText(AppTypography.caption, width: 110)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
            .shimmer()
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .skeletonLoadingLabel()
    }
}
