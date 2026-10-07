//
//  IconSkeleton.swift
//  DesignKit
//
//  Placeholder of an `Icon` (a brand logo too): the icon's size and shape, grey.
//  `Icon` lives in DesignSupport; its skeleton needs the skeleton primitives, so it lives
//  here.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An icon that is still loading: a circle, the style's rounded square or a square.
///
/// ```swift
/// IconSkeleton()                                   // like Icon(source:) — a 44 pt circle
/// IconSkeleton(style: .roundedSquare(size: 40))    // the corner of that style
/// ```
public struct IconSkeleton: View {
    let style: IconStyle

    /// The shape and size of an icon drawn with `style`.
    public init(style: IconStyle) {
        self.style = style
    }

    /// Like `Icon(source:size:)`: a circle.
    public init(size: CGFloat = AppIconSize.Tile.sm) {
        self.style = .circle(size: size)
    }

    public var body: some View {
        Skeleton(height: style.size, width: style.size, cornerRadius: cornerRadius)
            .skeletonLoadingLabel()
    }

    private var cornerRadius: CGFloat {
        switch style.shape {
        case .circle: return style.size / 2
        case .roundedSquare(let radius): return radius
        case .square: return 0
        }
    }
}

// MARK: - Names before 2.0

@available(*, deprecated, renamed: "IconSkeleton")
public typealias IconViewSkeleton = IconSkeleton
