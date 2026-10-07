//
//  DSButton.swift
//  DesignKit
//
//  The design system's button (2.0.0): a title with an icon before, after or above it (or the
//  icon alone), appearance × role × size, a loading state that keeps the button's width, full
//  width or the label's own. It replaces LoadingButtonLabel, BulkDeleteButton and
//  EntityActionButton, which were one button each. (Material: Button; HIG: Buttons.)
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A button of the design system.
///
/// ```swift
/// DSButton("Save", isLoading: saving, fullWidth: true) { save() }
/// DSButton("Delete", systemImage: "trash", role: .destructive) { delete() }
/// DSButton("Next", systemImage: "arrow.right", iconPlacement: .trailing, appearance: .secondary) { next() }
/// DSButton("Edit", systemImage: "pencil", iconPlacement: .top) { edit() }        // a tile
/// DSButton("Close", systemImage: "xmark", iconPlacement: .only, appearance: .secondary) { close() }
/// ```
///
/// - `appearance`: `.primary` (filled glass, the main action), `.secondary` (clear glass),
///   `.flat` (text, no container).
/// - `role`: `.normal` (the accent), `.destructive` (red), `.neutral` (primary text colour).
/// - `size`: `.large`, `.medium`, `.small` (the system `controlSize`).
/// - `iconPlacement: .top` draws a tile: the symbol above a two-line title in a rounded
///   rectangle that fills the width it is given (actions under a detail screen's hero).
/// - `isLoading` swaps the label for a spinner in the same width and blocks taps.
///
/// The label takes the font around it, like a SwiftUI `Button`. A press plays a light haptic,
/// a warning one for `.destructive`.
public struct DSButton: View {
    public typealias Appearance = DSButtonAppearance
    public typealias Role = DSButtonRole
    public typealias Size = DSButtonSize

    /// Where the symbol goes.
    public enum IconPlacement: Hashable, Sendable {
        /// Before the title (a `Label`).
        case leading
        /// After the title.
        case trailing
        /// Above the title, as a tile.
        case top
        /// The symbol alone; the title is its VoiceOver label.
        case only
    }

    /// The outline of the button.
    public enum Shape: Hashable, Sendable {
        /// The system's for the appearance and size.
        case automatic
        /// A capsule (a call to action floating over content).
        case capsule
        /// A rounded rectangle, `AppRadius.lg` (a tile's own).
        case roundedRectangle
    }

    let title: String
    let systemImage: String?
    let iconPlacement: IconPlacement
    let appearance: Appearance
    let role: Role
    let size: Size
    let shape: Shape
    let fullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        iconPlacement: IconPlacement = .leading,
        appearance: Appearance = .primary,
        role: Role = .normal,
        size: Size = .large,
        shape: Shape = .automatic,
        fullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconPlacement = iconPlacement
        self.appearance = appearance
        self.role = role
        self.size = size
        self.shape = shape
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        if iconPlacement == .top {
            tile
        } else {
            standard
        }
    }

    // MARK: - Standard

    private var standard: some View {
        Button(role: buttonRole, action: tap) {
            ZStack {
                content
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .animation(AppAnimation.contentSpring, value: isLoading)
        }
        .dsButton(appearance, role: role, size: size, disabled: isDisabled || isLoading)
        .modifier(DSButtonShapeModifier(shape: shape))
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(isLoading
            ? Text(String(localized: "skeleton.loading", defaultValue: "Loading"))
            : Text(verbatim: ""))
    }

    @ViewBuilder
    private var content: some View {
        switch iconPlacement {
        case .leading, .top:
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(verbatim: title)
            }
        case .trailing:
            HStack(spacing: AppSpacing.xs) {
                Text(verbatim: title)
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
        case .only:
            Image(systemName: systemImage ?? "circle")
        }
    }

    // MARK: - Tile

    /// The symbol above a two-line title: the layout of the action tiles under a detail
    /// screen's hero (Tenra's EntityActionButton before 2.0).
    private var tile: some View {
        Button(role: buttonRole, action: tap) {
            VStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: AppIconSize.lg, height: AppIconSize.lg)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: AppIconSize.lg, weight: .semibold))
                        .frame(width: AppIconSize.lg, height: AppIconSize.lg)
                }
                Text(verbatim: title)
                    .font(AppTypography.bodySmall)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.sm)
        }
        .dsButton(appearance, role: role, size: .medium, disabled: isDisabled || isLoading)
        .modifier(DSButtonShapeModifier(shape: shape == .automatic ? .roundedRectangle : shape))
        .accessibilityLabel(Text(verbatim: title))
    }

    // MARK: - Action

    private var buttonRole: ButtonRole? {
        role == .destructive ? .destructive : nil
    }

    private func tap() {
        if role == .destructive {
            HapticManager.warning()
        } else {
            HapticManager.light()
        }
        action()
    }
}

private struct DSButtonShapeModifier: ViewModifier {
    let shape: DSButton.Shape

    @ViewBuilder
    func body(content: Content) -> some View {
        switch shape {
        case .automatic:
            content
        case .capsule:
            content.buttonBorderShape(.capsule)
        case .roundedRectangle:
            content.buttonBorderShape(.roundedRectangle(radius: AppRadius.lg))
        }
    }
}
