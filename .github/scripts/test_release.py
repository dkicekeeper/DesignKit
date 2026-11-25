#!/usr/bin/env python3
"""Tests of .github/scripts/release.py: release notes in .changes/, the version a merge gets, the
CHANGELOG section, the vNext token, the branch check and the release bot (docs/releasing.md).
Run: python3 .github/scripts/test_release.py (CI's Changelog job runs it)."""

import contextlib
import io
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

    def test_combine_keeps_paragraphs_apart(self):
        prose = lambda text: release.parse_fragment(  # noqa: E731
            f"---\nbump: patch\n---\nIntro.\n\n### Migration\n\n{text}\n")
        c = release.combine([prose("Nothing to change."), prose("Rename the call."), prose("- An item.")])
        self.assertEqual(c.sections["Migration"], ["Nothing to change.", "", "Rename the call.", "", "- An item."])
        items = release.combine([prose("- One."), prose("- Two.")])
        self.assertEqual(items.sections["Migration"], ["- One.", "- Two."])

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

    def test_check_nested_note(self):
        commit(self.root, {".changes/sub/x.md": NOTE, "Sources/A.swift": 'let a = "vNext"\n'})
        errors, _ = self.check()
        self.assertTrue(any(".changes/sub/x.md" in e for e in errors), errors)

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


class FakeGh:
    """The gh CLI as the bot calls it: records each call; a release's notes are read from its file.
    `published` are the GitHub Releases that exist; `fail` lists call prefixes that fail once."""

    def __init__(self, published=("8.14.0",), fail=()):
        self.calls = []
        self.notes = {}
        self.published = set(published)
        self.fail = list(fail)

    def __call__(self, *args):
        self.calls.append(args)
        for index, prefix in enumerate(self.fail):
            if args[:len(prefix)] == prefix:
                del self.fail[index]
                raise subprocess.CalledProcessError(1, ["gh", *args], output="", stderr="HTTP 403: Resource not accessible by integration")
        if args[:2] == ("release", "view"):
            if args[2] not in self.published:
                raise subprocess.CalledProcessError(1, ["gh", *args], output="", stderr="release not found")
            return ""
        if args[:2] == ("release", "create"):
            with open(args[args.index("--notes-file") + 1], encoding="utf-8") as file:
                self.notes[args[2]] = file.read()
            self.published.add(args[2])
        return ""

    def released(self):
        return [call[2] for call in self.calls if call[:2] == ("release", "create")]


def regenerate(root):
    write(root, "docs/components.md", "# Components\n\nRegenerated.\n")


class BotTests(unittest.TestCase):
    """A bare remote, a developer's clone that merges PRs into main, and the bot's clone."""

    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        base = self.dir.name
        self.remote = os.path.join(base, "remote.git")
        self.dev = os.path.join(base, "dev")
        self.bot = os.path.join(base, "bot")
        os.makedirs(self.dev)
        make_repo(self.dev)
        git(base, "init", "-q", "--bare", "-b", "main", self.remote)
        git(self.dev, "remote", "add", "origin", self.remote)
        git(self.dev, "push", "-q", "origin", "main", "--tags")
        git(base, "clone", "-q", self.remote, self.bot)
        self.gh = FakeGh()

    def tearDown(self):
        self.dir.cleanup()

    def merge_pr(self, number, files):
        git(self.dev, "checkout", "-q", "-b", f"pr-{number}", "main")
        commit(self.dev, files, f"PR {number}")
        git(self.dev, "checkout", "-q", "main")
        git(self.dev, "merge", "-q", "--no-ff", "-m", f"Merge pull request #{number} from o/pr-{number}", f"pr-{number}")
        git(self.dev, "push", "-q", "origin", "main")

    def run_bot(self, regen=regenerate):
        return release.run_release(self.bot, today="2026-11-25", gh=self.gh, regenerate=regen, repo="o/r")

    def remote_file(self, path):
        return git(self.remote, "show", f"main:{path}")

    def remote_tags(self):
        return sorted(git(self.remote, "tag", "--list").split())

    def test_run_one_note(self):
        self.merge_pr(120, {".changes/a.md": NOTE.replace("A share card names its app.", "A card."),
                            "Sources/A.swift": 'let since = "vNext"\n'})
        self.assertEqual(self.run_bot(), "8.15.0")
        self.assertEqual(self.remote_file("VERSION"), "8.15.0\n")
        self.assertTrue(self.remote_file("CHANGELOG.md").startswith(
            "# Changelog\n\nPreamble.\n\n## 8.15.0 - 2026-11-25\n\nA card.\n[#120](https://github.com/o/r/pull/120)\n\n### Added\n"))
        self.assertEqual(self.remote_file("Sources/A.swift"), 'let since = "8.15.0"\n')
        self.assertEqual(self.remote_file("docs/components.md"), "# Components\n\nRegenerated.\n")
        self.assertEqual(git(self.remote, "ls-tree", "--name-only", "main", ".changes/").strip(), "")
        self.assertEqual(git(self.remote, "log", "-1", "--format=%s|%an", "main").strip(), "Release 8.15.0|github-actions[bot]")
        self.assertEqual(git(self.remote, "rev-parse", "8.15.0^{commit}"), git(self.remote, "rev-parse", "main"))
        self.assertEqual(self.gh.released(), ["8.15.0"])
        self.assertIn("A card.", self.gh.notes["8.15.0"])
        self.assertIn("https://github.com/o/r/compare/8.14.0...8.15.0", self.gh.notes["8.15.0"])
        self.assertIn(("workflow", "run", "testflight.yml", "--ref", "8.15.0"), self.gh.calls)

    def test_run_no_note(self):
        self.merge_pr(120, {"Sources/A.swift": "let a = 2\n"})
        self.assertIsNone(self.run_bot())
        self.assertEqual(self.remote_tags(), ["8.14.0"])
        self.assertEqual(self.gh.released(), [])
        self.assertEqual(git(self.remote, "log", "-1", "--format=%s", "main").strip(), "docs: regenerate the component reference")
        self.assertIsNone(self.run_bot())  # nothing to regenerate any more: no new commit
        self.assertEqual(git(self.remote, "log", "-1", "--format=%s", "main").strip(), "docs: regenerate the component reference")
        self.assertEqual(len(git(self.remote, "log", "--format=%s", "main").splitlines()), 4)

    def test_run_two_notes_make_one_release(self):
        self.merge_pr(121, {".changes/b.md": FIX.replace("- A snapshot.", "- The fix's snapshot.")})
        self.merge_pr(122, {".changes/a.md": NOTE})
        self.assertEqual(self.run_bot(), "8.15.0")
        changelog_text = self.remote_file("CHANGELOG.md")
        self.assertIn("A fix.\n\nA share card names its app.\n[#121](https://github.com/o/r/pull/121), [#122](https://github.com/o/r/pull/122)\n", changelog_text)
        self.assertEqual(self.remote_tags(), ["8.14.0", "8.15.0"])
        self.assertEqual(git(self.remote, "ls-tree", "--name-only", "main", ".changes/").strip(), "")
        self.assertLess(changelog_text.index("- The fix's snapshot."), changelog_text.index("- A snapshot."))

    def test_run_leftover_and_note_in_one_run(self):
        section = "## 8.15.0 - 2026-11-25\n\nLeft over.\n\n### Fixed\n\n- X.\n\n"
        release_sha = commit(self.dev, {"VERSION": "8.15.0\n",
                                        "CHANGELOG.md": CHANGELOG.replace("## 8.14.0", section + "## 8.14.0")}, "Release 8.15.0")
        git(self.dev, "push", "-q", "origin", "main")
        self.merge_pr(130, {".changes/a.md": NOTE})
        self.assertEqual(self.run_bot(), "8.16.0")
        self.assertEqual(git(self.remote, "rev-parse", "8.15.0^{commit}").strip(), release_sha)
        self.assertEqual(self.remote_tags(), ["8.14.0", "8.15.0", "8.16.0"])
        self.assertEqual(self.gh.released(), ["8.15.0", "8.16.0"])

    def test_run_refuses_a_token_the_reference_brings_back(self):
        self.merge_pr(120, {".changes/a.md": NOTE})
        before = git(self.remote, "rev-parse", "main")
        with self.assertRaises(release.ReleaseError):
            self.run_bot(regen=lambda root: write(root, "docs/components.md", "Since vNext.\n"))
        self.assertEqual(git(self.remote, "rev-parse", "main"), before)

    def test_run_leaves_untracked_files_alone(self):
        self.merge_pr(120, {".changes/a.md": NOTE})
        write(self.bot, "stray.log", "left by a tool\n")
        self.assertEqual(self.run_bot(), "8.15.0")
        self.assertNotIn("stray.log", git(self.remote, "ls-tree", "--name-only", "main").split())

    def test_run_refuses_major_mismatch(self):
        self.merge_pr(120, {".changes/a.md": NOTE.replace("bump: minor", "bump: major\nversion: 10.0.0")})
        before = git(self.remote, "rev-parse", "main")
        with self.assertRaises(release.ReleaseError):
            self.run_bot()
        self.assertEqual(git(self.remote, "rev-parse", "main"), before)
        self.assertEqual(self.remote_tags(), ["8.14.0"])
        self.assertEqual(self.gh.released(), [])

    def test_run_tags_leftover_version_on_its_commit(self):
        section = "## 8.15.0 - 2026-11-25\n\nLeft over.\n\n### Fixed\n\n- X.\n\n"
        release_sha = commit(self.dev, {"VERSION": "8.15.0\n",
                                        "CHANGELOG.md": CHANGELOG.replace("## 8.14.0", section + "## 8.14.0")}, "Release 8.15.0")
        commit(self.dev, {"README.md": "Later.\n"}, "later")
        git(self.dev, "push", "-q", "origin", "main")
        self.assertIsNone(self.run_bot(regen=lambda root: None))
        self.assertEqual(git(self.remote, "rev-parse", "8.15.0^{commit}").strip(), release_sha)
        self.assertEqual(self.gh.released(), ["8.15.0"])
        self.assertIn("Left over.", self.gh.notes["8.15.0"])
        # A person's commit set VERSION (the old way): its push built TestFlight already.
        self.assertFalse(any(call[:2] == ("workflow", "run") for call in self.gh.calls))

    def test_run_tags_leftover_merge_on_main(self):
        section = "## 8.15.0 - 2026-11-25\n\nThe old way.\n\n### Fixed\n\n- X.\n\n"
        git(self.dev, "checkout", "-q", "-b", "pr-130", "main")
        commit(self.dev, {"VERSION": "8.15.0\n", "CHANGELOG.md": CHANGELOG.replace("## 8.14.0", section + "## 8.14.0")}, "8.15.0")
        git(self.dev, "checkout", "-q", "main")
        commit(self.dev, {"Sources/Other.swift": "let other = 1\n"}, "other")
        git(self.dev, "merge", "-q", "--no-ff", "-m", "Merge pull request #130 from o/pr-130", "pr-130")
        git(self.dev, "push", "-q", "origin", "main")
        self.assertIsNone(self.run_bot(regen=lambda root: None))
        self.assertEqual(git(self.remote, "rev-parse", "8.15.0^{commit}"), git(self.remote, "rev-parse", "main"))

    def test_leftover_below_a_tag_is_refused(self):
        commit(self.dev, {"VERSION": "8.13.5\n"}, "stale")
        git(self.dev, "push", "-q", "origin", "main")
        with self.assertRaises(release.ReleaseError):
            self.run_bot(regen=lambda root: None)
        self.assertEqual(self.remote_tags(), ["8.14.0"])

    def test_leftover_not_a_version_is_refused(self):
        commit(self.dev, {"VERSION": "next\n"}, "garbage")
        git(self.dev, "push", "-q", "origin", "main")
        with self.assertRaises(release.ReleaseError):
            self.run_bot(regen=lambda root: None)
        self.assertEqual(self.remote_tags(), ["8.14.0"])

    def test_rerun_finishes_a_half_published_release(self):
        self.merge_pr(120, {".changes/a.md": NOTE})
        self.gh = FakeGh(fail=[("release", "create")])
        with self.assertRaises(subprocess.CalledProcessError):
            self.run_bot()
        self.assertEqual(self.remote_tags(), ["8.14.0", "8.15.0"])
        self.assertNotIn("8.15.0", self.gh.published)
        self.assertIsNone(self.run_bot())
        self.assertIn("8.15.0", self.gh.published)
        self.assertIn(("workflow", "run", "testflight.yml", "--ref", "8.15.0"), self.gh.calls)

    def test_run_says_why_the_push_was_refused(self):
        self.merge_pr(120, {".changes/a.md": NOTE})
        number = [130]

        def always_race(root):
            regenerate(root)
            number[0] += 1
            self.merge_pr(number[0], {f".changes/n{number[0]}.md": FIX})

        with self.assertRaises(release.ReleaseError) as caught:
            self.run_bot(regen=always_race)
        self.assertIn("rejected", str(caught.exception))

    def run_cli(self, regen=regenerate):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            status = release.run_cli(self.bot, gh=self.gh, regenerate=regen, repo="o/r", today="2026-11-25")
        return status, out.getvalue()

    def test_cli_failure_comments_on_the_pr(self):
        self.merge_pr(120, {".changes/a.md": NOTE})

        def broken(root):
            raise RuntimeError("the generator broke")

        status, out = self.run_cli(regen=broken)
        self.assertEqual(status, 1)
        self.assertIn("the generator broke", out)
        self.assertTrue(any(call[:3] == ("pr", "comment", "120") for call in self.gh.calls), self.gh.calls)

    def test_cli_prints_the_command_error(self):
        self.merge_pr(120, {".changes/a.md": NOTE})
        self.gh = FakeGh(fail=[("release", "create")])
        status, out = self.run_cli()
        self.assertEqual(status, 1)
        self.assertIn("HTTP 403", out)

    def test_run_retries_after_rejected_push(self):
        self.merge_pr(120, {".changes/a.md": NOTE})
        state = {"merged": False}

        def regen_and_race(root):
            regenerate(root)
            if not state["merged"]:
                state["merged"] = True
                self.merge_pr(121, {".changes/b.md": FIX})

        self.assertEqual(self.run_bot(regen=regen_and_race), "8.15.0")
        self.assertIn("[#120](https://github.com/o/r/pull/120), [#121](https://github.com/o/r/pull/121)", self.remote_file("CHANGELOG.md"))
        self.assertEqual(self.remote_tags(), ["8.14.0", "8.15.0"])
        self.assertEqual(self.gh.released(), ["8.15.0"])

    def test_notify_failure(self):
        release.notify_failure(self.gh, [120], "https://github.com/o/r/actions/runs/1")
        call = self.gh.calls[0]
        self.assertEqual(call[:3], ("pr", "comment", "120"))
        self.assertIn("https://github.com/o/r/actions/runs/1", call[call.index("--body") + 1])


if __name__ == "__main__":
    unittest.main()
