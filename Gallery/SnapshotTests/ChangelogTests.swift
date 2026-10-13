//
//  ChangelogTests.swift
//  DesignKit Gallery
//
//  The Updates screen reads CHANGELOG.md, bundled with the Gallery: these check that the file
//  ships and reads into releases and sections (CI's `changelog.py check` holds its format), and
//  that the reader handles each kind of block. Not a snapshot: the notes grow with every release.
//

import Foundation
import Testing

@Suite("Changelog")
struct ChangelogTests {
    @Test("The bundled CHANGELOG.md reads into every release, newest first")
    func bundled() throws {
        let changelog = try #require(Changelog.bundled, "CHANGELOG.md is not in the Gallery's bundle")
        #expect(changelog.releases.count >= 44)
        #expect(changelog.releases.last?.version == "0.2.0")
        #expect(!changelog.intro.isEmpty)

        let versions = changelog.releases.map { $0.version.split(separator: ".").compactMap { Int($0) } }
        #expect(versions.allSatisfy { $0.count == 3 })
        #expect(zip(versions, versions.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) == false })

        for release in changelog.releases {
            #expect(release.date.count == 10, "\(release.version) has no date")
            #expect(!release.summary.isEmpty, "\(release.version) has no summary")
            #expect(!release.sections.isEmpty, "\(release.version) has no section")
            #expect(release.sections.allSatisfy { $0.kind != nil && !$0.blocks.isEmpty },
                    "\(release.version) has an unknown or empty section")
        }

        let major = try #require(changelog.releases.first { $0.version == "2.0.0" })
        #expect(major.isMajor)
        #expect(major.section(.removed) != nil)
        #expect(major.codeSpans.contains("DSButton"))
        #expect(changelog.release(mentionedIn: "since 1.12.0")?.version == "1.12.0")
    }

    @Test("Paragraphs, list items over several lines, and code")
    func blocks() {
        let changelog = Changelog.parse("""
        # Changelog

        Intro line one
        and two.

        ## 1.1.0 - 2026-10-02

        What it is. [#2](https://example.com/2)

        ### Added

        - `Thing(a:)`: does
          something.
        - `Other`.

        ```swift
        Thing(a: 1)

        Other()
        ```

        After the code.

        ### Migration

        - `Old` → `Thing`.

        ## 1.0.0 - 2026-10-01

        First.

        ### Removed

        - `Gone`.
        """)

        #expect(changelog.intro == [.paragraph("Intro line one and two.")])
        #expect(changelog.releases.map(\.version) == ["1.1.0", "1.0.0"])

        let release = changelog.releases[0]
        #expect(release.date == "2026-10-02")
        #expect(release.summary == ["What it is. [#2](https://example.com/2)"])
        #expect(release.sections.map(\.title) == ["Added", "Migration"])
        #expect(release.sections[0].blocks == [
            .bullets(["`Thing(a:)`: does something.", "`Other`."]),
            .code("Thing(a: 1)\n\nOther()"),
            .paragraph("After the code."),
        ])
        #expect(release.codeSpans == ["Thing(a:)", "Other", "Old", "Thing"])
        #expect(changelog.releases[1].isMajor)
        #expect(changelog.releases[1].section(.removed)?.blocks == [.bullets(["`Gone`."])])
    }
}
