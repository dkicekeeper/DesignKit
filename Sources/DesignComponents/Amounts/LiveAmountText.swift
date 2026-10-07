//
//  LiveAmountText.swift
//  DesignKit
//
//  An amount that arrives and changes visibly (2.3.0): on its first appearance the digits roll
//  up from zero, and when the amount changes it flashes green (up) or red (down) for a moment
//  while the digits roll to the new value. For a hero balance, a total that just updated.
//
//  Built on FormattedAmountText, which already rolls its digits (`numericText`); this only
//  feeds it zero first and tints the change; one short sleep ends the flash. Hidden amounts (`.amountsHidden`) stay
//  hidden; under Reduce Motion or `.designKitMotion(false)` the amount shows as it is and
//  changes without a flash.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A `FormattedAmountText` that rolls up from zero on its first appearance and flashes the
/// direction of a change.
///
/// ```swift
/// LiveAmountText(amount: totalBalance, currency: "KZT", fontSize: AppTypography.h1)
/// ```
public struct LiveAmountText: View {
    let amount: Double
    let currency: String
    let prefix: String
    let fontSize: Font
    let fontWeight: Font.Weight
    let color: Color
    let rollsUpOnAppear: Bool
    let flashesChanges: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    /// What the text shows; `nil` before the first appearance.
    @State private var shown: Double?
    /// The direction of the last change while its flash lasts.
    @State private var flash: FlashDirection?
    @State private var flashCount = 0

    private enum FlashDirection { case up, down }

    /// - Parameters:
    ///   - rollsUpOnAppear: The digits roll up from zero the first time the text appears.
    ///   - flashesChanges: A change tints the amount green (up) or red (down) for a moment.
    public init(
        amount: Double,
        currency: String,
        prefix: String = "",
        fontSize: Font = AppTypography.body,
        fontWeight: Font.Weight = .semibold,
        color: Color = AppColors.Text.primary,
        rollsUpOnAppear: Bool = true,
        flashesChanges: Bool = true
    ) {
        self.amount = amount
        self.currency = currency
        self.prefix = prefix
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.rollsUpOnAppear = rollsUpOnAppear
        self.flashesChanges = flashesChanges
    }

    private var allowsMotion: Bool { !reduceMotion && designKitMotion }

    private var tint: Color {
        switch flash {
        case .up: AppColors.Text.positive
        case .down: AppColors.Text.negative
        case nil: color
        }
    }

    public var body: some View {
        FormattedAmountText(
            amount: shown ?? (allowsMotion && rollsUpOnAppear ? 0 : amount),
            currency: currency,
            prefix: prefix,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: tint
        )
        .animation(AppAnimation.smooth, value: flash)
        .onAppear {
            guard shown == nil else { return }
            if allowsMotion && rollsUpOnAppear {
                withAnimation(.smooth(duration: LiveAmountMetrics.rollDuration)) { shown = amount }
            } else {
                shown = amount
            }
        }
        .onChange(of: amount) { old, new in
            shown = new
            guard allowsMotion, flashesChanges, new != old else { return }
            flash = new > old ? .up : .down
            flashCount += 1
            let count = flashCount
            Task {
                try? await Task.sleep(for: .seconds(LiveAmountMetrics.flashDuration))
                if flashCount == count { flash = nil }
            }
        }
    }
}

enum LiveAmountMetrics {
    /// The first roll from zero.
    static let rollDuration: Double = 0.8
    /// How long a change stays tinted.
    static let flashDuration: Double = 0.7
}

// MARK: - Skeleton

/// Placeholder of a `LiveAmountText`: the same line as `FormattedAmountTextSkeleton`. Reveal the
/// amount with `SkeletonReveal` so it comes into focus, then rolls up.
public typealias LiveAmountTextSkeleton = FormattedAmountTextSkeleton
