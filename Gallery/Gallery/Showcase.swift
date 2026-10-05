//
//  Showcase.swift
//  DesignKit Gallery
//
//  Layout helpers shared by the showcase screens: the paged screen, its sections, token labels.
//

import SwiftUI
import DesignTokens

/// A showcase screen. Every `ShowcaseSection` in `content` is a page of its own: chips under
/// the navigation bar name the pages and switch between them, and a horizontal swipe pages
/// too. A screen with a single section is one scrolling page without chips.
struct ShowcasePage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    @State private var selection = 0

    var body: some View {
        Group(subviews: content) { pages in
            if pages.count > 1 {
                TabView(selection: $selection) {
                    ForEach(pages.indices, id: \.self) { index in
                        page(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .safeAreaBar(edge: .top) {
                    ShowcaseChips(
                        titles: pages.indices.map { index in
                            let title = pages[index].containerValues.showcaseTitle
                            return title.isEmpty ? "\(index + 1)" : title
                        },
                        selection: $selection
                    )
                }
            } else {
                page(ForEach(pages) { $0 })
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func page(_ content: some View) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                content
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The page switcher of a `ShowcasePage`: one chip per page, the current one selected and
/// scrolled into view.
private struct ShowcaseChips: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(titles.indices, id: \.self) { index in
                        Button {
                            withAnimation(AppAnimation.contentSpring) { selection = index }
                        } label: {
                            Text(titles[index])
                                .lineLimit(1)
                                .filterChipStyle(isSelected: index == selection)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(index == selection ? .isSelected : [])
                        .id(index)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xs)
            }
            .scrollIndicators(.hidden)
            .onChange(of: selection) { _, index in
                withAnimation(AppAnimation.contentSpring) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
        }
    }
}

extension ContainerValues {
    /// The chip title of a showcase page: its section's title.
    @Entry var showcaseTitle: String = ""
}

/// A labelled group of specimens.
struct ShowcaseSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.h4)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            content
        }
        .containerValue(\.showcaseTitle, title)
    }
}

/// Caption used to annotate a token's name/value.
struct TokenLabel: View {
    let name: String
    var value: String? = nil
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(name)
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            if let value {
                Text(value)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
