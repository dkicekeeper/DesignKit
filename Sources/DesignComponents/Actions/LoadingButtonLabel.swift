//
//  LoadingButtonLabel.swift
//  DesignKit
//
//  Button label that swaps its title for a spinner while an action runs, keeping the
//  button's width so nothing jumps. (Material / Polaris / Fluent "loading" button state.)
//  Pair with `.dsButton(disabled:)` so the button cannot be tapped twice.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Title, or a spinner of the same size while `isLoading`.
///
/// ```swift
/// Button { Task { await save() } } label: {
///     LoadingButtonLabel("Save", isLoading: isSaving)
///         .frame(maxWidth: .infinity)
/// }
/// .dsButton(disabled: isSaving)
/// ```
///
/// VoiceOver keeps the title and adds the loading state (key `skeleton.loading`).
@available(*, deprecated, message: "Use DSButton(title, systemImage:, isLoading:, fullWidth:), which keeps the width and blocks taps while loading.")
public struct LoadingButtonLabel: View {
    let title: String
    let systemImage: String?
    let isLoading: Bool

    public init(_ title: String, systemImage: String? = nil, isLoading: Bool) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
    }

    public var body: some View {
        ZStack {
            label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.contentSpring, value: isLoading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(isLoading
            ? Text(String(localized: "skeleton.loading", defaultValue: "Loading"))
            : Text(verbatim: ""))
    }

    @ViewBuilder
    private var label: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(verbatim: title)
        }
    }
}
