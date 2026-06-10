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
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

