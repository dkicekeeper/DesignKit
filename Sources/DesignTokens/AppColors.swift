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
    public static let bgBase = Background.base

    /// Приподнятая поверхность — карточки, elevated containers.
    public static let bgCard = Background.neutral1

    /// "Утопленный" фон — chips, прогресс-бар треки, secondary buttons.
    public static let bgMuted = Background.neutral2

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

/// Цвета для категорий транзакций — hash-based assignment из палитры
public struct CategoryColors {
    /// Pre-computed color palette (avoids hex parsing on every call)
    private nonisolated static let palette: [Color] = {
        let hexValues: [UInt64] = [
            0x3b82f6, 0x8b5cf6, 0xec4899, 0xf97316, 0xeab308,
            0x22c55e, 0x14b8a6, 0x06b6d4, 0x6366f1, 0xd946ef,
            0xf43f5e, 0xa855f7, 0x10b981, 0xf59e0b
        ]
        return hexValues.map { rgb in
            Color(
                red:   Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8)  / 255.0,
                blue:  Double( rgb & 0x0000FF)         / 255.0
            )
        }
    }()

    /// The 14 palette colours in order: what categories hash into, and what an app's own
    /// name-coloured visuals (letter avatars) draw from, so both share one palette.
    public nonisolated static var paletteColors: [Color] { palette }

    /// Deterministic color for a category name, hashed into the palette.
    /// (DesignKit drops Tenra's custom-category override; the palette is the single source.)
    public nonisolated static func hexColor(for category: String, opacity: Double = 1.0) -> Color {
        palette[paletteIndex(for: category)].opacity(opacity)
    }

    /// Palette slot for a category name: the same on every launch and every device.
    ///
    /// FNV-1a over the UTF-8 bytes. Until 0.7.0 this used `String.hashValue`, which Swift seeds
    /// per process, so a category's fallback colour changed on every launch.
    public nonisolated static func paletteIndex(for category: String) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in category.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(palette.count))
    }
}
