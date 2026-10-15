//
//  VoiceOrbButton.swift
//  DesignKit
//
//  The stop button while something records the voice (4.14.0): `VoiceWave`'s orb, swelling
//  with the voice, with a small glyph in the middle. At rest the orb is about an 80 pt button;
//  only that circle takes the tap. Ported from Tenra's VoiceStopOrb; the recording, its level
//  and the feature tour's hint stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A breathing orb with ⏹ in the middle; the voice's level makes it swell.
///
/// ```swift
/// VoiceOrbButton(level: recorder.level, accessibilityLabel: "Stop recording") {
///     recorder.stop()
/// }
/// ```
///
/// Keep it in its own small view that reads the level, so the level's updates (about 47 a
/// second) redraw the orb only.
public struct VoiceOrbButton: View {
    let level: Double?
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    /// The orb's canvas: room for it to swell and for its glow.
    public static let size: CGFloat = 144
    /// The tappable circle: the canvas inset to about the orb at rest.
    static let tapInset: CGFloat = 32
    /// The orb at rest: the circle the tap goes round, and the one to anchor a hint to.
    public static let restingDiameter: CGFloat = size - 2 * tapInset

    /// - Parameters:
    ///   - level: The voice's level, 0…1; none lets the orb breathe on its own (a screenshot,
    ///     nothing recording).
    ///   - systemImage: The glyph in the middle, "stop.fill" by default.
    public init(
        level: Double?,
        systemImage: String = "stop.fill",
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.level = level
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VoiceWave(level: level, style: .orb)
                .frame(width: Self.size, height: Self.size)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: AppIconSize.lg))
                        .foregroundStyle(AppColors.staticWhite)
                        .shadow(color: .black.opacity(0.25), radius: 4)
                }
                .contentShape(Circle().inset(by: Self.tapInset))
        }
        .buttonStyle(.bounce)
        .accessibilityLabel(accessibilityLabel)
    }
}
