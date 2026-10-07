//
//  AppSpacing.swift
//  Tenra
//
//  Spatial tokens: spacing, corner radii, icon sizes, container sizes.
//

import CoreGraphics

// MARK: - Spacing System (4pt Grid)

/// Консистентная система отступов на основе 4pt grid
/// Используй ТОЛЬКО эти значения для всех spacing и padding
public enum AppSpacing {
    /// 2pt - Минимальный отступ (tight inline spacing, fine-tuned layouts)
    public static let xxs: CGFloat = 2

    /// 4pt - Микро отступ (между иконкой и текстом в одной строке)
    public static let xs: CGFloat = 4

    /// 8pt - Малый отступ (vertical padding для rows, spacing внутри кнопок)
    public static let sm: CGFloat = 8

    /// 12pt - Средний отступ (default VStack/HStack spacing, внутренний padding карточек)
    public static let md: CGFloat = 12

    /// 16pt - Большой отступ (horizontal padding экранов, spacing между карточками)
    public static let lg: CGFloat = 16

    /// 20pt - Очень большой отступ (spacing между major sections)
    public static let xl: CGFloat = 20

    /// 24pt - Максимальный отступ (spacing между screen sections)
    public static let xxl: CGFloat = 24

    /// 32pt - Screen margins (редко используется)
    public static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius System

/// Консистентная система скругления углов
public enum AppRadius {
    /// 4pt - Минимальные элементы (indicators, badges)
    public static let xs: CGFloat = 4

    /// 12pt - Стандартные карточки и кнопки (основной радиус)
    public static let md: CGFloat = 12

    /// 16pt - Большие карточки
    public static let lg: CGFloat = 16

    /// 20pt - Large radius (cards, pills, filter chips)
    public static let xl: CGFloat = 20

    // MARK: - Semantic Radius

    /// Card corner radius (alias для md)
    public static let card: CGFloat = md

    /// Button corner radius (alias для md)
    public static let button: CGFloat = md

    /// The soft corner of a skeleton shape whose component has no corner of its own: a line of
    /// text, an amount, a chart's plot area. 12 pt, which on a line of text (shorter than 24 pt)
    /// rounds the ends fully. A shape that stands for something with its own corner (a card, a
    /// chip, an icon) takes that corner instead.
    public static let soft: CGFloat = md
}

// MARK: - Icon Sizing System

/// Icon sizes, two scales named like `AppSpacing`:
///
/// - **Glyphs** (`AppIconSize.xs` … `.xxl`, 12–40): an SF Symbol, a logo or an avatar on its
///   own — in text, a toolbar, a row.
/// - **Tiles** (`AppIconSize.Tile.sm` … `.xxxl`, 44–80): an icon with its own backing — a
///   circle or rounded square with the icon's padding, a category coin, a hero symbol.
///
/// 2.0.0: 40 pt moved from the tiles (`Tile.xs`) to the glyphs (`xxl`): at 40 pt the icon's
/// padding rules do not apply, so it is a glyph; the smallest tile is `Tile.sm`, 44 pt. The
/// names deprecated in 1.13.0 (`avatar`, `categoryIcon`, `mega`, `budgetRing`, `ultra`, and the
/// old `xxl` = 44 / `xxxl` = 48) are gone.
public enum AppIconSize {
    /// 12 pt — a glyph at caption size (a status dot's symbol, a tiny mark).
    public static let xs: CGFloat = 12

    /// 16 pt — inline icons (in text, small indicators).
    public static let sm: CGFloat = 16

    /// 20 pt — default icons (toolbar, list rows).
    public static let md: CGFloat = 20

    /// 24 pt — emphasized icons.
    public static let lg: CGFloat = 24

    /// 32 pt — large glyphs and logos.
    public static let xl: CGFloat = 32

    /// 40 pt — an avatar, a logo in a row (2.0.0; `Tile.xs` before).
    public static let xxl: CGFloat = 40

    /// Icons with their own backing (circle, rounded square), coins, heroes.
    public enum Tile {
        /// 40 pt — not a tile: too small for an icon's padding.
        @available(*, deprecated, renamed: "AppIconSize.xxl", message: "40 pt is a glyph since 2.0.0: AppIconSize.xxl.")
        public static let xs: CGFloat = 40

        /// 44 pt — the smallest tile: the icon of a content row (`Icon`'s default).
        public static let sm: CGFloat = 44

        /// 48 pt — an empty state's icon.
        public static let md: CGFloat = 48

        /// 52 pt — a category coin.
        public static let lg: CGFloat = 52

        /// 64 pt — a large tile (category coin in a grid, a profile avatar).
        public static let xl: CGFloat = 64

        /// 72 pt — a ring around an `xl` tile (an 8 pt stroke).
        public static let xxl: CGFloat = 72

        /// 80 pt — a hero icon.
        public static let xxxl: CGFloat = 80
    }
}
