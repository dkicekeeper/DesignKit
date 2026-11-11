//
//  ContrastTests.swift
//  DesignKit
//
//  Text colours against what they sit on, by WCAG 2.x (8.9.0, benchmark round 4): status text on
//  the page and on its pale container, a category's colour made readable on its own tint, white
//  on a filled badge and on the accents. 4.5:1 is AA for body text and icons.
//
//  8.10.0: white text sits on `AppColors.accentFill` (the accent made readable as a fill) and
//  income text is `AppColors.incomeText`, so the accents and income pass too; the apps' raw
//  accents and the bright `income` stay for tints, fills and charts.
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

    /// Dalada's AccentColor: light #2E8B57, dark #3CB371 (as the Gallery's Dalada theme).
    private static let daladaGreen = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x3C / 255, green: 0xB3 / 255, blue: 0x71 / 255, alpha: 1)
            : UIColor(red: 0x2E / 255, green: 0x8B / 255, blue: 0x57 / 255, alpha: 1)
    })

    @Test("White reads on the accent's fill: Tenra's indigo and Dalada's green, both themes (8.10.0)")
    func accentFills() {
        let accents: [(String, Color)] = [("Tenra's indigo", .indigo), ("Dalada's green", Self.daladaGreen)]
        for (name, accent) in accents {
            for (mode, traits) in Self.modes {
                let ratio = AppColors.contrastRatio(AppColors.Text.onAccent, AppColors.readableFill(accent), in: traits)
                #expect(ratio >= Self.minimum, "white on \(name), \(mode): \(ratio)")
            }
        }
    }

    @Test("The accent's fill is the accent where white already reads on it (Tenra's indigo, light)")
    func accentFillKeepsAReadableAccent() {
        let fill = UIColor(AppColors.readableFill(.indigo)).resolvedColor(with: Self.light)
        let indigo = UIColor(Color.indigo).resolvedColor(with: Self.light)
        var a = (r: CGFloat(0), g: CGFloat(0), b: CGFloat(0), alpha: CGFloat(0))
        var b = a
        fill.getRed(&a.r, green: &a.g, blue: &a.b, alpha: &a.alpha)
        indigo.getRed(&b.r, green: &b.g, blue: &b.b, alpha: &b.alpha)
        #expect(abs(a.r - b.r) < 0.01 && abs(a.g - b.g) < 0.01 && abs(a.b - b.b) < 0.01)
    }

    @Test("Income as text reads on the page in both themes (8.10.0)")
    func incomeText() {
        for (mode, traits) in Self.modes {
            let ratio = AppColors.contrastRatio(AppColors.incomeText, AppColors.Background.base, in: traits)
            #expect(ratio >= Self.minimum, "income text, \(mode): \(ratio)")
        }
    }
}
