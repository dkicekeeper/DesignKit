//
//  SegmentedPickerView.swift
//  Tenra
//
//  Reusable segmented picker component
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct SegmentedPickerView<T: Hashable>: View {
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
        Group {
            if #available(iOS 26, *) {
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .glassEffect(.regular.interactive())
            } else {
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(.ultraThinMaterial)
            }
        }
    }
}

