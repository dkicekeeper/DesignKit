//
//  StepperRow.swift
//  DesignKit
//
//  A whole number in a form (3.0.0): the title, the value, and − / + to change it. Added for
//  Dalada's forms (fish caught, spare items); any count with a range.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A count in a form row: the title on the leading edge, the value and a stepper on the
/// trailing one. At accessibility text sizes the value and the stepper move under the title.
///
/// ```swift
/// StepperRow(icon: "number", title: "Fish caught", value: $count, in: 1...99)
/// StepperRow(title: "Spares", value: $spares, in: 0...20) { "\($0) pcs" }
/// ```
///
/// Its skeleton is `UniversalRowSkeleton.menuPicker`: the same shape, a title and a value.
@available(*, deprecated, message: "Use UniversalRow(_:icon:accessory: .stepper(_:in:step:format:)) (6.2.0).")
public struct StepperRow: View {
    let icon: String?
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let format: (Int) -> String


    /// - Parameters:
    ///   - icon: An SF Symbol before the title, in the accent; none by default.
    ///   - range: The lowest and highest value; the stepper stops at either end.
    ///   - format: How the value reads ("3", "3 pcs"); VoiceOver reads it too.
    public init(
        icon: String? = nil,
        title: String,
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        step: Int = 1,
        format: @escaping (Int) -> String = { "\($0)" }
    ) {
        self.icon = icon
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    public var body: some View {
        UniversalRow(title, icon: icon, accessory: .stepper($value, in: range, step: step, format: format))
    }
}
