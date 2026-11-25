//
//  SurfaceStyleTests.swift
//  DesignKit
//
//  8.12.0: surfaces as Liquid Glass or a grey fill. The environment's default is the app's hook,
//  and the neutral greys follow the style (the card's own grey must not be what lies on it).
//

import SwiftUI
import Testing
@testable import DesignTokens
import DesignSupport

@Suite("Surface style")
struct SurfaceStyleTests {
    @Test("The environment's default is DesignKitTheme.surface, read when asked")
    func environmentDefault() {
        let saved = DesignKitTheme.surface
        defer { DesignKitTheme.surface = saved }

        DesignKitTheme.surface = .glass
        #expect(EnvironmentValues().surfaceStyle == .glass)
        DesignKitTheme.surface = .fill
        #expect(EnvironmentValues().surfaceStyle == .fill)

        var values = EnvironmentValues()
        values.surfaceStyle = .glass
        #expect(values.surfaceStyle == .glass)
    }

    @Test("On glass the neutrals are the tokens; under .fill, translucent fills, not the card's grey")
    func neutrals() {
        #expect(SurfaceStyle.glass.neutral1 == AppColors.Background.neutral1)
        #expect(SurfaceStyle.glass.neutral2 == AppColors.Background.neutral2)
        #expect(SurfaceStyle.fill.neutral1 == AppColors.Background.fill)
        #expect(SurfaceStyle.fill.neutral1 != AppColors.Background.neutral1)
        #expect(SurfaceStyle.fill.neutral2 != AppColors.Background.neutral2)
    }

    /// A ring or disc that cuts a shape out (`.surfaceBackground`) is the colour of what lies
    /// under it: the page, or the grey of a `.fill` card, never white on grey.
    @Test("A knockout is the page's colour off a card")
    func surfaceBackgroundDefaultsToPage() {
        var values = EnvironmentValues()
        values.surfaceStyle = .fill
        #expect(values.surfaceBackground == AppColors.Background.base)
    }

    @Test("On a grey card a knockout is the card's grey")
    func surfaceBackgroundFollowsCard() {
        var values = EnvironmentValues()
        values.surfaceStyle = .fill
        values.isOnCard = true
        #expect(values.surfaceBackground == AppColors.Background.neutral1)
    }

    @Test("On a glass card a knockout stays the page's colour")
    func surfaceBackgroundOnGlassCard() {
        var values = EnvironmentValues()
        values.surfaceStyle = .glass
        values.isOnCard = true
        #expect(values.surfaceBackground == AppColors.Background.base)
        #expect(SurfaceBackground().resolve(in: values) == AppColors.Background.base)
    }

    /// `Icon` maps a preset's plate to the surface's grey by comparing it with the token.
    @Test("The icon presets' plates compare equal to the neutral token")
    func iconPresetPlates() {
        #expect(IconStyle.categoryIcon().backgroundColor == AppColors.Background.neutral1)
        #expect(IconStyle.placeholder(size: AppIconSize.Tile.sm).backgroundColor == AppColors.Background.neutral1)
    }
}
