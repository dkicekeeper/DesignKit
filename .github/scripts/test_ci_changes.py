#!/usr/bin/env python3
"""Tests of .github/scripts/ci_changes.py: which changes need CI's macOS jobs, and which runs
leave them to another run. Run: python3 .github/scripts/test_ci_changes.py (CI's Changelog job
runs it)."""

import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ci_changes  # noqa: E402

REPO = {"full_name": "dkicekeeper/DesignKit"}


def pull_request(ref, repo=REPO):
    return {
        "repository": REPO,
        "pull_request": {
            "base": {"sha": "b" * 40},
            "head": {"sha": "a" * 40, "ref": ref, "repo": repo},
        },
    }


class Diff:
    """A stand-in for git_diff: answers with fixed paths and keeps what it was asked."""

    def __init__(self, paths):
        self.paths = paths
        self.calls = []

    def __call__(self, base, head):
        self.calls.append((base, head))
        return self.paths


class NeedsBuildTests(unittest.TestCase):
    def test_what_the_build_reads(self):
        for path in [
            "Sources/DesignComponents/Rows/UniversalRow.swift",
            "Sources/DesignComponents/Resources/Shaders/README.md",
            "Gallery/Gallery/Screens/RowsScreen.swift",
            "Gallery/project.yml",
            "Gallery/SnapshotTests/__Snapshots__/RowsSnapshotTests/row.light.png",
            "Tests/DesignSupportTests/FormattingTests.swift",
            "Shaders/Ripple.metal",
            "Package.swift",
            "CHANGELOG.md",
            "scripts/snapshot-tests.sh",
            ".github/workflows/ci.yml",
            "VERSION",
        ]:
            with self.subTest(path=path):
                self.assertTrue(ci_changes.needs_build(path))

    def test_docs_notes_and_tooling(self):
        for path in [
            "docs/releasing.md",
            "docs/components.json",
            "README.md",
            "CLAUDE.md",
            ".changes/optimistic-bell-2026-11-25-tag.md",
            ".github/scripts/release.py",
            ".github/ISSUE_TEMPLATE/component.yml",
            ".github/workflows/release.yml",
            "scripts/designkit_lint.py",
            "scripts/migrations/8.0.json",
        ]:
            with self.subTest(path=path):
                self.assertFalse(ci_changes.needs_build(path))


class JudgeTests(unittest.TestCase):
    def test_one_swift_file_among_docs_builds(self):
        build, reason = ci_changes.judge(["docs/a.md", "Sources/X.swift"])
        self.assertTrue(build)
        self.assertIn("`Sources/X.swift`", reason)
        self.assertNotIn("docs/a.md", reason)

    def test_docs_only_skips(self):
        self.assertFalse(ci_changes.judge(["docs/a.md", ".changes/b.md"])[0])

    def test_no_change_skips(self):
        self.assertFalse(ci_changes.judge([])[0])

    def test_unknown_changes_build(self):
        self.assertTrue(ci_changes.judge(None)[0])

    def test_long_list_is_cut(self):
        build, reason = ci_changes.judge([f"Sources/{n}.swift" for n in range(12)])
        self.assertTrue(build)
        self.assertIn("and 2 more", reason)


class DecideTests(unittest.TestCase):
    def test_manual_run_builds_without_a_diff(self):
        diff = Diff(["docs/a.md"])
        self.assertTrue(ci_changes.decide("workflow_dispatch", {}, "refs/heads/claude/x", diff)[0])
        self.assertEqual(diff.calls, [])

    def test_pull_request_of_a_claude_branch_leaves_it_to_the_push_run(self):
        diff = Diff(["Sources/X.swift"])
        build, reason = ci_changes.decide("pull_request", pull_request("claude/x"), "refs/pull/1/merge", diff)
        self.assertFalse(build)
        self.assertIn("push run of aaaaaaa", reason)
        self.assertEqual(diff.calls, [])

    def test_pull_request_of_another_branch_reads_its_diff(self):
        diff = Diff(["Sources/X.swift"])
        self.assertTrue(ci_changes.decide("pull_request", pull_request("feature/x"), "refs/pull/1/merge", diff)[0])
        self.assertEqual(diff.calls, [("b" * 40, "a" * 40)])

    def test_pull_request_from_a_fork_reads_its_diff(self):
        diff = Diff(["docs/a.md"])
        fork = pull_request("claude/x", repo={"full_name": "someone/DesignKit"})
        self.assertFalse(ci_changes.decide("pull_request", fork, "refs/pull/1/merge", diff)[0])
        self.assertEqual(len(diff.calls), 1)

    def test_pull_request_from_a_deleted_fork_reads_its_diff(self):
        diff = Diff(["Sources/X.swift"])
        self.assertTrue(ci_changes.decide("pull_request", pull_request("claude/x", repo=None), "refs/pull/1/merge", diff)[0])
        self.assertEqual(len(diff.calls), 1)

    def test_push_to_a_branch_reads_it_against_main(self):
        diff = Diff([".github/scripts/release.py", ".changes/a.md"])
        self.assertFalse(ci_changes.decide("push", {"before": "c" * 40, "after": "d" * 40}, "refs/heads/claude/x", diff)[0])
        self.assertEqual(diff.calls, [("origin/main", "HEAD")])

    def test_push_to_main_reads_the_pushed_commits(self):
        diff = Diff(["Sources/X.swift"])
        self.assertTrue(ci_changes.decide("push", {"before": "c" * 40, "after": "d" * 40}, "refs/heads/main", diff)[0])
        self.assertEqual(diff.calls, [("c" * 40, "d" * 40)])

    def test_a_new_main_builds(self):
        diff = Diff([])
        self.assertTrue(ci_changes.decide("push", {"before": "0" * 40, "after": "d" * 40}, "refs/heads/main", diff)[0])
        self.assertEqual(diff.calls, [])

    def test_a_diff_git_cannot_tell_builds(self):
        self.assertTrue(ci_changes.decide("push", {}, "refs/heads/claude/x", Diff(None))[0])


class GitDiffTests(unittest.TestCase):
    """git_diff against a real repository: a branch's own changes since main, not main's."""

    def git(self, *args):
        subprocess.run(["git", "-C", self.root, *args], check=True, capture_output=True)

    def commit(self, path, text):
        full = os.path.join(self.root, path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w") as file:
            file.write(text)
        self.git("add", path)
        self.git("-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-qm", path)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        self.git("init", "-q", "-b", "main")
        self.commit("Sources/A.swift", "a")
        self.git("switch", "-qc", "branch")
        self.commit("docs/a.md", "doc")
        self.git("switch", "-q", "main")
        self.commit("Sources/B.swift", "b")
        self.git("switch", "-q", "branch")

    def tearDown(self):
        self.tmp.cleanup()

    def test_only_the_branch_changes(self):
        self.assertEqual(ci_changes.git_diff("main", "HEAD", cwd=self.root), ["docs/a.md"])

    def test_an_unknown_base_is_none(self):
        self.assertIsNone(ci_changes.git_diff("no-such-ref", "HEAD", cwd=self.root))


class RunGithubTests(unittest.TestCase):
    def test_writes_the_output_and_the_summary(self):
        with tempfile.TemporaryDirectory() as tmp:
            env = {
                "GITHUB_EVENT_NAME": "pull_request",
                "GITHUB_EVENT_PATH": os.path.join(tmp, "event.json"),
                "GITHUB_REF": "refs/pull/1/merge",
                "GITHUB_OUTPUT": os.path.join(tmp, "output"),
                "GITHUB_STEP_SUMMARY": os.path.join(tmp, "summary"),
            }
            with open(env["GITHUB_EVENT_PATH"], "w") as file:
                json.dump(pull_request("feature/x"), file)
            self.assertFalse(ci_changes.run_github(env, diff=Diff(["docs/a.md"])))
            with open(env["GITHUB_OUTPUT"]) as file:
                self.assertEqual(file.read(), "build=false\n")
            with open(env["GITHUB_STEP_SUMMARY"]) as file:
                self.assertIn("macOS jobs: skipped", file.read())


if __name__ == "__main__":
    unittest.main()
