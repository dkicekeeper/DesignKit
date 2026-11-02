//
//  SquareImageCropper.swift
//  DesignKit
//
//  8.5.0: crops a picture to a square, for an icon of the person's own (IconPicker's "Photo",
//  `DesignKitIconPhotos`). The picture fills the square to start; a finger moves it, two fingers
//  zoom it (never smaller than the square, up to six times); the parts outside the square are
//  veiled. Choose returns the square at `outputSize` pixels.
//

import SwiftUI
import ImageIO
import DesignTokens
import DesignSupport

/// A square crop of a picture.
///
/// ```swift
/// .fullScreenCover(item: $picked) { picked in
///     SquareImageCropper(image: picked.image) { cropped in save(cropped) } onCancel: { picked = nil }
/// }
/// ```
public struct SquareImageCropper: View {
    let image: UIImage
    let outputSize: CGFloat
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var side: CGFloat = 0

    /// The largest zoom.
    private static let maxScale: CGFloat = 6

    /// - Parameters:
    ///   - image: The picture (`SquareImageCropper.downsampled(_:maxPixelSize:)` reads a big one
    ///     cheaply).
    ///   - outputSize: The side of the square returned, in pixels.
    public init(
        image: UIImage,
        outputSize: CGFloat = 512,
        onCrop: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self.outputSize = outputSize
        self.onCrop = onCrop
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let square = max(min(geometry.size.width, geometry.size.height) - 2 * AppSpacing.lg, 1)
                let shown = shownSize(square: square)
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: shown.width, height: shown.height)
                        .offset(offset)
                    CropVeil(side: square)
                        .allowsHitTesting(false)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(SimultaneousGesture(drag(square: square), zoom(square: square)))
                .onAppear { side = square }
                .onChange(of: square) { _, new in
                    side = new
                    offset = clamped(offset, square: new)
                    lastOffset = offset
                }
            }
            .background(AppColors.bgBase)
            .navigationTitle(String(localized: "imageCropper.title", defaultValue: "Move and scale"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        // A system bar's item: iOS draws its symbol (7.0.0, outside the Icon rule).
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "imageCropper.cancel", defaultValue: "Cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticManager.selection()
                        onCrop(cropped())
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .dsButton()
                    .disabled(side <= 1)
                    .accessibilityLabel(String(localized: "imageCropper.choose", defaultValue: "Choose"))
                }
            }
        }
    }

    // MARK: - Geometry

    /// The picture's size on screen: its shorter side fills the square, times the zoom.
    private func shownSize(square: CGFloat) -> CGSize {
        let fill = square / max(min(image.size.width, image.size.height), 1)
        return CGSize(width: image.size.width * fill * scale, height: image.size.height * fill * scale)
    }

    /// An offset that keeps the square covered by the picture.
    private func clamped(_ offset: CGSize, square: CGFloat) -> CGSize {
        let shown = shownSize(square: square)
        let maxX = max((shown.width - square) / 2, 0)
        let maxY = max((shown.height - square) / 2, 0)
        return CGSize(width: min(max(offset.width, -maxX), maxX), height: min(max(offset.height, -maxY), maxY))
    }

    private func drag(square: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clamped(
                    CGSize(width: lastOffset.width + value.translation.width,
                           height: lastOffset.height + value.translation.height),
                    square: square
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func zoom(square: CGFloat) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), Self.maxScale)
                offset = clamped(offset, square: square)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    /// The square under the veil, drawn at `outputSize` pixels.
    private func cropped() -> UIImage {
        Self.crop(image, square: side, scale: scale, offset: offset, outputSize: outputSize)
    }

    /// The part of `image` a square of `square` points shows at `scale` and `offset`, drawn at
    /// `outputSize` pixels. Pure, so the Gallery and the tests can use it.
    public static func crop(_ image: UIImage, square: CGFloat, scale: CGFloat, offset: CGSize, outputSize: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let total = square / max(min(width, height), 1) * max(scale, 1)
        let cropSide = square / total
        let center = CGPoint(x: width / 2 - offset.width / total, y: height / 2 - offset.height / total)
        let rect = CGRect(x: center.x - cropSide / 2, y: center.y - cropSide / 2, width: cropSide, height: cropSide)
        let factor = outputSize / max(cropSide, 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: outputSize, height: outputSize), format: format).image { _ in
            image.draw(in: CGRect(
                x: -rect.minX * factor,
                y: -rect.minY * factor,
                width: width * factor,
                height: height * factor
            ))
        }
    }

    /// A picture from the photo library read at most `maxPixelSize` on its longer side, turned
    /// upright: a 48-megapixel photo is not decoded whole to crop a logo.
    public nonisolated static func downsampled(_ data: Data, maxPixelSize: CGFloat = 2048) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
        let thumbnail = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnail) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// The page outside the square veiled, a thin line around it.
private struct CropVeil: View {
    let side: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(
                x: (geometry.size.width - side) / 2,
                y: (geometry.size.height - side) / 2,
                width: side,
                height: side
            )
            ZStack {
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geometry.size))
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: AppRadius.lg, height: AppRadius.lg))
                }
                .fill(AppColors.bgBase.opacity(0.72), style: FillStyle(eoFill: true))
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.Text.primary.opacity(0.6), lineWidth: 1)
                    .frame(width: side, height: side)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }
}
