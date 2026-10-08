//
//  GalleryApp.swift
//  DesignKit Gallery
//
//  A standalone showcase app for the DesignKit design system.
//  Does NOT depend on Tenra — renders tokens & components in isolation.
//

import SwiftUI
import DesignTokens
import DesignSupport

@main
struct GalleryApp: App {
    init() {
        // Make the bundled Inter font resolve before any view renders.
        DesignKitFonts.registerIfNeeded()
        // Fixed demo rates, so ConvertedAmount and CurrencyAmountInput have something to
        // show. Apps wire real FX; like Tenra, both hooks: convertSync is the cached-rate path
        // that shows CurrencyAmountInput's "≈" line at once.
        let demoRates: @Sendable (Double, String, String) -> Double? = { amount, from, to in
            let tengePerUnit: [String: Double] = ["KZT": 1, "USD": 480, "EUR": 520, "RUB": 5.2]
            guard let fromRate = tengePerUnit[from], let toRate = tengePerUnit[to] else { return nil }
            return amount * fromRate / toRate
        }
        DesignKitCurrencyConverter.convert = { amount, from, to in demoRates(amount, from, to) }
        DesignKitCurrencyConverter.convertSync = demoRates
        // A few brands, so the icon picker has a logos tab. Apps list their own.
        DesignKitLogoCatalog.sections = {
            [
                .init(title: "Banks", entries: [
                    .init(domain: "kaspi.kz", name: "Kaspi"),
                    .init(domain: "halykbank.kz", name: "Halyk"),
                ]),
                .init(title: "Streaming", entries: [
                    .init(domain: "netflix.com", name: "Netflix"),
                    .init(domain: "spotify.com", name: "Spotify"),
                ]),
            ]
        }
        DesignKitLogoCatalog.domainSuffixes = ["com", "kz"]
        // Invented brands with logos drawn on the fly (GalleryLogos), for PackedCircleIcons and
        // Icon; any other name has none.
        DesignKitLogoLoader.loader = { await GalleryLogos.load($0) }
        // Stand-in photos for RemotePhoto (GalleryPhotos): held ones show at once, the others
        // arrive after a moment, as from the network.
        GalleryPhotos.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
