//
//  RefreshIndicator.swift
//  DesignKit
//
//  vNext: the mercury of `.dsRefreshable`, drawn. Black liquid runs out of the Dynamic Island,
//  turns the accent below it, breaks into six beads that circle while loading and flows back
//  into the island. Without an island it runs, all accent, from the top edge. The shape is
//  `RefreshDropletGeometry`; here a blur and an alpha threshold melt its circles into one liquid
//  that masks a black-to-accent gradient. Under Reduce Motion (or `.designKitMotion(false)`) an
//  accent ring instead.
//

import SwiftUI
import UIKit
import DesignTokens

/// The indicator of a pull to refresh, in a phase (vNext). `.dsRefreshable` lays it over a
/// scroll view and drives it; use it yourself only to show a phase (the Gallery, a header of
/// your own).
///
/// ```swift
/// RefreshIndicator(phase: .refreshing(elapsed: 0.4), source: .island)
///     .frame(height: 140)
/// ```
public struct RefreshIndicator: View {
    /// Where the liquid comes from.
    public enum Source: Hashable, Sendable {
        /// The Dynamic Island when the device has one and the view starts at the screen's top;
        /// the top edge otherwise.
        case automatic
        /// The island of a 393 pt iPhone, wherever the view is (previews, the Gallery).
        case island
        /// Above the view's top edge, all accent.
        case topEdge
    }

    let phase: RefreshPhase
    let source: Source

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.heroTone) private var heroTone
    /// Where the indicator sits in its window: read from UIKit, since the safe area SwiftUI
    /// reports under a navigation bar includes the bar.
    @State private var window = WindowMetrics()

    public init(phase: RefreshPhase, source: Source = .automatic) {
        self.phase = phase
        self.source = source
    }

    public var body: some View {
        GeometryReader { proxy in
            let resolved = sourceRect(width: proxy.size.width)
            Group {
                if reduceMotion || !designKitMotion {
                    ring(source: resolved.rect)
                } else {
                    liquid(source: resolved.rect, fromIsland: resolved.isIsland, size: proxy.size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .background {
            if source == .automatic {
                WindowMetricsReader(metrics: $window)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Source

    private func sourceRect(width: CGFloat) -> (rect: CGRect, isIsland: Bool) {
        let island: CGRect?
        switch source {
        case .island:
            island = DynamicIslandFrame.frame(safeAreaTop: 59, screenWidth: width, isPhone: true,
                                              isPortrait: true, overlayMinY: 0)
        case .topEdge:
            island = nil
        case .automatic:
            island = DynamicIslandFrame.frame(
                safeAreaTop: window.safeAreaTop,
                screenWidth: window.width,
                isPhone: window.isPhone && abs(window.minX) <= 1,
                isPortrait: window.isPortrait,
                overlayMinY: window.minY
            )
        }
        return island.map { ($0, true) } ?? (DynamicIslandFrame.edge(width: width), false)
    }

    // MARK: Liquid

    private func liquid(source: CGRect, fromIsland: Bool, size: CGSize) -> some View {
        let frame = RefreshDropletGeometry.frame(for: phase, source: source)
        let drawsSource = phase != .idle
        let mask = Canvas { context, _ in
            context.addFilter(.alphaThreshold(min: 0.5))
            context.addFilter(.blur(radius: RefreshMetrics.blur))
            context.drawLayer { layer in
                if drawsSource {
                    let width = source.width * frame.sourceScale
                    let blob = CGRect(x: source.midX - width / 2, y: source.minY, width: width, height: source.height)
                    layer.fill(Path(roundedRect: blob, cornerRadius: source.height / 2), with: .color(.black))
                }
                for circle in frame.all where circle.radius > 0 {
                    layer.fill(Path(ellipseIn: CGRect(x: circle.center.x - circle.radius, y: circle.center.y - circle.radius,
                                                      width: circle.radius * 2, height: circle.radius * 2)),
                               with: .color(.black))
                }
            }
        }
        let height = max(size.height, 1)
        let black = fromIsland ? min(max(source.maxY / height, 0), 1) : 0
        let accent = fromIsland ? min(max((source.maxY + RefreshMetrics.gradientRun) / height, 0), 1) : 0
        let gradient = LinearGradient(
            stops: [.init(color: .black, location: black), .init(color: AppColors.accent, location: accent)],
            startPoint: .top, endPoint: .bottom
        )
        return ZStack(alignment: .topLeading) {
            if heroTone == .onColor {
                // On a coloured hero the beads would melt into a colour like their own: a soft
                // shadow under them, not under the thread at the island.
                mask
                    .opacity(RefreshMetrics.shadowOpacity)
                    .blur(radius: RefreshMetrics.shadowRadius)
                    .offset(y: RefreshMetrics.shadowY)
                    .mask(alignment: .top) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: source.maxY + 6)
                            Color.black
                        }
                    }
            }
            Rectangle()
                .fill(gradient)
                .mask { mask }
        }
    }

    // MARK: Reduce Motion

    private func ring(source: CGRect) -> some View {
        let diameter = RefreshMetrics.reduceMotionRing
        let (trim, angle, opacity): (Double, Double, Double) = {
            switch phase {
            case .idle: return (0, 0, 0)
            case .pulling(let progress, _): return (min(max(progress, 0), 1), -90, min(max(progress, 0), 1))
            case .refreshing(let elapsed): return (0.3, elapsed * 360, 1)
            case .finishing(let elapsed): return (0.3, elapsed * 360, max(0, 1 - elapsed / 0.3))
            }
        }()
        return ZStack {
            Circle().stroke(AppColors.Background.containerStrong, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: trim)
                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(angle))
        }
        .frame(width: diameter, height: diameter)
        .opacity(opacity)
        .position(x: source.midX, y: source.maxY + RefreshMetrics.ringDepth)
    }
}

// MARK: - The window

/// Where a view sits in its window: the window's own top safe area (the status bar, without a
/// navigation bar), the view's top-left corner in the window, the window's width, its idiom and
/// orientation.
struct WindowMetrics: Equatable {
    var safeAreaTop: CGFloat = 0
    var width: CGFloat = 0
    var minX: CGFloat = 0
    var minY: CGFloat = .infinity
    var isPhone = false
    var isPortrait = true
}

/// Reports `WindowMetrics` from UIKit as the view moves or lays out. No `UIApplication`:
/// DesignKit builds for app extensions too.
struct WindowMetricsReader: UIViewRepresentable {
    @Binding var metrics: WindowMetrics

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.isUserInteractionEnabled = false
        view.onChange = { metrics = $0 }
        return view
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onChange = { metrics = $0 }
    }

    final class ReaderView: UIView {
        var onChange: ((WindowMetrics) -> Void)?
        private var last: WindowMetrics?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            report()
        }

        private func report() {
            guard let window else { return }
            let frame = convert(bounds, to: window)
            let metrics = WindowMetrics(
                safeAreaTop: window.safeAreaInsets.top,
                width: window.bounds.width,
                minX: frame.minX,
                minY: frame.minY,
                isPhone: traitCollection.userInterfaceIdiom == .phone,
                isPortrait: window.bounds.height >= window.bounds.width
            )
            guard metrics != last else { return }
            last = metrics
            // Not during the layout pass that asked: the state change lays out again.
            DispatchQueue.main.async { [weak self] in self?.onChange?(metrics) }
        }
    }
}
