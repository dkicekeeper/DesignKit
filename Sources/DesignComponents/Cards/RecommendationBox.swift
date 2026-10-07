//
//  RecommendationBox.swift
//  Tenra
//
//  Tinted "lightbulb + advice" callout shared by InsightFormulaCard and
//  HealthComponentCard.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A tinted recommendation callout: an icon and a line of advice on a soft
/// `color`-tinted background. Used at the bottom of insight / health cards.
public struct RecommendationBox: View {
    let text: String
    let color: Color
    var icon: String = "lightbulb.fill"

    public init(text: String, color: Color, icon: String = "lightbulb.fill") {
        self.text = text
        self.color = color
        self.icon = icon
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: AppIconSize.sm))
                .foregroundStyle(color)

            Text(text)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background(AppColors.pale(color))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}


// MARK: - Skeleton

/// Placeholder of a `RecommendationBox`: one grey box with its corner, as tall as an icon
/// and `lines` lines of its text.
public struct RecommendationBoxSkeleton: View {
    let lines: Int

    public init(lines: Int = 2) {
        self.lines = max(1, lines)
    }

    public var body: some View {
        // The box's own layout, invisible, gives the height (it grows with Dynamic Type).
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: AppIconSize.sm))
            Text(verbatim: Array(repeating: "Ag", count: lines).joined(separator: "\n"))
                .font(AppTypography.bodySmall)
        }
        .hidden()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Skeleton.fill, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .shimmer()
        .skeletonLoadingLabel()
    }
}
