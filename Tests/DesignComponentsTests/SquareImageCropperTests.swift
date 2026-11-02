//
//  SquareImageCropperTests.swift
//  DesignComponentsTests
//
//  Pins the square crop (8.5.0): which part of a picture the square shows at a zoom and an
//  offset, and the size it comes out at.
//

import Testing
import UIKit
@testable import DesignComponents

@MainActor
struct SquareImageCropperTests {

    /// 200 × 100 points: the left half red, the right half blue.
    private func halves() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 100, y: 0, width: 100, height: 100))
        }
    }

    private func color(of image: UIImage, at point: CGPoint) -> (red: CGFloat, blue: CGFloat) {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return (0, 0) }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let offset = Int(point.y) * cgImage.bytesPerRow + Int(point.x) * bytesPerPixel
        // BGRA or RGBA: red and blue are the outer channels either way; compare them.
        let first = CGFloat(bytes[offset]) / 255
        let third = CGFloat(bytes[offset + 2]) / 255
        let isBGRA = cgImage.bitmapInfo.contains(.byteOrder32Little)
        return isBGRA ? (third, first) : (first, third)
    }

    @Test("The square fills with the picture's middle, red on the left and blue on the right")
    func middle() {
        let cropped = SquareImageCropper.crop(halves(), square: 100, scale: 1, offset: .zero, outputSize: 100)
        #expect(cropped.size == CGSize(width: 100, height: 100))
        #expect(color(of: cropped, at: CGPoint(x: 25, y: 50)).red > 0.9)
        #expect(color(of: cropped, at: CGPoint(x: 75, y: 50)).blue > 0.9)
    }

    @Test("Moving the picture right shows its left part")
    func movedRight() {
        let cropped = SquareImageCropper.crop(halves(), square: 100, scale: 1, offset: CGSize(width: 50, height: 0), outputSize: 100)
        #expect(color(of: cropped, at: CGPoint(x: 75, y: 50)).red > 0.9)
    }

    @Test("Zoomed in on the middle, the edge between the halves stays in the middle")
    func zoomed() {
        let cropped = SquareImageCropper.crop(halves(), square: 100, scale: 4, offset: .zero, outputSize: 64)
        #expect(cropped.size == CGSize(width: 64, height: 64))
        #expect(color(of: cropped, at: CGPoint(x: 10, y: 32)).red > 0.9)
        #expect(color(of: cropped, at: CGPoint(x: 54, y: 32)).blue > 0.9)
    }
}
