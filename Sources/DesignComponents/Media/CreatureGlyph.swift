//
//  CreatureGlyph.swift
//  DesignKit
//
//  ParticleCreature as a still glyph (4.8.0), in one colour. For where the live creature cannot
//  go: a tab bar item (CreatureTabLabel; a tab item takes only an image and a text) and sizes
//  under the compact style's 24 pt.
//  5.2.0 (the owner's variant B): a filled core in a ring of twelve dots, the two capsule eyes
//  cut out of the core. The ring and the eyes alone were too light beside a tab bar's filled
//  symbols.
//

import SwiftUI
import UIKit

/// ParticleCreature as a still, one-colour glyph: a filled core with two capsule eyes cut out of
/// it, in a ring of twelve dots (5.2.0; the ring and the eyes alone before).
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

        let core = side * CreatureGlyphMetrics.coreDiameter
        path.addEllipse(in: CGRect(x: center.x - core / 2, y: center.y - core / 2, width: core, height: core))

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
        var eyes = Path()
        for sign in [-1.0, 1.0] {
            let eye = CGRect(
                x: center.x + sign * eyeOffset - eyeWidth / 2,
                y: center.y - eyeHeight / 2 - eyeLift,
                width: eyeWidth,
                height: eyeHeight
            )
            eyes.addRoundedRect(in: eye, cornerSize: CGSize(width: eyeWidth / 2, height: eyeWidth / 2))
        }
        // Cut out, so a plain `.fill()` and the template image show the eyes as holes.
        return path.subtracting(eyes)
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
    /// Fractions of the square's side (5.2.0: the core, the ring out to the edge, smaller eyes
    /// cut out of the core; 4.8.0's ring was at 0.42 with 0.075 dots and 0.13 × 0.26 eyes).
    public static let coreDiameter: CGFloat = 0.70
    public static let ringRadius: CGFloat = 0.455
    public static let dotDiameter: CGFloat = 0.085
    public static let eyeWidth: CGFloat = 0.11
    public static let eyeHeight: CGFloat = 0.22
    public static let eyeOffset: CGFloat = 0.11
    public static let eyeLift: CGFloat = 0.02
    /// A tab bar item's image.
    public static let tabIconSize: CGFloat = 26
}
