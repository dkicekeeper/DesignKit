//
//  Spotlight.swift
//  DesignKit
//
//  A coach mark (2.6.0): the screen dims except a cut-out round one view, with a message in a
//  Tooltip next to it. For showing a new feature or the steps of an onboarding tour on the real
//  screen. (Material: feature discovery; HIG: TipKit for tips, this for a guided tour.)
//
//  Mark views with `.spotlightAnchor(id)`; put `.spotlight($current)` on the screen. Setting
//  `current` to another id moves the cut-out there; `nil` lifts it. A tap anywhere calls
//  `onTap` (the next step), or lifts it.
//
//  The cut-out moves on a spring (a fade under Reduce Motion). VoiceOver reads the message and
//  can dismiss it with the escape gesture.
//

import SwiftUI
import DesignTokens

public extension View {
    /// Marks this view as one the spotlight can point at.
    func spotlightAnchor<ID: Hashable>(_ id: ID) -> some View {
        anchorPreference(key: SpotlightAnchorsKey.self, value: .bounds) { [AnyHashable(id): $0] }
    }

    /// Dims this view except the anchor `current` names, with `message(id)` beside it.
    ///
    /// ```swift
    /// HomeScreen()
    ///     .spotlight($tourStep, message: { step in step.text }) {
    ///         tourStep = tourStep?.next
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - cornerRadius: The cut-out's corner; `AppRadius.xl` matches a card.
    ///   - padding: Room between the view and the cut-out's edge.
    ///   - onTap: A tap anywhere; `nil` lifts the spotlight.
    func spotlight<ID: Hashable>(
        _ current: Binding<ID?>,
        message: ((ID) -> String)? = nil,
        cornerRadius: CGFloat = AppRadius.xl,
        padding: CGFloat = AppSpacing.sm,
        onTap: (() -> Void)? = nil
    ) -> some View {
        overlayPreferenceValue(SpotlightAnchorsKey.self) { anchors in
            SpotlightOverlay(
                current: current,
                anchors: anchors,
                message: message,
                cornerRadius: cornerRadius,
                padding: padding,
                onTap: onTap
            )
        }
    }
}

struct SpotlightAnchorsKey: PreferenceKey {
    static let defaultValue: [AnyHashable: Anchor<CGRect>] = [:]

    static func reduce(value: inout [AnyHashable: Anchor<CGRect>], nextValue: () -> [AnyHashable: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

enum SpotlightMetrics {
    /// How dark the rest of the screen goes.
    static let dim: Double = 0.55
    /// Room between the cut-out and the message.
    static let gap: CGFloat = AppSpacing.sm
    /// The message's widest line.
    static let messageWidth: CGFloat = 280
}

private struct SpotlightOverlay<ID: Hashable>: View {
    @Binding var current: ID?
    let anchors: [AnyHashable: Anchor<CGRect>]
    let message: ((ID) -> String)?
    let cornerRadius: CGFloat
    let padding: CGFloat
    let onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let hole = current
                .flatMap { anchors[AnyHashable($0)] }
                .map { proxy[$0].insetBy(dx: -padding, dy: -padding) }
            ZStack(alignment: .topLeading) {
                if let hole, let current {
                    SpotlightShape(hole: hole, cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(SpotlightMetrics.dim), style: FillStyle(eoFill: true))
                        .contentShape(Rectangle())
                        .onTapGesture { tap() }
                        .transition(.opacity)
                    if let text = message?(current) {
                        bubble(text, hole: hole, in: proxy.size)
                    }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : AppAnimation.smooth, value: hole)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { current = nil }
        }
    }

    private func tap() {
        if let onTap { onTap() } else { current = nil }
    }

    /// The message under the cut-out, or over it when the cut-out sits low.
    @ViewBuilder
    private func bubble(_ text: String, hole: CGRect, in size: CGSize) -> some View {
        let below = hole.midY < size.height * 0.6
        Tooltip(arrowEdge: below ? .top : .bottom) {
            Text(verbatim: text)
                .font(AppTypography.bodySmall)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: SpotlightMetrics.messageWidth)
        .fixedSize(horizontal: false, vertical: true)
        .alignmentGuide(.top) { dimensions in
            below ? -(hole.maxY + SpotlightMetrics.gap) : -(hole.minY - SpotlightMetrics.gap - dimensions.height)
        }
        .alignmentGuide(.leading) { dimensions in
            let x = min(max(hole.midX - dimensions.width / 2, AppSpacing.lg), size.width - dimensions.width - AppSpacing.lg)
            return -x
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

/// A full rectangle with a rounded hole, filled even-odd; the hole animates.
struct SpotlightShape: Shape {
    var hole: CGRect
    let cornerRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(hole.minX, hole.minY), AnimatablePair(hole.width, hole.height)) }
        set { hole = CGRect(x: newValue.first.first, y: newValue.first.second, width: newValue.second.first, height: newValue.second.second) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect.insetBy(dx: -2000, dy: -2000))
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: cornerRadius, height: cornerRadius), style: .continuous)
        return path
    }
}
