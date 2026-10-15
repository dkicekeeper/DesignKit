#!/usr/bin/env python3
"""CHANGELOG.md: what each release changed and how to move an app to it.

  changelog.py check            the file is well formed and has a section for VERSION (CI)
  changelog.py notes VERSION    the version's section as Markdown: the GitHub Release body
  changelog.py plain VERSION    the same as plain text without code: TestFlight's What to Test

A release is a heading `## X.Y.Z - YYYY-MM-DD`, newest first, with `### Added`, `### Changed`,
`### Deprecated`, `### Removed`, `### Fixed`, `### Migration` and `### Gallery and tooling`
sections in that order (CLAUDE.md, "API Stability & Versioning"). The Gallery's Updates screen
parses the same format (Gallery/Gallery/Updates/Changelog.swift).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
RELEASE = re.compile(r"^## (\d+)\.(\d+)\.(\d+) - (\d{4}-\d{2}-\d{2})$")
SECTIONS = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Migration", "Gallery and tooling"]


def releases(text):
    """[(version, date, body lines)] in file order."""
    out = []
    for line in text.splitlines():
        match = RELEASE.match(line)
        if match:
            out.append((".".join(match.group(1, 2, 3)), match.group(4), []))
        elif out:
            out[-1][2].append(line)
    return out


def section(version):
    for name, _, body in releases((ROOT / "CHANGELOG.md").read_text()):
        if name == version:
            return "\n".join(body).strip()
    return None


def check():
    text = (ROOT / "CHANGELOG.md").read_text()
    errors = []
    in_code = False
    for number, line in enumerate(text.splitlines(), 1):
        if line.startswith("```"):
            in_code = not in_code
        elif in_code:
            continue
        elif line.startswith("## ") and not RELEASE.match(line):
            errors.append(f"line {number}: a release heading is `## X.Y.Z - YYYY-MM-DD`: {line!r}")
        elif line.startswith("### ") and line[4:] not in SECTIONS:
            errors.append(f"line {number}: unknown section {line[4:]!r} (one of {', '.join(SECTIONS)})")
        elif line.startswith("#### "):
            errors.append(f"line {number}: no headings below ###")
        elif "—" in line:
            errors.append(f"line {number}: an em dash; use a colon, a comma or two sentences")
        elif any(0x2700 <= ord(c) <= 0x27BF or ord(c) >= 0x1F000 for c in line):
            # App Store Connect refuses them in TestFlight's What to Test (✓ and ✕ did, 5.0.0).
            errors.append(f"line {number}: a dingbat or an emoji, which TestFlight's What to Test refuses; use words")
    if in_code:
        errors.append("a code block is not closed")

    found = releases(text)
    keys = [tuple(int(part) for part in version.split(".")) for version, _, _ in found]
    for (newer, newer_date), (older, older_date) in zip(
        [(v, d) for v, d, _ in found], [(v, d) for v, d, _ in found[1:]]
    ):
        if tuple(map(int, newer.split("."))) <= tuple(map(int, older.split("."))):
            errors.append(f"{newer} is listed above {older}: newest first")
        if newer_date < older_date:
            errors.append(f"{newer} ({newer_date}) is dated before {older} ({older_date})")
    if len(set(keys)) != len(keys):
        errors.append("a version is listed twice")
    for version, _, body in found:
        order = [line[4:] for line in body if line.startswith("### ")]
        if not order:
            errors.append(f"{version} has no section")
        if order != sorted(order, key=SECTIONS.index):
            errors.append(f"{version}: sections go {', '.join(SECTIONS)}")

    version = (ROOT / "VERSION").read_text().strip()
    if not any(name == version for name, _, _ in found):
        errors.append(
            f"no section for VERSION {version}: a release PR adds `## {version} - YYYY-MM-DD` "
            "to CHANGELOG.md"
        )
    elif found[0][0] != version:
        errors.append(f"the newest section is {found[0][0]}, VERSION is {version}")

    for error in errors:
        print(f"::error file=CHANGELOG.md::{error}")
    if errors:
        sys.exit(1)
    print(f"CHANGELOG.md: {len(found)} releases, the newest is {version}")


def plain(text):
    """Markdown to the plain text TestFlight shows: no code, no link targets, no marks."""
    lines, in_code, joins = [], False, False
    for line in text.splitlines():
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        line = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", line)
        line = line.replace("`", "").replace("**", "")
        if line.startswith("### "):
            lines.append(line[4:] + ":")
            joins = False
        elif line.startswith("- "):
            lines.append("• " + line[2:])
            joins = True
        elif not line.strip():
            lines.append("")
            joins = False
        elif joins:
            # The next line of a paragraph or a list item.
            lines[-1] += " " + line.strip()
        else:
            lines.append(line)
            joins = True
    out = re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip()
    # App Store Connect takes up to 4000 characters.
    return out if len(out) <= 3900 else out[:3899].rsplit("\n", 1)[0] + "\n…"


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command == "check":
        check()
    elif command in ("notes", "plain") and len(sys.argv) == 3:
        body = section(sys.argv[2])
        if body is None:
            sys.exit(f"CHANGELOG.md has no section for {sys.argv[2]}")
        print(body if command == "notes" else plain(body))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
