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

/// Placeholder of a line of text in a given style: as tall as that style's line (so it grows
/// with Dynamic Type), the bar 70% of it.
///
/// ```swift
/// SkeletonText(AppTypography.h4, width: 140)          // a title
/// SkeletonText(AppTypography.bodySmall, lines: 2)     // a paragraph; the last line is shorter
/// ```
public struct SkeletonText: View {
    let font: Font
    let width: CGFloat?
    let lines: Int

    /// - Parameters:
    ///   - width: The bar's width; full width by default.
    ///   - lines: With more than one, the last line is 60% as wide.
    public init(_ font: Font = AppTypography.body, width: CGFloat? = nil, lines: Int = 1) {
        self.font = font
        self.width = width
        self.lines = max(1, lines)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(0..<lines, id: \.self) { line in
                bar(isLast: line == lines - 1 && lines > 1)
            }
        }
        .frame(maxWidth: width ?? .infinity, alignment: .leading)
        .shimmer()
        .accessibilityHidden(true)
    }

    private func bar(isLast: Bool) -> some View {
        // A hidden line of the style gives the height; the bar is drawn over it, 70% as tall,
        // centred, and 60% as wide on the last line of several.
        Text(verbatim: "Ag")
            .font(font)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(AppColors.bgMuted)
                        .frame(width: proxy.size.width * (isLast ? 0.6 : 1), height: proxy.size.height * 0.7)
                        .frame(maxHeight: .infinity)
                }
            }
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

    /// For a stack of `SkeletonView` / `SkeletonRow` (whose shapes are hidden from VoiceOver):
    /// one element that reads "Loading" (key `skeleton.loading`), so the screen is not silent.
    ///
    /// ```swift
    /// VStack { ForEach(0..<4, id: \.self) { _ in SkeletonRow() } }
    ///     .skeletonLoadingLabel()
    /// ```
    func skeletonLoadingLabel() -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(String(localized: "skeleton.loading", defaultValue: "Loading")))
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
