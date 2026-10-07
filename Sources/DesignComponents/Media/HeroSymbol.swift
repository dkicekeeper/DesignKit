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

    /// - Parameters:
    ///   - size: diameter of the disc; the symbol is 3/7 of it.
    ///   - tint: symbol and disc colour, `AppColors.accent` by default.
    public init(systemImage: String, size: CGFloat = 140, tint: Color? = nil) {
        self.systemImage = systemImage
        self.size = size
        self.tint = tint
    }

    public var body: some View {
        let color = tint ?? AppColors.accent
        Image(systemName: systemImage)
            .font(.system(size: size * 3 / 7))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(AppColors.pale(color), in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Skeleton

/// Placeholder of a `HeroSymbol`: its disc.
public struct HeroSymbolSkeleton: View {
    let size: CGFloat

    public init(size: CGFloat = 140) {
        self.size = size
    }

    public var body: some View {
        SkeletonView.circle(size)
            .skeletonLoadingLabel()
    }
}
