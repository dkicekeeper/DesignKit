//
//  PagerArrows.swift
//  DesignKit
//
//  Step through pages with arrows as well as a swipe (2.9.0): a chevron on each side, centred on
//  the content (a chart), greyed at either end. For a pager of periods (this month, the last). A
//  page change by arrow animates; the pager's own swipe animates itself. Ported from Tenra's
//  PeriodPagerChartBand; the pages and what an empty one shows stay in Tenra.
//

import SwiftUI
import DesignTokens

/// A chevron on each side of `content`, stepping `index` through `count` pages.
///
/// ```swift
/// TabView(selection: $index) { … }                    // the swipe
/// PagerArrows(index: $index, count: pages.count) {    // the arrows, over the chart
///     PeriodChart(pages[index])
/// }
/// ```
public struct PagerArrows<Content: View>: View {
    @Binding var index: Int
    let count: Int
    let showsArrows: Bool
    let previousLabel: String
    let nextLabel: String
    let content: Content

    /// - Parameters:
    ///   - showsArrows: `false` when there is nothing to step through (one page).
    ///   - previousLabel, nextLabel: What VoiceOver says for each arrow.
    public init(
        index: Binding<Int>,
        count: Int,
        showsArrows: Bool = true,
        previousLabel: String = String(localized: "pager.previous", defaultValue: "Previous"),
        nextLabel: String = String(localized: "pager.next", defaultValue: "Next"),
        @ViewBuilder content: () -> Content
    ) {
        self._index = index
        self.count = count
        self.showsArrows = showsArrows
        self.previousLabel = previousLabel
        self.nextLabel = nextLabel
        self.content = content()
    }

    public var body: some View {
        ZStack {
            content

            if showsArrows {
                HStack {
                    arrow(step: -1, systemImage: "chevron.left", label: previousLabel)
                    Spacer()
                    arrow(step: 1, systemImage: "chevron.right", label: nextLabel)
                }
                .screenPadding()
            }
        }
    }

    private func arrow(step delta: Int, systemImage: String, label: String) -> some View {
        let enabled = Self.stepped(index, by: delta, count: count) != nil
        return Button { step(delta) } label: {
            Image(systemName: systemImage)
                .font(AppTypography.bodyEmphasis)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? AppColors.accent : AppColors.Text.tertiary)
        .disabled(!enabled)
        .accessibilityLabel(Text(verbatim: label))
    }

    private func step(_ delta: Int) {
        guard let next = Self.stepped(index, by: delta, count: count) else { return }
        withAnimation(.easeInOut(duration: AppAnimation.standard)) { index = next }
    }

    /// The page `delta` steps away from `index`, or `nil` past either end.
    static func stepped(_ index: Int, by delta: Int, count: Int) -> Int? {
        let next = index + delta
        return next >= 0 && next < count ? next : nil
    }
}
