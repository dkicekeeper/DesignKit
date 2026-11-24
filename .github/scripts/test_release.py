#!/usr/bin/env python3
"""Tests of .github/scripts/release.py: release notes in .changes/, the version a merge gets, the
CHANGELOG section, the vNext token, the branch check and the release bot (docs/releasing.md).
Run: python3 .github/scripts/test_release.py (CI's Changelog job runs it)."""

import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import changelog  # noqa: E402
import release  # noqa: E402

NOTE = """---
bump: minor
---
A share card names its app.

### Added
- `ShareCardFrame(brandIcon:)`.

### Gallery and tooling
- A snapshot.
"""

OUT_OF_ORDER = """---
bump: minor
---
Text.

### Gallery and tooling
- A snapshot.

### Added
- A view.
"""

FIX = """---
bump: patch
---
A fix.

### Fixed
- A fix.

### Gallery and tooling
- A snapshot.
"""


class NoteTests(unittest.TestCase):
    def test_parse_note(self):
        f = release.parse_fragment(NOTE, ".changes/a.md")
        self.assertEqual(f.bump, "minor")
        self.assertIsNone(f.version)
        self.assertEqual(f.intro, "A share card names its app.")
        self.assertEqual(list(f.sections), ["Added", "Gallery and tooling"])
        self.assertEqual(f.sections["Added"], ["- `ShareCardFrame(brandIcon:)`."])
        self.assertEqual(release.fragment_problems(f), [])

    def test_note_rules(self):
        bad = lambda text: release.note_problems(text, ".changes/x.md")  # noqa: E731
        self.assertTrue(any("bump" in p for p in bad(NOTE.replace("minor", "huge"))))
        self.assertTrue(any("Added" in p for p in bad(NOTE.replace("minor", "patch"))))
        self.assertTrue(any("Removed" in p for p in bad(NOTE.replace("### Added", "### Removed"))))
        self.assertTrue(any("version" in p for p in bad(NOTE.replace("bump: minor", "bump: minor\nversion: 9.0.0"))))
        self.assertTrue(any("order" in p for p in bad(OUT_OF_ORDER)))
        self.assertTrue(any("dash" in p for p in bad(NOTE.replace("names its app", "names it — the app"))))
        self.assertTrue(bad("bump: minor\n\nText\n"))  # no front matter: reported, not raised
        self.assertTrue(all(p.startswith(".changes/x.md") for p in bad(NOTE.replace("minor", "huge"))))
        self.assertEqual(bad(NOTE.replace("bump: minor", "bump: major\nversion: 9.0.0").replace("### Added", "### Removed")), [])

    def test_check_messages_unchanged(self):
        self.assertIn("em dash", changelog.line_problem("a — b"))
        self.assertIsNone(changelog.line_problem("a, b"))

    def test_versions_text(self):
        self.assertEqual(release.parse_version("8.16.1\n"), (8, 16, 1))
        self.assertEqual(release.format_version((9, 0, 0)), "9.0.0")


class VersionTests(unittest.TestCase):
    def test_versions(self):
        self.assertEqual(release.base_version(["8.13.0", "8.9.0", "8.14.0", "x"], "8.12.0\n"), (8, 14, 0))
        self.assertEqual(release.base_version(["8.14.0"], "8.16.1\n"), (8, 16, 1))
        self.assertEqual(release.next_version((8, 16, 1), "patch"), (8, 16, 2))
        self.assertEqual(release.next_version((8, 16, 1), "minor"), (8, 17, 0))
        self.assertEqual(release.next_version((8, 16, 1), "major"), (9, 0, 0))

    def test_combine_two_notes(self):
        a = release.parse_fragment(NOTE, ".changes/a.md")
        b = release.parse_fragment(FIX, ".changes/b.md")
        c = release.combine([a, b])
        self.assertEqual(c.bump, "minor")
        self.assertEqual(c.intro, "A share card names its app.\n\nA fix.")
        self.assertEqual(list(c.sections), ["Added", "Fixed", "Gallery and tooling"])
        self.assertEqual(c.sections["Gallery and tooling"], ["- A snapshot.", "- A snapshot."])

    def test_section_and_insert(self):
        head = "# Changelog\n\nPreamble.\n\n## 8.14.0 - 2026-11-24\n\nOld.\n"
        self.assertEqual(release.release_date("2026-11-23", head), "2026-11-24")
        self.assertEqual(release.release_date("2026-11-25", head), "2026-11-25")
        section = release.render_section("8.15.0", "2026-11-24", release.parse_fragment(NOTE), [109, 110], "dkicekeeper/DesignKit")
        self.assertTrue(section.startswith(
            "## 8.15.0 - 2026-11-24\n\nA share card names its app.\n"
            "[#109](https://github.com/dkicekeeper/DesignKit/pull/109), [#110](https://github.com/dkicekeeper/DesignKit/pull/110)\n\n### Added\n"))
        self.assertTrue(section.endswith("- A snapshot.\n"))
        self.assertNotIn("[#", release.render_section("8.15.0", "2026-11-24", release.parse_fragment(NOTE), [], "o/r"))
        out = release.insert_section(head, section)
        self.assertLess(out.index("## 8.15.0"), out.index("## 8.14.0"))
        self.assertTrue(out.startswith("# Changelog\n\nPreamble.\n\n## 8.15.0"))
        self.assertIn("- A snapshot.\n\n## 8.14.0", out)


class TokenTests(unittest.TestCase):
    def test_replace_token_cases(self):
        text = 'since: "vNext"\n(vNext)\nAdded in vNext.\nWrite `vNext` here.\nvNextFoo xvNext\n'
        out, n = release.replace_token(text, "8.15.0")
        self.assertEqual(out, 'since: "8.15.0"\n(8.15.0)\nAdded in 8.15.0.\nWrite `vNext` here.\nvNextFoo xvNext\n')
        self.assertEqual(n, 3)
        self.assertFalse(release.has_bare_token(out))
        self.assertTrue(release.has_bare_token(text))

    def test_skip_list(self):
        for path in (".changes/a.md", ".github/workflows/ci.yml", ".github/scripts/release.py",
                     ".github/scripts/test_release.py", "docs/releasing.md", "docs/superpowers/plans/p.md"):
            self.assertTrue(release.is_skipped(path), path)
        for path in ("CLAUDE.md", "Gallery/Gallery/Screens/MediaScreen.swift", "docs/design-system.md",
                     ".github/scripts/changelog.py"):
            self.assertFalse(release.is_skipped(path), path)

    def test_replace_in_tree(self):
        with tempfile.TemporaryDirectory() as root:
            def write(path, data):
                full = os.path.join(root, path)
                os.makedirs(os.path.dirname(full), exist_ok=True)
                open(full, "wb").write(data)
            write("a.swift", b'since: "vNext"\n')
            write(".changes/n.md", b"Added in vNext.\n")
            write("b.png", b"\0vNext")
            write("c.md", b"Nothing here.\n")
            changed = release.replace_in_tree(root, ["a.swift", ".changes/n.md", "b.png", "c.md"], "8.15.0")
            self.assertEqual(changed, ["a.swift"])
            self.assertEqual(open(os.path.join(root, "a.swift"), "rb").read(), b'since: "8.15.0"\n')
            self.assertEqual(open(os.path.join(root, ".changes/n.md"), "rb").read(), b"Added in vNext.\n")
            self.assertEqual(open(os.path.join(root, "b.png"), "rb").read(), b"\0vNext")


if __name__ == "__main__":
    unittest.main()
