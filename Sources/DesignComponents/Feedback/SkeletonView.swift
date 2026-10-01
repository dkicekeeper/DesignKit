//
//  SkeletonView.swift
//  DesignKit
//
//  Loading placeholders: grey shapes in the layout of the content that is coming, with a
//  slow shimmer. Every large design system has them (Polaris Skeleton, Carbon skeleton
//  states, Atlassian Skeleton, Fluent Shimmer); both apps showed a spinner instead.
//
//  The shimmer is ambient motion: it stops under Reduce Motion (and, on iOS 27, when the
//  system asks apps to save resources) via AmbientMotionGate, leaving a static placeholder.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// One placeholder shape.
///
/// ```swift
/// SkeletonView(height: 14, width: 120)                 // a line of text
/// SkeletonView(height: 40, width: 40, cornerRadius: 20) // an avatar
/// SkeletonView(height: 160)                            // an image, full width
/// ```
public struct SkeletonView: View {
    let height: CGFloat
    let width: CGFloat?
    let cornerRadius: CGFloat

    public init(height: CGFloat = 14, width: CGFloat? = nil, cornerRadius: CGFloat = AppRadius.xs) {
        self.height = height
        self.width = width
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.bgMuted)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .shimmer()
            .accessibilityHidden(true)
    }
}

/// Placeholder of a list row: a round icon and two lines of text.
///
/// ```swift
/// if isLoading { ForEach(0..<5) { _ in SkeletonRow() } }
/// ```
public struct SkeletonRow: View {
    let showsIcon: Bool

    public init(showsIcon: Bool = true) {
        self.showsIcon = showsIcon
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            if showsIcon {
                SkeletonView(height: AppIconSize.avatar, width: AppIconSize.avatar, cornerRadius: AppIconSize.avatar / 2)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonView(height: 14, width: 160)
                SkeletonView(height: 12, width: 100)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.sm)
        .accessibilityHidden(true)
    }
}

public extension View {
    /// Shows this view as a placeholder while `isLoading`: text and images become grey
    /// shapes (`.redacted(.placeholder)`) with a shimmer, and taps are ignored. Lay out the
    /// real view with sample data so the placeholder has the right shape.
    ///
    /// ```swift
    /// TripRow(trip: trip ?? .placeholder)
    ///     .skeleton(isLoading: trip == nil)
    /// ```
    ///
    /// VoiceOver hears the loading label (key `skeleton.loading`, default "Loading").
    @ViewBuilder
    func skeleton(isLoading: Bool) -> some View {
        if isLoading {
            self
                .redacted(reason: .placeholder)
                .shimmer()
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(String(localized: "skeleton.loading", defaultValue: "Loading")))
        } else {
            self
        }
    }

    /// A light band sweeping across the view every 1.4 s. Static under Reduce Motion.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        AmbientMotionGate { allowsMotion in
            if allowsMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    content.overlay {
                        GeometryReader { proxy in
                            band(width: proxy.size.width, at: context.date)
                        }
                        .mask(content)
                        .allowsHitTesting(false)
                    }
                }
            } else {
                content
            }
        }
    }

    /// Phase 0…1 over a 1.4 s cycle; the band travels from left of the view to its right.
    private func band(width: CGFloat, at date: Date) -> some View {
        let period = 1.4
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        let bandWidth = max(width * 0.6, 80)
        let x = -bandWidth + (width + bandWidth) * phase
        return LinearGradient(
            colors: [.clear, AppColors.staticWhite.opacity(0.35), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: bandWidth)
        .offset(x: x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
