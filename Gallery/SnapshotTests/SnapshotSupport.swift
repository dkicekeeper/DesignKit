//
//  SnapshotSupport.swift
//  DesignKit Gallery snapshot tests
//
//  Renders a component in a real window of the Gallery app (the test host), so Liquid
//  Glass, materials and UIKit-backed controls draw as on a device, and compares the image
//  with the reference PNG in __Snapshots__ (swift-snapshot-testing).
//
//  How to record / update references: docs/snapshots.md.
//

import SwiftUI
import UIKit
import Testing
import SnapshotTesting
import DesignTokens

/// The ways a component is drawn. Every snapshot test picks a subset.
enum SnapshotAppearance: String, CaseIterable {
    /// Light, default text size.
    case light
    /// Dark, default text size.
    case dark
    /// Light, accessibility text size (AX2): catches truncation and clipping.
    case largeText

    var colorScheme: ColorScheme { self == .dark ? .dark : .light }
    var interfaceStyle: UIUserInterfaceStyle { self == .dark ? .dark : .light }
    var dynamicTypeSize: DynamicTypeSize { self == .largeText ? .accessibility2 : .large }
}

/// Light and dark: what every component snapshot covers.
let lightAndDark: [SnapshotAppearance] = [.light, .dark]

/// Root suite: snapshots run one at a time (each one shows its own window).
@MainActor
@Suite(.serialized)
struct ComponentSnapshots {}

/// Renders `view` at `width` points and asserts it matches the reference images, one per
/// appearance (`<test>.light.png`, `<test>.dark.png`, `<test>.largeText.png`).
///
/// The view sits on `AppColors.bgBase` with `AppSpacing.lg` around it, animations off.
@MainActor
func assertComponentSnapshot<V: View>(
    _ view: V,
    width: CGFloat = 360,
    appearances: [SnapshotAppearance] = lightAndDark,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async {
    for appearance in appearances {
        let image = await ComponentRenderer.render(view, width: width, appearance: appearance)
        assertSnapshot(
            of: image,
            // Tolerates anti-aliasing noise; a moved edge, a new colour or other text fails.
            as: .image(precision: 0.995, perceptualPrecision: 0.98),
            named: appearance.rawValue,
            fileID: fileID,
            file: file,
            testName: testName,
            line: line,
            column: column
        )
    }
}

@MainActor
enum ComponentRenderer {
    /// Scale of the PNGs, whatever the simulator's screen: keeps references small and stable.
    static let scale: CGFloat = 2

    /// Empty background around the captured area, inside the window. Liquid Glass bends what
    /// lies just outside a card's edge; without this margin it sampled whatever was beyond the
    /// window and the edges of cards changed from run to run. Not part of the PNG.
    /// 360 + 2 × (16 + 24) = 440 pt: the width of the iPhone 17 Pro Max the tests run on.
    static let margin: CGFloat = 24

    /// Extra captures, 0.4 s apart, while two in a row still differ.
    static let stabilityAttempts = 8

    static func render<V: View>(_ view: V, width: CGFloat, appearance: SnapshotAppearance) async -> UIImage {
        DesignKitFonts.registerIfNeeded()
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let content = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .padding(AppSpacing.lg)
            .padding(margin)
            .background(AppColors.bgBase)
            .environment(\.colorScheme, appearance.colorScheme)
            .environment(\.locale, Locale(identifier: "en_US"))
            .dynamicTypeSize(appearance.dynamicTypeSize)
            .transaction { transaction in
                transaction.disablesAnimations = true
                transaction.animation = nil
            }

        let host = UIHostingController(rootView: content)
        host.safeAreaRegions = []
        host.overrideUserInterfaceStyle = appearance.interfaceStyle
        host.traitOverrides.preferredContentSizeCategory = appearance.dynamicTypeSize == .large
            ? .large
            : .accessibilityLarge

        let fitting = CGSize(width: width + (AppSpacing.lg + margin) * 2, height: .greatestFiniteMagnitude)
        var size = host.sizeThatFits(in: fitting)
        size.width = fitting.width
        size.height = max(1, size.height.rounded(.up))

        let window = makeWindow()
        // Glass and its shadow render unpredictably where the window is off the screen.
        let screen = window.windowScene?.screen.bounds.size ?? .zero
        if size.width > screen.width || size.height > screen.height {
            Issue.record("""
                Snapshot window \(Int(size.width))×\(Int(size.height)) pt does not fit the \
                \(Int(screen.width))×\(Int(screen.height)) pt screen: narrow the component or \
                split the test (docs/snapshots.md).
                """)
        }
        window.overrideUserInterfaceStyle = appearance.interfaceStyle
        // Opaque, so Liquid Glass samples only the component's own background.
        window.backgroundColor = .systemBackground
        host.view.backgroundColor = .systemBackground
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.isHidden = false

        // Let SwiftUI lay out, run onAppear / onGeometryChange, and glass settle.
        try? await Task.sleep(for: .seconds(1.5))
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        // 8-bit sRGB: the simulator's default is extended range (16 bits per channel), which
        // makes every PNG several times larger for no visible difference.
        format.preferredRange = .standard
        // The renderer's bounds start at the margin, so the drawn window is cropped to the
        // component and its `AppSpacing.lg` padding.
        let captured = window.bounds.insetBy(dx: margin, dy: margin)
        func capture() -> UIImage {
            UIGraphicsImageRenderer(bounds: captured, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
        }

        // Liquid Glass keeps animating its shadow for a moment after layout (a card that is
        // still changing, like a paging TabView, restarts it). Capture until two frames in a
        // row are identical, so the reference is the settled picture, not a phase of it.
        var image = capture()
        for _ in 0..<stabilityAttempts {
            try? await Task.sleep(for: .milliseconds(400))
            let next = capture()
            let settled = next.pngData() == image.pngData()
            image = next
            if settled { break }
        }

        window.isHidden = true
        window.rootViewController = nil
        return image
    }

    private static func makeWindow() -> UIWindow {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        guard let scene else {
            Issue.record("No window scene: snapshot tests must run hosted in the Gallery app")
            return UIWindow(frame: .zero)
        }
        // Glass samples whatever is on screen below it, other windows included: hide the
        // Gallery's own UI for the whole run so it never shows through a component.
        for other in scene.windows where !other.isHidden {
            other.isHidden = true
        }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        return window
    }
}
