//
//  AppColors.swift
//  Tenra
//
//  Semantic color tokens + category palette. Single source of truth for all colors.
//

import SwiftUI

// MARK: - Semantic Colors

/// Semantic colours. Since 1.6.0 the canonical tokens are grouped (`AppColors.Text`,
/// `.Background`, `.Status`, `.Border`: AppColors+Semantic.swift); the flat names below are
/// aliases of them and keep working.
public enum AppColors {
    // MARK: Backgrounds
    //
    // Три уровня иерархии — base → card → muted.
    // bgBase   — фон самого экрана.
    // bgCard   — приподнятая поверхность (карточки, fallback под cardStyle на iOS<26).
    // bgMuted  — "утопленный" слой внутри карточек (треки прогресс-баров, фон чипов).

    /// Фон самого экрана.
    public static let bgBase = Background.page

    /// Приподнятая поверхность — карточки, elevated containers.
    public static let bgCard = Background.card

    /// "Утопленный" фон — chips, прогресс-бар треки, secondary buttons.
    public static let bgMuted = SurfaceStyle.glass.containerStrong

    // MARK: Text Colors

    /// Primary text (используй системный .primary для auto light/dark)
    public static let textPrimary = Text.primary

    /// Secondary text — системный адаптивный цвет (.secondary).
    public static let textSecondary = Text.secondary

    /// Tertiary text (используй системный .gray для мета-информации)
    public nonisolated static let textTertiary = Text.tertiary

    // MARK: Interactive Colors

    /// Accent color (для выделений, selections).
    /// Configured per app via `DesignKitTheme.accent` (default: indigo).
    public nonisolated static var accent: Color { DesignKitTheme.accent }

    /// The accent as a fill under white text or a white symbol (8.10.0): a primary button, the
    /// person's own message, a send button, a picked day or icon. `readableFill` of the accent, so
    /// white on it is 4.5:1 in both themes: Tenra's indigo is a step deeper in dark mode only,
    /// Dalada's green a step deeper in both. Tints, outlines and tracks keep `accent`.
    public nonisolated static var accentFill: Color { readableFill(DesignKitTheme.accent) }

    /// Destructive actions
    public nonisolated static let destructive = Status.negative

    /// Success/positive — используй для UI-состояний (кнопки, индикаторы).
    /// Для финансового дохода используй `income`.
    public nonisolated static let success = Status.positive

    /// Warning
    public nonisolated static let warning = Status.warning

    // MARK: Static Colors

    /// Белый цвет без адаптации к теме — для текста поверх тёмных/цветных фонов.
    /// Не используй для обычного текста: предпочитай `textPrimary`.
    public static let staticWhite = Text.primaryOnDark

    // MARK: Transaction Type Colors (semantic)

    /// Income transactions — финансово-специфичный зелёный.
    /// Не зависит от `success`: если дизайн меняет success, income не изменится.
    /// `nonisolated` so the nonisolated `InsightsService` can read it without a
    /// MainActor hop (`Color` is `Sendable`).
    public nonisolated static let income = Color(red: 0.13, green: 0.70, blue: 0.37)

    /// Income as text (8.10.0): an amount of money in, a "paid" mark. `readable(income)`: 4.5:1 on
    /// the page and on its tint (the bright `income` reads at 2.75:1 on white). Fills, bars, icons
    /// on a plate and chart marks keep `income`.
    public nonisolated static let incomeText = readable(income)

    /// Expense transactions.
    /// Сознательно НЕ красный (как могло бы подсказать "destructive"-чтение расхода):
    /// если бы расходы рендерились красным, всё приложение визуально кричало бы
    /// тревогой — большинство транзакций это расходы. Чёрный (`.primary`) даёт
    /// нейтральный baseline, а контраст создаётся через `income` (зелёный)
    /// и `transfer` (cyan). Резолвится в тот же цвет, что и `textPrimary`,
    /// но семантически это отдельный токен — менять расход на другой цвет
    /// (если когда-нибудь понадобится) можно будет в одной точке.
    public nonisolated static let expense = Color.primary

    /// Transfer / internal transactions (distinct cyan-teal, not accent blue)
    public static let transfer = Color(red: 0.0, green: 0.75, blue: 0.85)

    /// Planned / future / scheduled transactions
    public static let planned = Status.info

}

// MARK: - Category Color Palette

/// The colour of a name, by hash, and the colours a person picks. Deprecated (vNext): the same
/// colours as `AppColors.Data`, which names them for any data, not one app's categories.
@available(*, deprecated, message: "Use AppColors.Data (color(for:opacity:), paletteIndex(for:), palette, pickerPalette).")
public struct CategoryColors {
    /// The colours a user can pick: `AppColors.Data.pickerPalette`.
    public nonisolated static var pickerPalette: [String] { AppColors.Data.pickerPalette }

    /// The 14 hash palette colours: `AppColors.Data.palette`.
    public nonisolated static var paletteColors: [Color] { AppColors.Data.palette }

    /// The colour of a name: `AppColors.Data.color(for:opacity:)`.
    public nonisolated static func color(for name: String, opacity: Double = 1.0) -> Color {
        AppColors.Data.color(for: name, opacity: opacity)
    }

    /// The palette slot of a name: `AppColors.Data.paletteIndex(for:)`.
    public nonisolated static func paletteIndex(for category: String) -> Int {
        AppColors.Data.paletteIndex(for: category)
    }
}
