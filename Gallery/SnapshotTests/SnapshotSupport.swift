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

    static func render<V: View>(_ view: V, width: CGFloat, appearance: SnapshotAppearance) async -> UIImage {
        DesignKitFonts.registerIfNeeded()
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let content = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .padding(AppSpacing.lg)
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

        let fitting = CGSize(width: width + AppSpacing.lg * 2, height: .greatestFiniteMagnitude)
        var size = host.sizeThatFits(in: fitting)
        size.width = fitting.width
        size.height = max(1, size.height.rounded(.up))

        let window = makeWindow()
        window.overrideUserInterfaceStyle = appearance.interfaceStyle
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.isHidden = false

        // Let SwiftUI lay out, run onAppear / onGeometryChange and settle.
        try? await Task.sleep(for: .seconds(1))
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
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
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        return window
    }
}
