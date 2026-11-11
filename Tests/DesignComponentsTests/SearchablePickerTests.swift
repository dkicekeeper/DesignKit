//
//  SearchablePickerTests.swift
//  DesignKit
//
//  What SearchablePicker's search keeps (8.9.0): title or subtitle, any case, any accents, in
//  the options' order.
//

import Testing
@testable import DesignComponents

@MainActor
struct SearchablePickerTests {
    private typealias Picker = SearchablePicker<Int>

    private let options: [SearchablePickerOption<Int>] = [
        SearchablePickerOption("Cafés", value: 1, subtitle: "Coffee, lunch out"),
        SearchablePickerOption("Groceries", value: 2),
        SearchablePickerOption("Taxi", value: 3, subtitle: "Rides and parking"),
        SearchablePickerOption("Кафе", value: 4),
    ]

    @Test func anEmptyQueryKeepsEverything() {
        #expect(Picker.matching(options, query: "").map(\.value) == [1, 2, 3, 4])
    }

    @Test func caseAndAccentsDoNotMatter() {
        #expect(Picker.matching(options, query: "cafe").map(\.value) == [1])
        #expect(Picker.matching(options, query: "КАФ").map(\.value) == [4])
    }

    @Test func theSubtitleIsSearchedToo() {
        #expect(Picker.matching(options, query: "parking").map(\.value) == [3])
    }

    @Test func noMatchIsEmpty() {
        #expect(Picker.matching(options, query: "zzz").isEmpty)
    }
}
