//
//  Tooltip.swift
//  DesignKit
//
//  A short value or hint in an opaque bubble with a tail pointing at what it is about: the
//  amount over a tapped bar, a one-line explanation over a control. (Material: plain tooltip;
//  Atlassian: Tooltip; Fluent: Tooltip.) 2.0.0, from HeroBarPair's amount pill, which was pale
//  and see-through and ran into the text above the bars.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An opaque bubble on the top level surface (`AppColors.Background.elevation3`) with a soft
/// shadow and a tail.
///
/// ```swift
/// Tooltip("1 250 000 ₸")
/// Tooltip("Pending", arrowEdge: .top)
/// Tooltip(arrowEdge: .bottom) {
///     Text(amount).font(AppTypography.numbers(AppTypography.bodySmall.bold())).foregroundStyle(tint)
/// }
/// ```
///
/// Place it over its target with an overlay so it never moves the layout, and give its
/// target a higher `zIndex` than its neighbours so the bubble stays on top:
///
/// ```swift
/// bar
///     .overlay(alignment: .top) {
///         Tooltip(amount).tooltipAnchor(.top)   // its tail touches the bar's top edge
///     }
///     .zIndex(isSelected ? 1 : 0)
/// ```
///
/// A target by the edge of the screen (a button in a corner) takes a tail by the bubble's corner
/// (5.5.0), so the bubble runs on to the side that has room; `.tooltipAnchor` still puts the tail
/// over the target's middle:
///
/// ```swift
/// cornerButton
///     .overlay(alignment: .bottom) {
///         Tooltip("Map layers", arrowEdge: .top, arrowAlignment: .trailing).tooltipAnchor(.bottom)
///     }
/// ```
///
/// It shows a value that is already loaded, on a tap, so it has no skeleton.
public struct Tooltip<Content: View>: View {
    let arrowEdge: VerticalEdge
    let arrowAlignment: TooltipArrowAlignment
    let content: Content
    /// How far the tail sits from the middle of a centred one (`arrowShift(_:)`).
    private var shift: CGFloat = 0

    /// - Parameters:
    ///   - arrowEdge: the edge of the bubble the tail sticks out of: `.bottom` for a tooltip
    ///     above its target, `.top` for one below it.
    ///   - arrowAlignment: where the tail sits along that edge (5.5.0): in the middle, or by the
    ///     leading or trailing corner for a target by that edge of the screen.
    public init(
        arrowEdge: VerticalEdge = .bottom,
        arrowAlignment: TooltipArrowAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.arrowEdge = arrowEdge
        self.arrowAlignment = arrowAlignment
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: arrowAlignment.stackAlignment, spacing: 0) {
            if arrowEdge == .top {
                tail(pointsUp: true)
                    .padding(.bottom, -TooltipMetrics.tailOverlap)
            }
            content
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                // A tail by a corner needs the room between it and the corner on both sides.
                .frame(minWidth: arrowAlignment == .center ? nil : TooltipMetrics.tailInset * 2 + TooltipMetrics.tailWidth)
                .background(
                    AppColors.Background.elevation3,
                    in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                )
            if arrowEdge == .bottom {
                tail(pointsUp: false)
                    .padding(.top, -TooltipMetrics.tailOverlap)
            }
        }
        .compositingGroup()
        .shadow(color: TooltipMetrics.shadowColor, radius: TooltipMetrics.shadowRadius, y: TooltipMetrics.shadowY)
        .fixedSize()
        // The middle a centred overlay lines up with the target's is the tail's.
        .alignmentGuide(HorizontalAlignment.center) { dimensions in
            switch arrowAlignment {
            case .leading: TooltipMetrics.tailInset + TooltipMetrics.tailWidth / 2
            case .center: dimensions.width / 2
            case .trailing: dimensions.width - TooltipMetrics.tailInset - TooltipMetrics.tailWidth / 2
            }
        }
    }

    /// The triangle turns on its own, so its place along the edge stays on the side it is set.
    private func tail(pointsUp: Bool) -> some View {
        TooltipTail()
            .fill(AppColors.Background.elevation3)
            // Its base reaches into the bubble so no seam shows between them.
            .frame(width: TooltipMetrics.tailWidth, height: TooltipMetrics.tailHeight + TooltipMetrics.tailOverlap)
            .rotationEffect(.degrees(pointsUp ? 180 : 0))
            .padding(.leading, arrowAlignment == .leading ? TooltipMetrics.tailInset : 0)
            .padding(.trailing, arrowAlignment == .trailing ? TooltipMetrics.tailInset : 0)
            .offset(x: shift)
    }

    /// The tail moved off the middle: `.spotlight` puts it back over a target it had to move the
    /// bubble away from, by the edge of the screen. Layout stays the centred one's.
    func arrowShift(_ shift: CGFloat) -> Tooltip {
        var tooltip = self
        tooltip.shift = shift
        return tooltip
    }
}

/// Where a `Tooltip`'s tail sits along its edge (5.5.0).
public enum TooltipArrowAlignment: Hashable, Sendable {
    /// By the bubble's leading corner: the bubble runs on to the trailing side of its target (a
    /// button at the screen's leading edge).
    case leading
    /// In the middle.
    case center
    /// By the bubble's trailing corner: the bubble runs on to the leading side (a button in the
    /// trailing corner).
    case trailing

    var stackAlignment: HorizontalAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

public extension Tooltip where Content == Text {
    /// A tooltip with a line of text.
    init(_ text: String, arrowEdge: VerticalEdge = .bottom, arrowAlignment: TooltipArrowAlignment = .center) {
        self.init(arrowEdge: arrowEdge, arrowAlignment: arrowAlignment) { Text(verbatim: text) }
    }
}

public extension View {
    /// Aligns a `Tooltip` in an overlay so its tail touches the overlay's `edge`, plus
    /// `gap`: `.overlay(alignment: .top) { Tooltip(…).tooltipAnchor(.top) }` puts the bubble
    /// right above the view, `.overlay(alignment: .bottom) { Tooltip(…, arrowEdge: .top)
    /// .tooltipAnchor(.bottom) }` right below it.
    func tooltipAnchor(_ edge: VerticalEdge, gap: CGFloat = AppSpacing.xs) -> some View {
        switch edge {
        case .top:
            return alignmentGuide(.top) { $0[.bottom] + gap }
        case .bottom:
            return alignmentGuide(.bottom) { $0[.top] - gap }
        }
    }
}

/// A triangle pointing down, with a rounded tip.
private struct TooltipTail: Shape {
    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = 1.5
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + tip, y: rect.maxY - tip))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - tip, y: rect.maxY - tip),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

enum TooltipMetrics {
    static let tailWidth: CGFloat = 14
    /// From a corner tail to its side of the bubble: past the corner's curve (`AppRadius.md`).
    static let tailInset: CGFloat = AppSpacing.md
    static let tailHeight: CGFloat = 7
    static let tailOverlap: CGFloat = 1
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 2
    static let shadowColor = Color.black.opacity(0.15)
}
