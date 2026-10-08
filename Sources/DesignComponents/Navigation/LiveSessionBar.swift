//
//  LiveSessionBar.swift
//  DesignKit
//
//  Something going on in the background, above the tabs (2.8.0): a recording dot that pulses
//  (a pause sign when paused), the time since it started, a detail (the distance), and a chevron
//  that says a tap opens it. `.liveSessionAccessory` puts it in the tab bar's accessory (iOS 26.1).
//  Ported from Dalada's TripMiniPlayer; the recorder stays in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A session in progress: its state, its running time, a detail; a tap opens it.
///
/// ```swift
/// TabView { … }
///     .liveSessionAccessory(isEnabled: recorder.isActive) {
///         LiveSessionBar(startedAt: recorder.startedAt, isPaused: recorder.isPaused,
///                        detail: distance, accessibilityLabel: "Trip recording in progress") {
///             showsRecording = true
///         }
///     }
/// ```
public struct LiveSessionBar: View {
    let startedAt: Date?
    let isPaused: Bool
    let detail: String?
    let accessibilityLabel: String
    let onOpen: () -> Void

    /// - Parameters:
    ///   - startedAt: When it started; the clock counts from it, once a second.
    ///   - isPaused: A pause sign instead of the pulsing recording dot.
    ///   - detail: After the clock, in the secondary colour ("3.2 km").
    public init(
        startedAt: Date?,
        isPaused: Bool = false,
        detail: String? = nil,
        accessibilityLabel: String,
        onOpen: @escaping () -> Void
    ) {
        self.startedAt = startedAt
        self.isPaused = isPaused
        self.detail = detail
        self.accessibilityLabel = accessibilityLabel
        self.onOpen = onOpen
    }

    public var body: some View {
        Button {
            onOpen()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: isPaused ? "pause.circle.fill" : "record.circle")
                    .foregroundStyle(isPaused ? AppColors.warning : AppColors.destructive)
                    .symbolEffect(.pulse, isActive: !isPaused)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(verbatim: Self.clock(context.date.timeIntervalSince(startedAt ?? context.date)))
                        .monospacedDigit()
                }
                if let detail {
                    Text(verbatim: detail)
                        .foregroundStyle(AppColors.Text.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            .font(AppTypography.bodyEmphasis)
            .padding(.horizontal, AppSpacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
    }

    /// "1:05:03": hours, minutes, seconds.
    static func clock(_ seconds: TimeInterval) -> String {
        Duration.seconds(Int(max(seconds, 0))).formatted(.time(pattern: .hourMinuteSecond))
    }
}

public extension View {
    /// Shows `bar` in the tab bar's bottom accessory while `isEnabled` (iOS 26.1 and later; on
    /// iOS 26.0 nothing is shown, so offer another way back to the session there).
    func liveSessionAccessory<Bar: View>(isEnabled: Bool, @ViewBuilder bar: @escaping () -> Bar) -> some View {
        modifier(LiveSessionAccessoryModifier(isEnabled: isEnabled, bar: bar))
    }
}

public enum LiveSessionAccessory {
    /// Whether the tab bar can show the bar on this system (iOS 26.1 and later).
    public static var isAvailable: Bool {
        if #available(iOS 26.1, *) { return true }
        return false
    }
}

private struct LiveSessionAccessoryModifier<Bar: View>: ViewModifier {
    let isEnabled: Bool
    let bar: () -> Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isEnabled) {
                bar()
            }
        } else {
            content
        }
    }
}

// MARK: - Skeleton

/// Placeholder of a `LiveSessionBar`: the dot, the clock and the detail.
public struct LiveSessionBarSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Skeleton.circle(AppIconSize.md)
            SkeletonText(AppTypography.bodyEmphasis, width: 64)
            SkeletonText(AppTypography.bodyEmphasis, width: 48)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
