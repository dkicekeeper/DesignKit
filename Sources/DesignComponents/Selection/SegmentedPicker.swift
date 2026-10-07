//
//  SegmentedPicker.swift
//  Tenra
//
//  Reusable segmented picker component.
//  2.0.0: the system control alone. An interactive glass layer over it (before 2.0) took the
//  touch, so a quick tap did not move the selection; iOS 26 draws the control in Liquid Glass
//  itself.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct SegmentedPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [(label: String, value: T)]
    
    public init(
        title: String,
        selection: Binding<T>,
        options: [(label: String, value: T)]
    ) {
        self.title = title
        self._selection = selection
        self.options = options
    }
    
    public var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.value) { option in
                Text(option.label).tag(option.value)
            }
        }
        .pickerStyle(.segmented)
        // 2.3.0: a selection tick as the segment moves.
        .hapticCue(.select, trigger: selection)
    }
}

// MARK: - Names before 2.0

@available(*, deprecated, renamed: "SegmentedPicker")
public typealias SegmentedPickerView<T: Hashable> = SegmentedPicker<T>
