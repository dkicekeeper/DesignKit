//
//  ColorSwatch.swift
//  DesignKit
//
//  A palette's swatch for `UniversalRow(accessory: .colors)` (ColorPickerRow's until 7.0.0),
//  and the placeholder of that row.
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - Color Swatch

/// One colour of a palette: a filled circle, outlined with a check when chosen (`RowAccessory.colors`).
struct ColorSwatch: View {
    let colorHex: String
    let isSelected: Bool
    let onTap: () -> Void

    private var color: Color {
        colorFromHex(colorHex)
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: AppIconSize.Tile.sm, height: AppIconSize.Tile.sm)

                if isSelected {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: AppIconSize.Tile.sm, height: AppIconSize.Tile.sm)

                    Icon("checkmark", size: AppIconSize.md, scalesWithText: false)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.staticWhite)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Function

/// Converts hex string to Color
/// Example: "#3b82f6" -> Color(red: 0.23, green: 0.51, blue: 0.96)
private func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
    let b = Double(rgb & 0x0000FF) / 255.0

    return Color(red: r, green: g, blue: b)
}

// MARK: - Previews

// MARK: - Skeleton

/// Placeholder of a colour row (`accessory: .colors`): the title, then a row of round swatches.
struct RowColorsSkeleton: View {
    let swatches: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonText(AppTypography.bodyEmphasis, width: 100)
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<swatches, id: \.self) { _ in
                    Skeleton.circle(AppIconSize.Tile.sm)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
