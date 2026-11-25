//
//  AppModifiers.swift
//  Tenra
//
//  SwiftUI view modifiers for consistent styling across the app.
//

import SwiftUI

// MARK: - Card & Row Styles

public extension View {
    /// Interactive filter chip — Liquid Glass surface.
    ///
    /// The `isSelected` state adds an `accent` tint.
    ///
    /// **Use when:** the chip triggers filtering, navigation, or any tap action
    /// (filter buttons, action menu triggers, segmented-style selectors in toolbars).
    ///
    /// Under `SurfaceStyle.fill` (8.12.0) the chip is a grey capsule (`.surfaceNeutral1`), the
    /// selected one the accent's pale tint.
    func filterChipStyle(isSelected: Bool = false) -> some View {
        self
            .font(AppTypography.bodySmall.weight(.medium))
            .foregroundStyle(AppColors.Text.primary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .clipShape(.rect(cornerRadius: AppRadius.xl))
            .modifier(FilterChipSurface(isSelected: isSelected))
            .animation(AppAnimation.contentSpring, value: isSelected)
    }

    /// Применяет glass effect с стандартным cornerRadius для карточек (iOS 26+).
    /// Padding НЕ добавляется — ответственность за отступы лежит на содержимом
    /// (строки используют собственный padding; произвольный контент добавляет .padding перед вызовом).
    ///
    /// **Use this for every card** (AccountCard, LoanCard, HealthScoreCard, hero sections) and,
    /// since 8.0.0, for form sections too: `FormSection` and `CardList` are built on it, and a
    /// `Picker(.menu)` / `Menu` inside opens from its row (a device probe showed it; the fear that
    /// glass would become the menu's morph source and collapse a one-row section into the popover
    /// came from an early iOS 26 build, docs/gotchas.md).
    ///
    /// 3.0.0: the glass is drawn behind the content, not applied to it. Applied to the content,
    /// Liquid Glass blended each layer into the layers under it (darker in light mode, lighter
    /// in dark): a marker over an arc looked translucent, a label over its pale capsule changed
    /// colour. Behind it, the content keeps its exact colours; the card itself looks the same.
    ///
    /// 8.12.0: under `SurfaceStyle.fill` (`DesignKitTheme.surface`, `.surfaceStyle(_:)`) the card
    /// is the opaque grey `AppColors.Background.neutral1` instead of glass, in the same shape.
    ///
    /// vNext: the content knows it lies on a card, so a knockout in it (`.surfaceBackground`) is
    /// the card's grey under `.fill`, not the page's white.
    func cardStyle(radius: CGFloat = AppRadius.xl) -> some View {
        modifier(CardSurface(radius: radius))
    }

    /// The accent outline of a chosen option (5.0.0): one look for the cards and tiles a person
    /// picks from (`OptionCardPicker`, `PickerCarousel`, `IconPicker`), 2 pt on the shape's edge, clear
    /// when not chosen.
    func selectionOutline(_ isSelected: Bool, cornerRadius: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: AppSelection.outline)
        )
    }

    /// A Material card (`.ultraThinMaterial` on every iOS), for a host that wants one; the same
    /// shape and padding contract as `cardStyle()`. `FormSection` used it up to 7.x, for fear
    /// that iOS 26's Liquid Glass would become the morph source of a menu inside it and collapse
    /// a one-row section into the popover; since 8.0.0 `FormSection` is glass (`cardStyle()`),
    /// and menus open from their row there. It does not follow `SurfaceStyle`.
    func formCardStyle(radius: CGFloat = AppRadius.xl) -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: radius)
            )
    }
}

/// The card behind `cardStyle()`: Liquid Glass, or the grey of `SurfaceStyle.fill` (8.12.0).
private struct CardSurface: ViewModifier {
    let radius: CGFloat
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        content
            // The content lies on the card: its knockouts take the card's colour (vNext).
            .environment(\.isOnCard, true)
            .contentShape(Rectangle())
            .clipShape(.rect(cornerRadius: radius))
            .background {
                switch surface {
                case .glass:
                    Color.clear.glassEffect(.regular, in: .rect(cornerRadius: radius))
                case .fill:
                    Color.clear.background(AppColors.Background.neutral1, in: .rect(cornerRadius: radius))
                }
            }
    }
}

/// The surface of `filterChipStyle()`: interactive glass, accent-tinted when selected; under
/// `SurfaceStyle.fill` a grey capsule, the accent's pale tint when selected (8.12.0).
private struct FilterChipSurface: ViewModifier {
    let isSelected: Bool
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        switch surface {
        case .glass:
            content.glassEffect(
                isSelected
                ? .regular.tint(AppColors.accent.opacity(0.2)).interactive()
                : .regular.interactive()
            )
        case .fill:
            content.background(
                isSelected ? AnyShapeStyle(AppColors.pale(AppColors.accent)) : AnyShapeStyle(.surfaceNeutral1),
                in: Capsule()
            )
        }
    }
}

// MARK: - Layout Helpers

public extension View {
    /// Стандартный horizontal padding для экранов
    func screenPadding() -> some View {
        self.padding(.horizontal, AppSpacing.lg)
    }

    /// Визуально приглушает view для будущих / запланированных транзакций.
    /// Применяй вместо inline `opacity(0.5)` чтобы значение было единым по всему проекту.
    func futureTransactionStyle(isFuture: Bool) -> some View {
        self.opacity(isFuture ? 0.55 : 1.0)
    }

    /// Card padding (внутренний padding карточек) — 16pt, канон для контента карточек (см. design-system §10)
    func cardContentPadding() -> some View {
        self.padding(AppSpacing.lg)
    }
}

// MARK: - Staggered Entrance Modifier

/// Animates a view's entrance with scale + opacity, typically used for facepile icons.
/// Triggers once on first appearance. Respects Reduce Motion accessibility setting.
///
/// ```swift
/// Icon(source: account.iconSource, style: iconStyle)
///     .staggeredEntrance(delay: Double(index) * AppAnimation.facepileStagger)
/// ```
public struct StaggeredEntranceModifier: ViewModifier {
    let delay: Double

    public init(delay: Double = 0) {
        self.delay = delay
    }

    @State private var appeared = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : AppAnimation.facepileHiddenScale)
            .opacity(appeared ? 1 : 0)
            .animation(
                AppAnimation.isReduceMotionEnabled
                    ? .linear(duration: 0)
                    : AppAnimation.facepileSpring.delay(delay),
                value: appeared
            )
            .task { appeared = true }
    }
}

public extension View {
    /// Animates entrance with scale + opacity spring, with optional stagger delay.
    /// - Parameter delay: Delay before animation starts (use `Double(index) * AppAnimation.facepileStagger` for facepiles).
    func staggeredEntrance(delay: Double = 0) -> some View {
        modifier(StaggeredEntranceModifier(delay: delay))
    }
}

// MARK: - Chart Appear Modifier

/// Animates a chart's entrance: fades in + scales up from the bottom edge.
///
/// Apply to any chart container view. Triggers once on first appearance.
/// Respects the user's Reduce Motion accessibility setting.
///
/// ```swift
/// SpendingTrendChart(dataPoints: points, currency: "KZT")
///     .chartAppear()
/// ```
public struct ChartAppearModifier: ViewModifier {
    @State private var appeared = false
    let delay: Double

    public init(delay: Double = 0) {
        self.delay = delay
    }

    public func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : AppAnimation.chartHiddenScale, anchor: .bottom)
            .onAppear {
                withAnimation(
                    AppAnimation.chartAppearAnimation
                        .delay(AppAnimation.chartAppearDelay + delay)
                ) {
                    appeared = true
                }
            }
    }
}

public extension View {
    /// Animates chart entrance with opacity + scale spring from the bottom.
    /// - Parameter delay: Extra delay before animation starts (use to stagger multiple charts).
    func chartAppear(delay: Double = 0) -> some View {
        modifier(ChartAppearModifier(delay: delay))
    }
}

// MARK: - Scroll edges

public extension View {
    /// The soft scroll edge effect, top and bottom, for the scroll views in this hierarchy
    /// (5.4.0): what iOS 26 draws under the navigation bar, the tab bar and a `safeAreaBar`.
    /// Built with Xcode 27 the effect as it comes on iOS 27 is hard, an almost opaque plate
    /// with a line, under the navigation bar too. Put it on every `NavigationStack`, a sheet's
    /// included: a sheet's stack does not take it from the screen under it (docs/gotchas.md).
    /// A scroll view that names its own style keeps it (a chat's hard top).
    ///
    /// On iOS 26 it sets nothing (the effect as it comes is soft there). Built with Xcode 26
    /// it sets nothing either: on iOS 27 such a build blurs only the status bar with a soft
    /// top and leaves the title on sharp content, so the system's own bar stays.
    @ViewBuilder
    func softScrollEdges() -> some View {
        #if compiler(>=6.4) // iOS 27 SDK (Xcode 27); Xcode 26 builds keep the system's edge
        if #available(iOS 27, *) {
            scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// The chosen option's outline (`selectionOutline`, 5.0.0).
public enum AppSelection {
    /// 2 pt: `OptionCard` (removed in 6.0.0) drew 3 pt before 5.0.0, `PickerCarousel` and `IconPicker` 2 pt.
    public static let outline: CGFloat = 2
}
