//
//  GallerySettings.swift
//  DesignKit Gallery
//
//  What the Gallery shows its components with (vNext): the app's preset (accent and surfaces),
//  and the canvas's text size, direction and width. One object for the session, so the home
//  screen's menu and every canvas's app switch set the same preset, and a whole section can be
//  read in AX3 or right to left by paging through it.
//

import SwiftUI
import Observation
import DesignTokens

/// The apps that consume DesignKit, as presets of the Gallery (8.21.0: accent and surfaces
/// together, as each app sets them), and a custom accent to try one.
enum GalleryTheme: String, CaseIterable, Identifiable {
    case tenra = "Tenra"
    case dalada = "Dalada"
    case platina = "Platina"
    case custom = "Custom"

    var id: String { rawValue }

    /// The three apps, the canvas's switch.
    static let apps: [GalleryTheme] = [.tenra, .dalada, .platina]

    /// The app's accent; the custom one is the Gallery's own state.
    var accent: Color? {
        switch self {
        case .tenra: return .indigo
        // Dalada's AccentColor (light #2E8B57 / dark #3CB371).
        case .dalada: return Self.pair(light: (0x2E, 0x8B, 0x57), dark: (0x3C, 0xB3, 0x71))
        // Platina's Plasma (8.21.0; #3573BA before): light #D6006F / dark #FF4FA0.
        case .platina: return Self.pair(light: (0xD6, 0x00, 0x6F), dark: (0xFF, 0x4F, 0xA0))
        case .custom: return nil
        }
    }

    /// The app's surfaces: Tenra keeps Liquid Glass, Dalada and Platina draw grey cards.
    var surface: SurfaceStyle? {
        switch self {
        case .tenra: return .glass
        case .dalada, .platina: return .fill
        case .custom: return nil
        }
    }

    private static func pair(light: (Int, Int, Int), dark: (Int, Int, Int)) -> Color {
        Color(UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(rgb.0) / 255, green: CGFloat(rgb.1) / 255, blue: CGFloat(rgb.2) / 255, alpha: 1)
        })
    }
}

/// How wide the canvas draws its component on a wide screen (vNext): as on a phone, in a
/// screen's readable column, or across the whole page.
enum CanvasWidth: String, CaseIterable, Identifiable {
    case phone = "Phone"
    case column = "Column"
    case full = "Full width"

    var id: String { rawValue }

    /// The widest the component gets; nil, the canvas's own width.
    var maxWidth: CGFloat? {
        switch self {
        case .phone: 393
        case .column: AppLayout.readableWidth
        case .full: nil
        }
    }

    var systemImage: String {
        switch self {
        case .phone: "iphone"
        case .column: "rectangle.center.inset.filled"
        case .full: "rectangle"
        }
    }
}

extension DynamicTypeSize {
    /// The canvas's short name for the size: "L" (the system's default), "XXL", "AX3".
    var galleryLabel: String {
        switch self {
        case .xSmall: "xS"
        case .small: "S"
        case .medium: "M"
        case .large: "L"
        case .xLarge: "XL"
        case .xxLarge: "XXL"
        case .xxxLarge: "XXXL"
        case .accessibility1: "AX1"
        case .accessibility2: "AX2"
        case .accessibility3: "AX3"
        case .accessibility4: "AX4"
        case .accessibility5: "AX5"
        @unknown default: "?"
        }
    }
}

/// The Gallery's preset and canvas settings for the session.
@MainActor
@Observable
final class GallerySettings {
    static let shared = GallerySettings()

    /// The app whose accent and surfaces the components show.
    private(set) var theme: GalleryTheme = .tenra
    /// The surfaces of every page (8.12.0): the preset's, or the custom choice.
    private(set) var surface: SurfaceStyle = .glass
    /// The custom preset's accent (8.21.0).
    private(set) var customAccent: Color = .orange
    /// Grows each time the accent or the surfaces change. `DesignKitTheme.accent` is a static
    /// read, so the views that show it and keep no state worth keeping take this as their `.id`
    /// (`.galleryRefreshes()`) and draw again; the page around them stays open.
    private(set) var renderKey = 0

    /// The canvas's text size (vNext); nil follows the device's, as the page around it does.
    var textSize: DynamicTypeSize?
    /// The canvas lays out right to left (vNext), as in Arabic or Hebrew.
    var isRightToLeft = false
    /// How wide the canvas draws on a wide screen (vNext).
    var canvasWidth: CanvasWidth = .full

    /// Whether the canvas shows anything but the defaults: its bar says so.
    var changesCanvas: Bool { textSize != nil || isRightToLeft || canvasWidth != .full }

    /// An app's preset: its accent and surfaces together. The custom one keeps its own.
    func select(_ newTheme: GalleryTheme) {
        let newSurface = newTheme.surface ?? surface
        // Set the statics BEFORE the state change, so the views drawn again read them.
        DesignKitTheme.accent = newTheme.accent ?? customAccent
        DesignKitTheme.surface = newSurface
        surface = newSurface
        theme = newTheme
        renderKey += 1
    }

    /// The custom preset with this accent.
    func setCustomAccent(_ color: Color) {
        DesignKitTheme.accent = color
        customAccent = color
        theme = .custom
        renderKey += 1
    }

    /// The custom preset with these surfaces.
    func setCustomSurface(_ newSurface: SurfaceStyle) {
        DesignKitTheme.accent = customAccent
        DesignKitTheme.surface = newSurface
        surface = newSurface
        theme = .custom
        renderKey += 1
    }

    /// The canvas as it opens: the device's text size, left to right, full width.
    func resetCanvas() {
        textSize = nil
        isRightToLeft = false
        canvasWidth = .full
    }
}

extension View {
    /// Draws the view again when the preset changes (vNext), for a view that keeps no state worth
    /// keeping: it takes `GallerySettings.renderKey` as its identity.
    func galleryRefreshes() -> some View {
        modifier(GalleryRefresh())
    }
}

private struct GalleryRefresh: ViewModifier {
    func body(content: Content) -> some View {
        content.id(GallerySettings.shared.renderKey)
    }
}
