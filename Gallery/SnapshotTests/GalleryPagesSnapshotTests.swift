//
//  GalleryPagesSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Whole Gallery pages in a phone-sized window, as a person opens them: the section screen in a
//  NavigationStack, on the component's page of its paging TabView. A component that crashes or
//  draws past its canvas only in the Gallery shows here (5.0.0: the PickerCarousel page and a
//  centred SnapCardPicker crashed on a device, and the EdgeBackdrop page's backing covered more
//  than its preview).
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

        // DIAGNOSTIC (removed before merge): the specimen straight in the page, with the edge
        // effect as it comes (4.15's page), and with a safe-area inset instead of a bar.
        @Test func edgeBackdropDiagnosticEdgeEffect() async {
            await assertPageSnapshot(NavigationStack { EdgeBackdropDiagnostic(variant: .edgeEffect) }, page: "Variant")
        }

        @Test func edgeBackdropDiagnosticInset() async {
            await assertPageSnapshot(NavigationStack { EdgeBackdropDiagnostic(variant: .inset) }, page: "Variant")
        }
    }
}

private struct EdgeBackdropDiagnostic: View {
    enum Variant { case edgeEffect, inset }
    let variant: Variant

    var body: some View {
        ShowcasePage(title: "Effects") {
            ComponentPage(name: "Variant", summary: "EdgeBackdrop straight in the page.", canvas: .tall(minHeight: 360)) {
                specimen
                    .frame(height: 340)
                    .clipShape(.rect(cornerRadius: AppRadius.lg))
            }
            ComponentPage(name: "Other", summary: "A second page.") {
                Text(verbatim: "Other")
            }
        }
    }

    private var rows: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(0..<8, id: \.self) { index in
                    Text(verbatim: "Row \(index + 1) of the thread under the bar")
                        .font(AppTypography.body)
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.accent.opacity(0.15), in: .rect(cornerRadius: AppRadius.lg))
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private var bar: some View {
        Circle()
            .fill(AppColors.accent)
            .frame(width: AppIconSize.Tile.xxxl, height: AppIconSize.Tile.xxxl)
            .padding(.vertical, AppSpacing.lg)
            .frame(maxWidth: .infinity)
            .edgeBackdrop(.top)
    }

    @ViewBuilder
    private var specimen: some View {
        switch variant {
        case .edgeEffect:
            rows.safeAreaBar(edge: .top) { bar }
        case .inset:
            rows
                .scrollEdgeEffectHidden(true, for: .top)
                .safeAreaInset(edge: .top, spacing: 0) { bar }
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
/// run on) and compares it with `<test>.png`.
@MainActor
private func assertPageSnapshot<V: View>(
    _ screen: V,
    page: String,
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
        fileID: fileID,
        file: file,
        testName: testName,
        line: line,
        column: column
    )
}
