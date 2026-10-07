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
        // Fixed demo rates, so ConvertedAmountView and CurrencyAmountInput have something to
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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
