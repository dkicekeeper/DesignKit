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
/// It shows a value that is already loaded, on a tap, so it has no skeleton.
public struct Tooltip<Content: View>: View {
    let arrowEdge: VerticalEdge
    let content: Content

    /// - Parameter arrowEdge: the edge of the bubble the tail sticks out of: `.bottom` for a
    ///   tooltip above its target, `.top` for one below it.
    public init(arrowEdge: VerticalEdge = .bottom, @ViewBuilder content: () -> Content) {
        self.arrowEdge = arrowEdge
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            if arrowEdge == .top {
                tail
                    .rotationEffect(.degrees(180))
                    .padding(.bottom, -TooltipMetrics.tailOverlap)
            }
            content
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    AppColors.Background.elevation3,
                    in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                )
            if arrowEdge == .bottom {
                tail
                    .padding(.top, -TooltipMetrics.tailOverlap)
            }
        }
        .compositingGroup()
        .shadow(color: TooltipMetrics.shadowColor, radius: TooltipMetrics.shadowRadius, y: TooltipMetrics.shadowY)
        .fixedSize()
    }

    private var tail: some View {
        TooltipTail()
            .fill(AppColors.Background.elevation3)
            // Its base reaches into the bubble so no seam shows between them.
            .frame(width: TooltipMetrics.tailWidth, height: TooltipMetrics.tailHeight + TooltipMetrics.tailOverlap)
    }
}

public extension Tooltip where Content == Text {
    /// A tooltip with a line of text.
    init(_ text: String, arrowEdge: VerticalEdge = .bottom) {
        self.init(arrowEdge: arrowEdge) { Text(verbatim: text) }
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
    static let tailHeight: CGFloat = 7
    static let tailOverlap: CGFloat = 1
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 2
    static let shadowColor = Color.black.opacity(0.15)
}
