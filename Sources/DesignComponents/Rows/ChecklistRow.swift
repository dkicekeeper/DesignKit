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
/// A row of a glass section (8.1.0): it pads itself `AppSpacing.sm` above and below, and the
/// divider under it starts at its title, after the circle. In a stack that spaces its rows,
/// or a `List`, pass `verticalPadding: 0` (before 8.1.0 it had no padding of its own).
public struct ChecklistRow: View {
    let title: String
    let isChecked: Bool
    let tint: Color
    let accessorySystemImage: String?
    let accessoryLabel: String?
    let verticalPadding: CGFloat
    let onToggle: () -> Void

    /// Where the title starts: the circle and the space after it.
    static let dividerInset = AppIconSize.lg + AppSpacing.md

    /// - Parameters:
    ///   - tint: The checked circle.
    ///   - accessorySystemImage: A small mark on the right (where the item came from).
    ///   - accessoryLabel: The mark's VoiceOver label.
    ///   - verticalPadding: Above and below the row: `AppSpacing.sm` in a glass section, 0 in a
    ///     stack that spaces its rows or a `List`.
    public init(
        _ title: String,
        isChecked: Bool,
        tint: Color = AppColors.success,
        accessorySystemImage: String? = nil,
        accessoryLabel: String? = nil,
        verticalPadding: CGFloat = AppSpacing.sm,
        onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.isChecked = isChecked
        self.tint = tint
        self.accessorySystemImage = accessorySystemImage
        self.accessoryLabel = accessoryLabel
        self.verticalPadding = verticalPadding
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.md) {
                SelectionIndicator(isSelected: isChecked, tint: tint)
                Text(verbatim: title)
                    .font(AppTypography.body)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? AppColors.Text.secondary : AppColors.Text.primary)
                Spacer(minLength: 0)
                if let accessorySystemImage {
                    Icon(accessorySystemImage, size: AppIconSize.sm)
                        .foregroundStyle(AppColors.Text.tertiary)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: accessoryLabel ?? ""))
                        .accessibilityHidden(accessoryLabel == nil)
                }
            }
            .padding(.vertical, verticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
        // 8.1.0: on the button, not in its label, which keeps it to itself.
        .rowDividerInset(Self.dividerInset)
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
                    .foregroundStyle(AppColors.Text.primary)
                Spacer(minLength: 0)
                if isComplete {
                    Icon("checkmark.seal.fill", size: AppIconSize.md, tint: .monochrome(AppColors.success))
                        // 2.2.0: the seal draws itself on when the list is complete.
                        .drawOnAppear()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: completeLabel
                            ?? String(localized: "checklist.complete", defaultValue: "Complete")))
                }
            }
            if let subtitle {
                Label { Text(verbatim: subtitle) } icon: { Icon(subtitleSystemImage, size: AppIconSize.xs) }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
            if total == 0 {
                Text(verbatim: emptyText ?? String(localized: "checklist.empty", defaultValue: "No items yet"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            } else {
                LinearProgressBar(
                    value: progress,
                    color: isComplete ? AppColors.success : AppColors.accent,
                    height: ChecklistMetrics.barHeight,
                    animatesOnAppear: false
                )
                // 2.3.0: checking the last item makes the bar glow, with the success haptic.
                .completionMoment(isComplete: isComplete, in: RoundedRectangle(cornerRadius: AppRadius.xs))
                Text(verbatim: progressText ?? Self.defaultProgressText(checked: checked, total: total))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    static func defaultProgressText(checked: Int, total: Int) -> String {
        String(
            format: String(localized: "checklist.progress %lld %lld", defaultValue: "%1$lld of %2$lld"),
            checked, total
        )
    }
}

/// Sizes shared by the checklist rows and their skeletons.
enum ChecklistMetrics {
    static let barHeight: CGFloat = 6
}

// MARK: - Skeletons

/// Placeholder of a `ChecklistRow`: the circle and a title line, padded as the row is.
public struct ChecklistRowSkeleton: View {
    let verticalPadding: CGFloat

    public init(verticalPadding: CGFloat = AppSpacing.sm) {
        self.verticalPadding = verticalPadding
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            // The indicator's own size, as a grey circle.
            SelectionIndicator(isSelected: false)
                .hidden()
                .overlay { Circle().fill(Skeleton.fill) }
            SkeletonText(AppTypography.body, width: 180)
            Spacer(minLength: 0)
        }
        .padding(.vertical, verticalPadding)
        .shimmer()
        .skeletonLoadingLabel()
        .rowDividerInset(ChecklistRow.dividerInset)
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
