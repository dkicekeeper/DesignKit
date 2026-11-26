//
//  GalleryCodeTests.swift
//  DesignKit Gallery snapshot tests
//
//  vNext: what a component page shows besides its preview. The code of the current configuration
//  (`SwiftCode`) and the parameters read from docs/components.json (`ComponentReference`).
//

import Foundation
import Testing
@testable import DesignKitGallery

@MainActor
@Suite("Gallery code and parameters")
struct GalleryCodeTests {
    // MARK: SwiftCode

    @Test("A short call stays on one line, its defaults left out")
    func shortCall() {
        let code = SwiftCode.call("DSButton", [
            .text("Save"),
            .option("role", ".normal", default: ".normal"),
            .flag("isLoading", true),
            .flag("isDisabled", false),
        ], trailing: "save()")
        #expect(code == "DSButton(\"Save\", isLoading: true) { save() }")
    }

    @Test("A long call puts an argument a line")
    func longCall() {
        let code = SwiftCode.call("DSButton", [
            .text("Continue without signing in"),
            .labeled("appearance", ".secondary"),
            .flag("fullWidth", true),
        ])
        #expect(code == """
        DSButton(
            "Continue without signing in",
            appearance: .secondary,
            fullWidth: true
        )
        """)
    }

    @Test("No arguments and a trailing closure: the name and the closure")
    func onlyTrailing() {
        #expect(SwiftCode.call("FormSection", trailing: "rows") == "FormSection { rows }")
        #expect(SwiftCode.call("Spacer") == "Spacer()")
    }

    @Test("A long or multi-line closure body goes under the call, indented")
    func longClosure() {
        let code = SwiftCode.call("FormSection", [.text("header", "Display")], trailing: "UniversalRow(\"Currency\")\nUniversalRow(\"Theme\")")
        #expect(code == """
        FormSection(header: "Display") {
            UniversalRow("Currency")
            UniversalRow("Theme")
        }
        """)
    }

    @Test("A modifier goes on its own line under the view")
    func modifier() {
        let code = SwiftCode.modifier("Text(\"Pressure\")", "infoTip", [.text("Over the last 24 hours."), .text("title", "Pressure")])
        #expect(code == """
        Text("Pressure")
            .infoTip("Over the last 24 hours.", title: "Pressure")
        """)
    }

    @Test("Strings are escaped, numbers written as Swift writes them")
    func literals() {
        #expect(SwiftCode.string("Kaspi \"Gold\"\nCard") == "\"Kaspi \\\"Gold\\\"\\nCard\"")
        #expect(SwiftCode.number(1_284_500) == "1_284_500")
        #expect(SwiftCode.number(4200) == "4200")
        #expect(SwiftCode.number(-42_000) == "-42_000")
        #expect(SwiftCode.number(0.35) == "0.35")
        #expect(SwiftCode.number(0.5) == "0.5")
        #expect(SwiftCode.Argument.number("progress", 0.4, default: 0.4) == nil)
        #expect(SwiftCode.array(["1", "2"]) == "[1, 2]")
    }

    // MARK: ComponentReference

    @Test("A signature's parameters: labels, names, types and defaults")
    func parameters() {
        let parameters = ComponentReference.parameters(of: "init(_ title: String, systemImage: String? = nil, role: Role = .normal, action: @escaping () -> Void)")
        #expect(parameters == [
            .init(label: "_", name: "title", type: "String", defaultValue: nil),
            .init(label: "systemImage", name: nil, type: "String?", defaultValue: "nil"),
            .init(label: "role", name: nil, type: "Role", defaultValue: ".normal"),
            .init(label: "action", name: nil, type: "@escaping () -> Void", defaultValue: nil),
        ])
    }

    @Test("Commas and colons inside closures, generics and strings stay with their parameter")
    func nested() {
        let parameters = ComponentReference.parameters(of: "init(icon: String = \"\", action: (() -> Void)? = nil, values: [String: Int] = [:], label: String = \"a, b\", @ViewBuilder artwork: () -> Artwork)")
        #expect(parameters.map(\.label) == ["icon", "action", "values", "label", "artwork"])
        #expect(parameters[1].type == "(() -> Void)?")
        #expect(parameters[2].type == "[String: Int]")
        #expect(parameters[2].defaultValue == "[:]")
        #expect(parameters[3].defaultValue == "\"a, b\"")
        #expect(parameters[4].type == "() -> Artwork")
    }

    @Test("A modifier's signature: its generics before the parentheses do not count")
    func modifierSignature() {
        let parameters = ComponentReference.parameters(of: "func celebration<Trigger: Equatable>(trigger: Trigger, colors: [Color]? = nil, playsHaptic: Bool = true) -> some View")
        #expect(parameters.map(\.label) == ["trigger", "colors", "playsHaptic"])
        #expect(parameters[2].defaultValue == "true")
    }

    @Test("The bundled reference reads, and DSButton's page has its initialiser")
    func bundled() throws {
        let reference = try #require(ComponentReference.bundled)
        #expect(reference.count > 150)
        let declarations = reference.declarations(forPage: "DSButton")
        let initialiser = try #require(declarations.first?.initialisers.first)
        #expect(ComponentReference.parameters(of: initialiser).contains { $0.label == "isLoading" })
    }

    @Test("Every signature of the reference reads into parameters")
    func everySignature() throws {
        let url = try #require(Bundle.main.url(forResource: "components", withExtension: "json"))
        let entries = try JSONDecoder().decode([ComponentReference.Entry].self, from: Data(contentsOf: url))
        for signature in entries.flatMap(\.code).flatMap(\.initialisers) where signature.contains(":") {
            let parameters = ComponentReference.parameters(of: signature)
            #expect(!parameters.isEmpty, "\(signature)")
            #expect(parameters.allSatisfy { !$0.type.isEmpty }, "\(signature)")
        }
    }
}
