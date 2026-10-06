//
//  AmountVisibilityToggle.swift
//  DesignKit
//
//  The eye button that hides and shows amounts (`.amountsHidden`). The app keeps the value
//  (a setting) and applies `.amountsHidden(value)` near the root.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An eye that hides amounts when tapped, and a crossed eye that shows them again.
///
/// ```swift
/// @AppStorage("hidesAmounts") private var hidesAmounts = false
///
/// HStack {
///     FormattedAmountText(amount: balance, currency: "KZT", fontSize: AppTypography.h1)
///     AmountVisibilityToggle(isHidden: $hidesAmounts)
/// }
/// .amountsHidden(hidesAmounts)
/// ```
///
/// VoiceOver: "Hide amounts" / "Show amounts" (keys `amount.hide` / `amount.show`).
public struct AmountVisibilityToggle: View {
    @Binding var isHidden: Bool
    let size: CGFloat
    let color: Color

    /// - Parameters:
    ///   - size: The symbol's point size, `AppIconSize.md` (20) by default.
    ///   - color: `AppColors.Text.secondary` by default.
    public init(isHidden: Binding<Bool>, size: CGFloat = AppIconSize.md, color: Color = AppColors.Text.secondary) {
        self._isHidden = isHidden
        self.size = size
        self.color = color
    }

    public var body: some View {
        Button {
            HapticManager.selection()
            withAnimation(AppAnimation.contentSpring) {
                isHidden.toggle()
            }
        } label: {
            Image(systemName: isHidden ? "eye.slash" : "eye")
                .font(.system(size: size))
                .foregroundStyle(color)
                .contentTransition(.symbolEffect(.replace))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isHidden
                ? String(localized: "amount.show", defaultValue: "Show amounts")
                : String(localized: "amount.hide", defaultValue: "Hide amounts")
        )
    }
}
