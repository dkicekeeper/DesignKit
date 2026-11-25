# Releasing DesignKit: numbers given at merge

Several sessions open release PRs at once. A PR therefore never names its own version: it
declares its release in a note, and after the merge a bot on `main` gives it the next number.
The design and the reasons: [superpowers/specs/2026-11-24-release-on-merge-design.md](superpowers/specs/2026-11-24-release-on-merge-design.md).

## In a PR

1. **Add a note**, `.changes/<name>.md`. The name must be unique: a branch is often reused for
   the next PR, so take the branch without `claude/`, the date and a word on the change
   (`optimistic-bell-2026-11-24-numbers.md`).

   ```markdown
   ---
   bump: minor
   ---
   A line or two on what the release is (the intro of its CHANGELOG section).

   ### Added
   - `ShareCardFrame(brandIcon:)`: …

   ### Gallery and tooling
   - …
   ```

   - `bump`: `patch` (fixes, docs, tooling), `minor` (new API, visual changes) or `major`
     (removals). `### Added` needs `minor` or `major`; `### Removed` needs `major`.
   - The sections and their rules are a CHANGELOG section's (CLAUDE.md, "API Stability &
     Versioning"): `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Migration`,
     `Gallery and tooling`, in that order; English; no em dash; no emoji.
   - No heading and no PR link: the bot writes `## X.Y.Z - YYYY-MM-DD` and links the PR.
   - A PR with no note releases nothing (docs, CI). CI warns when such a PR changes `Sources/` or
     `Gallery/`.

2. **Write vNext where the version goes**: a Gallery page's `since: "vNext"`, "(vNext)" after a
   feature in docs/design-system.md, a doc comment, a deprecation message. The bot replaces
   every bare vNext with the number. `vNext` in backticks is the word itself and stays, so a doc
   can name the token. The bot does not touch `.changes/`, `.github/workflows/` (its token may
   not push them), `.github/scripts/release.py`, its tests, this file and `docs/superpowers/`.

3. **A major names its number.** Its file names carry it (`docs/migration-9.0.md`,
   `scripts/migrations/9.0.0.json`) and so does the short form (`TODO(DesignKit 9.0)`), which the
   token cannot stand for. The note says `bump: major` and `version: 9.0.0`, and the PR writes
   9.0 where it needs it. Minor and patch releases merged meanwhile do not change the next major.
   One major at a time: a second waits for the first.

4. **Leave the bot's files alone**: `VERSION`, the `## X.Y.Z` headings of CHANGELOG.md, and
   docs/components.md and .json (run `python3 .github/scripts/components_reference.py build` to
   see the reference builds; the bot writes it after the merge).

CI's Changelog job checks the branch (`python3 .github/scripts/release.py check --base origin/main`)
and writes into the run's summary what a merge would release now
(`python3 .github/scripts/release.py next`).

## At the merge

`release.yml` runs the bot (`python3 .github/scripts/release.py run`) on every push to `main`,
one run at a time. Starting from the newest `main`, it:

1. tags a `VERSION` left without a tag (a run that stopped after its commit) on the commit that
   set it, with its GitHub Release;
2. with no note, regenerates the component reference, commits it if it changed, and stops;
3. gives the notes the next version: the higher of the latest tag and `VERSION`, raised by the
   highest `bump` (a major must match its note's `version:`);
4. writes the CHANGELOG section (the intro, the PR links, the sections), `VERSION`, replaces the
   token, deletes the notes, regenerates the component reference, and checks the result
   (`changelog.py`'s rules, no bare token left) before it commits;
5. commits `Release X.Y.Z` as `github-actions[bot]` and pushes it; if `main` moved on meanwhile,
   it starts again from the new `main` (the new note joins this release);
6. tags the commit (a tag GitHub refuses right after the commit, "missing necessary objects", is
   pushed again after 5, 15 and 30 seconds), publishes the GitHub Release with the section and the
   compare link, and starts the TestFlight build on the tag.

Notes that meet in one run (quick merges) make one release: the highest bump, their intros and
items in merge order, all their PR links. Their code is in one commit already.

The bot's commit starts no workflow (it pushes with `GITHUB_TOKEN`), so CI does not run on it,
and TestFlight is started by the bot. The merge push that carries a note builds nothing in
TestFlight: its version is not set yet.

## When it fails

A failed run is red in Actions and comments on each PR whose note it holds. Nothing it does
before its commit is pushed. Read the run, fix the cause on `main` by a PR (a broken note, a
major's number), then run **Release** again from Actions: it picks up every note still in
`.changes/`, and tags a `VERSION` an earlier run left untagged.

## Before this

Until November 2026 a PR bumped `VERSION` and wrote its CHANGELOG section itself, and each
session picked a number by looking at the open PRs. A PR opened that way fails the branch check once
this is on `main`: move its section into a note, its number to the token, and restore
`VERSION`, CHANGELOG.md and docs/components.md(.json) to `main`'s.
