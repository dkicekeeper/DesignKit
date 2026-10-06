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
/// The view sits on `AppColors.bgBase` with `AppSpacing.lg` around it, animations off; the PNG
/// is the view's own frame.
///
/// - Parameter named: Tells several snapshots of one test apart (`<test>.<named>-<appearance>.png`).
///   Give each Liquid Glass card its own snapshot: glass reflects a card next to it, and whether
///   that reflection shows varies from run to run (docs/snapshots.md).
@MainActor
func assertComponentSnapshot<V: View>(
    _ view: V,
    named: String? = nil,
    width: CGFloat = 360,
    appearances: [SnapshotAppearance] = lightAndDark,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async {
    for appearance in appearances {
        let name = named.map { "\($0).\(appearance.rawValue)" } ?? appearance.rawValue
        let image = await ComponentRenderer.render(
            view, width: width, appearance: appearance, label: "\(testName).\(name)"
        )
        assertSnapshot(
            of: image,
            // Tolerates anti-aliasing noise; a moved edge, a new colour or other text fails.
            as: .image(precision: 0.995, perceptualPrecision: 0.98),
            named: name,
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

    /// Extra captures, 0.4 s apart, until `stableCaptures` in a row are identical.
    static let stabilityAttempts = 20
    /// Identical captures in a row that make a picture settled. Two was not enough: Liquid
    /// Glass shadows between stacked cards can hold still for one interval and move again.
    static let stableCaptures = 3

    /// - Parameter label: Names the snapshot in the log line printed when it never settles.
    static func render<V: View>(
        _ view: V,
        width: CGFloat,
        appearance: SnapshotAppearance,
        label: String = ""
    ) async -> UIImage {
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

        var host = makeHost(content, appearance: appearance)

        let fitting = CGSize(width: width + (AppSpacing.lg + margin) * 2, height: .greatestFiniteMagnitude)
        var size = host.sizeThatFits(in: fitting)
        size.width = fitting.width
        size.height = max(1, size.height.rounded(.up))

        var window = show(host, size: size, appearance: appearance)
        // Glass and its shadow render unpredictably where the window is off the screen.
        let screen = window.windowScene?.screen.bounds.size ?? .zero
        func checkFitsScreen() {
            guard size.width > screen.width || size.height > screen.height else { return }
            Issue.record("""
                Snapshot window \(Int(size.width))×\(Int(size.height)) pt does not fit the \
                \(Int(screen.width))×\(Int(screen.height)) pt screen: narrow the component or \
                split the test (docs/snapshots.md).
                """)
        }
        checkFitsScreen()

        // Let SwiftUI lay out, run onAppear / onGeometryChange, and glass settle.
        try? await Task.sleep(for: .seconds(1.5))
        // Content that measures itself after the first layout can grow (ExpandableText adds its
        // More button once it knows the text is truncated). Show it again in a new window of the
        // final size, or the grown content sits centred in the old height and is cut off at the
        // top and bottom. A new window, not the old one resized: glass drawn at the first size
        // did not always redraw after a resize, so a card's bottom edge kept or lost its shading
        // from run to run (large-text snapshots, October 2026).
        let settledHeight = max(1, host.sizeThatFits(in: fitting).height.rounded(.up))
        if settledHeight != size.height {
            print("SNAPSHOT-RESIZED \(label): \(Int(size.height)) → \(Int(settledHeight)) pt")
            size.height = settledHeight
            checkFitsScreen()
            window.isHidden = true
            window.rootViewController = nil
            host = makeHost(content, appearance: appearance)
            window = show(host, size: size, appearance: appearance)
            try? await Task.sleep(for: .seconds(1.5))
        }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        // 8-bit sRGB: the simulator's default is extended range (16 bits per channel), which
        // makes every PNG several times larger for no visible difference.
        format.preferredRange = .standard
        // The renderer's bounds start at the component's frame, so the drawn window is cropped
        // to the component itself. The `AppSpacing.lg` around it stays in the layout but out
        // of the PNG: that is where Liquid Glass casts its shadow, which the simulator renders
        // slightly differently from run to run (the component's own pixels do not change).
        let inset = margin + AppSpacing.lg
        let captured = window.bounds.insetBy(dx: inset, dy: inset)
        func capture() -> UIImage {
            UIGraphicsImageRenderer(bounds: captured, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
        }

        // Liquid Glass keeps animating its shadow for a moment after layout (a card that is
        // still changing, like a paging TabView, restarts it). Capture until several frames in
        // a row are identical, so the reference is the settled picture, not a phase of it.
        var image = capture()
        var identical = 1
        var attempts = 0
        while identical < stableCaptures, attempts < stabilityAttempts {
            try? await Task.sleep(for: .milliseconds(400))
            let next = capture()
            identical = next.pngData() == image.pngData() ? identical + 1 : 1
            image = next
            attempts += 1
        }
        if identical < stableCaptures {
            // Not an error by itself (the comparison decides), but the first suspect when a
            // snapshot fails in one run and passes in another: scripts/snapshot-tests.sh prints it.
            print("SNAPSHOT-UNSETTLED \(label): \(attempts) captures, last \(identical) identical")
        }

        window.isHidden = true
        window.rootViewController = nil
        return image
    }

    private static func makeHost<Content: View>(
        _ content: Content,
        appearance: SnapshotAppearance
    ) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: content)
        host.safeAreaRegions = []
        host.overrideUserInterfaceStyle = appearance.interfaceStyle
        host.traitOverrides.preferredContentSizeCategory = appearance.dynamicTypeSize == .large
            ? .large
            : .accessibilityLarge
        host.view.backgroundColor = .systemBackground
        return host
    }

    /// A new window of `size` at the top of the screen, showing `host`.
    private static func show(_ host: UIViewController, size: CGSize, appearance: SnapshotAppearance) -> UIWindow {
        let window = makeWindow()
        window.overrideUserInterfaceStyle = appearance.interfaceStyle
        // Opaque, so Liquid Glass samples only the component's own background.
        window.backgroundColor = .systemBackground
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.isHidden = false
        return window
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
