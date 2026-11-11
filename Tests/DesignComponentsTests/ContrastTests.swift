//
//  ContrastTests.swift
//  DesignKit
//
//  Text colours against what they sit on, by WCAG 2.x (8.9.0, benchmark round 4): status text on
//  the page and on its pale container, a category's colour made readable on its own tint, white
//  on a filled badge and on the accents. 4.5:1 is AA for body text and icons.
//
//  A pair that is the apps' own choice and does not pass yet is a known issue here (Tenra's
//  indigo and Dalada's green under white text in dark mode, the income green on white): it is
//  reported, and the test fails once it passes, so the note is removed with the cause.
//

import SwiftUI
import UIKit
import Testing
import DesignTokens

@Suite("Contrast")
struct ContrastTests {
    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let modes: [(String, UITraitCollection)] = [("light", light), ("dark", dark)]
    private static let minimum = 4.5

    private static let statuses: [(name: String, text: Color, pale: Color, solid: Color)] = [
        ("info", AppColors.Status.infoText, AppColors.Status.infoPale, AppColors.Status.info),
        ("positive", AppColors.Status.positiveText, AppColors.Status.positivePale, AppColors.Status.positive),
        ("negative", AppColors.Status.negativeText, AppColors.Status.negativePale, AppColors.Status.negative),
        ("warning", AppColors.Status.warningText, AppColors.Status.warningPale, AppColors.Status.warning),
        ("neutral", AppColors.Status.neutralText, AppColors.Status.neutralPale, AppColors.Status.neutral),
    ]

    @Test("Status text reads on its pale container and on the page, in both themes")
    func statusText() {
        for status in Self.statuses {
            for (mode, traits) in Self.modes {
                let onPale = AppColors.contrastRatio(status.text, status.pale, in: traits)
                #expect(onPale >= Self.minimum, "\(status.name) on its pale, \(mode): \(onPale)")
                let onPage = AppColors.contrastRatio(status.text, AppColors.Background.base, in: traits)
                #expect(onPage >= Self.minimum, "\(status.name) on the page, \(mode): \(onPage)")
            }
        }
    }

    @Test("The text tokens of a rise, a fall and a warning read on the page")
    func textTokens() {
        let tokens: [(String, Color)] = [
            ("Text.positive", AppColors.Text.positive),
            ("Text.negative", AppColors.Text.negative),
            ("Text.warning", AppColors.Text.warning),
        ]
        for (name, color) in tokens {
            for (mode, traits) in Self.modes {
                let ratio = AppColors.contrastRatio(color, AppColors.Background.base, in: traits)
                #expect(ratio >= Self.minimum, "\(name), \(mode): \(ratio)")
            }
        }
    }

    @Test("Any category colour made readable reads on its own tint")
    func readableCategoryColours() {
        let colours = CategoryColors.paletteColors + CategoryColors.pickerPalette.map { Color(hex: $0) }
        for (index, colour) in colours.enumerated() {
            for (mode, traits) in Self.modes {
                let ratio = AppColors.contrastRatio(AppColors.readable(colour), AppColors.pale(colour), in: traits)
                #expect(ratio >= Self.minimum, "colour \(index), \(mode): \(ratio)")
            }
        }
    }

    @Test("A colour that already reads is left as it is")
    func readableKeepsWhatPasses() {
        let black = UIColor(AppColors.readable(.black)).resolvedColor(with: Self.light)
        var white: CGFloat = 1, alpha: CGFloat = 0
        black.getWhite(&white, alpha: &alpha)
        #expect(white < 0.01)
    }

    @Test("White reads on a filled badge of every status colour")
    func filledBadges() {
        for status in Self.statuses {
            for (mode, traits) in Self.modes {
                let ratio = AppColors.contrastRatio(.white, AppColors.readableFill(status.solid), in: traits)
                #expect(ratio >= Self.minimum, "white on filled \(status.name), \(mode): \(ratio)")
            }
        }
    }

    @Test("White on Tenra's indigo accent: it reads in light mode, 3.5:1 in dark mode (its choice)")
    func tenraAccent() {
        let light = AppColors.contrastRatio(AppColors.Text.onAccent, Color.indigo, in: Self.light)
        #expect(light >= Self.minimum, "white on indigo, light: \(light)")
        // iOS 26's dark indigo is lighter than white text needs; a deeper accent is Tenra's call.
        withKnownIssue("The system indigo in dark mode is too light for white text") {
            let dark = AppColors.contrastRatio(AppColors.Text.onAccent, Color.indigo, in: Self.dark)
            #expect(dark >= Self.minimum, "white on indigo, dark: \(dark)")
        }
    }

    /// Dalada's AccentColor: light #2E8B57, dark #3CB371 (as the Gallery's Dalada theme).
    @Test("White on Dalada's green accent: 4.3:1 in light mode, 2.7:1 in dark mode (its choice)")
    func daladaAccent() {
        let green = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0x3C / 255, green: 0xB3 / 255, blue: 0x71 / 255, alpha: 1)
                : UIColor(red: 0x2E / 255, green: 0x8B / 255, blue: 0x57 / 255, alpha: 1)
        })
        withKnownIssue("Dalada's accent is too light for white text; a deeper green is its decision") {
            for (mode, traits) in Self.modes {
                let ratio = AppColors.contrastRatio(AppColors.Text.onAccent, green, in: traits)
                #expect(ratio >= Self.minimum, "white on Dalada's green, \(mode): \(ratio)")
            }
        }
    }

    @Test("The income green on the page: 2.75:1 in light mode (Tenra's look, decided apart)")
    func incomeGreen() {
        withKnownIssue("AppColors.income is lighter than text needs in light mode") {
            let ratio = AppColors.contrastRatio(AppColors.income, AppColors.Background.base, in: Self.light)
            #expect(ratio >= Self.minimum, "income on white: \(ratio)")
        }
        let dark = AppColors.contrastRatio(AppColors.income, AppColors.Background.base, in: Self.dark)
        #expect(dark >= Self.minimum, "income on black: \(dark)")
    }
}
