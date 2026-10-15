//
//  EdgeBackdrop.swift
//  DesignKit
//
//  The backing of a bar over scrolling content (4.14.0): the content under it blurs and the
//  page's colour lies over it, both strongest at the screen's edge and fading to nothing at the
//  bar's inner edge, so what the bar holds reads on any content without a solid plate. The iOS
//  bar backing, drawn by hand where the system's scroll edge effect is too faint to carry a large
//  bar (Tenra's chat: Ten hangs 120 pt over the thread). SwiftUI has no blur of varying radius,
//  so one ultra-thin material, full near the edge, fades out towards the content: the blurred
//  content gives way to the sharp one. The page's colour over it is light (25% at the edge), so
//  the blurred content's colours show through (the owner's review: blur, not a plate; a second
//  material and a 45% tint still read as a grey plate).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Blur and the page's colour under a bar, fading out towards the content.
///
/// ```swift
/// ScrollView { … }
///     .safeAreaBar(edge: .top) {
///         Header()
///             .frame(maxWidth: .infinity)
///             .edgeBackdrop(.top)
///     }
/// ```
///
/// It reaches past the safe area to the screen's edge (under the status bar and the navigation
/// bar), takes no touches and is hidden from VoiceOver.
public struct EdgeBackdrop: View {
    let edge: VerticalEdge
    let color: Color

    /// - Parameters:
    ///   - edge: The screen edge the bar sits on: the backing is strongest there.
    ///   - color: The page's colour, laid over the blur (the system background by default).
    public init(edge: VerticalEdge = .top, color: Color = AppColors.bgBase) {
        self.edge = edge
        self.color = color
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask { fade(EdgeBackdropMetrics.blurStops) }
            LinearGradient(
                stops: EdgeBackdropMetrics.tintStops.map { .init(color: color.opacity($0.opacity), location: $0.location) },
                startPoint: start,
                endPoint: end
            )
        }
        .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var start: UnitPoint { edge == .top ? .top : .bottom }
    private var end: UnitPoint { edge == .top ? .bottom : .top }

    /// A mask from opaque at the edge to clear, through the given stops.
    private func fade(_ stops: [EdgeBackdropMetrics.Stop]) -> LinearGradient {
        LinearGradient(
            stops: stops.map { .init(color: .black.opacity($0.opacity), location: $0.location) },
            startPoint: start,
            endPoint: end
        )
    }
}

/// How an `EdgeBackdrop` fades: opacity at each share of its height, from the screen's edge.
public enum EdgeBackdropMetrics {
    public struct Stop: Sendable {
        public let location: CGFloat
        public let opacity: Double
    }

    /// The blur: full over the half nearest the edge, gone at the inner edge.
    static let blurStops = [Stop(location: 0, opacity: 1), Stop(location: 0.5, opacity: 1), Stop(location: 1, opacity: 0)]
    /// The page's colour over the blur, light so the blurred content's colours show: 25% at the
    /// edge, 10% at two fifths, clear at three quarters.
    static let tintStops = [Stop(location: 0, opacity: 0.25), Stop(location: 0.4, opacity: 0.1), Stop(location: 0.75, opacity: 0)]
}

public extension View {
    /// Puts an `EdgeBackdrop` behind the view: a bar's backing over scrolling content, blur and
    /// the page's colour fading out towards the content.
    func edgeBackdrop(_ edge: VerticalEdge = .top, color: Color = AppColors.bgBase) -> some View {
        background {
            EdgeBackdrop(edge: edge, color: color)
        }
    }
}
