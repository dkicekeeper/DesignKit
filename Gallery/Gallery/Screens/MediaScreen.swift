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
            IconViewPage()
            AvatarViewPage()
            AvatarGroupPage()
            HeroSymbolPage()
            PackedCircleIconsViewPage()
            AchievementMedalPage()
            AchievementTilePage()
            AchievementProgressRowPage()
            ThumbnailPlaceholderPage()
        }
    }
}

private struct IconViewPage: View {
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
            name: "IconView",
            summary: "Every icon: an SF Symbol or a brand logo (loaded by the app's DesignKitLogoLoader), in a shape, a size, a tint, on glass or not.",
            apps: [.tenra, .dalada],
            notes: [
                "A brand logo is IconView(source: .brandService(\"netflix.com\")); BrandLogoView is its engine, deprecated as a view of its own since 1.13.0.",
                "Sizes: AppIconSize (glyphs) and AppIconSize.Tile (icons with a backing).",
            ]
        ) {
            if state == .loading {
                IconViewSkeleton(style: style)
            } else {
                IconView(source: iconSource, style: style)
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

private struct AvatarViewPage: View {
    @State private var name = "Aida Nurlanovna"
    @State private var size = Double(AppIconSize.Tile.xs)
    @State private var hasPhoto = false
    @State private var state: SpecimenState = .content

    var body: some View {
        ComponentPage(
            name: "AvatarView",
            summary: "A round avatar: the photo when there is one, otherwise the initials on a pale tint.",
            since: "0.4.0",
            apps: [.dalada]
        ) {
            if state == .loading {
                AvatarViewSkeleton(size: size)
            } else {
                AvatarView(name: name, image: hasPhoto ? Image(systemName: "photo.artframe") : nil, size: size)
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
            apps: [.tenra, .dalada]
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

private struct PackedCircleIconsViewPage: View {
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
            name: "PackedCircleIconsView",
            summary: "Icons packed as circles sized by their amounts: the accounts of a home card.",
            apps: [.tenra]
        ) {
            if state == .loading {
                PackedCircleIconsViewSkeleton(containerWidth: width)
            } else {
                PackedCircleIconsView(items: items, maxVisible: maxVisible, containerWidth: width)
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

#Preview { NavigationStack { MediaScreen() } }
