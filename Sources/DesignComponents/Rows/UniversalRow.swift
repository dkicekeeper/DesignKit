//
//  UniversalRow.swift
//  Tenra
//
//  Universal row component with IconView integration and Design System compliance
//  Created: 2026-02-16
//
//  Architecture:
//  - Generic ViewBuilders for content and trailing elements
//  - IconView integration for leading icons
//  - Presets for common use cases (settings, selectable, info)
//  - Modifiers for interactive behavior (navigation, action, selectable)
//
//  Usage Examples:
//
//  1. Settings Action Row:
//  ```swift
//  UniversalRow(
//      config: .settings,
//      leadingIcon: .sfSymbol("trash", color: .red)
//  ) {
//      Text("Delete All")
//  } trailing: {
//      EmptyView()
//  }
//  .actionRow(role: .destructive) { deleteAll() }
//  ```
//
//  2. Navigation Row:
//  ```swift
//  UniversalRow(
//      config: .settings,
//      leadingIcon: .sfSymbol("tag")
//  ) {
//      Text("Categories")
//  } trailing: {
//      EmptyView() // NavigationLink adds chevron automatically
//  }
//  .navigationRow { CategoriesView() }
//  ```
//
//  3. Selectable Row:
//  ```swift
//  UniversalRow(
//      config: .selectable,
//      leadingIcon: .brandService("kaspi.kz")
//  ) {
//      Text("Kaspi Bank")
//  } trailing: {
//      if isSelected {
//          Image(systemName: "checkmark")
//      }
//  }
//  .selectableRow(isSelected: isSelected) { select() }
//  ```
//

import SwiftUI
import DesignTokens
import DesignSupport

// MARK: - Universal Row Component

/// Universal row component for consistent UI patterns across the app
/// Integrates with IconView for leading icons and supports flexible content
public struct UniversalRow<Content: View, Trailing: View>: View {

    // MARK: - Properties

    let config: RowConfiguration
    let leadingIcon: IconConfig?
    let hint: String?

    @ViewBuilder let content: () -> Content
    @ViewBuilder let trailing: () -> Trailing

    private var hintLeadingPad: CGFloat {
        leadingIcon != nil ? AppIconSize.md + config.spacing : 0
    }

    // MARK: - Initializer

    public init(
        config: RowConfiguration = .standard,
        leadingIcon: IconConfig? = nil,
        hint: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.config = config
        self.leadingIcon = leadingIcon
        self.hint = hint
        self.content = content
        self.trailing = trailing
    }

    // MARK: - Body

    public var body: some View {
        let stack = VStack(alignment: .leading, spacing: hint != nil ? AppSpacing.xs : 0) {
            HStack(spacing: config.spacing) {
                // Leading icon via IconView
                if let iconConfig = leadingIcon {
                    IconView(
                        source: iconConfig.source,
                        style: iconConfig.style
                    )
                }

                // Content expands to fill available space, pushing trailing to the right edge.
                // Using frame(maxWidth:) instead of a Spacer avoids competing spacers when
                // content itself contains an inner Spacer (e.g. infoRow HStack).
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Trailing element
                trailing()
            }

            if let hint {
                Text(hint)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, hintLeadingPad)
                    .padding(.bottom, AppSpacing.xxs)
            }
        }
        .padding(.vertical, config.verticalPadding)
        .padding(.horizontal, config.horizontalPadding)
        .background(config.backgroundColor)

        // Apply `clipShape` only when the row actually needs a rounded corner.
        // A `0`-radius `clipShape(.rect)` still creates a content boundary that
        // iOS 26's `Picker`/`Menu` morph picks up as its *source view* — so the
        // entire row collapses into the menu popover on tap. Skipping the
        // clip for the no-op case (every shipped `RowConfiguration` uses
        // cornerRadius=0 today) keeps the morph anchored to the trigger
        // control itself.
        return Group {
            if config.cornerRadius > 0 {
                stack.clipShape(.rect(cornerRadius: config.cornerRadius))
            } else {
                stack
            }
        }
    }
}

// MARK: - Icon Configuration

/// Configuration for leading icon in UniversalRow
/// Wraps IconSource and IconStyle for convenient usage
public struct IconConfig {
    let source: IconSource?
    let style: IconStyle

    // MARK: - Convenience Initializers

    /// SF Symbol with color
    /// - Parameters:
    ///   - name: SF Symbol name
    ///   - color: Tint color (default: textPrimary)
    ///   - size: Icon size (default: AppIconSize.md)
    public static func sfSymbol(
        _ name: String,
        color: Color = AppColors.textPrimary,
        size: CGFloat = AppIconSize.md
    ) -> IconConfig {
        IconConfig(
            source: .sfSymbol(name),
            style: .circle(size: size, tint: .monochrome(color))
        )
    }

    /// Brand service logo
    /// - Parameters:
    ///   - brandName: Service name (e.g., "netflix")
    ///   - size: Icon size (default: AppIconSize.xl)
    public static func brandService(
        _ brandName: String,
        size: CGFloat = AppIconSize.xl
    ) -> IconConfig {
        IconConfig(
            source: .brandService(brandName),
            style: .serviceLogo(size: size)
        )
    }

    /// Custom IconSource with IconStyle
    /// - Parameters:
    ///   - source: IconSource
    ///   - style: IconStyle
    public static func custom(source: IconSource?, style: IconStyle) -> IconConfig {
        IconConfig(source: source, style: style)
    }

    /// Auto-select style based on source type
    /// Mirrors IconView convenience init: sfSymbol→categoryIcon, brandService→serviceLogo
    /// - Parameters:
    ///   - source: IconSource
    ///   - size: Icon size (default: AppIconSize.xl)
    public static func auto(source: IconSource, size: CGFloat = AppIconSize.xl) -> IconConfig {
        switch source {
        case .sfSymbol:
            return IconConfig(source: source, style: .categoryIcon(size: size))
        case .brandService:
            return IconConfig(source: source, style: .serviceLogo(size: size))
        }
    }
}

// MARK: - Row Configuration

/// Configuration for UniversalRow layout and styling
public struct RowConfiguration {
    let spacing: CGFloat
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat

    // MARK: - Presets

    /// Standard form row (default)
    /// V: 12pt / H: 16pt — rows own their padding; cardStyle() adds no padding.
    /// Used for: MenuPickerRow, DatePickerRow, InfoRow, BudgetSettingsSection rows.
    public static let standard = RowConfiguration(
        spacing: AppSpacing.md,
        verticalPadding: AppSpacing.md,
        horizontalPadding: AppSpacing.lg,
        backgroundColor: .clear,
        cornerRadius: 0
    )

    /// Settings row style
    /// Used for ActionSettingsRow, NavigationSettingsRow
    /// No horizontal padding (managed by List)
    public static let settings = RowConfiguration(
        spacing: AppSpacing.md,
        verticalPadding: AppSpacing.xs,
        horizontalPadding: 0,
        backgroundColor: .clear,
        cornerRadius: 0
    )

    /// Selectable row — for single-select lists (checkmark pattern).
    /// V: 12pt / H: 16pt — same rhythm as .standard; semantic distinction only.
    /// Use `.selectableRow(isSelected:action:)` modifier on top.
    /// Used for: TimeFilterView selectable rows
    public static let selectable = RowConfiguration(
        spacing: AppSpacing.md,
        verticalPadding: AppSpacing.md,
        horizontalPadding: AppSpacing.lg,
        backgroundColor: .clear,
        cornerRadius: 0
    )

    /// Sheet / form-list row — wider horizontal inset for modal selection sheets.
    /// V: 12pt / H: 16pt — gives breathing room in full-width sheet lists.
    /// Used for: modal selection sheets with wider horizontal inset
    public static let sheetList = RowConfiguration(
        spacing: AppSpacing.md,
        verticalPadding: AppSpacing.md,
        horizontalPadding: AppSpacing.lg,
        backgroundColor: .clear,
        cornerRadius: 0
    )

    /// Info row style — display-only component, always inside a padded container.
    /// V: 8pt / H: 0 — container (detail card VStack with .padding(.lg)) owns horizontal spacing.
    /// Used for InfoRow (read-only label + value) inside LoanDetailView, DepositDetailView, etc.
    public static let info = RowConfiguration(
        spacing: AppSpacing.md,
        verticalPadding: AppSpacing.sm,
        horizontalPadding: 0,
        backgroundColor: .clear,
        cornerRadius: 0
    )
}

// MARK: - Row Modifiers

public extension View {
    /// Applies navigation row behavior
    /// Wraps the row in NavigationLink
    /// - Parameter destination: Destination view
    func navigationRow<Destination: View>(
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            self
        }
    }

    /// Applies action row behavior
    /// Wraps the row in Button
    /// - Parameters:
    ///   - role: Button role (e.g., .destructive)
    ///   - action: Action to perform
    func actionRow(
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            self
        }
    }

    /// Applies selectable row behavior
    /// Makes row tappable with contentShape
    /// - Parameters:
    ///   - isSelected: Whether the row is selected
    ///   - action: Action to perform on tap
    func selectableRow(
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityRemoveTraits(isSelected ? [] : .isSelected)
    }
}

// MARK: - Convenience Initializers

public extension UniversalRow where Trailing == EmptyView {
    /// Initializer without trailing element
    public init(
        config: RowConfiguration = .standard,
        leadingIcon: IconConfig? = nil,
        hint: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.config = config
        self.leadingIcon = leadingIcon
        self.hint = hint
        self.content = content
        self.trailing = { EmptyView() }
    }
}

public extension UniversalRow where Content == Text, Trailing == EmptyView {
    /// Initializer with text content and no trailing
    /// Useful for simple labeled rows
    public init(
        config: RowConfiguration = .standard,
        leadingIcon: IconConfig? = nil,
        hint: String? = nil,
        title: String,
        titleColor: Color = AppColors.textPrimary
    ) {
        self.config = config
        self.leadingIcon = leadingIcon
        self.hint = hint
        self.content = {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(titleColor)
        }
        self.trailing = { EmptyView() }
    }
}

public extension UniversalRow where Content == Text {
    /// Initializer with a string `title` (auto-styled as `AppTypography.body` +
    /// `AppColors.textPrimary`) and a custom `trailing` view. Removes the boilerplate
    /// of building the leading `Text { … }.font(…).foregroundStyle(…)` at every call
    /// site — see `LoanEditView`, `SubscriptionEditView`, etc., where the same three
    /// modifiers were duplicated on every row's content closure.
    ///
    /// Use `titleColor: AppColors.destructive` for destructive labels; otherwise
    /// stick to the default so all forms remain visually consistent.
    public init(
        config: RowConfiguration = .standard,
        leadingIcon: IconConfig? = nil,
        hint: String? = nil,
        title: String,
        titleColor: Color = AppColors.textPrimary,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.config = config
        self.leadingIcon = leadingIcon
        self.hint = hint
        self.content = {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(titleColor)
        }
        self.trailing = trailing
    }
}

// Note: Removed overly-specific convenience initializer for navigation rows
// Use the standard UniversalRow initializer with explicit trailing view instead

// MARK: - Previews







