//
//  PhotoViewer.swift
//  DesignKit
//
//  Photos full screen (2.8.0): black, swiped sideways, closed with ✕. Pinch to zoom in, drag the
//  zoomed photo around, double-tap to zoom in or back out; VoiceOver zooms with its own gesture.
//  An optional caption sits on a dark band at the bottom with "2 / 5", and an optional menu sits
//  in the top bar (report, block). Ported from Dalada's PhotoViewer and PlacePhotoViewer, with zoom
//  added; the app passes each image, its caption and its menu.
//
//  Present it with `.fullScreenCover`; it dismisses itself.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Full-screen paged photos with zoom.
///
/// ```swift
/// .fullScreenCover(item: $opened) { photo in
///     PhotoViewer(report.media, selection: photo.id) { AppRemotePhoto(path: $0.path, contentMode: .fit) }
/// }
/// // With a caption and a menu
/// PhotoViewer(gallery, selection: photo.id) { photo in
///     AppRemotePhoto(path: photo.path, contentMode: .fit)
/// } caption: { photo in
///     Text(photo.author).font(AppTypography.bodyEmphasis)
/// } actions: { photo in
///     photo.isOwn ? nil : ModerationMenu(photo)   // nil: no menu for this photo
/// }
/// ```
///
/// The photo should fit (`.scaledToFit()`): the viewer zooms it, not the app.
public struct PhotoViewer<Item: Identifiable, Photo: View, Caption: View, Actions: View>: View where Item.ID: Hashable {
    let items: [Item]
    let closeTitle: String
    let hasCaption: Bool
    let hasActions: Bool
    let photo: (Item) -> Photo
    let caption: (Item) -> Caption
    let actions: (Item) -> Actions?

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Item.ID

    /// - Parameters:
    ///   - selection: The photo shown first.
    ///   - caption: Under the photo, on a dark band, in white; "2 / 5" is added under it.
    ///   - actions: A control in the top bar's trailing corner for the photo on screen (a menu
    ///     to report it); `nil` leaves the corner empty for that photo.
    public init(
        _ items: [Item],
        selection: Item.ID,
        closeTitle: String = String(localized: "common.close", defaultValue: "Close"),
        @ViewBuilder photo: @escaping (Item) -> Photo,
        @ViewBuilder caption: @escaping (Item) -> Caption,
        actions: @escaping (Item) -> Actions?
    ) {
        self.init(items, selection: selection, closeTitle: closeTitle, hasCaption: true, hasActions: true,
                  photo: photo, caption: caption, actions: actions)
    }

    init(
        _ items: [Item],
        selection: Item.ID,
        closeTitle: String,
        hasCaption: Bool,
        hasActions: Bool,
        photo: @escaping (Item) -> Photo,
        caption: @escaping (Item) -> Caption,
        actions: @escaping (Item) -> Actions?
    ) {
        self.items = items
        self.closeTitle = closeTitle
        self.hasCaption = hasCaption
        self.hasActions = hasActions
        self.photo = photo
        self.caption = caption
        self.actions = actions
        self._selection = State(initialValue: selection)
    }

    private var current: Item? { items.first { $0.id == selection } }

    public var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(items) { item in
                    ZoomablePhoto { photo(item) }
                        .tag(item.id)
                }
            }
            // With a caption the band counts the photos; without one, the page dots do.
            .tabViewStyle(.page(indexDisplayMode: !hasCaption && items.count > 1 ? .automatic : .never))
            .background(Color.black)
            .overlay(alignment: .bottom) {
                if hasCaption, let item = current {
                    captionBand(item)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(closeTitle, systemImage: "xmark") { dismiss() }
                }
                if hasActions, let item = current, let control = actions(item) {
                    ToolbarItem(placement: .topBarTrailing) {
                        control
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func captionBand(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            caption(item)
            if items.count > 1, let index = items.firstIndex(where: { $0.id == item.id }) {
                Text(verbatim: "\(index + 1) / \(items.count)")
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(.black.opacity(0.45))
    }
}

public extension PhotoViewer where Caption == EmptyView, Actions == EmptyView {
    /// Photos only: page dots when there are several.
    init(
        _ items: [Item],
        selection: Item.ID,
        closeTitle: String = String(localized: "common.close", defaultValue: "Close"),
        @ViewBuilder photo: @escaping (Item) -> Photo
    ) {
        self.init(items, selection: selection, closeTitle: closeTitle, hasCaption: false, hasActions: false,
                  photo: photo, caption: { _ in EmptyView() }, actions: { _ in nil })
    }
}

public extension PhotoViewer where Actions == EmptyView {
    /// Photos with a caption, no menu.
    init(
        _ items: [Item],
        selection: Item.ID,
        closeTitle: String = String(localized: "common.close", defaultValue: "Close"),
        @ViewBuilder photo: @escaping (Item) -> Photo,
        @ViewBuilder caption: @escaping (Item) -> Caption
    ) {
        self.init(items, selection: selection, closeTitle: closeTitle, hasCaption: true, hasActions: false,
                  photo: photo, caption: caption, actions: { _ in nil })
    }
}

// MARK: - Zoom

public enum PhotoViewerMetrics {
    /// The closest a pinch goes.
    public static let maxScale: CGFloat = 4
    /// Where a double tap zooms to.
    public static let doubleTapScale: CGFloat = 2.5
}

/// One page of the viewer: pinch to zoom, drag while zoomed, double-tap to zoom in or out. At 1×
/// the drag is off, so a swipe turns the page.
struct ZoomablePhoto<Content: View>: View {
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var settledOffset: CGSize = .zero
    @State private var size: CGSize = .zero

    private var animation: Animation? { reduceMotion ? nil : AppAnimation.smooth }
    private var isZoomed: Bool { scale > 1 }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .gesture(pinch)
            .gesture(pan, including: isZoomed ? .all : .subviews)
            .onTapGesture(count: 2) { toggleZoom() }
            .accessibilityZoomAction { action in
                withAnimation(animation) {
                    switch action.direction {
                    case .zoomIn:
                        settle(scale: min(scale + 1, PhotoViewerMetrics.maxScale))
                    case .zoomOut:
                        settle(scale: max(scale - 1, 1))
                    @unknown default:
                        break
                    }
                }
            }
            .onDisappear { settle(scale: 1) }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(settledScale * value.magnification, 1), PhotoViewerMetrics.maxScale)
                offset = clamped(offset)
            }
            .onEnded { _ in
                withAnimation(animation) { settle(scale: scale) }
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clamped(CGSize(
                    width: settledOffset.width + value.translation.width,
                    height: settledOffset.height + value.translation.height
                ))
            }
            .onEnded { _ in settledOffset = offset }
    }

    private func toggleZoom() {
        withAnimation(animation) {
            settle(scale: isZoomed ? 1 : PhotoViewerMetrics.doubleTapScale)
        }
    }

    /// Ends a zoom at `newScale`; back at 1× the photo recentres.
    private func settle(scale newScale: CGFloat) {
        scale = newScale
        settledScale = newScale
        offset = newScale > 1 ? clamped(offset) : .zero
        settledOffset = offset
    }

    /// Keeps the zoomed photo over the screen: it moves at most as far as it overhangs.
    private func clamped(_ proposed: CGSize) -> CGSize {
        let maxX = size.width * (scale - 1) / 2
        let maxY = size.height * (scale - 1) / 2
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }
}
