//
//  AppSurface.swift
//  DesignKit
//
//  8.12.0: how the design system draws its surfaces, Liquid Glass or a grey fill. An app on the
//  white page that wants less glass (Platina) sets `DesignKitTheme.surface = .fill` once; Tenra and
//  Dalada keep the glass, the default.
//

import SwiftUI

/// How DesignKit draws a surface: the card behind `cardStyle()` and everything built on it
/// (`FormSection`, `CardList`, the cards), the filter chip, a tile's glass circle, the glass
/// plate of an `Icon`, a banner.
///
/// Set it for the whole app with `DesignKitTheme.surface`, or for a subtree with
/// `.surfaceStyle(_:)`. Controls (`DSButton`, `.buttonStyle(.glass)`), the chrome that floats
/// over content (`MessageComposer`, `GlassActionMenu`, the system's bars) and glass drawn as an
/// effect on a coloured hero (`.glassBar`, `OrbChart`) stay Liquid Glass under both.
public enum SurfaceStyle: Hashable, Sendable {
    /// Liquid Glass (the default): Tenra's and Dalada's look.
    case glass
    /// An opaque grey, `AppColors.Background.neutral1` (`#F2F2F7` on the white page, `#1C1C1E` on
    /// black, a step lighter in a dark sheet), with no glass. The neutral containers inside it
    /// (an icon's plate, a track, a skeleton) turn translucent so they still read on the grey:
    /// `SurfaceStyle.neutral1` / `.neutral2`, `.surfaceNeutral1` / `.surfaceNeutral2`.
    case fill
}

public extension SurfaceStyle {
    /// `AppColors.Background.neutral1` as it reads on this surface: itself on glass; under
    /// `.fill`, where it is the card's own grey, the translucent `AppColors.Background.fill`
    /// (`tertiarySystemFill`), a step darker than whatever lies under it (the page, a grey card,
    /// a card in a sheet). Fields, an icon's plate, an inactive chip.
    var neutral1: Color {
        switch self {
        case .glass: return AppColors.Background.neutral1
        case .fill: return AppColors.Background.fill
        }
    }

    /// `AppColors.Background.neutral2` as it reads on this surface: itself on glass; under
    /// `.fill` the translucent `secondarySystemFill`, which stays a step darker than a grey card
    /// in a dark sheet too (where the opaque `neutral2` is the card's own colour). Progress
    /// tracks, skeletons, sunken controls.
    var neutral2: Color {
        switch self {
        case .glass: return AppColors.Background.neutral2
        case .fill: return Color(.secondarySystemFill)
        }
    }
}

// MARK: - Environment

private struct SurfaceStyleKey: EnvironmentKey {
    /// Read when nothing above sets it: the app's choice, `DesignKitTheme.surface`.
    static var defaultValue: SurfaceStyle { DesignKitTheme.surface }
}

public extension EnvironmentValues {
    /// How DesignKit's surfaces draw below (8.12.0): `DesignKitTheme.surface` unless a view
    /// above sets `.surfaceStyle(_:)`.
    var surfaceStyle: SurfaceStyle {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }
}

public extension View {
    /// Draws DesignKit's surfaces below as `style` (8.12.0): a glass card over a photo in an app
    /// of grey cards, or one grey screen in an app of glass. The app's own choice is
    /// `DesignKitTheme.surface`.
    func surfaceStyle(_ style: SurfaceStyle) -> some View {
        environment(\.surfaceStyle, style)
    }
}

// MARK: - Neutral fills that follow the surface

/// A neutral grey that keeps reading on the surface it lies on (8.12.0): `neutral1` or
/// `neutral2` while surfaces are glass, their translucent fills under `SurfaceStyle.fill`
/// (`SurfaceStyle.neutral1` / `.neutral2`). Resolved from the view's `surfaceStyle`, so a
/// `.surfaceStyle(_:)` above it counts.
///
/// ```swift
/// Capsule().fill(.surfaceNeutral2)                         // a track
/// Text("New").padding(8).background(.surfaceNeutral1, in: Capsule())
/// ```
public struct SurfaceNeutral: ShapeStyle {
    /// Which neutral: `neutral1` (fields, plates, chips) or `neutral2` (tracks, skeletons).
    public enum Level: Hashable, Sendable {
        case neutral1
        case neutral2
    }

    public let level: Level

    public init(_ level: Level) {
        self.level = level
    }

    public func resolve(in environment: EnvironmentValues) -> Color {
        switch level {
        case .neutral1: return environment.surfaceStyle.neutral1
        case .neutral2: return environment.surfaceStyle.neutral2
        }
    }
}

public extension ShapeStyle where Self == SurfaceNeutral {
    /// `AppColors.Background.neutral1` that reads on a grey card too (`SurfaceNeutral`).
    static var surfaceNeutral1: SurfaceNeutral { SurfaceNeutral(.neutral1) }
    /// `AppColors.Background.neutral2` that reads on a grey card too (`SurfaceNeutral`).
    static var surfaceNeutral2: SurfaceNeutral { SurfaceNeutral(.neutral2) }
}
