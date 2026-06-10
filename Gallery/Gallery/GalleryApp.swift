//
//  GalleryApp.swift
//  DesignKit Gallery
//
//  A standalone showcase app for the DesignKit design system.
//  Does NOT depend on Tenra — renders tokens & components in isolation.
//

import SwiftUI
import DesignTokens

@main
struct GalleryApp: App {
    init() {
        // Make the bundled Inter font resolve before any view renders.
        DesignKitFonts.registerIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
