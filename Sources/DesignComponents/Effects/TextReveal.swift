//
//  TextReveal.swift
//  DesignKit
//
//  Text that writes itself in (2.2.0): each glyph rises a little, sharpens from a blur and
//  fades in, one after another. For text that arrives: an insight's summary, an answer, an
//  onboarding line, a result.
//
//  Light: a TextRenderer draws the laid-out text once per frame with a per-glyph offset,
//  blur and opacity; nothing is split into views and the layout never changes (the text has
//  its final size from the first frame). It runs only while the reveal plays.
//
//  • .textReveal                — a transition: `if shown { Text(…).transition(.textReveal) }`
//  • .textRevealOnAppear()      — reveals the text when it first appears.
//
//  Under Reduce Motion or `.designKitMotion(false)` the text fades in as a whole.
//  (`.blurSlideHero` stays the block-level text transition.)
//

import SwiftUI
import DesignTokens

public extension View {
    /// Reveals the text inside glyph by glyph when it first appears, over `duration`.
    ///
    /// ```swift
    /// Text(insight.summary).textRevealOnAppear()
    /// ```
    func textRevealOnAppear(duration: Double = TextRevealMetrics.duration) -> some View {
        modifier(TextRevealOnAppearModifier(duration: duration))
    }
}

/// Glyph by glyph in, faded out.
public struct TextRevealTransition: Transition {
    let duration: Double

    public init(duration: Double = TextRevealMetrics.duration) {
        self.duration = duration
    }

    public static var properties: TransitionProperties {
        TransitionProperties(hasMotion: true)
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        let elapsed = phase.isIdentity ? duration : 0
        content.transaction { transaction in
            if !transaction.disablesAnimations {
                transaction.animation = .linear(duration: duration)
            }
        } body: { view in
            view.modifier(TextRevealRendering(elapsed: elapsed, duration: duration))
        }
    }
}

public extension Transition where Self == TextRevealTransition {
    /// Text written in glyph by glyph (rising, sharpening, fading in).
    static var textReveal: TextRevealTransition { TextRevealTransition() }
}

public enum TextRevealMetrics {
    /// The whole reveal, however long the text.
    public static let duration: Double = 0.9
    /// One glyph's own animation.
    static let glyphDuration: Double = 0.4
}

// MARK: - Rendering

/// Applies the renderer when motion is allowed; otherwise fades the whole text.
private struct TextRevealRendering: ViewModifier {
    let elapsed: Double
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        if !reduceMotion && designKitMotion {
            content.textRenderer(GlyphRevealRenderer(elapsedTime: elapsed, totalDuration: duration))
        } else {
            content.opacity(elapsed >= duration ? 1 : 0)
        }
    }
}

private struct TextRevealOnAppearModifier: ViewModifier {
    let duration: Double

    @State private var elapsed: Double = 0
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .modifier(TextRevealRendering(elapsed: elapsed, duration: duration))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.linear(duration: duration)) {
                    elapsed = duration
                }
            }
    }
}

/// Draws each glyph by the time since the reveal began: later glyphs start later, each
/// rising from below its baseline with a spring, sharpening and fading in.
struct GlyphRevealRenderer: TextRenderer, Animatable {
    var elapsedTime: Double
    let totalDuration: Double

    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    private var glyphDuration: Double { min(TextRevealMetrics.glyphDuration, totalDuration) }
    private var spring: Spring { .snappy(duration: glyphDuration - 0.05, extraBounce: 0.3) }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { line in line.flatMap { run in run } }
        // The glyphs start one after another so the last one ends with the reveal.
        let delay = slices.count > 1 ? (totalDuration - glyphDuration) / Double(slices.count - 1) : 0
        for (index, slice) in slices.enumerated() {
            let time = max(0, min(elapsedTime - Double(index) * delay, glyphDuration))
            var copy = context
            draw(slice, at: time, in: &copy)
        }
    }

    private func draw(_ slice: Text.Layout.RunSlice, at time: Double, in context: inout GraphicsContext) {
        let progress = glyphDuration > 0 ? time / glyphDuration : 1
        let bounds = slice.typographicBounds
        let opacity = UnitCurve.easeIn.value(at: min(1, 1.4 * progress))
        let blur = bounds.rect.height / 16 * UnitCurve.easeIn.value(at: 1 - progress)
        let rise = spring.value(fromValue: bounds.descent, toValue: 0, initialVelocity: 0, time: time)
        context.translateBy(x: 0, y: rise)
        context.addFilter(.blur(radius: blur))
        context.opacity = opacity
        context.draw(slice, options: .disablesSubpixelQuantization)
    }
}
