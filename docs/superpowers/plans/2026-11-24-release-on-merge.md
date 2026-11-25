# Release Numbers Given at Merge: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A PR declares its release in `.changes/<name>.md` and writes `vNext` where it would name its version; after the merge a bot on `main` gives it the next number, writes `VERSION`, CHANGELOG.md and docs/components.md(.json), tags it, publishes the GitHub Release and starts the TestFlight build.

**Architecture:** One stdlib Python module, `.github/scripts/release.py`, holds every rule (fragment format, version math, CHANGELOG section, token replacement, the PR check, the bot run) with a CLI `check` / `next` / `run`; `changelog.py` and `components_reference.py` give it what it reuses. Workflows only call it: CI's Changelog job runs `check` and `next` on branches, `release.yml` runs `run` on every push to `main`, `testflight.yml` skips the merge push that carries a note and recognises a release build by its tag.

**Tech Stack:** Python 3 standard library (`unittest`, `subprocess`, `re`, `dataclasses`), git, the `gh` CLI in GitHub Actions, GitHub Actions YAML.

**Spec:** `docs/superpowers/specs/2026-11-24-release-on-merge-design.md` (approved by the owner, in Russian). Read it with this plan.

## Global Constraints

- Python 3 standard library only (CI runs `python3` on `ubuntu-latest` with no `pip install`), like the other scripts in `.github/scripts/` and `scripts/`.
- A note is `.changes/<name>.md`: front matter between `---` lines with `bump: patch | minor | major`, and `version: X.0.0` only with `bump: major`; then an intro paragraph; then `### ` sections from `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Migration`, `Gallery and tooling`, in that order; English; no em dash `—`; no dingbat or emoji (the ranges `changelog.py` refuses); items one level of `- `.
- `### Added` with `bump: patch` is an error; `### Removed` without `bump: major` is an error.
- The token is `vNext`. Bare `vNext` (no backtick right before or after it, not part of a longer word) is replaced; `` `vNext` `` stays.
- Token replacement skips `.changes/`, `.github/workflows/`, `.github/scripts/release.py`, `.github/scripts/test_release.py`, `docs/releasing.md`, `docs/superpowers/`, and binary files.
- Version base = the higher of the latest `X.Y.Z` tag (ordered as `sort -V` orders them) and `VERSION`; `patch` → Z+1, `minor` → Y+1 and Z=0, `major` → X+1.0.0; the new version must be greater than the latest tag; a major must equal its note's `version:`.
- CHANGELOG section: `## X.Y.Z - YYYY-MM-DD`, the intro, a line of PR links `[#N](https://github.com/<owner>/<repo>/pull/N)` joined by `, `, then the sections. Date = today in UTC, never before the date of the section under it.
- Bot commit: author `github-actions[bot]` `<41898282+github-actions[bot]@users.noreply.github.com>`, message `Release X.Y.Z` (or `docs: regenerate the component reference` with no release); it never touches `.github/workflows/`.
- Every existing check keeps passing on `main`: `changelog.py check`, `scripts/test_designkit_lint.py`, `scripts/test_migrate.py`, `gallery_badges.py check`.
- No model identifiers in commit messages or files.

## Review Focus

- A run that finds `VERSION` untagged because an earlier run pushed `Release X.Y.Z` and then failed: it tags the commit that set `VERSION`, not `HEAD`, and only then cuts a release for any new note. Test: `test_run_tags_leftover_version_on_its_commit` (Task 5).
- The bot's push refused because a PR was merged between its fetch and its push: it starts again from the new `main`, the new note joins this release, and no tag or release is made twice. Test: `test_run_retries_after_rejected_push` (Task 5).
- Two notes on `main` at once (quick merges, a cancelled waiting run): one release, the higher bump, both intros, both PR links, items in merge order. Tests: `test_combine_two_notes` (Task 2), `test_run_two_notes_make_one_release` (Task 5).
- `vNext` in a Swift string, in prose, in parentheses, in a code span, inside a word: only the bare token is replaced. Test: `test_replace_token_cases` (Task 3).
- A major whose `version:` is not the computed number: the run fails before it commits, nothing is pushed or tagged. Test: `test_run_refuses_major_mismatch` (Task 5).

---

### Task 1: Notes: parse and validate

**Files:**
- Modify: `.github/scripts/changelog.py` (extract the per-line text rules from `check()`)
- Create: `.github/scripts/release.py`
- Create: `.github/scripts/test_release.py`

**Interfaces:**
- Consumes: `changelog.SECTIONS`, `changelog.RELEASE`, `changelog.releases(text)` (existing).
- Produces:
  - `changelog.line_problem(line: str) -> str | None`: the em dash or dingbat/emoji message for a line outside code, `None` when fine; `check()` uses it, messages unchanged.
  - `release.Fragment` dataclass: `path: str`, `bump: str`, `version: tuple[int, int, int] | None`, `intro: str`, `sections: dict[str, list[str]]` (section name → its body lines as written, blank edge lines trimmed).
  - `release.FragmentError(ValueError)`.
  - `release.parse_fragment(text: str, path: str = "") -> Fragment`: raises `FragmentError` with no front matter, an unknown key, or a line before the front matter.
  - `release.fragment_problems(fragment: Fragment) -> list[str]`: every rule of Global Constraints about notes; messages start with the note's path.
  - `release.note_problems(text: str, path: str) -> list[str]`: parse and check in one call; a `FragmentError` becomes a problem line instead of an exception (the branch check uses this).
  - `release.parse_version(text: str) -> tuple[int, int, int]`, `release.format_version(v: tuple) -> str`.
  - Constants: `TOKEN = "vNext"`, `NOTES_DIR = ".changes"`, `BUMPS = ("patch", "minor", "major")`.

- [ ] **Step 1: Write the failing tests** in `test_release.py` (a `unittest` file run as `python3 .github/scripts/test_release.py`, importing `release` from its own folder as `scripts/test_migrate.py` does):

```python
NOTE = """---
bump: minor
---
A share card names its app.

### Added
- `ShareCardFrame(brandIcon:)`.

### Gallery and tooling
- A snapshot.
"""

def test_parse_note(self):
    f = release.parse_fragment(NOTE, ".changes/a.md")
    self.assertEqual(f.bump, "minor")
    self.assertIsNone(f.version)
    self.assertEqual(f.intro, "A share card names its app.")
    self.assertEqual(list(f.sections), ["Added", "Gallery and tooling"])
    self.assertEqual(f.sections["Added"], ["- `ShareCardFrame(brandIcon:)`."])
    self.assertEqual(release.fragment_problems(f), [])

OUT_OF_ORDER = """---
bump: minor
---
Text.

### Gallery and tooling
- A snapshot.

### Added
- A view.
"""

def test_note_rules(self):
    bad = lambda text: release.note_problems(text, ".changes/x.md")
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
```

- [ ] **Step 2: Run, expect failure**

Run: `python3 .github/scripts/test_release.py`
Expected: `ModuleNotFoundError: No module named 'release'` (or `AttributeError` for `line_problem`).

- [ ] **Step 3: Implement** `changelog.line_problem` (move the two `elif` text rules out of `check()`, which then calls it) and in `release.py` the `Fragment`, `parse_fragment`, `fragment_problems`, `parse_version`, `format_version`. Front matter is plain `key: value` lines; no YAML library.

- [ ] **Step 4: Run, expect pass**

Run: `python3 .github/scripts/test_release.py && python3 .github/scripts/changelog.py check`
Expected: `OK`, then `CHANGELOG.md: 94 releases, the newest is 8.14.0` (or whatever `main` has).

- [ ] **Step 5: Commit** `release.py`, `test_release.py`, `changelog.py`: `Release notes: parse and check .changes notes`.

### Task 2: Version, combined note and CHANGELOG section

**Files:**
- Modify: `.github/scripts/release.py`, `.github/scripts/test_release.py`

**Interfaces:**
- Consumes: Task 1's `Fragment`, `parse_version`, `format_version`; `changelog.releases`.
- Produces:
  - `release.base_version(tags: list[str], version_file: str) -> tuple[int, int, int]`: ignores tags that are not `X.Y.Z`.
  - `release.next_version(base: tuple, bump: str) -> tuple[int, int, int]`.
  - `release.combine(fragments: list[Fragment]) -> Fragment`: highest bump; `version` of the major (if any); intros joined by a blank line; each section's lines concatenated in the given order; sections in `SECTIONS` order; `path` = the paths joined by `, `.
  - `release.release_date(today: str, changelog: str) -> str`: `max(today, date of the first section)`.
  - `release.render_section(version: str, date: str, fragment: Fragment, prs: list[int], repo: str) -> str`: the section text ending in one newline; no PR line when `prs` is empty.
  - `release.insert_section(changelog: str, section: str) -> str`: before the first `## ` line, one blank line after it.

- [ ] **Step 1: Write the failing tests**

```python
def test_versions(self):
    self.assertEqual(release.base_version(["8.13.0", "8.9.0", "8.14.0", "x"], "8.12.0\n"), (8, 14, 0))
    self.assertEqual(release.base_version(["8.14.0"], "8.16.1\n"), (8, 16, 1))
    self.assertEqual(release.next_version((8, 16, 1), "patch"), (8, 16, 2))
    self.assertEqual(release.next_version((8, 16, 1), "minor"), (8, 17, 0))
    self.assertEqual(release.next_version((8, 16, 1), "major"), (9, 0, 0))

FIX = """---
bump: patch
---
A fix.

### Fixed
- A fix.

### Gallery and tooling
- A snapshot.
"""

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
    section = release.render_section("8.15.0", "2026-11-24", release.parse_fragment(NOTE), [109, 110], "dkicekeeper/DesignKit")
    self.assertTrue(section.startswith("## 8.15.0 - 2026-11-24\n\nA share card names its app.\n[#109](https://github.com/dkicekeeper/DesignKit/pull/109), [#110](https://github.com/dkicekeeper/DesignKit/pull/110)\n\n### Added\n"))
    out = release.insert_section(head, section)
    self.assertLess(out.index("## 8.15.0"), out.index("## 8.14.0"))
    self.assertTrue(out.startswith("# Changelog\n\nPreamble.\n\n## 8.15.0"))
```

- [ ] **Step 2: Run, expect failure** (`python3 .github/scripts/test_release.py`: `AttributeError: module 'release' has no attribute 'base_version'`).
- [ ] **Step 3: Implement** the six functions.
- [ ] **Step 4: Run, expect pass** (`OK`).
- [ ] **Step 5: Commit**: `Release notes: version, combined notes, CHANGELOG section`.

### Task 3: The `vNext` token

**Files:**
- Modify: `.github/scripts/release.py`, `.github/scripts/test_release.py`

**Interfaces:**
- Produces:
  - `release.replace_token(text: str, version: str) -> tuple[str, int]`: the text with each bare token replaced, and how many.
  - `release.has_bare_token(text: str) -> bool`.
  - `release.is_skipped(path: str) -> bool`: the skip list of Global Constraints (path relative to the repo root, `/` separators).
  - `release.replace_in_tree(root: str, paths: list[str], version: str) -> list[str]`: rewrites each non-skipped text file (a file whose first 8 KB contain a NUL byte is binary) with a bare token; returns the changed paths.

- [ ] **Step 1: Write the failing tests**

```python
def test_replace_token_cases(self):
    text = 'since: "vNext"\n(vNext)\nAdded in vNext.\nWrite `vNext` here.\nvNextFoo xvNext\n'
    out, n = release.replace_token(text, "8.15.0")
    self.assertEqual(out, 'since: "8.15.0"\n(8.15.0)\nAdded in 8.15.0.\nWrite `vNext` here.\nvNextFoo xvNext\n')
    self.assertEqual(n, 3)
    self.assertFalse(release.has_bare_token(out))

def test_skip_list(self):
    for path in (".changes/a.md", ".github/workflows/ci.yml", ".github/scripts/release.py",
                 ".github/scripts/test_release.py", "docs/releasing.md", "docs/superpowers/plans/p.md"):
        self.assertTrue(release.is_skipped(path), path)
    for path in ("CLAUDE.md", "Gallery/Gallery/Screens/MediaScreen.swift", "docs/design-system.md"):
        self.assertFalse(release.is_skipped(path), path)

def test_replace_in_tree(self):
    # temp dir: a.swift with since: "vNext", .changes/n.md with bare vNext, b.png with b"\0vNext"
    # → returns ["a.swift"]; .changes/n.md and b.png unchanged
```

- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** with the pattern `(?<![`\w])vNext(?![`\w])`.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit**: `Release notes: the vNext token`.

### Task 4: The branch check in CI

**Files:**
- Modify: `.github/scripts/release.py`, `.github/scripts/test_release.py`, `.github/scripts/components_reference.py`, `.github/workflows/ci.yml` (job `changelog`)

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - `release.check_branch(root: str, base: str) -> tuple[list[str], list[str]]` (errors, warnings), from `git diff --name-status <merge-base(base, HEAD)>..HEAD` and the files at both ends:
    - error: `VERSION` changed; CHANGELOG.md gained a `## X.Y.Z` heading; docs/components.md or .json changed ("the release bot writes it");
    - error: each added or modified note's `fragment_problems`; more than one major note; a major whose `version:` is not `next_version(base_version(tags, VERSION at the base), "major")`;
    - error: an added line with a bare token in a non-skipped file while the branch adds no note;
    - warning: `Sources/` or `Gallery/` changed while the branch adds no note ("no release: add a note if this should ship").
  - `release.preview(root: str) -> str | None`: the version the notes now in `.changes/` would get on merge (`None` with no notes).
  - CLI: `release.py check --base REF` prints `::error::` / `::warning::` lines and exits 1 on any error; `release.py next` prints `Merging this would release X.Y.Z` or `No release note`.
  - `components_reference.py build`: builds both outputs in memory and prints `docs/components.md builds (N components).`; exit 0; writes nothing.

- [ ] **Step 1: Write the failing tests**: a temp git repo (`git init`, a commit with `VERSION` 8.14.0, CHANGELOG.md with `## 8.14.0`, a tag `8.14.0`, a `Sources/A.swift`), then branches:

```python
def test_check_clean_note(self):        # adds .changes/n.md (minor) and since: "vNext" in Sources → ([], [])
def test_check_version_edit(self):      # edits VERSION → an error naming VERSION
def test_check_token_without_note(self):# adds a bare vNext, no note → an error naming vNext
def test_check_reference_edit(self):    # edits docs/components.md → an error naming docs/components.md
def test_check_major_number(self):      # bump: major, version: 10.0.0 → error; version: 9.0.0 → none
def test_check_code_without_note(self): # edits Sources/A.swift only → no errors, one warning
def test_preview(self):                 # with a minor note on the branch → "8.15.0"
```

Each test asserts on the returned lists (`self.assertTrue(any("VERSION" in e for e in errors))` etc.).

- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** `check_branch`, `preview`, the CLI, and `components_reference.py build`.
- [ ] **Step 4: Run, expect pass**; also run `python3 .github/scripts/components_reference.py build` (prints the count, `git status` clean).
- [ ] **Step 5: Wire CI.** In `ci.yml`, job `changelog`: `actions/checkout@v5` with `fetch-depth: 0`; add `python3 .github/scripts/test_release.py` to the test step; replace `components_reference.py check` with `build`; add a step that runs only when `github.ref != 'refs/heads/main'`: `git fetch --no-tags origin main` then `python3 .github/scripts/release.py check --base origin/main` and `python3 .github/scripts/release.py next` (append the second's output to `$GITHUB_STEP_SUMMARY`).
- [ ] **Step 6: Commit**: `Release notes: the branch check in CI`.

### Task 5: The release bot

**Files:**
- Modify: `.github/scripts/release.py`, `.github/scripts/test_release.py`
- Modify: `.github/workflows/release.yml` (rewrite)

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - `release.run_release(root: str, *, today: str, gh: Callable[..., str], regenerate: Callable[[str], None], repo: str, remote: str = "origin", branch: str = "main", attempts: int = 3, dispatch: bool = True) -> str | None`: the version released, or `None`. Git runs as subprocesses in `root`; `gh(*args) -> str` runs the GitHub CLI (tests pass a fake that records calls; `gh api repos/<repo>/commits/<sha>/pulls --jq .[].number` returns PR numbers). Steps, in order, per the spec's "Бот" section:
    1. `git fetch <remote> <branch> --tags`, `git reset --hard <remote>/<branch>`;
    2. if `VERSION` is not a tag: tag the last commit that changed `VERSION` (`git log -1 --format=%H -- VERSION`), push the tag, `gh release create` with `changelog.py notes` text plus the compare link (as `release.yml` writes it today);
    3. notes = `.changes/*.md` sorted by the time the commit that added each one landed (`git log --diff-filter=A --format=%ct -1 -- <path>`); no notes → `regenerate(root)`, commit and push `docs: regenerate the component reference` if anything changed, return `None`;
    4. combine; version = `next_version(base_version(tags, VERSION), bump)`; a major must equal its `version:`; the version must be greater than every tag;
    5. PRs = for each note, the PR of the commit that added it (`gh api …/pulls`), unique, ascending;
    6. write the CHANGELOG section (`release_date`, `render_section`, `insert_section`), `VERSION`, `replace_in_tree` over `git ls-files`, delete the notes, `regenerate(root)`;
    7. `changelog.py check` must pass and no tracked non-skipped file may keep a bare token, else raise before committing;
    8. commit `Release X.Y.Z` as the bot, `git push <remote> HEAD:<branch>`; on a refused push, start again at step 1 (up to `attempts`), then raise;
    9. tag `X.Y.Z` on that commit, push the tag, `gh release create X.Y.Z --verify-tag --title "DesignKit X.Y.Z" --notes-file …`;
    10. if `dispatch`: `gh workflow run testflight.yml --ref X.Y.Z`.
  - `release.notify_failure(gh, prs: list[int], run_url: str) -> None`: one `gh pr comment N --body …` per PR whose note did not ship: what failed is in the run, and `release.yml` can be run again by hand.
  - CLI: `release.py run [--no-dispatch]`: `today` from UTC, `repo` from `GITHUB_REPOSITORY`, `gh` = subprocess `gh`, `regenerate` = `python3 .github/scripts/components_reference.py write`; on an exception, `notify_failure` for the pending notes' PRs with `$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID`, then exit 1.

- [ ] **Step 1: Write the failing tests** on a temp bare remote with a clone (`main` at a commit with `VERSION` 8.14.0, tag `8.14.0`, CHANGELOG.md, `Sources/A.swift`), a recording fake `gh`, `regenerate` writing `docs/components.md` from the file count:

```python
def test_run_one_note(self):
    # main gets .changes/n.md (minor, "A card.") and since: "vNext" in Sources/A.swift; fake gh says PR 120
    v = release.run_release(clone, today="2026-11-25", gh=fake, regenerate=regen, repo="o/r", dispatch=True)
    self.assertEqual(v, "8.15.0")
    # remote main: VERSION "8.15.0\n"; CHANGELOG starts "## 8.15.0 - 2026-11-25\n\nA card.\n[#120](https://github.com/o/r/pull/120)"
    # Sources/A.swift has since: "8.15.0"; .changes/ is empty; last commit "Release 8.15.0" by github-actions[bot]
    # remote tag 8.15.0 is that commit; fake recorded "release create 8.15.0" and "workflow run testflight.yml --ref 8.15.0"

def test_run_no_note(self):                       # returns None, no tag, no release; only the reference commit when regen changes it
def test_run_two_notes_make_one_release(self):    # a patch note then a minor note → one "8.15.0", both PR links, notes deleted
def test_run_refuses_major_mismatch(self):        # bump: major, version: 10.0.0 → raises; remote main and tags unchanged
def test_run_tags_leftover_version_on_its_commit(self):
    # remote main: a "Release 8.15.0" commit (VERSION 8.15.0, untagged), then another commit
    # → run tags 8.15.0 on the Release commit (not HEAD), creates its release, returns None
def test_run_retries_after_rejected_push(self):
    # regenerate pushes a new note to the remote from a second clone the first time it is called
    # → the first push is refused; the run returns "8.15.0" with both notes' links; exactly one tag; one "release create"
def test_notify_failure(self):                    # fake records "pr comment 120 --body …" containing the run URL
```

- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** `run_release`, `notify_failure` and the `run` CLI.
- [ ] **Step 4: Run, expect pass** (`python3 .github/scripts/test_release.py` → `OK`).
- [ ] **Step 5: Rewrite `release.yml`**: on `push` to `main` (every path) and `workflow_dispatch`; `permissions: contents: write, pull-requests: write, actions: write`; `concurrency: {group: release, cancel-in-progress: false}`; one job on `ubuntu-latest`: `actions/checkout@v5` with `fetch-depth: 0`, then `python3 .github/scripts/release.py run` with `GH_TOKEN: ${{ github.token }}`. Keep the header comment, rewritten for notes.
- [ ] **Step 6: Commit**: `Release notes: the release bot on main`.

### Task 6: TestFlight follows the bot

**Files:**
- Modify: `.github/workflows/testflight.yml`

**Interfaces:**
- Consumes: Task 5 dispatches `testflight.yml` with `--ref X.Y.Z`.

- [ ] **Step 1:** In job `preflight`, add `actions/checkout@v5` and, for `push` events only, set `ready=false` with the notice `A release note is on this commit: the release bot builds it (release.yml)` when `ls .changes/*.md` matches anything.
- [ ] **Step 2:** In job `whats-new`, a release build is one where `git tag --points-at HEAD` lists `$VERSION` (in place of `git diff --quiet HEAD^ HEAD -- VERSION`).
- [ ] **Step 3: Verify** the YAML parses: `python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" .github/workflows/testflight.yml` (PyYAML is in the dev container; CI does not need it). Do the same for `release.yml` and `ci.yml`. The workflow itself first runs on the merge of this PR (Task 7, step 5).
- [ ] **Step 4: Commit**: `TestFlight: the release bot starts the release build`.

### Task 7: Docs, this PR's own note, and the switch

**Files:**
- Create: `docs/releasing.md`
- Create: `.changes/release-on-merge-2026-11-24-numbers.md`
- Modify: `CLAUDE.md`, `CHANGELOG.md` (the preamble only), `docs/testflight.md`, `docs/gallery-structure.md`, `docs/snapshots.md` (if it tells anyone to write a version)

- [ ] **Step 1: `docs/releasing.md`** (English, like CLAUDE.md): the note (format, unique name, bump rules), `` `vNext` `` and the backtick rule, a major's `version:`, what the bot does on each push to `main`, the skip list, what CI checks on a branch, how to read `release.py next`, and recovery (a red `release.yml` run: read it, fix, run it again by hand from Actions; it tags a leftover `VERSION` first).
- [ ] **Step 2: `CLAUDE.md`**: "Cutting a release" and "A CHANGELOG section" describe the note and the bot (link `docs/releasing.md`), and say a PR never edits `VERSION`, CHANGELOG.md or docs/components.md(.json); "Porting a Component" step 4 drops `components_reference.py write` (run `build` to see it builds) and step 6 puts the component under `### Added` in the PR's note; a page's `since:` is `` `vNext` ``; Package Layout names `.changes/` and `release.py`; one Known Gaps line (date, what changed, the open PRs that went out the old way). Only `` `vNext` `` in backticks anywhere in CLAUDE.md.
- [ ] **Step 3: The rest**: CHANGELOG.md's preamble says the bot writes the sections from notes; docs/testflight.md says the release build comes from the bot and the merge push with a note is skipped; docs/gallery-structure.md says the bot writes the component reference.
- [ ] **Step 4: This PR's note**: `bump: patch`, an intro (release numbers are given at merge), `### Gallery and tooling` items for the note, the bot, the CI check, TestFlight and the docs; and `### Migration`: nothing changes in an app.
- [ ] **Step 5: Verify**: `python3 .github/scripts/test_release.py`, `python3 scripts/test_designkit_lint.py`, `python3 scripts/test_migrate.py`, `python3 .github/scripts/changelog.py check`, `python3 .github/scripts/release.py check --base origin/main` (no errors), `python3 .github/scripts/release.py next` (`Merging this would release …`). Push; CI green. The first real run is this PR's merge, after #105, #109, #110 and #111: read the `Release` run and the TestFlight run it starts.
- [ ] **Step 6: Commit**: `Release notes: docs, and this change's own note`.
