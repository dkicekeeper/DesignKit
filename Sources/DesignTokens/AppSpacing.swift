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
}

// MARK: - Icon Sizing System

/// Консистентная система размеров иконок
public enum AppIconSize {
    /// 16pt - Inline icons (в тексте, мелкие индикаторы)
    public static let sm: CGFloat = 16

    /// 20pt - Default icons (toolbar, списки)
    public static let md: CGFloat = 20

    /// 24pt - Emphasized icons (category icons в списках)
    public static let lg: CGFloat = 24

    /// 32pt - Large icons (bank logos)
    public static let xl: CGFloat = 32

    /// 40pt - Medium avatar size (logo picker, subscription icons)
    public static let avatar: CGFloat = 40

    /// 44pt - Extra large (category circles в QuickAdd)
    public static let xxl: CGFloat = 44

    /// 48pt - Hero icons (empty states)
    public static let xxxl: CGFloat = 48

    /// 52pt - Category row icons
    public static let categoryIcon: CGFloat = 52

    /// 64pt - Mega icons (category coins, large display elements)
    public static let mega: CGFloat = 64

    /// 72pt - Budget ring (coin + 8pt stroke space)
    public static let budgetRing: CGFloat = 72

    /// 80pt - Ultra icons (hero sections, large action buttons)
    public static let ultra: CGFloat = 80
}
