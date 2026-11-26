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
    /// Liquid Glass (the default): Tenra's look.
    case glass
    /// An opaque grey, `AppColors.Background.card` (`#F2F2F7` on the white page, `#1C1C1E` on
    /// black, a step lighter in a dark sheet), with no glass. The containers inside it (an icon's
    /// plate, a track, a skeleton) turn translucent so they still read on the grey:
    /// `AppColors.Background.container` / `.containerStrong`. Platina's and Dalada's look. (Named
    /// `.solid` from 9.0.0, so "fill" means one thing.)
    case fill
}

public extension SurfaceStyle {
    /// A container inside a card on this surface (vNext): a field, an icon's plate, an inactive
    /// chip. On glass the opaque grey `AppColors.Background.card`; under `.fill`, where that grey
    /// is the card itself, the translucent `tertiarySystemFill`, a step darker than whatever lies
    /// under it (the page, a grey card, a card in a sheet). The colour behind the shape style
    /// `AppColors.Background.container`, for an API that takes a `Color`.
    var container: Color {
        switch self {
        case .glass: return AppColors.Background.card
        case .fill: return ContainerColors.onFill
        }
    }

    /// A stronger container inside a card on this surface (vNext): a progress track, a skeleton,
    /// a sunken control. On glass the opaque `systemGray5`; under `.fill` the translucent
    /// `secondarySystemFill`, which stays a step darker than a grey card in a dark sheet too.
    var containerStrong: Color {
        switch self {
        case .glass: return ContainerColors.strongOnGlass
        case .fill: return ContainerColors.strongOnFill
        }
    }

    /// `AppColors.Background.neutral1` as it reads on this surface.
    @available(*, deprecated, renamed: "container", message: "Use SurfaceStyle.container.")
    var neutral1: Color { container }

    /// `AppColors.Background.neutral2` as it reads on this surface.
    @available(*, deprecated, renamed: "containerStrong", message: "Use SurfaceStyle.containerStrong.")
    var neutral2: Color { containerStrong }
}

/// One instance of each container colour, so a preset's plate compares equal to it (`Icon`).
private enum ContainerColors {
    nonisolated static let onFill = Color(.tertiarySystemFill)
    nonisolated static let strongOnGlass = Color(.systemGray5)
    nonisolated static let strongOnFill = Color(.secondarySystemFill)
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

extension EnvironmentValues {
    /// Set by `cardStyle()` on its content (8.20.0): the views below lie on a card, so a knockout
    /// takes the card's colour (`surfaceBackground`).
    @Entry var isOnCard = false
}

package extension View {
    /// The view starts again on a page (8.20.0): a sheet presented from a row inside a card
    /// inherits the card's environment, so DesignKit's sheets put this on their root and their
    /// knockouts take the sheet's colour, not the card's.
    func startsOnPage() -> some View {
        environment(\.isOnCard, false)
    }
}

public extension EnvironmentValues {
    /// The opaque colour of the surface a view lies on (8.20.0): the page's
    /// (`AppColors.Background.page`), or, inside a `cardStyle()` card under `SurfaceStyle.fill`,
    /// the card's grey (`AppColors.Background.card`, raised in a dark sheet as the card is).
    /// On a glass card it stays the page's colour, which the glass lets through.
    ///
    /// For a ring or a disc that cuts a shape out of whatever lies under it: the ring between
    /// avatars, a chart's point, a gauge's tick, a badge over an icon. Read it in a `Canvas` or a
    /// `TextRenderer`; elsewhere use the shape style `.surfaceBackground`.
    ///
    /// A sheet inherits the environment of the view it is presented from: DesignKit's sheets
    /// (`EditSheetContainer`, `PromptSheet`, `DateRangePickerSheet`, `ShareCardSheet`) start again
    /// on the page; an app's own sheet presented from inside a card draws its knockouts on the
    /// sheet's page in the card's grey.
    var surfaceBackground: Color {
        isOnCard && surfaceStyle == .fill ? AppColors.Background.card : AppColors.Background.page
    }
}

/// The colour of the surface under a view, as a shape style (8.20.0): `EnvironmentValues
/// .surfaceBackground`, the page's colour or a grey card's. For knockouts, so a grey card shows
/// no white rings.
///
/// ```swift
/// avatar.overlay(Circle().stroke(.surfaceBackground, lineWidth: 2))
/// ```
public struct SurfaceBackground: ShapeStyle {
    public init() {}

    public func resolve(in environment: EnvironmentValues) -> Color {
        environment.surfaceBackground
    }
}

public extension ShapeStyle where Self == SurfaceBackground {
    /// The colour of the surface under the view: the page's or a grey card's (`SurfaceBackground`).
    static var surfaceBackground: SurfaceBackground { SurfaceBackground() }
}

public extension View {
    /// Draws DesignKit's surfaces below as `style` (8.12.0): a glass card over a photo in an app
    /// of grey cards, or one grey screen in an app of glass. The app's own choice is
    /// `DesignKitTheme.surface`.
    func surfaceStyle(_ style: SurfaceStyle) -> some View {
        environment(\.surfaceStyle, style)
    }
}

// MARK: - Containers that follow the surface

/// A container that keeps reading on the surface it lies on (vNext): opaque grey on glass,
/// translucent on a grey `.fill` card (`SurfaceStyle.container` / `.containerStrong`). Resolved
/// from the view's `surfaceStyle`, so a `.surfaceStyle(_:)` above it counts. Reached as
/// `AppColors.Background.container` / `.containerStrong`.
///
/// ```swift
/// Capsule().fill(AppColors.Background.containerStrong)                    // a track
/// Text("New").padding(8).background(AppColors.Background.container, in: Capsule())
/// ```
public struct SurfaceContainer: ShapeStyle {
    /// Which container: `standard` (fields, plates, chips) or `strong` (tracks, skeletons).
    public enum Level: Hashable, Sendable {
        case standard
        case strong
    }

    public let level: Level

    public init(_ level: Level) {
        self.level = level
    }

    public func resolve(in environment: EnvironmentValues) -> Color {
        switch level {
        case .standard: return environment.surfaceStyle.container
        case .strong: return environment.surfaceStyle.containerStrong
        }
    }
}

/// A neutral grey that keeps reading on the surface it lies on (8.12.0). Deprecated (vNext):
/// `AppColors.Background.container` / `.containerStrong` (`SurfaceContainer`).
public struct SurfaceNeutral: ShapeStyle {
    /// Which neutral: `neutral1` (fields, plates, chips) or `neutral2` (tracks, skeletons).
    public enum Level: Hashable, Sendable {
        case neutral1
        case neutral2
    }

    public let level: Level

    @available(*, deprecated, message: "Use AppColors.Background.container or .containerStrong.")
    public init(_ level: Level) {
        self.level = level
    }

    public func resolve(in environment: EnvironmentValues) -> Color {
        switch level {
        case .neutral1: return environment.surfaceStyle.container
        case .neutral2: return environment.surfaceStyle.containerStrong
        }
    }
}

public extension ShapeStyle where Self == SurfaceNeutral {
    /// A container that reads on a grey card too.
    @available(*, deprecated, message: "Use AppColors.Background.container.")
    static var surfaceNeutral1: SurfaceNeutral { SurfaceNeutral(.neutral1) }
    /// A stronger container that reads on a grey card too.
    @available(*, deprecated, message: "Use AppColors.Background.containerStrong.")
    static var surfaceNeutral2: SurfaceNeutral { SurfaceNeutral(.neutral2) }
}
