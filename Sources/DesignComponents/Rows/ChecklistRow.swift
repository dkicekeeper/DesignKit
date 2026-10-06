//
//  ChecklistRow.swift
//  DesignKit
//
//  Checklists: an item to tick off (the circle, the title struck through once done, an
//  optional mark on the right) and a checklist in a list (its title, a line under it, the
//  progress bar and "12 of 20"). Ported from Dalada's ChecklistItemRow and
//  ChecklistSummaryRow; the checklist model and its storage stay in the app.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A checklist item; a tap toggles it.
///
/// ```swift
/// ChecklistRow(item.title, isChecked: item.isChecked) { toggle(item) }
/// ChecklistRow("Tent", isChecked: false, accessorySystemImage: "backpack",
///              accessoryLabel: "From gear") { … }
/// ```
///
/// Padding: none, like a row that lives in a `List` (design-system §10).
public struct ChecklistRow: View {
    let title: String
    let isChecked: Bool
    let tint: Color
    let accessorySystemImage: String?
    let accessoryLabel: String?
    let onToggle: () -> Void

    /// - Parameters:
    ///   - tint: The checked circle.
    ///   - accessorySystemImage: A small mark on the right (where the item came from).
    ///   - accessoryLabel: The mark's VoiceOver label.
    public init(
        _ title: String,
        isChecked: Bool,
        tint: Color = AppColors.success,
        accessorySystemImage: String? = nil,
        accessoryLabel: String? = nil,
        onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.isChecked = isChecked
        self.tint = tint
        self.accessorySystemImage = accessorySystemImage
        self.accessoryLabel = accessoryLabel
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.md) {
                SelectionIndicator(isSelected: isChecked, tint: tint)
                Text(verbatim: title)
                    .font(AppTypography.body)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? AppColors.textSecondary : AppColors.textPrimary)
                Spacer(minLength: 0)
                if let accessorySystemImage {
                    Image(systemName: accessorySystemImage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .accessibilityLabel(Text(verbatim: accessoryLabel ?? ""))
                        .accessibilityHidden(accessoryLabel == nil)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

/// A checklist in a list: title (with a seal once complete), a line under it (the day it is
/// for), and the progress bar with "12 of 20"; an empty checklist says so instead.
///
/// ```swift
/// ChecklistSummaryRow(title: list.title, subtitle: "Sat, 12 Oct", checked: 12, total: 20)
/// ```
///
/// Padding: `AppSpacing.xxs` vertically, a row that lives in a `List`.
public struct ChecklistSummaryRow: View {
    let title: String
    let subtitle: String?
    let subtitleSystemImage: String
    let checked: Int
    let total: Int
    let progressText: String?
    let emptyText: String?
    let completeLabel: String?

    /// - Parameters:
    ///   - subtitle: A caption line with `subtitleSystemImage` (a calendar by default).
    ///   - progressText: Under the bar; "12 of 20" (key `checklist.progress`) by default.
    ///   - emptyText: Instead of the bar when `total` is 0; key `checklist.empty` by default.
    ///   - completeLabel: The seal's VoiceOver label; key `checklist.complete` by default.
    public init(
        title: String,
        subtitle: String? = nil,
        subtitleSystemImage: String = "calendar",
        checked: Int,
        total: Int,
        progressText: String? = nil,
        emptyText: String? = nil,
        completeLabel: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleSystemImage = subtitleSystemImage
        self.checked = checked
        self.total = total
        self.progressText = progressText
        self.emptyText = emptyText
        self.completeLabel = completeLabel
    }

    private var isComplete: Bool { total > 0 && checked >= total }
    private var progress: Double { total > 0 ? Double(checked) / Double(total) : 0 }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Text(verbatim: title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer(minLength: 0)
                if isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppColors.success)
                        .accessibilityLabel(Text(verbatim: completeLabel
                            ?? String(localized: "checklist.complete", defaultValue: "Complete")))
                }
            }
            if let subtitle {
                Label(subtitle, systemImage: subtitleSystemImage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            if total == 0 {
                Text(verbatim: emptyText ?? String(localized: "checklist.empty", defaultValue: "No items yet"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                LinearProgressBar(
                    value: progress,
                    color: isComplete ? AppColors.success : AppColors.accent,
                    height: ChecklistMetrics.barHeight,
                    animatesOnAppear: false
                )
                Text(verbatim: progressText ?? Self.defaultProgressText(checked: checked, total: total))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    static func defaultProgressText(checked: Int, total: Int) -> String {
        String(localized: "checklist.progress \(checked) \(total)", defaultValue: "\(checked) of \(total)")
    }
}

/// Sizes shared by the checklist rows and their skeletons.
enum ChecklistMetrics {
    static let barHeight: CGFloat = 6
}

// MARK: - Skeletons

/// Placeholder of a `ChecklistRow`: the circle and a title line.
public struct ChecklistRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            // The indicator's own size, as a grey circle.
            SelectionIndicator(isSelected: false)
                .hidden()
                .overlay { Circle().fill(SkeletonView.fill) }
            SkeletonText(AppTypography.body, width: 180)
            Spacer(minLength: 0)
        }
        .shimmer()
        .skeletonLoadingLabel()
    }
}

/// Placeholder of a `ChecklistSummaryRow`: the title, the bar's track and the count line.
public struct ChecklistSummaryRowSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SkeletonText(AppTypography.bodyEmphasis, width: 160)
            LinearProgressBarSkeleton(height: ChecklistMetrics.barHeight)
            SkeletonText(AppTypography.caption, width: 64)
        }
        .padding(.vertical, AppSpacing.xxs)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
