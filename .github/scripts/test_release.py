#!/usr/bin/env python3
"""Tests of .github/scripts/release.py: release notes in .changes/, the version a merge gets, the
CHANGELOG section, the vNext token, the branch check and the release bot (docs/releasing.md).
Run: python3 .github/scripts/test_release.py (CI's Changelog job runs it)."""

import os
import sys
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


if __name__ == "__main__":
    unittest.main()
