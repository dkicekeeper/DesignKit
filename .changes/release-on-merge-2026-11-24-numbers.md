---
bump: patch
---
Release numbers are given at merge: a PR declares its release in a note in `.changes/` and writes `vNext` where its version goes, and a bot on `main` numbers, writes and tags it. Parallel PRs no longer collide on numbers or conflict over `VERSION`, CHANGELOG.md and docs/components.md. This release is the bot's first.

### Migration

- Nothing changes in an app. A DesignKit PR adds a note in `.changes/` instead of bumping `VERSION` and writing its CHANGELOG section (docs/releasing.md).

### Gallery and tooling

- `.github/scripts/release.py`: the release notes (`.changes/<name>.md`, `bump:` and, for a major, `version:`), the token, the branch check (`release.py check --base origin/main`, in CI's Changelog job, with what a merge would release in the run's summary) and the release bot (`release.py run`), with its tests in `.github/scripts/test_release.py`.
- `release.yml` runs the bot on every push to `main`: the next version, the CHANGELOG section with the PR links, `VERSION`, the token replaced, the component reference regenerated, the commit `Release X.Y.Z`, the tag, the GitHub Release and the TestFlight build on the tag. A `VERSION` left untagged is tagged first; a failed run comments on the PRs it holds up.
- TestFlight skips the merge push that carries a note and takes a release build's What to Test from the tag on it.
- docs/components.md and .json are the bot's: CI checks that they build (`components_reference.py build`), a PR leaves them alone.
- docs/releasing.md, and CLAUDE.md, CHANGELOG.md's preamble, docs/testflight.md and docs/gallery-structure.md on the new way.
