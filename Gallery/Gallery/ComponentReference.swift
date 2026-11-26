//
//  ComponentReference.swift
//  DesignKit Gallery
//
//  The parameters a component page lists (vNext): its initialisers from docs/components.json,
//  which the release bot writes after every merge (`.github/scripts/components_reference.py`) and
//  `Gallery/project.yml` puts in the bundle, as it does CHANGELOG.md. A page that is not in it yet
//  (a component added since the last release) shows no parameters.
//

import Foundation

struct ComponentReference {
    /// One component of the reference: a page of the Gallery.
    struct Entry: Decodable {
        let name: String
        let code: [Declaration]
    }

    /// A type or modifier the page shows, with its initialisers (or the modifier's signature).
    struct Declaration: Decodable {
        let name: String
        let doc: String?
        let initialisers: [String]
        let skeleton: String?
    }

    /// One parameter of an initialiser: `_ title: String`, `role: Role = .normal`.
    struct Parameter: Equatable {
        /// The argument label, `_` when there is none.
        let label: String
        /// The parameter's own name when it differs from the label (`_ title`).
        let name: String?
        let type: String
        let defaultValue: String?
    }

    private let entries: [String: Entry]

    /// The reference in the Gallery's bundle; nil when it is missing or unreadable.
    static let bundled: ComponentReference? = {
        guard let url = Bundle.main.url(forResource: "components", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? ComponentReference(data: data)
    }()

    init(data: Data) throws {
        let list = try JSONDecoder().decode([Entry].self, from: data)
        entries = Dictionary(list.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var count: Int { entries.count }

    /// The declarations of the page titled `page`.
    func declarations(forPage page: String) -> [Declaration] {
        entries[page]?.code ?? []
    }

    /// The parameters of `signature` (an `init(…)` or a modifier's `func name(…) -> some View`), in
    /// order. Commas inside brackets, closures' types, generics and string defaults stay with their
    /// parameter.
    static func parameters(of signature: String) -> [Parameter] {
        let characters = Array(signature)
        guard let open = characters.firstIndex(of: "("),
              let close = matching(characters, from: open) else { return [] }
        let inner = Array(characters[(open + 1)..<close])
        return split(inner, at: ",").compactMap(parameter)
    }

    /// The `)` that closes the `(` at `start`, strings and nested brackets aside.
    private static func matching(_ characters: [Character], from start: Int) -> Int? {
        var depth = 0
        var inString = false
        var index = start
        while index < characters.count {
            let character = characters[index]
            if inString {
                if character == "\\" { index += 2; continue }
                if character == "\"" { inString = false }
            } else if character == "\"" {
                inString = true
            } else if character == "(" {
                depth += 1
            } else if character == ")" {
                depth -= 1
                if depth == 0 { return index }
            }
            index += 1
        }
        return nil
    }

    /// `text` split at each `separator` that is outside strings and brackets. `->` is an arrow,
    /// not a closing `>`.
    private static func split(_ text: [Character], at separator: Character) -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0
        var inString = false
        var index = 0
        while index < text.count {
            let character = text[index]
            if inString {
                current.append(character)
                if character == "\\", index + 1 < text.count {
                    current.append(text[index + 1])
                    index += 2
                    continue
                }
                if character == "\"" { inString = false }
            } else if character == "\"" {
                inString = true
                current.append(character)
            } else if character == "-", index + 1 < text.count, text[index + 1] == ">" {
                current.append("->")
                index += 2
                continue
            } else if "([{<".contains(character) {
                depth += 1
                current.append(character)
            } else if ")]}>".contains(character) {
                depth -= 1
                current.append(character)
            } else if character == separator, depth == 0 {
                parts.append(current)
                current = ""
            } else {
                current.append(character)
            }
            index += 1
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty { parts.append(current) }
        return parts
    }

    /// `@ViewBuilder content: () -> Content`, `_ title: String`, `role: Role = .normal`.
    private static func parameter(_ text: String) -> Parameter? {
        var text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Attributes before the names (`@ViewBuilder`, `@MainActor`).
        while text.hasPrefix("@"), let space = text.firstIndex(of: " ") {
            text = String(text[space...]).trimmingCharacters(in: .whitespaces)
        }
        let characters = Array(text)
        guard let colon = topLevelIndex(of: ":", in: characters) else { return nil }
        let names = String(characters[..<colon]).split(separator: " ").map(String.init)
        guard let label = names.first else { return nil }
        let rest = Array(characters[(colon + 1)...])
        let type: String
        let defaultValue: String?
        if let equals = topLevelIndex(of: "=", in: rest) {
            type = String(rest[..<equals]).trimmingCharacters(in: .whitespaces)
            defaultValue = String(rest[(equals + 1)...]).trimmingCharacters(in: .whitespaces)
        } else {
            type = String(rest).trimmingCharacters(in: .whitespaces)
            defaultValue = nil
        }
        return Parameter(label: label, name: names.count > 1 ? names[1] : nil, type: type, defaultValue: defaultValue)
    }

    /// The first `character` outside strings and brackets; an `=` of `==`, `>=`, `<=` or `!=`
    /// does not count.
    private static func topLevelIndex(of character: Character, in text: [Character]) -> Int? {
        var depth = 0
        var inString = false
        var index = 0
        while index < text.count {
            let current = text[index]
            if inString {
                if current == "\\" { index += 2; continue }
                if current == "\"" { inString = false }
            } else if current == "\"" {
                inString = true
            } else if current == "-", index + 1 < text.count, text[index + 1] == ">" {
                index += 2
                continue
            } else if "([{<".contains(current) {
                depth += 1
            } else if ")]}>".contains(current) {
                depth -= 1
            } else if current == character, depth == 0 {
                let before = index > 0 ? text[index - 1] : " "
                let after = index + 1 < text.count ? text[index + 1] : " "
                if character != "=" || (!"=!<>".contains(before) && after != "=") {
                    return index
                }
            }
            index += 1
        }
        return nil
    }
}
