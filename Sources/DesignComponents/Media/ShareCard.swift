//
//  ShareCard.swift
//  DesignKit
//
//  A picture to share in Stories or a chat (2.8.0): a fixed-size card, a photo filling it under
//  a dark gradient (or a dark gradient alone), the content at the top, the brand and the site at
//  the bottom. `ShareCardSheet` renders it to an image. Ported from Dalada's ShareCardFrame and
//  ShareCardStat; the brand, the site and the colours are parameters, the cards' content stays in
//  the app.
//
//  The card is an image, not a screen: its sizes are fixed points (360 wide, rendered at 3× to
//  1080 px), so the type does not follow Dynamic Type and the colours do not follow the theme.
//
//  8.16.0 (Tenra's year in review, the founder: a shared picture should say which app it is):
//  the app's icon before its name in the brand line, and the name in Inter as well as rounded.
//

import SwiftUI
import UIKit
import DesignTokens

/// The pieces of a share card: its formats and its colours. (A namespace, so an app's own
/// `ShareCardFormat` does not clash.)
public enum ShareCard {
    /// The shapes of a share card: a Stories frame or a post.
    public enum Format: String, CaseIterable, Identifiable, Hashable, Sendable {
        /// 9:16, for Stories.
        case story
        /// 4:5, for a post or a chat.
        case post

        public var id: String { rawValue }

        /// "Stories", "Post".
        public var title: String {
            switch self {
            case .story: String(localized: "share.format.story", defaultValue: "Stories")
            case .post: String(localized: "share.format.post", defaultValue: "Post")
            }
        }

        public var width: CGFloat { 360 }

        public var height: CGFloat {
            switch self {
            case .story: 640
            case .post: 450
            }
        }

        /// The rendering scale: 360 points become 1080 pixels.
        public static let scale: CGFloat = 3
    }

    /// How the brand line sets the app's name (8.16.0).
    public enum BrandTypeface: Hashable, Sendable {
        /// Rounded and heavy (the look before 8.16.0, Dalada's).
        case rounded
        /// Inter, DesignKit's typeface, bold (Tenra's).
        case inter
    }

    /// The colours of a share card. They stay the same in light and dark mode: the picture leaves
    /// the app.
    public struct Style: Sendable {
        /// The gradient behind a card with no photo, top to bottom.
        public let top: Color
        public let bottom: Color
        /// The kicker over the title ("Fishing"), a track, an icon.
        public let accent: Color
        /// The brand's name: rounded by default, Inter for an app set in it (8.16.0).
        public let brandTypeface: BrandTypeface

        public init(top: Color, bottom: Color, accent: Color, brandTypeface: BrandTypeface = .rounded) {
            self.top = top
            self.bottom = bottom
            self.accent = accent
            self.brandTypeface = brandTypeface
        }

        /// Graphite with the accent.
        public static var standard: Style {
            Style(
                top: Color(red: 0.12, green: 0.13, blue: 0.16),
                bottom: Color(red: 0.03, green: 0.03, blue: 0.04),
                accent: AppColors.accent
            )
        }
    }
}

enum ShareCardMetrics {
    static let padding: CGFloat = 28
    static let brandGap: CGFloat = 20
    static let brandSize: CGFloat = 22
    static let siteSize: CGFloat = 11
    static let statValueSize: CGFloat = 24
    static let statTitleSize: CGFloat = 12
    /// The app's icon before its name (8.16.0): a little taller than the name, with the
    /// home screen's corner (22.5 % of its side, continuous).
    static let brandIconSize: CGFloat = 30
    static let brandIconCorner: CGFloat = 0.225
    static let brandIconGap: CGFloat = 10
}

/// A share card's frame: the photo or gradient, the content from the top, and the brand line.
///
/// ```swift
/// ShareCardFrame(format: format, brand: "Dalada", site: "dalada.kz", photo: photo) {
///     Text("Kapchagay").font(.system(size: 34, weight: .bold))
///     ShareCardStat(value: "12.4 km", title: "Distance")
/// }
/// ```
///
/// The content is white; lay it out with fixed point sizes, as the card is an image.
///
/// With the app's icon (8.16.0), the brand line shows which app the picture is from:
///
/// ```swift
/// ShareCardFrame(
///     format: .story, brand: "Tenra", brandIcon: UIImage(named: "AppIconImage"),
///     style: ShareCard.Style(top: …, bottom: …, accent: …, brandTypeface: .inter)
/// ) { … }
/// ```
public struct ShareCardFrame<Content: View>: View {
    let format: ShareCard.Format
    let brand: String
    let brandIcon: UIImage?
    let site: String?
    let photo: UIImage?
    let style: ShareCard.Style
    let content: Content

    /// - Parameters:
    ///   - brand: The name at the bottom left ("Dalada").
    ///   - brandIcon: The app's icon before the name, in the home screen's rounded square
    ///     (8.16.0). An app icon set cannot be read as an image: add the icon as an image set.
    ///   - site: At the bottom right, small ("dalada.kz").
    ///   - photo: Fills the card under a dark gradient; without it, the style's gradient.
    public init(
        format: ShareCard.Format,
        brand: String,
        brandIcon: UIImage? = nil,
        site: String? = nil,
        photo: UIImage? = nil,
        style: ShareCard.Style = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.format = format
        self.brand = brand
        self.brandIcon = brandIcon
        self.site = site
        self.photo = photo
        self.style = style
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            brandLine
                .padding(.top, ShareCardMetrics.brandGap)
        }
        .padding(ShareCardMetrics.padding)
        .frame(width: format.width, height: format.height, alignment: .topLeading)
        .foregroundStyle(.white)
        .background { background }
        .clipped()
    }

    @ViewBuilder
    private var background: some View {
        if let photo {
            Color.black
                .overlay {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                }
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.35), .clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipped()
        } else {
            LinearGradient(colors: [style.top, style.bottom], startPoint: .top, endPoint: .bottom)
        }
    }

    private var brandLine: some View {
        HStack(spacing: ShareCardMetrics.brandIconGap) {
            if let brandIcon {
                Image(uiImage: brandIcon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: ShareCardMetrics.brandIconSize, height: ShareCardMetrics.brandIconSize)
                    .clipShape(RoundedRectangle(
                        cornerRadius: ShareCardMetrics.brandIconSize * ShareCardMetrics.brandIconCorner,
                        style: .continuous
                    ))
                    .accessibilityHidden(true)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: brand)
                    .font(brandFont)
                Spacer(minLength: AppSpacing.sm)
                if let site {
                    Text(verbatim: site)
                        .font(.system(size: ShareCardMetrics.siteSize, weight: .medium))
                        .opacity(0.7)
                        .lineLimit(1)
                }
            }
        }
    }

    private var brandFont: Font {
        switch style.brandTypeface {
        case .rounded:
            .system(size: ShareCardMetrics.brandSize, weight: .heavy, design: .rounded)
        case .inter:
            .custom(AppInterFont.family, fixedSize: ShareCardMetrics.brandSize).weight(.bold)
        }
    }
}

/// A number on a share card with its caption under it ("12.4 km" / "Distance").
public struct ShareCardStat: View {
    let value: String
    let title: String

    public init(value: String, title: String) {
        self.value = value
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value)
                .font(.system(size: ShareCardMetrics.statValueSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(verbatim: title)
                .font(.system(size: ShareCardMetrics.statTitleSize, weight: .medium))
                .opacity(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Skeleton

/// Placeholder of a share card's preview while its data loads: the card's shape, scaled to fit.
public struct ShareCardSkeleton: View {
    let format: ShareCard.Format

    public init(format: ShareCard.Format = .story) {
        self.format = format
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.lg)
            .fill(Skeleton.fill)
            .aspectRatio(format.width / format.height, contentMode: .fit)
            .shimmer()
            .skeletonLoadingLabel()
    }
}
