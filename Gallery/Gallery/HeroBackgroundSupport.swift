//
//  HeroBackgroundSupport.swift
//  DesignKit Gallery
//
//  A hero piece's page shows it on the page or on a hero's colour (`.heroBackground`, 4.5.0):
//  the "Background" control, and the specimen wrapped in the colour on a `.bleed` canvas (which
//  clips the colour that runs up and down past the hero).
//

import SwiftUI
import DesignTokens
import DesignComponents

extension View {
    /// On `onColor`, the specimen on a hero's gradient of `color`, padded as a hero is.
    @ViewBuilder
    func galleryHeroBackground(_ onColor: Bool, color: Color = AppColors.success) -> some View {
        if onColor {
            frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .heroBackground(color)
        } else {
            self
        }
    }
}

/// "Page" or "Colour".
struct HeroBackgroundControl: View {
    @Binding var onColor: Bool

    var body: some View {
        ChoiceControl("Background", selection: $onColor, options: [("Page", false), ("Colour", true)])
    }
}
