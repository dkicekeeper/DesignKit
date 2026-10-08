//
//  MediaScreen.swift
//  DesignKit Gallery
//
//  Media and identity: icons and brand logos, avatars, hero symbols, packed icons,
//  achievements, the picture placeholder.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct MediaScreen: View {
    var body: some View {
        ShowcasePage(title: "Media & Identity") {
            IconPage()
            AvatarPage()
            AvatarGroupPage()
            HeroSymbolPage()
            PackedCircleIconsPage()
            AchievementMedalPage()
            AchievementTilePage()
            AchievementProgressRowPage()
            ThumbnailPlaceholderPage()
            PhotoTilePage()
            PhotoStripPage()
            PhotoGridPage()
            PhotoCarouselPage()
            PhotoViewerPage()
            ShareCardFramePage()
        }
    }
}

private struct IconPage: View {
    @State private var source = 0
    @State private var shape = 0
    @State private var tint = 0
    @State private var glass = false
    @State private var size = Double(AppIconSize.Tile.sm)
    @State private var state: SpecimenState = .content

    private var iconSource: IconSource? {
        switch source {
        case 1: return .brandService("netflix.com")
        case 2: return nil
        default: return .sfSymbol("fork.knife")
        }
    }

    private var iconTint: IconTint {
        switch tint {
        case 1: return .monochrome(AppColors.accent)
        case 2: return .hierarchical(AppColors.success)
        default: return .original
        }
    }

    private var style: IconStyle {
        let background: Color? = source == 0 && !glass ? AppColors.pale(AppColors.accent) : nil
        switch shape {
        case 1:
            return .roundedSquare(size: size, tint: iconTint, backgroundColor: background, hasGlassEffect: glass)
        case 2:
            return .square(size: size, tint: iconTint, backgroundColor: background, hasGlassEffect: glass)
        default:
            return .circle(size: size, tint: iconTint, backgroundColor: background, hasGlassEffect: glass)
        }
    }

    var body: some View {
        ComponentPage(
            name: "Icon",
            summary: "Every icon: an SF Symbol or a brand logo (loaded by the app's DesignKitLogoLoader), in a shape, a size, a tint, on glass or not.",
            apps: [.tenra, .dalada],
            notes: [
                "A brand logo is Icon(source: .brandService(\"netflix.com\")); BrandLogoView, its view of its own, was removed in 2.0.0.",
                "Sizes: AppIconSize (glyphs, xs 12 to xxl 40) and AppIconSize.Tile (icons with a backing, sm 44 to xxxl 80).",
            ]
        ) {
            if state == .loading {
                IconSkeleton(style: style)
            } else {
                Icon(source: iconSource, style: style)
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Source", selection: $source, options: [("Symbol", 0), ("Brand logo", 1), ("None", 2)])
            ChoiceControl("Shape", selection: $shape, options: [("Circle", 0), ("Rounded", 1), ("Square", 2)])
            ChoiceControl("Tint", selection: $tint, options: [("Original", 0), ("Mono", 1), ("Hierarchical", 2)])
            ToggleControl("Glass", isOn: $glass)
            SliderControl("Size", value: $size, in: 24...80, step: 4) { "\(Int($0)) pt" }
        }
    }
}

private struct AvatarPage: View {
    @State private var name = "Aida Nurlanovna"
    @State private var size = Double(AppIconSize.xxl)
    @State private var hasPhoto = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "Avatar",
            summary: "A round avatar: the photo when there is one, otherwise the initials on a pale tint.",
            since: "0.4.0",
            apps: [.dalada]
        ) {
            if state == .loading {
                AvatarSkeleton(size: size)
            } else {
                Avatar(name: name, image: hasPhoto ? Image(systemName: "photo.artframe") : nil, size: size)
            }
        } controls: {
            StateControl(state: $state)
            TextControl("Name", text: $name)
            SliderControl("Size", value: $size, in: 24...96, step: 4) { "\(Int($0)) pt" }
            ToggleControl("Photo", isOn: $hasPhoto)
        }
    }
}

private struct AvatarGroupPage: View {
    @State private var count = 6
    @State private var maxVisible = 4
    @State private var state: SpecimenState = .content

    private let names = ["Aida", "Timur", "Askar", "Dana", "Ernar", "Zhanna", "Marat", "Saule"]

    var body: some View {
        ComponentPage(
            name: "AvatarGroup",
            summary: "Overlapping avatars with “+N” for the rest: the people on a trip.",
            since: "0.6.0",
            apps: [.dalada]
        ) {
            if state == .loading {
                AvatarGroupSkeleton(count: min(count, maxVisible))
            } else {
                AvatarGroup(names: Array(names.prefix(count)), maxVisible: maxVisible)
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("People", value: $count, in: 1...8)
            StepperControl("Visible", value: $maxVisible, in: 1...6)
        }
    }
}

private struct HeroSymbolPage: View {
    @State private var size = 140.0
    @State private var tint = 0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "HeroSymbol",
            summary: "A large SF Symbol on a disc of its tint: the picture of an onboarding page or a permission primer.",
            since: "0.7.0",
            apps: [.tenra, .dalada],
            notes: [
                "The symbol draws itself on as it appears (2.2.0) and is drawn in an SF Symbols 7 gradient of its tint, for depth (2.3.0).",
                "In an OnboardingPager the symbol lags behind its page as you swipe (2.3.0).",
            ]
        ) {
            if state == .loading {
                HeroSymbolSkeleton(size: size)
            } else {
                HeroSymbol(systemImage: "map", size: size,
                           tint: [AppColors.accent, AppColors.success, AppColors.warning][tint])
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Size", value: $size, in: 80...200, step: 10) { "\(Int($0)) pt" }
            ChoiceControl("Tint", selection: $tint, options: [("Accent", 0), ("Success", 1), ("Warning", 2)])
        }
    }
}

private struct PackedCircleIconsPage: View {
    @State private var maxVisible = 5
    @State private var width = 120.0
    @State private var state: SpecimenState = .content

    private let items = [
        PackedCircleItem(id: "1", iconSource: .sfSymbol("creditcard.fill"), amount: 1_250_000, tint: AppColors.accent),
        PackedCircleItem(id: "2", iconSource: .sfSymbol("banknote.fill"), amount: 480_000, tint: AppColors.success),
        PackedCircleItem(id: "3", iconSource: .sfSymbol("wallet.bifold.fill"), amount: 220_000, tint: AppColors.warning),
        PackedCircleItem(id: "4", iconSource: .sfSymbol("bitcoinsign.circle.fill"), amount: 90_000, tint: AppColors.transfer),
        PackedCircleItem(id: "5", iconSource: .sfSymbol("building.columns.fill"), amount: 40_000, tint: .purple),
    ]

    var body: some View {
        ComponentPage(
            name: "PackedCircleIcons",
            summary: "Icons packed as circles sized by their amounts: the accounts of a home card.",
            apps: [.tenra]
        ) {
            if state == .loading {
                PackedCircleIconsSkeleton(containerWidth: width)
            } else {
                PackedCircleIcons(items: items, maxVisible: maxVisible, containerWidth: width)
            }
        } controls: {
            StateControl(state: $state)
            StepperControl("Visible", value: $maxVisible, in: 1...5)
            SliderControl("Width", value: $width, in: 80...200, step: 10) { "\(Int($0)) pt" }
        }
    }
}

private struct AchievementMedalPage: View {
    @State private var isEarned = true
    @State private var size = 64.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "AchievementMedal",
            summary: "A round medal: in its colour once earned, grey until then.",
            since: "1.12.0",
            apps: [.dalada]
        ) {
            if state == .loading {
                AchievementMedalSkeleton(size: size)
            } else {
                AchievementMedal(systemImage: "figure.hiking", color: .green, isEarned: isEarned, size: size)
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Earned", isOn: $isEarned)
            SliderControl("Size", value: $size, in: 32...96, step: 4) { "\(Int($0)) pt" }
        }
    }
}

private struct AchievementTilePage: View {
    @State private var isEarned = false
    @State private var showsProgress = true
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "AchievementTile",
            summary: "A medal with its title under it and, while not earned, the progress towards it.",
            since: "1.12.0",
            apps: [.dalada]
        ) {
            if state == .loading {
                AchievementTileSkeleton(medalSize: 64)
            } else {
                AchievementTile(title: "10 trips", systemImage: "map.fill", color: .blue, isEarned: isEarned,
                                medalSize: 64, progressText: showsProgress ? "7 of 10" : nil)
                    .frame(width: 120)
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Earned", isOn: $isEarned)
            ToggleControl("Progress", isOn: $showsProgress)
        }
    }
}

private struct AchievementProgressRowPage: View {
    @State private var fraction = 0.7
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "AchievementProgressRow",
            summary: "The achievement closest to being earned: “Up next:”, its title, the progress and a bar.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                AchievementProgressRowSkeleton()
            } else {
                AchievementProgressRow(label: "Up next:", title: "10 trips",
                                       progressText: "\(Int(fraction * 10)) of 10", fraction: fraction,
                                       systemImage: "map.fill", color: .blue)
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Progress", value: $fraction, in: 0...1, step: 0.1) { "\(Int($0 * 100))%" }
        }
    }
}

private struct ThumbnailPlaceholderPage: View {
    @State private var tint = 0

    var body: some View {
        ComponentPage(
            name: "ThumbnailPlaceholder",
            summary: "The picture of a ThumbnailCard or ThumbnailRow when there is no photo: a symbol on a pale tint.",
            since: "1.12.0",
            apps: [.dalada]
        ) {
            ThumbnailPlaceholder(systemImage: "tent.fill", tint: [AppColors.accent, .orange, .teal][tint])
                .frame(width: 200, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        } controls: {
            ChoiceControl("Tint", selection: $tint, options: [("Accent", 0), ("Orange", 1), ("Teal", 2)])
        }
    }
}

private struct PhotoTilePage: View {
    @State private var hasPhoto = true
    @State private var size = 88.0
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PhotoTile",
            summary: "A photo cropped to a square on the muted background, with rounded corners: the tile of photo rows and grids, a picked photo's preview.",
            since: "2.8.0",
            apps: [.dalada],
            notes: [
                "The app passes the image view (its loader, its cache); PhotoTile(image:) takes a UIImage and shows the photo symbol without one.",
                "size: nil fills the width and stays square (a grid cell).",
            ]
        ) {
            if state == .loading {
                PhotoTileSkeleton(size: size)
            } else if hasPhoto {
                PhotoTile(size: size) { GalleryPhotoView(photo: GalleryPhoto.samples[0]) }
            } else {
                PhotoTile(image: nil, size: size)
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Photo", isOn: $hasPhoto)
            SliderControl("Size", value: $size, in: 64...160, step: 8)
        }
    }
}

private struct PhotoStripPage: View {
    @State private var photos = GalleryPhoto.samples
    @State private var removable = false
    @State private var opened: GalleryPhoto?
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PhotoStrip",
            summary: "A row of photo tiles that scrolls sideways: a report's photos (a tap opens one), or the photos picked for a form, each with a remove button.",
            since: "2.8.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            if state == .loading {
                PhotoStripSkeleton()
            } else if removable {
                PhotoStrip(photos, onRemove: { photo in
                    withAnimation(AppAnimation.gentleSpring) { photos.removeAll { $0.id == photo.id } }
                }) { GalleryPhotoView(photo: $0) }
            } else {
                PhotoStrip(photos, onOpen: { opened = $0 }) { GalleryPhotoView(photo: $0) }
                    .fullScreenCover(item: $opened) { photo in
                        PhotoViewer(photos, selection: photo.id) { GalleryPhotoView(photo: $0, fits: true) }
                    }
            }
        } controls: {
            StateControl(state: $state)
            ToggleControl("Removable", isOn: $removable)
            ActionControl("Restore photos") { photos = GalleryPhoto.samples }
        }
    }
}

private struct PhotoGridPage: View {
    @State private var style: PhotoGridStyle = .rounded
    @State private var opened: GalleryPhoto?
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PhotoGrid",
            summary: "Square photo cells in columns: a person's photos (rounded, small gaps) or a gallery (square cells, hairline gaps, the next page loaded as the last cell appears).",
            since: "2.8.0",
            apps: [.dalada],
            canvas: .fill,
            notes: ["Lazy: put it in a ScrollView. onReachEnd loads the next page."]
        ) {
            if state == .loading {
                PhotoGridSkeleton(style: style)
            } else {
                PhotoGrid(GalleryPhoto.samples, style: style, onOpen: { opened = $0 },
                          label: { $0.caption }) { GalleryPhotoView(photo: $0) }
                    .fullScreenCover(item: $opened) { photo in
                        PhotoViewer(GalleryPhoto.samples, selection: photo.id) { GalleryPhotoView(photo: $0, fits: true) }
                    }
            }
        } controls: {
            StateControl(state: $state)
            ChoiceControl("Style", selection: $style, options: [("Rounded", .rounded), ("Edge to edge", .edgeToEdge)])
        }
    }
}

private struct PhotoCarouselPage: View {
    @State private var count = 3.0
    @State private var opened: GalleryPhoto?
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "PhotoCarousel",
            summary: "The photos of a post, one at a time in a rounded 4:3 frame, swiped sideways with page dots; a tap opens the photo.",
            since: "2.8.0",
            apps: [.dalada],
            canvas: .fill
        ) {
            let photos = Array(GalleryPhoto.samples.prefix(Int(count)))
            if state == .loading {
                PhotoCarouselSkeleton()
            } else {
                PhotoCarousel(photos, onOpen: { opened = $0 }) { GalleryPhotoView(photo: $0) }
                    .fullScreenCover(item: $opened) { photo in
                        PhotoViewer(photos, selection: photo.id) { GalleryPhotoView(photo: $0, fits: true) }
                    }
            }
        } controls: {
            StateControl(state: $state)
            SliderControl("Photos", value: $count, in: 1...6, step: 1)
        }
    }
}

private struct PhotoViewerPage: View {
    @State private var opened: GalleryPhoto?
    @State private var showsCaption = true
    @State private var showsMenu = true

    var body: some View {
        ComponentPage(
            name: "PhotoViewer",
            summary: "Photos full screen: swiped sideways, pinch or double-tap to zoom, drag the zoomed photo. An optional caption with \"2 / 5\" and a menu in the top bar.",
            since: "2.8.0",
            apps: [.dalada],
            notes: [
                "Present it with .fullScreenCover; it closes itself. Pass the photo fitted (.scaledToFit()): the viewer zooms it.",
                "At 1× a drag turns the page; zoomed in, it moves the photo. VoiceOver zooms with its own gesture.",
            ]
        ) {
            Button("Open the viewer") { opened = GalleryPhoto.samples[0] }
                .dsButton(.secondary)
                .fullScreenCover(item: $opened) { photo in
                    viewer(selection: photo.id)
                }
        } controls: {
            ToggleControl("Caption", isOn: $showsCaption)
            ToggleControl("Menu", isOn: $showsMenu)
        }
    }

    @ViewBuilder
    private func viewer(selection: Int) -> some View {
        let photos = GalleryPhoto.samples
        if showsCaption && showsMenu {
            PhotoViewer(photos, selection: selection) { GalleryPhotoView(photo: $0, fits: true) } caption: { photo in
                Text(photo.caption).font(AppTypography.bodyEmphasis)
                Text("Aida · 12 May 2026").font(AppTypography.caption).foregroundStyle(.white.opacity(0.8))
            } actions: { _ in
                Menu {
                    Button("Report", systemImage: "flag") {}
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        } else if showsCaption {
            PhotoViewer(photos, selection: selection) { GalleryPhotoView(photo: $0, fits: true) } caption: { photo in
                Text(photo.caption).font(AppTypography.bodyEmphasis)
            }
        } else {
            PhotoViewer(photos, selection: selection) { GalleryPhotoView(photo: $0, fits: true) }
        }
    }
}

private struct ShareCardFramePage: View {
    @State private var format: ShareCardFormat = .story
    @State private var hasPhoto = false

    var body: some View {
        ComponentPage(
            name: "ShareCardFrame",
            summary: "A picture to share in Stories or a chat: a photo under a dark gradient (or a gradient alone), the content from the top, the brand and the site at the bottom.",
            since: "2.8.0",
            apps: [.dalada],
            notes: [
                "An image, not a screen: fixed point sizes (360 wide, rendered at 3× to 1080 px), the same colours in light and dark.",
                "ShareCardSheet renders it, lets the person pick Stories or post, and shares it.",
            ]
        ) {
            ShareCardFrame(format: format, brand: "Dalada", site: "dalada.kz", photo: hasPhoto ? GallerySharePhoto.image : nil) {
                GalleryShareCardContent(format: format)
            }
            .scaleEffect(0.6)
            .frame(width: format.width * 0.6, height: format.height * 0.6)
        } controls: {
            ChoiceControl("Format", selection: $format, options: ShareCardFormat.allCases.map { ($0.title, $0) })
            ToggleControl("Photo", isOn: $hasPhoto)
        }
    }
}

/// A sample card's content: kicker, title, date, stats.
struct GalleryShareCardContent: View {
    let format: ShareCardFormat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Fishing", systemImage: "fish")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ShareCardStyle.standard.accent)
            Text("Kapchagay weekend")
                .font(.system(size: format == .story ? 32 : 28, weight: .bold))
                .lineLimit(2)
            Text("12 May 2026")
                .font(.system(size: 14))
                .opacity(0.7)
        }
        Spacer(minLength: 0)
        HStack(alignment: .top, spacing: 12) {
            ShareCardStat(value: "12.4 km", title: "Distance")
            ShareCardStat(value: "5 h 12 min", title: "Time")
            ShareCardStat(value: "320 m", title: "Elevation")
        }
    }
}

/// A photo for the share card specimens, drawn once from a `GalleryPhoto`.
@MainActor
enum GallerySharePhoto {
    static let image: UIImage? = {
        let renderer = ImageRenderer(content: GalleryPhotoView(photo: GalleryPhoto.samples[1]).frame(width: 360, height: 640))
        renderer.scale = 2
        return renderer.uiImage
    }()
}

#Preview { NavigationStack { MediaScreen() } }
