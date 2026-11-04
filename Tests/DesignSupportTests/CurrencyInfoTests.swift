//
//  CurrencyInfoTests.swift
//  DesignSupportTests
//
//  Pins the currency list a person picks from (onboarding, account and transaction forms):
//  currencies in use only. `Locale.Currency.isoCurrencies` also holds withdrawn ones (the
//  Austrian schilling, the Deutsche Mark), which Tenra's onboarding listed among "All
//  currencies".
//

import Testing
import Foundation
@testable import DesignSupport

struct CurrencyInfoTests {

    private var codes: Set<String> { Set(CurrencyInfo.allCurrencies.map(\.code)) }

    @Test("Withdrawn currencies are not offered")
    func noWithdrawnCurrencies() {
        #expect(!codes.contains("ATS"))
        #expect(!codes.contains("DEM"))
        #expect(!codes.contains("FRF"))
    }

    @Test("Currencies in use are offered")
    func currenciesInUse() {
        #expect(codes.isSuperset(of: ["KZT", "USD", "EUR", "RUB", "UZS"]))
    }
}
