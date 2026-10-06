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
public struct ColorPickerRow: View {
    @Binding var selectedColorHex: String
    let title: String
    let palette: [String]

    public init(
        selectedColorHex: Binding<String>,
        title: String = String(localized: "common.color"),
        palette: [String] = [
            "#3b82f6", "#8b5cf6", "#ec4899", "#f97316", "#eab308",
            "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef",
            "#f43f5e", "#a855f7", "#10b981", "#f59e0b"
        ]
    ) {
        self._selectedColorHex = selectedColorHex
        self.title = title
        self.palette = palette
    }

    /// Palette to render. If the current color isn't one of the presets (custom color,
    /// or a stored color in a different case), it's prepended so the user can see and
    /// keep their current selection instead of nothing appearing selected.
    private var displayPalette: [String] {
        let selected = selectedColorHex.lowercased()
        if palette.contains(where: { $0.lowercased() == selected }) {
            return palette
        }
        return [selectedColorHex] + palette
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Title
            if !title.isEmpty {
                SectionHeaderView(
                    String(title),
                    style: .default
                )
            }

            // Color swatches using UniversalCarousel
            UniversalCarousel(config: .compact) {
                ForEach(displayPalette, id: \.self) { colorHex in
                    ColorSwatch(
                        colorHex: colorHex,
                        isSelected: selectedColorHex.lowercased() == colorHex.lowercased(),
                        onTap: {
                            HapticManager.selection()
                            selectedColorHex = colorHex
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Color Swatch

private struct ColorSwatch: View {
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
                    .frame(width: AppIconSize.xxl, height: AppIconSize.xxl)

                if isSelected {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: AppIconSize.xxl, height: AppIconSize.xxl)

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
                    SkeletonView.circle(AppIconSize.xxl)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
