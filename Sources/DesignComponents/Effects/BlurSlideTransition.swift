//
//  BlurSlideTransition.swift
//  Tenra
//
//  Canonical text-reveal transition. Insertion: slides up from below +
//  un-blurs + fades in. Removal: keeps sliding up off-screen + blurs +
//  fades out. Originally built for the onboarding hero title/subtitle
//  loop; now the shared style for any animated text appearance.
//
//  Use the presets instead of hand-tuning parameters:
//  • `.blurSlideHero` — block-level text (onboarding title/subtitle).
//  • `.blurSlideWord` — per-word streaming text (voice transcription).
//    Deliberately shorter travel + lighter blur: many words can be
//    transitioning at once and per-word blur is the dominant GPU cost.
//

import SwiftUI
import DesignTokens
import DesignSupport

public struct BlurSlideTransition: Transition {
    var slideDistance: CGFloat = 24
    var blurRadius: CGFloat = 10

    public init(
        slideDistance: CGFloat = 24,
        blurRadius: CGFloat = 10
    ) {
        self.slideDistance = slideDistance
        self.blurRadius = blurRadius
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        let yOffset: CGFloat = {
            switch phase {
            case .willAppear: return slideDistance      // start below identity
            case .identity: return 0
            case .didDisappear: return -slideDistance   // exit upward
            }
        }()

        return content
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : blurRadius)
            .offset(y: yOffset)
    }
}

public extension Transition where Self == BlurSlideTransition {
    /// Block-level text reveal — onboarding hero title/subtitle blocks.
    static var blurSlideHero: BlurSlideTransition { BlurSlideTransition() }

    /// Per-word reveal for streaming text (voice transcription).
    /// Shorter travel + lighter blur than `blurSlideHero` — tuned for many
    /// small views transitioning simultaneously.
    static var blurSlideWord: BlurSlideTransition {
        BlurSlideTransition(slideDistance: 18, blurRadius: 6)
    }
}

// MARK: - Preview
