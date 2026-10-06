//
//  DesignKitLogoCatalog.swift
//  DesignKit
//
//  The brand logos an icon picker offers are an app concern: which banks and services its
//  users meet (Tenra: Kazakh banks, streaming, telecom…). The host sets the catalog once
//  in App.init(); with none set, `IconPicker` shows only SF Symbols. The logos themselves
//  load through `DesignKitLogoLoader`, like every `.brandService` icon.
//

import Foundation

public enum DesignKitLogoCatalog {
    /// One brand: its domain (the `.brandService` source) and the name to show.
    public struct Entry: Identifiable, Hashable, Sendable {
        public let domain: String
        public let name: String
        public var id: String { domain }

        public init(domain: String, name: String) {
            self.domain = domain
            self.name = name
        }
    }

    /// A titled group of brands ("Banks", "Streaming").
    public struct Section: Identifiable, Sendable {
        public let title: String
        public let entries: [Entry]
        public var id: String { title }

        public init(title: String, entries: [Entry]) {
            self.title = title
            self.entries = entries
        }
    }

    /// The picker's logo sections, in order. Default: none, and the picker has no logos tab.
    public static var sections: @Sendable () -> [Section] = { [] }

    /// Brands matching what the user typed. Default: the sections' names containing the query.
    public static var search: @Sendable (String) -> [Entry] = { query in
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return DesignKitLogoCatalog.sections().flatMap(\.entries).filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    /// Top-level domains tried when the typed text is not a domain: "kaspi" → kaspi.com, …
    /// Default `["com"]`; Tenra adds "kz".
    public static var domainSuffixes: [String] = ["com"]
}
