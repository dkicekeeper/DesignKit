//
//  RatingView.swift
//  DesignKit
//
//  Star rating: read-only display with half stars (`RatingView`) and a tap-to-rate
//  input (`RatingPicker`). From Dalada's StarsView / StarPicker (place reviews).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Read-only star rating with half stars: 3.4 → ★★★⯨☆.
///
/// ```swift
/// RatingView(rating: 4.3)
/// RatingView(rating: place.averageRating, size: 12)
/// ```
///
/// VoiceOver reads `rating.value %@ %lld` ("Rated 4.3 out of 5") — see localization-keys.md.
public struct RatingView: View {
    let rating: Double
    let maximum: Int
    let size: CGFloat
    let color: Color

    public init(
        rating: Double,
        maximum: Int = 5,
        size: CGFloat = 14,
        color: Color = AppColors.warning
    ) {
        self.rating = rating
        self.maximum = max(1, maximum)
        self.size = size
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maximum, id: \.self) { star in
                Image(systemName: Self.symbol(for: star, rating: rating))
                    .font(.system(size: size))
                    .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "rating.value \(Self.formatted(rating)) \(maximum)")))
    }

    /// Filled from 0.75, half from 0.25 of a star, so 3.8 shows four stars and 3.3 three and a half.
    static func symbol(for star: Int, rating: Double) -> String {
        let value = rating - Double(star - 1)
        if value >= 0.75 { return "star.fill" }
        if value >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }

    static func formatted(_ rating: Double) -> String {
        rating.formatted(.number.precision(.fractionLength(0...1)))
    }
}

/// Tap-to-rate input: whole stars, 1…`maximum`.
///
/// ```swift
/// @State private var rating = 0
/// RatingPicker(rating: $rating)
/// ```
///
/// Each star reads `rating.pick %lld %lld` ("4 out of 5") and carries the `.isSelected` trait.
public struct RatingPicker: View {
    @Binding var rating: Int
    let maximum: Int
    let size: CGFloat
    let color: Color

    public init(
        rating: Binding<Int>,
        maximum: Int = 5,
        size: CGFloat = 32,
        color: Color = AppColors.warning
    ) {
        self._rating = rating
        self.maximum = max(1, maximum)
        self.size = size
        self.color = color
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(1...maximum, id: \.self) { star in
                Button {
                    rating = star
                    HapticManager.selection()
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundStyle(color)
                        .symbolEffect(.bounce, value: star == rating)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(String(localized: "rating.pick \(star) \(maximum)")))
                .accessibilityAddTraits(star == rating ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }
}
