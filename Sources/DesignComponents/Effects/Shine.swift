//
//  Shine.swift
//  DesignKit
//
//  Two one-shot highlights that point at something new (2.2.0):
//  • .shine(trigger:in:)          — a band of light sweeps across a shape once: a card just
//                                   added, a premium badge, an achievement unlocked.
//  • .attentionPulse(trigger:in:) — two rings spread from a shape and fade: a new feature, a
//                                   control the user should notice (a coach mark without text).
//
//  Each plays for under a second and leaves nothing running. Neither plays under Reduce Motion
//  or `.designKitMotion(false)`.
//

import SwiftUI
import DesignTokens

public extension View {
    /// A band of light sweeps across `shape` once each time `trigger` changes.
    ///
    /// ```swift
    /// BalanceCard(…).shine(trigger: justAdded, in: RoundedRectangle(cornerRadius: AppRadius.xl))
    /// Badge("Pro", style: .filled).shine(trigger: isUnlocked, in: Capsule())
    /// ```
    func shine<Trigger: Equatable, S: Shape>(trigger: Trigger, in shape: S) -> some View {
        modifier(ShineModifier(trigger: trigger, shape: shape))
    }

    /// A band of light sweeps across the view's card shape (`AppRadius.xl`) once each time
    /// `trigger` changes.
    func shine<Trigger: Equatable>(trigger: Trigger) -> some View {
        shine(trigger: trigger, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    /// Two rings spread from `shape` and fade each time `trigger` changes.
    ///
    /// ```swift
    /// DSButton("Scan", systemImage: "doc.viewfinder", iconPlacement: .only) { scan() }
    ///     .attentionPulse(trigger: showsHint, in: Circle())
    /// ```
    func attentionPulse<Trigger: Equatable, S: Shape>(
        trigger: Trigger,
        in shape: S,
        tint: Color = AppColors.accent
    ) -> some View {
        modifier(AttentionPulseModifier(trigger: trigger, shape: shape, tint: tint))
    }
}

// MARK: - Shine

private struct ShineModifier<Trigger: Equatable, S: Shape>: ViewModifier {
    let trigger: Trigger
    let shape: S

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    /// Where the band is: −1 before the leading edge, 1 past the trailing one.
    @State private var position: CGFloat = -1
    @State private var isShining = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isShining {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [.clear, .white.opacity(ShineMetrics.peakOpacity), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * ShineMetrics.bandWidth, height: proxy.size.height * 2)
                        .rotationEffect(.degrees(ShineMetrics.angle))
                        .offset(x: position * width * ShineMetrics.travel)
                        .frame(width: width, height: proxy.size.height)
                    }
                    .clipShape(shape)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .onChange(of: trigger) {
                guard !reduceMotion, designKitMotion else { return }
                position = -1
                isShining = true
                Task { @MainActor in
                    // One frame with the band at the start, then the sweep.
                    await Task.yield()
                    withAnimation(.easeInOut(duration: ShineMetrics.duration)) {
                        position = 1
                    } completion: {
                        isShining = false
                    }
                }
            }
    }
}

enum ShineMetrics {
    static let duration: Double = 0.8
    /// The band's width, as a share of the view's.
    static let bandWidth: CGFloat = 0.45
    static let angle: Double = 20
    /// How far the band travels each way, as a share of the width: past both edges.
    static let travel: CGFloat = 0.85
    static let peakOpacity: Double = 0.55
}

// MARK: - Attention pulse

private struct AttentionPulseModifier<Trigger: Equatable, S: Shape>: ViewModifier {
    let trigger: Trigger
    let shape: S
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion

    func body(content: Content) -> some View {
        content
            .background {
                if !reduceMotion && designKitMotion {
                    ZStack {
                        ring(delay: 0)
                        ring(delay: AttentionPulseMetrics.secondRingDelay)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }

    /// At rest the ring is invisible at the shape's size; a trigger shows it and spreads it
    /// out while it fades, then it snaps back unseen.
    private func ring(delay: Double) -> some View {
        shape
            .stroke(tint, lineWidth: AttentionPulseMetrics.lineWidth)
            .phaseAnimator(AttentionPulsePhase.allCases, trigger: trigger) { ring, phase in
                ring
                    .scaleEffect(phase.scale)
                    .opacity(phase.opacity)
            } animation: { phase in
                switch phase {
                case .rest, .shown: .linear(duration: 0.01)
                case .spread: .easeOut(duration: AttentionPulseMetrics.duration).delay(delay)
                }
            }
    }
}

private enum AttentionPulsePhase: CaseIterable {
    case rest, shown, spread

    var scale: CGFloat {
        switch self {
        case .rest, .shown: 1
        case .spread: AttentionPulseMetrics.spreadScale
        }
    }

    var opacity: Double {
        switch self {
        case .rest, .spread: 0
        case .shown: 0.6
        }
    }
}

enum AttentionPulseMetrics {
    static let duration: Double = 0.9
    static let spreadScale: CGFloat = 1.6
    static let lineWidth: CGFloat = 2
    static let secondRingDelay: Double = 0.2
}
