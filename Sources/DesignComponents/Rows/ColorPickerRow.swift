//
//  ColorPickerRow.swift
//  Tenra
//
//  Reusable color picker with preset palette
//  Used for category customization
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Color picker row with preset palette and custom color option
/// Shows horizontal scrollable color swatches
@available(*, deprecated, message: "Use UniversalRow(_:accessory: .colors(_:palette:)) (6.2.0).")
public struct ColorPickerRow: View {
    @Binding var selectedColorHex: String
    let title: String
    let palette: [String]

    public init(
        selectedColorHex: Binding<String>,
        title: String = String(localized: "common.color"),
        palette: [String] = CategoryColors.pickerPalette
    ) {
        self._selectedColorHex = selectedColorHex
        self.title = title
        self.palette = palette
    }

    public var body: some View {
        // No padding of its own, as before 6.2.0: the container placed it.
        UniversalRow(title, config: ColorPickerRowMetrics.unpadded, accessory: .colors($selectedColorHex, palette: palette))
    }
}

enum ColorPickerRowMetrics {
    /// The deprecated row's padding: none, its container placed it.
    static let unpadded = RowConfiguration(
        spacing: AppSpacing.md,
        verticalPadding: 0,
        horizontalPadding: 0,
        backgroundColor: .clear,
        cornerRadius: 0
    )
}

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

                    Image(systemName: "checkmark")
                        .font(.system(size: AppIconSize.md, weight: .bold))
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

/// Placeholder of a `ColorPickerRow`: the title, then a row of round swatches.
public struct ColorPickerRowSkeleton: View {
    let swatches: Int

    public init(swatches: Int = 6) {
        self.swatches = max(1, swatches)
    }

    public var body: some View {
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
