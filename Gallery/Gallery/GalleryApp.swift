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
        // Fixed demo rates, so ConvertedAmountView has something to show. Apps wire real FX.
        DesignKitCurrencyConverter.convert = { amount, from, to in
            let tengePerUnit: [String: Double] = ["KZT": 1, "USD": 480, "EUR": 520, "RUB": 5.2]
            guard let fromRate = tengePerUnit[from], let toRate = tengePerUnit[to] else { return nil }
            return amount * fromRate / toRate
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
