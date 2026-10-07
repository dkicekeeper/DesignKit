//
//  ThinkingShimmer.swift
//  DesignKit
//
//  Text that shows the app is working on it (2.4.0): a band of aurora colour runs through the
//  words, the way Apple Intelligence writes "Thinking". For "Listening…", "Analysing…", an
//  insight on its way. (A skeleton's shimmer says "content is coming"; this one says "I am
//  working on what you asked".)
//
//  Light: one gradient masked by the text, moved at 30 fps while it is active and motion is
//  allowed. Under Reduce Motion or `.designKitMotion(false)` the text is drawn in the still
//  aurora gradient.
//

import SwiftUI
import DesignTokens

public extension View {
    /// Runs a band of aurora colour through this text while `isActive`.
    ///
    /// ```swift
    /// Text("Listening…")
    ///     .font(AppTypography.h4)
    ///     .foregroundStyle(AppColors.Text.secondary)
    ///     .thinkingShimmer(isActive: voice.isRecording)
    /// ```
    ///
    /// - Parameter colors: The band's colours; by default the accent's aurora palette.
    func thinkingShimmer(isActive: Bool = true, colors: [Color]? = nil) -> some View {
        modifier(ThinkingShimmerModifier(isActive: isActive, colors: colors))
    }
}

enum ThinkingShimmerMetrics {
    /// One pass of the band through the text.
    static let period: Double = 1.8
    /// The band's width, as a share of the text's.
    static let band: CGFloat = 0.7
    static let frameInterval: Double = 1.0 / 30
}

struct ThinkingShimmerModifier: ViewModifier {
    let isActive: Bool
    let colors: [Color]?

    @Environment(\.designKitMotion) private var designKitMotion

    private var palette: [Color] {
        let given = colors ?? []
        return given.isEmpty ? VoiceWave.defaultColors : given
    }

    func body(content: Content) -> some View {
        if isActive {
            AmbientMotionGate { allowsAmbientMotion in
                if allowsAmbientMotion && designKitMotion {
                    TimelineView(.animation(minimumInterval: ThinkingShimmerMetrics.frameInterval)) { timeline in
                        content.overlay {
                            GeometryReader { proxy in
                                band(width: proxy.size.width, at: timeline.date)
                            }
                            .mask(content)
                            .allowsHitTesting(false)
                        }
                    }
                } else {
                    content.overlay {
                        LinearGradient(colors: palette, startPoint: .leading, endPoint: .trailing)
                            .mask(content)
                            .allowsHitTesting(false)
                    }
                }
            }
        } else {
            content
        }
    }

    /// The band, travelling from before the text's leading edge to past its trailing edge.
    private func band(width: CGFloat, at date: Date) -> some View {
        let period = ThinkingShimmerMetrics.period
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        let bandWidth = max(width * ThinkingShimmerMetrics.band, 60)
        let x = -bandWidth + (width + bandWidth) * CGFloat(phase)
        return LinearGradient(colors: [.clear] + palette + [.clear], startPoint: .leading, endPoint: .trailing)
            .frame(width: bandWidth)
            .offset(x: x)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
