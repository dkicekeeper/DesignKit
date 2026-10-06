//
//  StatusBanner.swift
//  DesignKit
//
//  A notice that stays in the layout: a status icon and text on the status's pale container,
//  with a chevron when it opens something. Same build as RecommendationBox (icon, text, a
//  tinted rounded box), coloured by status. For a message that comes and goes, MessageBanner;
//  for one line under a field, InlineStatusText.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// "ⓘ Your statement for September is ready ›" on a pale blue box.
///
/// ```swift
/// StatusBanner("Card expires on 30 Nov", status: .warning)
/// StatusBanner("Statement is ready", status: .info) { showStatement() }   // with a chevron
/// StatusBanner("Synced", status: .positive, style: .compact)
/// ```
public struct StatusBanner: View {
    /// What the notice is about; picks the icon and the colours (`AppColors.Status`).
    public enum Status: Hashable, Sendable {
        case info, positive, negative, warning, neutral

        var solid: Color {
            switch self {
            case .info: return AppColors.Status.info
            case .positive: return AppColors.Status.positive
            case .negative: return AppColors.Status.negative
            case .warning: return AppColors.Status.warning
            case .neutral: return AppColors.Status.neutral
            }
        }

        var pale: Color {
            switch self {
            case .info: return AppColors.Status.infoPale
            case .positive: return AppColors.Status.positivePale
            case .negative: return AppColors.Status.negativePale
            case .warning: return AppColors.Status.warningPale
            case .neutral: return AppColors.Status.neutralPale
            }
        }

        var systemImage: String {
            switch self {
            case .info: return "info.circle.fill"
            case .positive: return "checkmark.circle.fill"
            case .negative: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .neutral: return "info.circle.fill"
            }
        }
    }

    /// `.standard` on a screen; `.compact` inside a card.
    public enum Style: Hashable, Sendable {
        case standard, compact
    }

    let text: String
    let status: Status
    let style: Style
    let systemImage: String?
    let action: (() -> Void)?

    /// - Parameters:
    ///   - systemImage: Replaces the status's icon.
    ///   - action: Makes the banner a button with a chevron on the trailing edge.
    public init(
        _ text: String,
        status: Status = .info,
        style: Style = .standard,
        systemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.status = status
        self.style = style
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) { content(showsChevron: true) }
                .buttonStyle(.bounce)
        } else {
            content(showsChevron: false)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: systemImage ?? status.systemImage)
                .font(style == .standard ? .system(size: AppIconSize.sm) : AppTypography.caption)
                .foregroundStyle(status.solid)
                .accessibilityHidden(true)

            Text(text)
                .font(style == .standard ? AppTypography.bodySmall : AppTypography.caption)
                .foregroundStyle(AppColors.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if showsChevron {
                DisclosureChevron()
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, style == .standard ? AppSpacing.md : AppSpacing.sm)
        .background(status.pale, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Skeleton

/// Placeholder of a `StatusBanner`: one grey box with its corner, as tall as the banner with
/// `lines` lines of text.
public struct StatusBannerSkeleton: View {
    let style: StatusBanner.Style
    let lines: Int

    public init(style: StatusBanner.Style = .standard, lines: Int = 1) {
        self.style = style
        self.lines = max(1, lines)
    }

    public var body: some View {
        // The banner's own layout, invisible, gives the height (it grows with Dynamic Type).
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(style == .standard ? .system(size: AppIconSize.sm) : AppTypography.caption)
            Text(verbatim: Array(repeating: "Ag", count: lines).joined(separator: "\n"))
                .font(style == .standard ? AppTypography.bodySmall : AppTypography.caption)
        }
        .hidden()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, style == .standard ? AppSpacing.md : AppSpacing.sm)
        .background(SkeletonView.fill, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .shimmer()
        .skeletonLoadingLabel()
    }
}
