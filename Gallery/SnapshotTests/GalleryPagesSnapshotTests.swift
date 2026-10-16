//
//  GalleryPagesSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Whole Gallery pages in a phone-sized window, as a person opens them: the section screen in a
//  NavigationStack, on the component's page of its paging TabView. A component that crashes or
//  draws past its canvas only in the Gallery shows here (5.0.0: the PickerCarousel page and a
//  centred SnapCardPicker crashed on a device in a build between 4.15.0 and 5.0.0, and the
//  EdgeBackdrop page blurred above its preview: a safeAreaBar on a scroll view inside the page's
//  drew the page's edge effect down to itself).
//

import SwiftUI
import UIKit
import Testing
import SnapshotTesting
@testable import DesignKitGallery
import DesignTokens
import DesignSupport
import DesignComponents

extension ComponentSnapshots {
    @MainActor
    @Suite("Gallery pages")
    struct GalleryPages {
        /// The Selection screen on PickerCarousel's page.
        @Test func pickerCarouselPage() async {
            await assertPageSnapshot(NavigationStack { SelectionScreen() }, page: "PickerCarousel")
        }

        /// A centred SnapCardPicker on a page of a paging section, as the SnapCardPicker page
        /// shows it with Centered chosen.
        @Test func snapCardPickerCenteredPage() async {
            await assertPageSnapshot(NavigationStack { CenteredPickerSection() }, page: "Centered")
        }

        /// The Effects screen on EdgeBackdrop's page.
        @Test func edgeBackdropPage() async {
            await assertPageSnapshot(NavigationStack { EffectsScreen() }, page: "EdgeBackdrop")
        }

        /// EdgeBackdrop's comparison screen, a thread under Ten in a top safeAreaBar as Tenra's
        /// chat holds it, with each backing: EdgeBackdrop, the system's soft and hard scroll edge
        /// effects (5.0.0).
        @Test func edgeBackdropComparison() async {
            for backing in EdgeBackdropComparison.Backing.allCases {
                await assertPageSnapshot(
                    EdgeBackdropComparison(backing: backing, colorOpacity: .constant(EdgeBackdropMetrics.colorOpacity)),
                    named: backing.rawValue
                )
            }
        }

        /// The comparison in Hard opened from a page, as the Gallery opens it
        /// (`presentShowcaseScreen`): presented from inside a page's scroll view, its bar drew
        /// no edge effect, soft or hard (5.0.0, the owner's device; the plate shows it does now).
        @Test func edgeBackdropComparisonFromPage() async {
            await assertPageSnapshot(NavigationStack { PresentingSection() }, page: "Page")
        }
    }
}

/// A paging section whose page opens the comparison in Hard when it appears, through the
/// showcase screen, as the EdgeBackdrop page's "Compare on a screen" does.
private struct PresentingSection: View {
    var body: some View {
        ShowcasePage(title: "Effects") {
            ComponentPage(name: "Page", summary: "Opens the comparison.", canvas: .tall(minHeight: 200)) {
                PresentsComparison()
            }
            ComponentPage(name: "Other", summary: "A second page.") {
                Text(verbatim: "Other")
            }
        }
    }
}

private struct PresentsComparison: View {
    @Environment(\.presentShowcaseScreen) private var presentScreen

    var body: some View {
        Text(verbatim: "Preview")
            .onAppear {
                presentScreen?(EdgeBackdropComparison(backing: .hard, colorOpacity: .constant(EdgeBackdropMetrics.colorOpacity)))
            }
    }
}

/// Two pages, the first a centred SnapCardPicker of balance cards (the page's own sample).
private struct CenteredPickerSection: View {
    private struct Wallet: Identifiable {
        let id: String
        let name: String
        let symbol: String
        let balance: Double
    }

    private let wallets = [
        Wallet(id: "gold", name: "Kaspi Gold", symbol: "creditcard.fill", balance: 1_284_500),
        Wallet(id: "cash", name: "Cash", symbol: "banknote.fill", balance: 42_000),
        Wallet(id: "deposit", name: "Deposit", symbol: "lock.fill", balance: 2_500_000),
    ]

    @State private var selection: String? = "gold"

    var body: some View {
        ShowcasePage(title: "Selection") {
            ComponentPage(name: "Centered", summary: "A centred SnapCardPicker.", canvas: .bleed) {
                SnapCardPicker(wallets, selection: $selection, style: .centered(width: 220)) { wallet, isSelected, select in
                    SelectableBalanceCard(iconSource: .sfSymbol(wallet.symbol), title: wallet.name,
                                          amount: wallet.balance, currency: "KZT",
                                          isSelected: isSelected, action: select)
                }
            }
            ComponentPage(name: "Other", summary: "A second page, so the section pages.") {
                Text(verbatim: "Other")
            }
        }
    }
}

/// Renders `screen` opened on `page` in a 440 × 956 pt window (the iPhone 17 Pro Max the tests
/// run on) and compares it with `<test>.png` (`<test>.<named>.png`).
@MainActor
private func assertPageSnapshot<V: View>(
    _ screen: V,
    page: String? = nil,
    named: String? = nil,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
        Issue.record("No window scene: snapshot tests must run hosted in the Gallery app")
        return
    }
    let window = UIWindow(windowScene: scene)
    window.windowLevel = .alert + 1
    window.frame = CGRect(x: 0, y: 0, width: 440, height: 956)
    window.overrideUserInterfaceStyle = .light
    let host = UIHostingController(rootView:
        screen
            .environment(\.showcaseInitialPage, page)
            .environment(\.locale, Locale(identifier: "en_US"))
            .designKitMotion(false)
            .skeletonShimmer(false)
    )
    window.rootViewController = host
    window.isHidden = false
    // Long enough for the TabView to land on the page and the scroll views to settle.
    try? await Task.sleep(for: .seconds(3))
    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    format.opaque = true
    format.preferredRange = .standard
    let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
        _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    window.isHidden = true
    window.rootViewController = nil
    assertSnapshot(
        of: image,
        as: .image(precision: 0.98, perceptualPrecision: 0.98),
        named: named,
        fileID: fileID,
        file: file,
        testName: testName,
        line: line,
        column: column
    )
}
