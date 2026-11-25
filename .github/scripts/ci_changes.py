#!/usr/bin/env python3
"""Whether a CI run needs its macOS jobs (CI's `What to build` job).

The macOS jobs (Package + Gallery, Package on Xcode 27, Snapshot tests, and Dalada, Tenra and
Platina against this DesignKit) build Swift. The account runs only a few macOS jobs at a time,
and DesignKit, Tenra, Dalada and Platina share them, so a run that cannot change what they build
skips them:

- a change of docs, release notes and tooling only (`needs_build` below);
- the pull_request run of a claude/** branch of this repository: the push run of the same
  commit builds it.

A manual run builds everything (it can record snapshots and take the apps' branches). A path this
file does not know needs the build, so a new kind of file builds until it is listed here.

    python3 .github/scripts/ci_changes.py github          # in CI: reads the event, writes build=true|false
    python3 .github/scripts/ci_changes.py diff [BASE]     # this checkout against BASE (origin/main)
    python3 .github/scripts/ci_changes.py files PATH...   # what a list of changed paths needs
"""

import json
import os
import subprocess
import sys

# Folders the build reads. Every file in them counts, Markdown too (a bundle's README).
BUILD_DIRS = ("Sources/", "Gallery/", "Tests/", "Shaders/")
# Files outside those folders that a macOS job reads: the Gallery bundles CHANGELOG.md (its
# Updates screen, ChangelogTests), the snapshot job runs the script, and CI itself.
BUILD_FILES = ("CHANGELOG.md", "Package.swift", "scripts/snapshot-tests.sh", ".github/workflows/ci.yml")
# Folders no macOS job reads: docs, release notes, the Python tooling (tested on Linux in the
# Changelog job), the issue forms and the other workflows.
NO_BUILD_DIRS = ("docs/", ".changes/", ".github/scripts/", ".github/ISSUE_TEMPLATE/", ".github/workflows/", "scripts/")

PR_PUSHED_BRANCHES = "claude/"


def needs_build(path):
    """True when a change of `path` can change what a macOS job builds or tests."""
    if path in BUILD_FILES or path.startswith(BUILD_DIRS):
        return True
    if path.startswith(NO_BUILD_DIRS):
        return False
    # Markdown elsewhere (README.md, CLAUDE.md) is read by people.
    return not path.endswith(".md")


def judge(paths):
    """(build, reason) for a list of changed paths; None means they could not be listed."""
    if paths is None:
        return True, "Could not list the changed files, so everything builds."
    build = [path for path in paths if needs_build(path)]
    if build:
        shown = ", ".join(f"`{path}`" for path in build[:10])
        more = f" and {len(build) - 10} more" if len(build) > 10 else ""
        return True, f"{len(build)} changed file(s) reach the build: {shown}{more}."
    if not paths:
        return False, "No file changed."
    return False, f"Only docs, release notes and tooling changed ({len(paths)} file(s)): the macOS jobs are skipped."


def decide(event_name, event, ref, diff):
    """(build, reason) for a run. `diff(base, head)` lists the paths changed on head since its
    merge base with base, or returns None."""
    if event_name == "workflow_dispatch":
        return True, "A manual run builds everything."
    if event_name == "pull_request":
        pr = event["pull_request"]
        head = pr["head"]
        same_repo = (head.get("repo") or {}).get("full_name") == event["repository"]["full_name"]
        if same_repo and head["ref"].startswith(PR_PUSHED_BRANCHES):
            return False, (f"The push run of {head['sha'][:7]} on `{head['ref']}` builds it: "
                           "this pull_request run skips the macOS jobs.")
        return judge(diff(pr["base"]["sha"], head["sha"]))
    if event_name == "push":
        if ref == "refs/heads/main":
            before = event.get("before") or ""
            if not before.strip("0"):
                return True, "A new main: everything builds."
            return judge(diff(before, event["after"]))
        return judge(diff("origin/main", "HEAD"))
    return True, f"A {event_name} run builds everything."


def git_diff(base, head, cwd=None):
    """The paths changed on head since its merge base with base, or None when git cannot tell."""
    result = subprocess.run(["git", "diff", "--name-only", "--no-renames", f"{base}...{head}"],
                            cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        return None
    return [line for line in result.stdout.splitlines() if line]


def run_github(env, diff=git_diff):
    """CI's step: decides from the event and writes `build` to GITHUB_OUTPUT and the reason to
    the step summary. Returns the decision."""
    with open(env["GITHUB_EVENT_PATH"]) as file:
        event = json.load(file)
    build, reason = decide(env["GITHUB_EVENT_NAME"], event, env.get("GITHUB_REF", ""), diff)
    with open(env["GITHUB_OUTPUT"], "a") as file:
        file.write(f"build={'true' if build else 'false'}\n")
    if env.get("GITHUB_STEP_SUMMARY"):
        with open(env["GITHUB_STEP_SUMMARY"], "a") as file:
            file.write(f"**macOS jobs: {'run' if build else 'skipped'}.** {reason}\n")
    print(f"build={'true' if build else 'false'}: {reason}")
    return build


def main(argv):
    if len(argv) >= 2 and argv[1] == "github":
        run_github(os.environ)
        return 0
    if len(argv) >= 2 and argv[1] == "diff":
        build, reason = judge(git_diff(argv[2] if len(argv) > 2 else "origin/main", "HEAD"))
    elif len(argv) >= 3 and argv[1] == "files":
        build, reason = judge(argv[2:])
    else:
        print(__doc__.strip())
        return 2
    print(f"build={'true' if build else 'false'}: {reason}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
