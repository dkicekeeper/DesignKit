//
//  DownloadRow.swift
//  DesignKit
//
//  Something to download for offline use (2.8.0): its name, a line that says how big it is or
//  how far along it got, and the action that fits: download, pause, resume. A bar fills while it
//  downloads; a check mark says it is here. Ported from Dalada's OfflineRegionRow (offline map
//  regions); the download itself, the sizes and the swipe to delete stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A downloadable item and its state.
///
/// ```swift
/// DownloadRow("Almaty region", status: .downloading(0.4), caption: "40% · 32 MB",
///             onDownload: { maps.download(region) }, onPause: { maps.pause(region) })
///     .swipeActions { Button("Delete", role: .destructive) { maps.remove(region) } }
/// ```
///
/// Padding: vertical only, `AppSpacing.xxs` (a `List` row).
public struct DownloadRow: View {
    /// Where the download is.
    public enum Status: Equatable, Sendable {
        /// Not here yet: the caption gives its size; the action downloads.
        case available
        /// On its way, 0…1: a bar over the caption; the action pauses.
        case downloading(Double)
        /// Stopped partway: the action resumes.
        case paused
        /// Here: a check mark before the caption; no action.
        case downloaded
        /// Stopped by an error: the caption, in the destructive colour, says why; the action retries.
        case failed
    }

    let title: String
    let status: Status
    let caption: String
    let onDownload: () -> Void
    let onPause: () -> Void
    let downloadLabel: String
    let pauseLabel: String

    /// - Parameters:
    ///   - caption: The line under the name: "About 80 MB", "40% · 32 MB", "Paused at 40%",
    ///     "Downloaded · 80 MB", the error.
    ///   - downloadLabel, pauseLabel: What VoiceOver says for the action.
    public init(
        _ title: String,
        status: Status,
        caption: String,
        onDownload: @escaping () -> Void,
        onPause: @escaping () -> Void = {},
        downloadLabel: String = String(localized: "download.start", defaultValue: "Download"),
        pauseLabel: String = String(localized: "download.pause", defaultValue: "Pause")
    ) {
        self.title = title
        self.status = status
        self.caption = caption
        self.onDownload = onDownload
        self.onPause = onPause
        self.downloadLabel = downloadLabel
        self.pauseLabel = pauseLabel
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.Text.primary)
                details
            }
            Spacer(minLength: 0)
            action
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    @ViewBuilder
    private var details: some View {
        switch status {
        case .available, .paused:
            Text(verbatim: caption)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.Text.secondary)
        case .downloading(let progress):
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                LinearProgressBar(value: progress, height: DownloadRowMetrics.barHeight, animatesOnAppear: false)
                Text(verbatim: caption)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        case .downloaded:
            Label {
                Text(verbatim: caption)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.accent)
            }
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.Text.secondary)
        case .failed:
            Text(verbatim: caption)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.destructive)
        }
    }

    @ViewBuilder
    private var action: some View {
        switch status {
        case .available, .failed, .paused:
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(verbatim: downloadLabel))
        case .downloading:
            Button(action: onPause) {
                Image(systemName: "pause.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(verbatim: pauseLabel))
        case .downloaded:
            EmptyView()
        }
    }
}

enum DownloadRowMetrics {
    static let barHeight: CGFloat = 6
}

// MARK: - Skeleton

/// Placeholder of a `DownloadRow`: the name, the caption and the action's circle.
public struct DownloadRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                SkeletonText(AppTypography.bodyEmphasis, width: 140)
                SkeletonText(AppTypography.caption, width: 90)
            }
            Spacer(minLength: 0)
            Skeleton.circle(DownloadRowMetrics.actionSize)
        }
        .padding(.vertical, AppSpacing.xxs)
        .shimmer()
        .skeletonLoadingLabel()
    }
}

extension DownloadRowMetrics {
    /// About the `.title2` action glyph.
    static let actionSize: CGFloat = 28
}
