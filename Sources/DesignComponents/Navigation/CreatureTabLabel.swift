//
//  CreatureTabLabel.swift
//  DesignKit
//
//  The tab bar item of an assistant drawn as ParticleCreature (4.8.0): its still glyph
//  (CreatureGlyph) over a title. A tab item takes only an image and a text, so the live creature
//  waits inside the screen the tab opens.
//

import SwiftUI
import UIKit

/// A tab bar item showing ParticleCreature's still glyph and a title.
///
/// ```swift
/// Tab(value: AppTab.assistant, role: .prominent) { … } label: {
///     CreatureTabLabel(title: String(localized: "tab.assistant"))
/// }
/// ```
public struct CreatureTabLabel: View {
    let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(uiImage: Self.icon)
        }
    }

    private static let icon = CreatureGlyph.templateImage()
}
