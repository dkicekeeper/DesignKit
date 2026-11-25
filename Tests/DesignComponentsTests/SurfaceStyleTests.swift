//
//  SurfaceStyleTests.swift
//  DesignKit
//
//  8.12.0: surfaces as Liquid Glass or a grey fill. The environment's default is the app's hook,
//  and the neutral greys follow the style (the card's own grey must not be what lies on it).
//

import SwiftUI
import UIKit
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

    private static func rgba(_ color: Color, _ style: UIUserInterfaceStyle) -> [Int] {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a].map { Int(($0 * 255).rounded()) }
    }

    /// vNext: the roles are today's colours under new names, so nothing an app draws changes.
    @Test("The background roles keep today's values", arguments: [UIUserInterfaceStyle.light, .dark])
    func rolesKeepTodaysValues(style: UIUserInterfaceStyle) {
        #expect(Self.rgba(AppColors.Background.page, style) == Self.rgba(Color(.systemBackground), style))
        #expect(Self.rgba(AppColors.Background.card, style) == Self.rgba(Color(.secondarySystemBackground), style))
        let dark = style == .dark
        #expect(Self.rgba(AppColors.Background.sheet, style) == (dark ? [28, 28, 28, 255] : [255, 255, 255, 255]))
        #expect(Self.rgba(AppColors.Background.floating, style) == (dark ? [58, 58, 58, 255] : [255, 255, 255, 255]))
    }

    /// A container inside a card is opaque on glass and translucent on a grey card, as the
    /// neutrals were (the owner's decision: the look does not change).
    @Test("The container follows the surface", arguments: [UIUserInterfaceStyle.light, .dark])
    func containerFollowsSurface(style: UIUserInterfaceStyle) {
        #expect(Self.rgba(SurfaceStyle.glass.container, style) == Self.rgba(AppColors.Background.card, style))
        #expect(Self.rgba(SurfaceStyle.glass.containerStrong, style) == Self.rgba(Color(.systemGray5), style))
        #expect(Self.rgba(SurfaceStyle.fill.container, style) == Self.rgba(Color(.tertiarySystemFill), style))
        #expect(Self.rgba(SurfaceStyle.fill.containerStrong, style) == Self.rgba(Color(.secondarySystemFill), style))

        var values = EnvironmentValues()
        values.surfaceStyle = .fill
        #expect(Self.rgba(AppColors.Background.container.resolve(in: values), style)
                == Self.rgba(Color(.tertiarySystemFill), style))
        values.surfaceStyle = .glass
        #expect(Self.rgba(AppColors.Background.containerStrong.resolve(in: values), style)
                == Self.rgba(Color(.systemGray5), style))
    }

    /// A ring or disc that cuts a shape out (`.surfaceBackground`) is the colour of what lies
    /// under it: the page, or the grey of a `.fill` card, never white on grey.
    @Test("A knockout is the page's colour off a card")
    func surfaceBackgroundDefaultsToPage() {
        var values = EnvironmentValues()
        values.surfaceStyle = .fill
        #expect(values.surfaceBackground == AppColors.Background.page)
    }

    @Test("On a grey card a knockout is the card's grey")
    func surfaceBackgroundFollowsCard() {
        var values = EnvironmentValues()
        values.surfaceStyle = .fill
        values.isOnCard = true
        #expect(values.surfaceBackground == AppColors.Background.card)
    }

    @Test("On a glass card a knockout stays the page's colour")
    func surfaceBackgroundOnGlassCard() {
        var values = EnvironmentValues()
        values.surfaceStyle = .glass
        values.isOnCard = true
        #expect(values.surfaceBackground == AppColors.Background.page)
        #expect(SurfaceBackground().resolve(in: values) == AppColors.Background.page)
    }

    /// `Icon` maps a preset's plate to the surface's grey by comparing it with the token.
    @Test("The icon presets' plates compare equal to the neutral token")
    func iconPresetPlates() {
        #expect(IconStyle.categoryIcon().backgroundColor == SurfaceStyle.glass.container)
        #expect(IconStyle.placeholder(size: AppIconSize.Tile.sm).backgroundColor == SurfaceStyle.glass.container)
    }
}
