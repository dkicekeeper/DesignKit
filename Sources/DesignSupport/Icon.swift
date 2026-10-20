//
//  Icon.swift
//  Tenra
//
//  Unified icon and logo display component with full Design System integration
//  Created: 2026-02-12
//

import SwiftUI
import DesignTokens

/// Универсальный компонент для отображения иконок и логотипов
/// Полностью интегрирован с Design System (AppTheme.swift)
///
/// 7.0.0 (the owner's rule): every icon in DesignKit is an `Icon`, and its size says what it
/// is (`IconKind`). Under 44 pt a **glyph**: the symbol at its size, no plate, growing with the
/// text size. From 44 pt a **tile**: the symbol on a plate with room around it (20 % of the
/// side to 63 pt, 25 % from 64 pt), at its size. A logo fills its shape at any size.
///
/// # Примеры использования:
///
/// ## SF Symbol с пресетом
/// ```swift
/// Icon(source: .sfSymbol("star.fill"), style: .categoryIcon())
/// ```
///
/// ## Динамический логотип сервиса
/// ```swift
/// Icon(source: .brandService("netflix"), style: .serviceLogo())
/// ```
///
/// ## Полный контроль над стилем
/// ```swift
/// Icon(
///     source: .sfSymbol("heart.fill"),
///     style: .circle(
///         size: AppIconSize.xl,
///         tint: .monochrome(.red),
///         backgroundColor: AppColors.Background.neutral1
///     )
/// )
/// ```
public struct Icon: View {

    // MARK: - Properties

    let source: IconSource?
    let style: IconStyle
    /// A glyph's side as the text size scales it (7.0.0); a tile keeps `style.size`.
    @ScaledMetric private var scaledSide: CGFloat

    // MARK: - Initializers

    public init(source: IconSource?, style: IconStyle) {
        self.source = source
        self.style = style
        self._scaledSide = ScaledMetric(wrappedValue: style.size, relativeTo: .body)
    }

    /// Convenience initializer с автоматическим выбором стиля по типу источника
    /// - Parameters:
    ///   - source: Источник иконки (IconSource)
    ///   - size: Размер иконки (по умолчанию AppIconSize.Tile.sm=44pt из Design System)
    public init(source: IconSource?, size: CGFloat = AppIconSize.Tile.sm) {
        self.source = source

        // Автоматический выбор стиля в зависимости от типа источника
        switch source {
        case .sfSymbol:
            self.style = .categoryIcon(size: size)
        case .brandService:
            self.style = .serviceLogo(size: size)
        case .none:
            self.style = .placeholder(size: size)
        }
        self._scaledSide = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    /// A glyph of an SF Symbol (7.0.0): `size` points, in `tint` (by default the colour around
    /// it), no plate.
    ///
    /// ```swift
    /// Icon("checkmark.circle.fill", size: AppIconSize.sm, tint: .monochrome(AppColors.success))
    /// ```
    ///
    /// - Parameter scalesWithText: Whether it grows with the text size (the default); off for a
    ///   symbol in a control of a fixed size (a round button, a key).
    public init(
        _ systemName: String,
        size: CGFloat = AppIconSize.md,
        tint: IconTint = .inherit,
        scalesWithText: Bool = true
    ) {
        self.init(source: .sfSymbol(systemName), style: IconStyle.glyph(size, tint: tint).scaling(scalesWithText))
    }

    // MARK: - Body

    public var body: some View {
        containerView {
            contentView
                .frame(width: contentSize, height: contentSize)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Computed Properties

    private var isTile: Bool { style.kind == .tile }

    private var isLogo: Bool {
        if case .brandService = source { return true }
        return false
    }

    /// The icon's side: a glyph's grows with the text size unless its style holds it.
    private var side: CGFloat {
        isTile || !style.scalesWithText ? style.size : scaledSide
    }

    /// Room between the plate's edge and the symbol: none for a glyph (the symbol is the
    /// icon), 20 % of the side for a tile to 63 pt and 25 % from 64 pt; an explicit `padding`
    /// sets a tile's. A logo fills its shape unless its style pads it.
    private var effectivePadding: CGFloat {
        if isLogo { return style.padding ?? 0 }
        guard isTile else { return 0 }
        if let explicitPadding = style.padding { return explicitPadding }
        return side * (side < IconMetrics.largeTile ? IconMetrics.tilePadding : IconMetrics.largeTilePadding)
    }

    /// What the icon sits on: a tile's plate (its style's colour, else the neutral fill; with
    /// glass, the glass and the colour if any), nothing for a glyph. A logo keeps its style's.
    private var plateColor: Color? {
        if isLogo { return style.backgroundColor }
        guard isTile else { return nil }
        if style.hasGlassEffect { return style.backgroundColor }
        return style.backgroundColor ?? AppColors.Background.neutral1
    }

    /// Glass on a tile or a logo; a glyph has no plate to be glass.
    private var hasGlass: Bool {
        style.hasGlassEffect && (isTile || isLogo)
    }

    /// Размер контента с учетом padding
    private var contentSize: CGFloat {
        side - effectivePadding * 2
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch source {
        case .sfSymbol(let name):
            sfSymbolView(name)
        case .brandService(let name):
            brandServiceView(name)
        case .none:
            placeholderView
        }
    }

    // MARK: - SF Symbol View

    @ViewBuilder
    private func sfSymbolView(_ symbolName: String) -> some View {
        let image = Image(systemName: symbolName)
            .resizable()
            .aspectRatio(contentMode: style.contentMode)

        // Применяем rendering mode в зависимости от tint
        switch style.tint {
        case .monochrome(let color):
            image
                .foregroundStyle(color)

        case .hierarchical(let color):
            image
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)

        case .palette(let colors):
            applyPalette(to: image, colors: colors)

        case .original:
            image
                .foregroundStyle(AppColors.accent)
        case .inherit:
            image
        }
    }

    @ViewBuilder
    private func applyPalette(to image: some View, colors: [Color]) -> some View {
        switch colors.count {
        case 1:
            image
                .symbolRenderingMode(.palette)
                .foregroundStyle(colors[0])
        case 2:
            image
                .symbolRenderingMode(.palette)
                .foregroundStyle(colors[0], colors[1])
        case 3...:
            image
                .symbolRenderingMode(.palette)
                .foregroundStyle(colors[0], colors[1], colors[2])
        default:
            image
                .foregroundStyle(AppColors.accent)
        }
    }

    // MARK: - Brand Service View

    @ViewBuilder
    private func brandServiceView(_ brandName: String) -> some View {
        BrandLogoImage(brandName: brandName, size: contentSize)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(AppColors.Text.secondary)
    }

    // MARK: - Container View

    @ViewBuilder
    private func containerView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let baseView = content()
            .frame(width: side, height: side)

        // Определяем, нужно ли обрезать контент (только для изображений, не для SF Symbols)
        let shouldClipContent = shouldClipContentForSource()

        // Применяем фон если задан
        let viewWithBackground = Group {
            if let bgColor = plateColor {
                // Для SF Symbols обрезаем только фон, не контент
                if shouldClipContent {
                    baseView.background(bgColor)
                } else {
                    // Для SF Symbols - фон с формой, но контент не обрезается
                    switch style.shape {
                    case .circle:
                        baseView.background(Circle().fill(bgColor))
                    case .roundedSquare(let radius):
                        baseView.background(RoundedRectangle(cornerRadius: radius).fill(bgColor))
                    case .square:
                        baseView.background(Rectangle().fill(bgColor))
                    }
                }
            } else {
                baseView
            }
        }

        // Применяем форму с обрезкой контента ТОЛЬКО для изображений (не SF Symbols)
        let viewWithShape = Group {
            if shouldClipContent {
                // Для изображений (bank logo, brand logo) - обрезаем по форме
                switch style.shape {
                case .circle:
                    viewWithBackground
                        .clipShape(Circle())
                        .contentShape(Circle())

                case .roundedSquare(let radius):
                    viewWithBackground
                        .clipShape(RoundedRectangle(cornerRadius: radius))
                        .contentShape(RoundedRectangle(cornerRadius: radius))

                case .square:
                    viewWithBackground
                        .clipShape(Rectangle())
                        .contentShape(Rectangle())
                }
            } else {
                // Для SF Symbols - только contentShape для tap area
                switch style.shape {
                case .circle:
                    viewWithBackground
                        .contentShape(Circle())

                case .roundedSquare(let radius):
                    viewWithBackground
                        .contentShape(RoundedRectangle(cornerRadius: radius))

                case .square:
                    viewWithBackground
                        .contentShape(Rectangle())
                }
            }
        }

        // Применяем glass effect если требуется
        if hasGlass {
            switch style.shape {
            case .circle:
                viewWithShape
                    .glassEffect(in: Circle())
            case .roundedSquare(let radius):
                viewWithShape
                    .glassEffect(in: RoundedRectangle(cornerRadius: radius))
            case .square:
                viewWithShape
                    .glassEffect(in: Rectangle())
            }
        } else {
            viewWithShape
        }
    }

    // MARK: - Helper Methods

    /// Определяет, нужно ли обрезать контент по форме контейнера
    /// SF Symbols не обрезаются, только изображения (bank logos, brand logos)
    private func shouldClipContentForSource() -> Bool {
        switch source {
        case .sfSymbol:
            return false // SF Symbols не обрезаются
        case .brandService:
            return true // Изображения обрезаются
        case .none:
            return false // Placeholder не обрезается
        }
    }
}

/// The tile's room around its symbol (7.0.0).
enum IconMetrics {
    /// From this side a tile is large and gets more room.
    static let largeTile: CGFloat = 64
    /// A tile's padding, of its side, to 63 pt.
    static let tilePadding: CGFloat = 0.2
    /// A large tile's padding, of its side.
    static let largeTilePadding: CGFloat = 0.25
}
