//
//  SwiftCode.swift
//  DesignKit Gallery
//
//  The code a component page shows (8.22.3): the call that draws its preview as the controls set
//  it, the arguments at their defaults left out, as a person would write it.
//
//  A page builds it in a computed property of its own and passes it as
//  `ComponentPage(code: buttonCode)`:
//
//      private var buttonCode: String {
//          SwiftCode.call("DSButton", [
//              .text(title),
//              .option("role", ".\(role)", default: ".normal"),
//              .flag("isLoading", isLoading),
//          ], trailing: "save()")
//      }
//
//  →   DSButton("Save", isLoading: true) { save() }
//

import Foundation

enum SwiftCode {
    /// One argument of a call. `nil` (from `flag`, `option`, `number`) leaves it out.
    struct Argument: Equatable {
        let label: String?
        let value: String

        var text: String { label.map { "\($0): \(value)" } ?? value }
    }

    /// A call that fits on one line stays on one line; a longer one puts an argument a line.
    static let lineWidth = 60

    /// `Name(arguments) { trailing }`. With no arguments and a trailing closure, `Name { … }`.
    static func call(_ name: String, _ arguments: [Argument?] = [], trailing: String? = nil) -> String {
        let arguments = arguments.compactMap { $0 }.map(\.text)
        var code: String
        let oneLine = "\(name)(\(arguments.joined(separator: ", ")))"
        if arguments.isEmpty, trailing != nil {
            code = name
        } else if oneLine.count <= lineWidth, !arguments.contains(where: { $0.contains("\n") }) {
            code = oneLine
        } else {
            code = "\(name)(\n" + arguments.map(indent).joined(separator: ",\n") + "\n)"
        }
        if let trailing { code += closure(trailing) }
        return code
    }

    /// `base` and a modifier under it: `Text("Pressure")` ⏎ `    .infoTip("…")`.
    static func modifier(_ base: String, _ name: String, _ arguments: [Argument?] = [], trailing: String? = nil) -> String {
        base + "\n" + indent("." + call(name, arguments, trailing: trailing))
    }

    /// A trailing closure: ` { body }` for a short line, the body indented under it otherwise.
    static func closure(_ body: String) -> String {
        if !body.contains("\n"), body.count <= lineWidth - 10 {
            return " { \(body) }"
        }
        return " {\n" + indent(body) + "\n}"
    }

    /// Every line of `text` four spaces in.
    static func indent(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : "    " + $0 }
            .joined(separator: "\n")
    }

    /// A string literal: `"Kaspi \"Gold\""`.
    static func string(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    /// A number as Swift writes it: `1_284_500`, `0.35`, `-42`.
    static func number(_ value: Double) -> String {
        if value.rounded() == value, abs(value) < 1e15 {
            let whole = Int(value)
            let digits = String(abs(whole))
            guard digits.count > 4 else { return String(whole) }
            var grouped = ""
            for (index, digit) in digits.reversed().enumerated() {
                if index > 0, index % 3 == 0 { grouped.append("_") }
                grouped.append(digit)
            }
            return (whole < 0 ? "-" : "") + String(grouped.reversed())
        }
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }

    /// An array literal: `[a, b]`, or an element a line when it is long.
    static func array(_ elements: [String]) -> String {
        let oneLine = "[\(elements.joined(separator: ", "))]"
        if oneLine.count <= lineWidth, !elements.contains(where: { $0.contains("\n") }) {
            return oneLine
        }
        return "[\n" + elements.map(indent).joined(separator: ",\n") + ",\n]"
    }
}

extension SwiftCode.Argument {
    /// An argument without a label: `items`, `$selection`.
    static func positional(_ value: String) -> Self {
        Self(label: nil, value: value)
    }

    /// `label: value`, written as given.
    static func labeled(_ label: String, _ value: String) -> Self {
        Self(label: label, value: value)
    }

    /// A string literal without a label: `"Save"`.
    static func text(_ text: String) -> Self {
        Self(label: nil, value: SwiftCode.string(text))
    }

    /// A string literal with its label: `title: "Save"`.
    static func text(_ label: String, _ text: String) -> Self {
        Self(label: label, value: SwiftCode.string(text))
    }

    /// `label: true`, left out at the parameter's default.
    static func flag(_ label: String, _ value: Bool, default defaultValue: Bool = false) -> Self? {
        value == defaultValue ? nil : Self(label: label, value: value ? "true" : "false")
    }

    /// `label: value`, left out when it is the parameter's default (both as Swift writes them).
    static func option(_ label: String, _ value: String, default defaultValue: String) -> Self? {
        value == defaultValue ? nil : Self(label: label, value: value)
    }

    /// `label: 0.4`, left out at the parameter's default; positional without a label.
    static func number(_ label: String?, _ value: Double, default defaultValue: Double? = nil) -> Self? {
        value == defaultValue ? nil : Self(label: label, value: SwiftCode.number(value))
    }
}
