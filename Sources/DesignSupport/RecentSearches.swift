//
//  RecentSearches.swift
//  DesignKit
//
//  The queries a person searched for, and how a typed query matches a text (3.5.0): the data
//  behind `.dsSearchSuggestions` (DesignComponents). No storage of its own: the app keeps the
//  value where it likes, `@AppStorage` included.
//

import Foundation

/// The queries a person searched for, newest first: what `.dsSearchSuggestions(text:recent:…)`
/// shows while the search field is empty.
///
/// A value without storage of its own. It is `RawRepresentable` (a JSON array of strings), so
/// an app keeps it under its own key:
///
/// ```swift
/// @AppStorage("places.recentSearches") private var recent = RecentSearches()
/// ```
public struct RecentSearches: Equatable, Hashable, Sendable, RawRepresentable {
    /// How many queries are kept unless `record(_:limit:)` says otherwise.
    public static let defaultLimit = 8

    /// Newest first, without duplicates (ignoring case and diacritics).
    public private(set) var queries: [String]

    public init(_ queries: [String] = []) {
        self.queries = []
        for query in queries.reversed() {
            record(query, limit: max(queries.count, Self.defaultLimit))
        }
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let queries = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        self.init(queries)
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(queries),
              let string = String(data: data, encoding: .utf8) else { return "[]" }
        return string
    }

    public var isEmpty: Bool { queries.isEmpty }

    /// Puts `query` first. Spaces around it are trimmed and an empty one is ignored; an
    /// earlier copy (in any case, with or without diacritics) goes; past `limit` the oldest
    /// drop off.
    public mutating func record(_ query: String, limit: Int = RecentSearches.defaultLimit) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        queries.removeAll { SearchMatch.isSame($0, trimmed) }
        queries.insert(trimmed, at: 0)
        if queries.count > max(limit, 1) {
            queries.removeLast(queries.count - max(limit, 1))
        }
    }

    /// Removes `query` (in any case).
    public mutating func remove(_ query: String) {
        queries.removeAll { SearchMatch.isSame($0, query) }
    }

    public mutating func removeAll() {
        queries.removeAll()
    }
}

/// How a typed query matches a text: ignoring case and diacritics ("е" finds "ё", "cafe" finds
/// "Café"), as the system's own search fields do.
public enum SearchMatch {
    private static let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    /// Where `query` (trimmed) first occurs in `text`; nil when it doesn't, or is empty.
    public static func range(of query: String, in text: String) -> Range<String.Index>? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return text.range(of: trimmed, options: options, locale: .current)
    }

    /// Whether `query` occurs in any of `texts`.
    public static func matches(_ query: String, _ texts: String?...) -> Bool {
        texts.contains { text in text.map { range(of: query, in: $0) != nil } ?? false }
    }

    /// Whether two queries are the same search (trimmed, ignoring case and diacritics).
    public static func isSame(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines)
            .compare(rhs.trimmingCharacters(in: .whitespacesAndNewlines), options: options, locale: .current)
            == .orderedSame
    }
}
