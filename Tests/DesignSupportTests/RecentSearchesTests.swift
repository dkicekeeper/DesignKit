//
//  RecentSearchesTests.swift
//  DesignKit
//
//  The recent queries behind `.dsSearchSuggestions` (3.5.0): order, duplicates, the limit, the
//  stored form; and how a typed query matches a text.
//

import Testing
@testable import DesignSupport

struct RecentSearchesTests {

    @Test func newestFirstWithoutDuplicates() {
        var recent = RecentSearches()
        recent.record("Kapchagay")
        recent.record("  pike ")
        recent.record("KAPCHAGAY")
        #expect(recent.queries == ["KAPCHAGAY", "pike"])
    }

    @Test func blankQueriesAreIgnored() {
        var recent = RecentSearches(["lake"])
        recent.record("   ")
        recent.record("")
        #expect(recent.queries == ["lake"])
    }

    @Test func oldestDropOffPastTheLimit() {
        var recent = RecentSearches()
        for index in 1...10 {
            recent.record("query \(index)")
        }
        #expect(recent.queries.count == RecentSearches.defaultLimit)
        #expect(recent.queries.first == "query 10")
        #expect(recent.queries.last == "query 3")

        recent.record("query 11", limit: 2)
        #expect(recent.queries == ["query 11", "query 10"])
    }

    @Test func removeIgnoresCase() {
        var recent = RecentSearches(["Coffee", "Fuel"])
        recent.remove("coffee")
        #expect(recent.queries == ["Fuel"])
        recent.removeAll()
        #expect(recent.isEmpty)
    }

    @Test func initKeepsTheGivenOrder() {
        #expect(RecentSearches(["c", "b", "a", "B"]).queries == ["c", "b", "a"])
    }

    @Test func rawValueRoundTrip() throws {
        let recent = RecentSearches(["Ақсай", "кофе \"Рай\"", "Café"])
        let restored = try #require(RecentSearches(rawValue: recent.rawValue))
        #expect(restored == recent)
        #expect(RecentSearches(rawValue: "not json") == nil)
        #expect(RecentSearches(rawValue: "[]")?.isEmpty == true)
    }

    @Test(arguments: [
        ("кофе", "Кофемания", true),
        ("ёлка", "Елка у дома", true),       // ё and е are one letter to a search
        ("cafe", "Café Central", true),
        ("озеро", "Большое Алматинское озеро", true),
        ("река", "Капчагай", false),
        ("  ", "Anything", false),
    ])
    func matchingIgnoresCaseAndDiacritics(query: String, text: String, matches: Bool) {
        #expect((SearchMatch.range(of: query, in: text) != nil) == matches)
    }

    @Test func matchesAnyOfSeveralTexts() {
        #expect(SearchMatch.matches("aida", "Aida Bekova", nil))
        #expect(SearchMatch.matches("bek", "Aida", "@bekova"))
        #expect(!SearchMatch.matches("x", nil, "Aida"))
    }

    @Test func sameQueryIgnoresCaseSpacesAndDiacritics() {
        #expect(SearchMatch.isSame(" Café ", "cafe"))
        #expect(!SearchMatch.isSame("cafe", "cafes"))
    }

    @Test func rangeCoversTheTypedPart() throws {
        let title = "Кофемания"
        let range = try #require(SearchMatch.range(of: "КОФ", in: title))
        #expect(title[range] == "Коф")
    }
}
