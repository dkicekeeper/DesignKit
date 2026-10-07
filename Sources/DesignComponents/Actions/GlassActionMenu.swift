//
//  GlassActionMenu.swift
//  DesignKit
//
//  A floating Liquid Glass button that flows open into its actions (2.3.0): the actions
//  grow out of the button's glass and melt back into it, the way iOS 26's own toolbars do.
//  (HIG: Liquid Glass, "morphing"; Material: speed dial / FAB menu.)
//
//  The morph is the system's: each glass shape has a `glassEffectID` inside one
//  `GlassEffectContainer`, so inserting and removing them in an animation blends them. Nothing
//  of ours runs per frame. Under Reduce Motion the actions fade in and out.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A glass button that opens into a row or column of glass actions.
///
/// ```swift
/// GlassActionMenu(items: [
///     .init("Scan a receipt", systemImage: "doc.viewfinder") { scan() },
///     .init("Transfer", systemImage: "arrow.left.arrow.right") { transfer() },
///     .init("Expense", systemImage: "minus") { addExpense() },
/// ])
/// ```
///
/// An action closes the menu after it runs. VoiceOver reads each action's title.
public struct GlassActionMenu: View {
    /// One action of the menu.
    public struct Item: Identifiable {
        public let id: String
        public let title: String
        public let systemImage: String
        public let action: () -> Void

        public init(_ title: String, systemImage: String, id: String? = nil, action: @escaping () -> Void) {
            self.id = id ?? title
            self.title = title
            self.systemImage = systemImage
            self.action = action
        }
    }

    /// Where the actions open towards.
    public enum Direction: Hashable, Sendable {
        /// Above the button (a corner of the screen, the default).
        case up
        /// To the leading side.
        case leading
    }

    let systemImage: String
    let items: [Item]
    let direction: Direction
    let tint: Color

    @State private var isOpen = false
    @Namespace private var glass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - systemImage: The closed button's symbol; it turns into "xmark" while open.
    ///   - tint: The closed button's glass tint, the accent by default.
    public init(
        systemImage: String = "plus",
        items: [Item],
        direction: Direction = .up,
        tint: Color = AppColors.accent
    ) {
        self.systemImage = systemImage
        self.items = items
        self.direction = direction
        self.tint = tint
    }

    public var body: some View {
        GlassEffectContainer(spacing: GlassActionMenuMetrics.spacing) {
            switch direction {
            case .up:
                VStack(spacing: GlassActionMenuMetrics.spacing) {
                    actions
                    toggle
                }
            case .leading:
                HStack(spacing: GlassActionMenuMetrics.spacing) {
                    actions
                    toggle
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if isOpen {
            ForEach(items) { item in
                Button {
                    HapticManager.light()
                    item.action()
                    setOpen(false)
                } label: {
                    Image(systemName: item.systemImage)
                        .font(.system(size: AppIconSize.md, weight: .semibold))
                        .frame(width: GlassActionMenuMetrics.action, height: GlassActionMenuMetrics.action)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .glassEffectID(item.id, in: glass)
                .accessibilityLabel(Text(verbatim: item.title))
                .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.identity)
            }
        }
    }

    private var toggle: some View {
        Button {
            HapticManager.selection()
            setOpen(!isOpen)
        } label: {
            Image(systemName: isOpen ? "xmark" : systemImage)
                .font(.system(size: AppIconSize.lg, weight: .semibold))
                .foregroundStyle(isOpen ? AppColors.Text.primary : AppColors.Text.onAccent)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: GlassActionMenuMetrics.button, height: GlassActionMenuMetrics.button)
        }
        .buttonStyle(.plain)
        .glassEffect(isOpen ? Glass.regular.interactive() : Glass.regular.tint(tint).interactive(), in: Circle())
        .glassEffectID("toggle", in: glass)
        .accessibilityLabel(Text(verbatim: isOpen
            ? String(localized: "menu.close", defaultValue: "Close")
            : String(localized: "menu.open", defaultValue: "Actions")))
    }

    private func setOpen(_ open: Bool) {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AppAnimation.bouncy) {
            isOpen = open
        }
    }
}

enum GlassActionMenuMetrics {
    /// The closed button: a comfortable floating target.
    static let button: CGFloat = 56
    /// An action.
    static let action: CGFloat = AppIconSize.Tile.lg
    /// Between the glass shapes; also the container's blending distance.
    static let spacing: CGFloat = AppSpacing.md
}
