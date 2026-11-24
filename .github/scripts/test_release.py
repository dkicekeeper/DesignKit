#!/usr/bin/env python3
"""Tests of .github/scripts/release.py: release notes in .changes/, the version a merge gets, the
CHANGELOG section, the vNext token, the branch check and the release bot (docs/releasing.md).
Run: python3 .github/scripts/test_release.py (CI's Changelog job runs it)."""

import os
import subprocess
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


def read_bytes(path):
    with open(path, "rb") as file:
        return file.read()


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
                with open(full, "wb") as file:
                    file.write(data)
            write("a.swift", b'since: "vNext"\n')
            write(".changes/n.md", b"Added in vNext.\n")
            write("b.png", b"\0vNext")
            write("c.md", b"Nothing here.\n")
            changed = release.replace_in_tree(root, ["a.swift", ".changes/n.md", "b.png", "c.md"], "8.15.0")
            self.assertEqual(changed, ["a.swift"])
            self.assertEqual(read_bytes(os.path.join(root, "a.swift")), b'since: "8.15.0"\n')
            self.assertEqual(read_bytes(os.path.join(root, ".changes/n.md")), b"Added in vNext.\n")
            self.assertEqual(read_bytes(os.path.join(root, "b.png")), b"\0vNext")


GIT_ENV = {
    "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.com",
    "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.com",
    "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1",
}
CHANGELOG = "# Changelog\n\nPreamble.\n\n## 8.14.0 - 2026-11-24\n\nOld.\n\n### Added\n\n- A thing.\n"


def git(root, *args):
    env = dict(os.environ, **GIT_ENV)
    return subprocess.run(["git", *args], cwd=root, env=env, check=True,
                          capture_output=True, text=True).stdout


def write(root, path, text):
    full = os.path.join(root, path)
    os.makedirs(os.path.dirname(full) or root, exist_ok=True)
    with open(full, "w", encoding="utf-8") as file:
        file.write(text)


def commit(root, files, message="change"):
    for path, text in files.items():
        if text is None:
            git(root, "rm", "-q", path)
        else:
            write(root, path, text)
            git(root, "add", path)
    git(root, "commit", "-q", "-m", message)
    return git(root, "rev-parse", "HEAD").strip()


def make_repo(root):
    """A repository on main at 8.14.0, tagged."""
    git(root, "init", "-q", "-b", "main")
    commit(root, {"VERSION": "8.14.0\n", "CHANGELOG.md": CHANGELOG,
                  "Sources/A.swift": "let a = 1\n", "docs/components.md": "# Components\n"}, "start")
    git(root, "tag", "8.14.0")


class BranchCheckTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.root = self.dir.name
        make_repo(self.root)
        git(self.root, "checkout", "-q", "-b", "feature")

    def tearDown(self):
        self.dir.cleanup()

    def check(self):
        return release.check_branch(self.root, "main")

    def test_check_clean_note(self):
        commit(self.root, {".changes/feature-2026-11-24-a.md": NOTE,
                           "Sources/A.swift": 'let a = 1 // since: "vNext"\n'})
        self.assertEqual(self.check(), ([], []))

    def test_check_version_edit(self):
        commit(self.root, {".changes/n.md": NOTE, "VERSION": "8.15.0\n"})
        errors, _ = self.check()
        self.assertTrue(any("VERSION" in e for e in errors), errors)

    def test_check_changelog_heading(self):
        commit(self.root, {".changes/n.md": NOTE,
                           "CHANGELOG.md": CHANGELOG.replace("## 8.14.0", "## 8.15.0 - 2026-11-24\n\nNew.\n\n### Fixed\n\n- X.\n\n## 8.14.0")})
        errors, _ = self.check()
        self.assertTrue(any("CHANGELOG" in e and "8.15.0" in e for e in errors), errors)

    def test_check_token_without_note(self):
        commit(self.root, {"Sources/A.swift": 'let a = 1 // since vNext\n'})
        errors, _ = self.check()
        self.assertTrue(any("vNext" in e for e in errors), errors)

    def test_check_token_in_backticks_needs_no_note(self):
        commit(self.root, {"README.md": "Write `vNext` where the version goes.\n"})
        self.assertEqual(self.check()[0], [])

    def test_check_reference_edit(self):
        commit(self.root, {".changes/n.md": NOTE, "docs/components.md": "# Components\n\nMore.\n"})
        errors, _ = self.check()
        self.assertTrue(any("docs/components.md" in e for e in errors), errors)

    def test_check_bad_note(self):
        commit(self.root, {".changes/n.md": NOTE.replace("minor", "patch")})
        errors, _ = self.check()
        self.assertTrue(any(e.startswith(".changes/n.md") and "Added" in e for e in errors), errors)

    def test_check_major_number(self):
        major = NOTE.replace("bump: minor", "bump: major\nversion: 10.0.0")
        commit(self.root, {".changes/n.md": major})
        errors, _ = self.check()
        self.assertTrue(any("9.0.0" in e for e in errors), errors)
        commit(self.root, {".changes/n.md": major.replace("10.0.0", "9.0.0")})
        self.assertEqual(self.check()[0], [])

    def test_check_code_without_note(self):
        commit(self.root, {"Sources/A.swift": "let a = 2\n"})
        errors, warnings = self.check()
        self.assertEqual(errors, [])
        self.assertEqual(len(warnings), 1)

    def test_preview(self):
        self.assertIsNone(release.preview(self.root))
        commit(self.root, {".changes/n.md": NOTE})
        self.assertEqual(release.preview(self.root), "8.15.0")


class ReferenceBuildTests(unittest.TestCase):
    def test_build_writes_nothing(self):
        script = os.path.join(HERE, "components_reference.py")
        markdown = os.path.join(HERE, "..", "..", "docs", "components.md")
        before = os.stat(markdown).st_mtime_ns
        result = subprocess.run([sys.executable, script, "build"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("builds", result.stdout)
        self.assertEqual(os.stat(markdown).st_mtime_ns, before)

    def test_cli_next_without_notes(self):
        result = subprocess.run([sys.executable, os.path.join(HERE, "release.py"), "next"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith(("No release note", "Merging this would release")))


if __name__ == "__main__":
    unittest.main()
