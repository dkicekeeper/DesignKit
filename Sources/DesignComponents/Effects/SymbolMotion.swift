//
//  SymbolMotion.swift
//  DesignKit
//
//  SF Symbols' own animations, by meaning (2.2.0). A symbol effect is the cheapest motion
//  there is: the system draws it, it follows the symbol's layers, and it costs no layout.
//  These modifiers name what the motion says, so the same thing moves the same way everywhere:
//
//  • drawOnAppear  — a symbol drawn on as it appears (SF Symbols 7's Draw): an empty state,
//                    a hero, a completed step. Symbols without draw data simply appear.
//  • symbolCue     — one beat when something happens: `.bounce` confirms, `.wiggle` asks for
//                    attention (an error, a ringing bell).
//  • symbolPulse   — a loop while a state lasts: `.breathe` for live (recording, sharing a
//                    location), `.working` for layers lighting in turn (searching, syncing).
//
//  All of them stop under Reduce Motion and with `.designKitMotion(false)`; the symbol is then
//  drawn still, in its final state. Loops also stop while the system asks apps to save
//  resources (AmbientMotionGate).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One beat of a symbol when something happens.
public enum SymbolCue: Hashable, Sendable {
    /// A confirmation: done, added, selected.
    case bounce
    /// Attention: an error, a warning, a bell that rings.
    case wiggle
}

/// A symbol's loop while a state lasts.
public enum SymbolPulse: Hashable, Sendable {
    /// Something live: recording, sharing a location, a connection open.
    case breathe
    /// Work in progress: the layers light in turn (searching, syncing, waiting for a reply).
    case working
}

public extension View {
    /// Draws the SF Symbols inside on as the view appears (iOS 26 Draw On). Symbols without
    /// draw data appear without it. No motion under Reduce Motion or `.designKitMotion(false)`.
    ///
    /// ```swift
    /// Image(systemName: "checkmark.seal.fill").drawOnAppear()
    /// HeroSymbol(systemImage: "map")             // draws its symbol on by default
    /// ```
    func drawOnAppear(delay: Double = 0, isEnabled: Bool = true) -> some View {
        modifier(DrawOnAppearModifier(delay: delay, isEnabled: isEnabled))
    }

    /// Plays `cue` on the SF Symbols inside each time `trigger` changes.
    ///
    /// ```swift
    /// Image(systemName: "bell.fill").symbolCue(.wiggle, trigger: unreadCount)
    /// ```
    func symbolCue<Trigger: Equatable>(_ cue: SymbolCue, trigger: Trigger) -> some View {
        modifier(SymbolCueModifier(cue: cue, trigger: trigger))
    }

    /// Plays `cue` once, `delay` after the view appears: a banner's icon as it slides in.
    /// `nil` plays nothing (a status with no cue of its own).
    func symbolCueOnAppear(_ cue: SymbolCue?, delay: Double = MotionBudget.entrance) -> some View {
        modifier(SymbolCueOnAppearModifier(cue: cue, delay: delay))
    }

    /// Loops `pulse` on the SF Symbols inside while `isActive`.
    ///
    /// ```swift
    /// Image(systemName: "mic.fill").symbolPulse(.breathe, isActive: isRecording)
    /// Image(systemName: "arrow.triangle.2.circlepath").symbolPulse(.working, isActive: isSyncing)
    /// ```
    func symbolPulse(_ pulse: SymbolPulse, isActive: Bool = true) -> some View {
        modifier(SymbolPulseModifier(pulse: pulse, isActive: isActive))
    }

    /// Swaps one symbol for another with Magic Replace: a badge or a slash draws itself
    /// (`eye` ↔ `eye.slash`, `circle` ↔ `checkmark.circle.fill`); other pairs cross-fade.
    func symbolMagicReplace() -> some View {
        contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
    }
}

// MARK: - Modifiers

/// Whether DesignKit may move things here: Reduce Motion off and `designKitMotion` on.
private struct MotionAllowance {
    let reduceMotion: Bool
    let designKitMotion: Bool
    var allowsMotion: Bool { !reduceMotion && designKitMotion }
}

private struct DrawOnAppearModifier: ViewModifier {
    let delay: Double
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    /// `true` until the view has appeared: the symbol waits undrawn.
    @State private var isWaiting = true

    private var plays: Bool { isEnabled && !reduceMotion && designKitMotion }

    func body(content: Content) -> some View {
        content
            // Active = not drawn yet; turning it off draws the symbol on.
            .symbolEffect(.drawOn, isActive: plays && isWaiting)
            .task {
                guard plays, isWaiting else { return }
                if delay > 0 {
                    try? await Task.sleep(for: .seconds(delay))
                }
                isWaiting = false
            }
    }
}

private struct SymbolCueModifier<Trigger: Equatable>: ViewModifier {
    let cue: SymbolCue
    let trigger: Trigger

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        if reduceMotion || !designKitMotion {
            content
        } else {
            switch cue {
            case .bounce:
                content.symbolEffect(.bounce, value: trigger)
            case .wiggle:
                content.symbolEffect(.wiggle, value: trigger)
            }
        }
    }
}

private struct SymbolCueOnAppearModifier: ViewModifier {
    let cue: SymbolCue?
    let delay: Double

    @State private var beats = 0

    func body(content: Content) -> some View {
        Group {
            if let cue {
                content.symbolCue(cue, trigger: beats)
            } else {
                content
            }
        }
        .task {
                guard cue != nil, beats == 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                beats += 1
            }
    }
}

private struct SymbolPulseModifier: ViewModifier {
    let pulse: SymbolPulse
    let isActive: Bool

    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        // A loop is ambient motion: Reduce Motion and (iOS 27) the system's request to save
        // resources stop it, through the one gate the other loops use.
        AmbientMotionGate { allowsAmbientMotion in
            let plays = isActive && allowsAmbientMotion && designKitMotion
            switch pulse {
            case .breathe:
                content.symbolEffect(.breathe, isActive: plays)
            case .working:
                content.symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: plays)
            }
        }
    }
}
