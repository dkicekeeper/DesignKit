//
//  ActionRowLabel.swift
//  DesignKit
//
//  The look of an action row (3.1.0) for a control that is not a Button: a `PhotosPicker`, a
//  `ShareLink`, a `Link`, a `NavigationLink` takes it as its label. An accent symbol and title,
//  as "Add photos" in a form card. Ported from Dalada's PickerRowLabel (its photo pickers).
//
//  Its init is `nonisolated`: `PhotosPicker` builds its label off the main actor, where the
//  initialisers of DesignKit's rows cannot run; the row itself is built in `body`.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An action row as a label: a symbol and a title, in the accent by default.
///
/// ```swift
/// PhotosPicker(selection: $items, matching: .images) {
///     ActionRowLabel("Add photos", systemImage: "photo.on.rectangle.angled")
/// }
/// .buttonStyle(.plain)
/// ```
///
/// `ActionSettingsRow` is the same row with its own button; use this one when the control is
/// someone else's. No skeleton: it shows no data.
public struct ActionRowLabel: View {
    let title: String
    let systemImage: String?
    let tint: Color
    let titleColor: Color?
    let config: RowConfiguration

    /// - Parameters:
    ///   - systemImage: The symbol before the title; none by default.
    ///   - tint: The symbol's colour, and the title's unless `titleColor` is given.
    ///   - titleColor: A title in another colour (`AppColors.Text.primary` for a quieter row).
    ///   - config: `.standard` (default) pads the row for a `FormSection` card; `.settings` for
    ///     a `List` row.
    public nonisolated init(
        _ title: String,
        systemImage: String? = nil,
        tint: Color = AppColors.accent,
        titleColor: Color? = nil,
        config: RowConfiguration = .standard
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.titleColor = titleColor
        self.config = config
    }

    public var body: some View {
        UniversalRow(
            config: config,
            leadingIcon: systemImage.map { .sfSymbol($0, color: tint, size: AppIconSize.lg) },
            title: title,
            titleColor: titleColor ?? tint
        )
        .contentShape(Rectangle())
    }
}
