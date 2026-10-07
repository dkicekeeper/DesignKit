//
//  UniversalFilterButton.swift
//  Tenra
//
//  Universal filter button component supporting both Button and Menu modes
//  Phase 14: Consolidates FilterChip, CategoryFilterButton, and AccountFilterMenu
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Universal filter button/menu component with consistent styling
/// Supports two modes: simple button tap or menu with custom content
public struct UniversalFilterButton<IconContent: View, MenuContent: View>: View {
    let title: String
    let isSelected: Bool
    let showChevron: Bool
    let icon: () -> IconContent
    let mode: FilterMode<MenuContent>

    public enum FilterMode<Content: View> {
        case button(() -> Void)
        case menu(() -> Content)
    }

    // MARK: - Initializers

    /// Button mode initializer - for simple tap actions
    public init(
        title: String,
        isSelected: Bool = false,
        showChevron: Bool = true,
        onTap: @escaping () -> Void,
        @ViewBuilder icon: @escaping () -> IconContent = { EmptyView() }
    ) where MenuContent == EmptyView {
        self.title = title
        self.isSelected = isSelected
        self.showChevron = showChevron
        self.icon = icon
        self.mode = .button(onTap)
    }

    /// Menu mode initializer - for dropdown menus with custom content
    public init(
        title: String,
        isSelected: Bool = false,
        showChevron: Bool = true,
        @ViewBuilder icon: @escaping () -> IconContent = { EmptyView() },
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.title = title
        self.isSelected = isSelected
        self.showChevron = showChevron
        self.icon = icon
        self.mode = .menu(menuContent)
    }

    // MARK: - Body Components

    /// Shared label view for both button and menu modes
    @ViewBuilder
    private var label: some View {
        HStack(spacing: AppSpacing.sm) {
            // Optional icon
            if !(IconContent.self == EmptyView.self) {
                icon()
                    .font(.system(size: AppIconSize.sm))
            }

            // Title text
            Text(title)

            // Optional chevron
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
            }
        }
        .filterChipStyle(isSelected: isSelected)
    }

    public var body: some View {
        switch mode {
        case .button(let action):
            // Button mode: simple tap action
            Button(action: action) {
                label
            }
            .contentShape(Rectangle())
            .accessibilityLabel(title)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            .accessibilityAddTraits(.isButton)

        case .menu(let content):
            // Menu mode: dropdown with custom content
            Menu {
                content()
            } label: {
                label
            }
            .accessibilityLabel(title)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        }
    }
}

// MARK: - Convenience Initializers

public extension UniversalFilterButton where IconContent == EmptyView {
    /// Text-only button (no icon)
    init(
        title: String,
        isSelected: Bool = false,
        showChevron: Bool = true,
        onTap: @escaping () -> Void
    ) where MenuContent == EmptyView {
        self.init(
            title: title,
            isSelected: isSelected,
            showChevron: showChevron,
            onTap: onTap,
            icon: { EmptyView() }
        )
    }

    /// Text-only menu (no icon)
    init(
        title: String,
        isSelected: Bool = false,
        showChevron: Bool = true,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.init(
            title: title,
            isSelected: isSelected,
            showChevron: showChevron,
            icon: { EmptyView() },
            menuContent: menuContent
        )
    }
}

// MARK: - Previews
