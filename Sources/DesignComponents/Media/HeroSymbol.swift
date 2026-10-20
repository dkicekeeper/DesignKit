//
//  HeroSymbol.swift
//  DesignKit
//
//  Large SF Symbol on a soft tinted disc: the picture at the top of an onboarding page or a
//  permission primer. Moved here from Dalada's intro pages (0.7.0) so both screens match.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A symbol centred in a circle of its tint at 12% opacity.
///
/// ```swift
/// HeroSymbol(systemImage: "bell.badge")
/// HeroSymbol(systemImage: "map", size: 96, tint: AppColors.success)
/// ```
///
/// Decorative: hidden from VoiceOver, the title next to it says what it is.
public struct HeroSymbol: View {
    let systemImage: String
    let size: CGFloat
    let tint: Color?
    let drawsOnAppear: Bool

    /// - Parameters:
    ///   - size: diameter of the disc; the symbol is 3/7 of it.
    ///   - tint: symbol and disc colour, `AppColors.accent` by default.
    ///   - drawsOnAppear: The symbol draws itself on as the hero appears (2.2.0, SF Symbols
    ///     Draw; symbols without draw data just appear). Still under Reduce Motion.
    public init(systemImage: String, size: CGFloat = 140, tint: Color? = nil, drawsOnAppear: Bool = true) {
        self.systemImage = systemImage
        self.size = size
        self.tint = tint
        self.drawsOnAppear = drawsOnAppear
    }

    public var body: some View {
        let color = tint ?? AppColors.accent
        // A tile (6.2.0): its disc is the plate, the symbol 3/7 of it.
        Icon(
            source: .sfSymbol(systemImage),
            style: .circle(size: size, tint: .monochrome(color), backgroundColor: AppColors.pale(color), padding: size * 2 / 7)
        )
        // 2.3.0: SF Symbols 7 gradient: the tint lightens across the symbol, for depth.
        .symbolColorRenderingMode(.gradient)
        .drawOnAppear(delay: HeroSymbolMetrics.drawDelay, isEnabled: drawsOnAppear)
    }
}

enum HeroSymbolMetrics {
    /// The disc shows first; the symbol draws in once the sheet or page has settled.
    static let drawDelay: Double = 0.15
}

// MARK: - Skeleton

/// Placeholder of a `HeroSymbol`: its disc.
public struct HeroSymbolSkeleton: View {
    let size: CGFloat

    public init(size: CGFloat = 140) {
        self.size = size
    }

    public var body: some View {
        Skeleton.circle(size)
            .skeletonLoadingLabel()
    }
}
