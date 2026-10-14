//
//  CreatureGlyph.swift
//  DesignKit
//
//  ParticleCreature as a still glyph (4.7.0): twelve dots in a ring and two capsule eyes, in one
//  colour. For where the live creature cannot go: a tab bar item (CreatureTabLabel; a tab item
//  takes only an image and a text) and sizes under the compact style's 24 pt.
//

import SwiftUI
import UIKit

/// ParticleCreature as a still, one-colour glyph: twelve dots in a ring and two capsule eyes.
///
/// ```swift
/// CreatureGlyph()
///     .fill(AppColors.accent)
///     .frame(width: 22, height: 22)
/// Image(uiImage: CreatureGlyph.templateImage())     // a tab bar item, tinted by the bar
/// ```
public struct CreatureGlyph: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        let ring = side * CreatureGlyphMetrics.ringRadius
        let dot = side * CreatureGlyphMetrics.dotDiameter
        for index in 0..<CreatureGlyphMetrics.dotCount {
            let angle = Double(index) / Double(CreatureGlyphMetrics.dotCount) * 2 * .pi
            let point = CGPoint(x: center.x + ring * cos(angle), y: center.y + ring * sin(angle))
            path.addEllipse(in: CGRect(x: point.x - dot / 2, y: point.y - dot / 2, width: dot, height: dot))
        }

        let eyeWidth = side * CreatureGlyphMetrics.eyeWidth
        let eyeHeight = side * CreatureGlyphMetrics.eyeHeight
        let eyeOffset = side * CreatureGlyphMetrics.eyeOffset
        let eyeLift = side * CreatureGlyphMetrics.eyeLift
        for sign in [-1.0, 1.0] {
            let eye = CGRect(
                x: center.x + sign * eyeOffset - eyeWidth / 2,
                y: center.y - eyeHeight / 2 - eyeLift,
                width: eyeWidth,
                height: eyeHeight
            )
            path.addRoundedRect(in: eye, cornerSize: CGSize(width: eyeWidth / 2, height: eyeWidth / 2))
        }
        return path
    }

    /// The glyph as a template image, which the bar or the button holding it tints.
    public static func templateImage(size: CGFloat = CreatureGlyphMetrics.tabIconSize) -> UIImage {
        let bounds = CGRect(x: 0, y: 0, width: size, height: size)
        let image = UIGraphicsImageRenderer(size: bounds.size).image { _ in
            // A mask: only the alpha counts, the template rendering gives the colour.
            UIColor.black.setFill()
            UIBezierPath(cgPath: CreatureGlyph().path(in: bounds).cgPath).fill()
        }
        return image.withRenderingMode(.alwaysTemplate)
    }
}

public enum CreatureGlyphMetrics {
    public static let dotCount = 12
    /// Fractions of the square's side.
    public static let ringRadius: CGFloat = 0.42
    public static let dotDiameter: CGFloat = 0.075
    public static let eyeWidth: CGFloat = 0.13
    public static let eyeHeight: CGFloat = 0.26
    public static let eyeOffset: CGFloat = 0.13
    public static let eyeLift: CGFloat = 0.02
    /// A tab bar item's image.
    public static let tabIconSize: CGFloat = 26
}
