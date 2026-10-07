//
//  ActivityTimeline.swift
//  DesignKit
//
//  Vertical list of events joined by a line: check-ins of a trip, the history of a record.
//  (Carbon progress indicator / Atlassian activity feed / Polaris timeline.) Named
//  "Activity" so it does not clash with SwiftUI's TimelineView or WidgetKit's TimelineEntry.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// How an event is marked on the line.
public struct TimelineMarker {
    public var systemImage: String?
    public var color: Color?

    /// - Parameters:
    ///   - systemImage: symbol in a tinted circle; `nil` draws a small dot.
    ///   - color: `AppColors.accent` by default.
    public init(systemImage: String? = nil, color: Color? = nil) {
        self.systemImage = systemImage
        self.color = color
    }

    /// A plain dot in the accent colour.
    public static var dot: TimelineMarker { TimelineMarker() }
}

/// Events top to bottom, each with a marker on a continuous line.
///
/// ```swift
/// ActivityTimeline(trip.checkins) { checkin in
///     TimelineMarker(systemImage: checkin.kind.systemImage, color: checkin.kind.color)
/// } content: { checkin in
///     VStack(alignment: .leading, spacing: AppSpacing.xxs) {
///         Text(checkin.title).font(AppTypography.bodyEmphasis)
///         Text(checkin.date, style: .time).font(AppTypography.caption)
///     }
/// }
/// ```
///
/// Not lazy: for long histories put it in a `ScrollView` and page the data. Each event is one
/// VoiceOver element made of its content.
public struct ActivityTimeline<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let marker: (Item) -> TimelineMarker
    let content: (Item) -> Content

    private static var markerSize: CGFloat { TimelineMetrics.markerSize }
    private static var lineWidth: CGFloat { TimelineMetrics.lineWidth }

    public init(
        _ items: [Item],
        marker: @escaping (Item) -> TimelineMarker = { _ in .dot },
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.marker = marker
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item, isLast: index == items.count - 1)
            }
        }
    }

    private func row(_ item: Item, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            markerView(marker(item))
            content(item)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppSpacing.xxs)
                .padding(.bottom, isLast ? 0 : AppSpacing.lg)
                .accessibilityElement(children: .combine)
        }
        // The line runs from under this marker to the next one, whatever the content height.
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.Background.neutral2)
                    .frame(width: Self.lineWidth)
                    .frame(maxHeight: .infinity)
                    .padding(.top, Self.markerSize)
                    .padding(.leading, (Self.markerSize - Self.lineWidth) / 2)
                    .accessibilityHidden(true)
            }
        }
    }

    private func markerView(_ marker: TimelineMarker) -> some View {
        let color = marker.color ?? AppColors.accent
        return ZStack {
            if let symbol = marker.systemImage {
                Circle()
                    .fill(AppColors.pale(color))
                Image(systemName: symbol)
                    .font(.system(size: AppIconSize.sm * 0.8, weight: .semibold))
                    .foregroundStyle(color)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: AppSpacing.md, height: AppSpacing.md)
            }
        }
        .frame(width: Self.markerSize, height: Self.markerSize)
        .accessibilityHidden(true)
    }
}

/// Sizes `ActivityTimeline` and its skeleton share.
enum TimelineMetrics {
    static let markerSize: CGFloat = AppIconSize.lg + AppSpacing.xs
    static let lineWidth: CGFloat = 2
}

// MARK: - Skeleton

/// Placeholder of an `ActivityTimeline`: `count` round markers on the line, each with a
/// title and a caption.
public struct ActivityTimelineSkeleton: View {
    let count: Int

    public init(count: Int = 3) {
        self.count = max(1, count)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                let isLast = index == count - 1
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    SkeletonView.circle(TimelineMetrics.markerSize)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        SkeletonText(AppTypography.bodyEmphasis, width: 140)
                        SkeletonText(AppTypography.caption, width: 90)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppSpacing.xxs)
                    .padding(.bottom, isLast ? 0 : AppSpacing.lg)
                }
                .background(alignment: .topLeading) {
                    if !isLast {
                        Rectangle()
                            .fill(SkeletonView.fill)
                            .frame(width: TimelineMetrics.lineWidth)
                            .frame(maxHeight: .infinity)
                            .padding(.top, TimelineMetrics.markerSize)
                            .padding(.leading, (TimelineMetrics.markerSize - TimelineMetrics.lineWidth) / 2)
                    }
                }
            }
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}
