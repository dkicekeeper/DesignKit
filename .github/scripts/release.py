#!/usr/bin/env python3
"""DesignKit's releases are numbered at merge (docs/releasing.md).

A PR declares its release in a note, .changes/<name>.md: front matter with `bump: patch | minor |
major` (and `version: X.0.0` for a major), an intro, then the CHANGELOG sections. Where it would
name its version it writes the bare token vNext. After the merge the release bot on main (this
script's `run`, release.yml) gives the notes the next number, writes VERSION, CHANGELOG.md and
the component reference, replaces the token, tags the commit, publishes the GitHub Release and
starts TestFlight.

    release.py check --base REF   the branch's notes and edits, against REF (CI on a branch)
    release.py next               the version the notes now in .changes/ would get
    release.py run [--no-dispatch]  the release bot (release.yml)
"""

import dataclasses
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import changelog  # noqa: E402

TOKEN = "vNext"
NOTES_DIR = ".changes"
BUMPS = ("patch", "minor", "major")
SECTIONS = changelog.SECTIONS
VERSION_TEXT = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
# The bare token: no backtick right before or after it (`vNext` in backticks is the word itself,
# as docs about the mechanism write it), not part of a longer word.
BARE_TOKEN = re.compile(r"(?<![`\w])vNext(?![`\w])")
# What the bot never rewrites: the notes (it deletes them), workflows (GITHUB_TOKEN may not push
# them), itself, its tests, and the documents that describe the token.
SKIPPED = (".changes/", ".github/workflows/", ".github/scripts/release.py",
           ".github/scripts/test_release.py", "docs/releasing.md", "docs/superpowers/")


class FragmentError(ValueError):
    """A note that cannot be read at all."""


@dataclasses.dataclass
class Fragment:
    path: str
    bump: str
    version: tuple | None
    intro: str
    sections: dict


def parse_version(text):
    match = VERSION_TEXT.match(text.strip())
    if not match:
        raise ValueError(f"not a version X.Y.Z: {text.strip()!r}")
    return tuple(int(part) for part in match.groups())


def format_version(version):
    return ".".join(str(part) for part in version)


def _trimmed(lines):
    while lines and not lines[0].strip():
        lines = lines[1:]
    while lines and not lines[-1].strip():
        lines = lines[:-1]
    return lines


def parse_fragment(text, path=""):
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise FragmentError(f"{path}: a note starts with front matter between --- lines")
    try:
        end = lines.index("---", 1)
    except ValueError:
        raise FragmentError(f"{path}: the front matter is not closed with ---") from None
    fields = {}
    for line in lines[1:end]:
        if not line.strip():
            continue
        key, sep, value = line.partition(":")
        key = key.strip()
        if not sep or key not in ("bump", "version"):
            raise FragmentError(f"{path}: unknown front matter line {line!r} (bump, version)")
        fields[key] = value.strip()
    version = None
    if "version" in fields:
        try:
            version = parse_version(fields["version"])
        except ValueError as error:
            raise FragmentError(f"{path}: {error}") from None
    intro, sections, current = [], {}, None
    for line in lines[end + 1:]:
        if line.startswith("### "):
            current = line[4:].strip()
            sections.setdefault(current, [])
        elif current is None:
            intro.append(line)
        else:
            sections[current].append(line)
    return Fragment(
        path=path,
        bump=fields.get("bump", ""),
        version=version,
        intro="\n".join(_trimmed(intro)),
        sections={name: _trimmed(body) for name, body in sections.items()},
    )


def fragment_problems(fragment):
    path, problems = fragment.path, []
    if fragment.bump not in BUMPS:
        problems.append(f"{path}: bump is {fragment.bump!r}, one of {', '.join(BUMPS)}")
    if fragment.version is not None and fragment.bump != "major":
        problems.append(f"{path}: version: is only for bump: major (a major names its number)")
    if fragment.bump == "major" and fragment.version is None:
        problems.append(f"{path}: a major names its number: version: X.0.0")
    if fragment.version is not None and fragment.version[1:] != (0, 0):
        problems.append(f"{path}: a major's version is X.0.0, not {format_version(fragment.version)}")
    if not fragment.intro.strip():
        problems.append(f"{path}: a line or two on what the release is goes before the sections")
    names = list(fragment.sections)
    for name in names:
        if name not in SECTIONS:
            problems.append(f"{path}: unknown section {name!r} (one of {', '.join(SECTIONS)})")
    known = [name for name in names if name in SECTIONS]
    if known != sorted(known, key=SECTIONS.index):
        problems.append(f"{path}: sections go in the order {', '.join(SECTIONS)}")
    if not names:
        problems.append(f"{path}: no section (### Added, ### Fixed, …)")
    if "Added" in names and fragment.bump == "patch":
        problems.append(f"{path}: ### Added is new API: bump: minor (or major), not patch")
    if "Removed" in names and fragment.bump != "major":
        problems.append(f"{path}: ### Removed is only for bump: major")
    in_code = False
    body = [fragment.intro] + [line for lines in fragment.sections.values() for line in lines]
    for line in "\n".join(body).splitlines():
        if line.startswith("```"):
            in_code = not in_code
        elif not in_code:
            if line.startswith("#### "):
                problems.append(f"{path}: no headings below ###")
            elif line.startswith("## "):
                problems.append(f"{path}: the bot writes the ## heading; a note starts at its intro")
            elif changelog.line_problem(line):
                problems.append(f"{path}: {changelog.line_problem(line)}")
    if in_code:
        problems.append(f"{path}: a code block is not closed")
    return problems


def note_problems(text, path):
    try:
        return fragment_problems(parse_fragment(text, path))
    except FragmentError as error:
        return [str(error)]


def base_version(tags, version_file):
    """The higher of the latest X.Y.Z tag and VERSION: what the next release counts from."""
    known = [parse_version(tag) for tag in tags if VERSION_TEXT.match(tag.strip())]
    return max(known + [parse_version(version_file)])


def next_version(base, bump):
    major, minor, patch = base
    if bump == "major":
        return (major + 1, 0, 0)
    if bump == "minor":
        return (major, minor + 1, 0)
    if bump == "patch":
        return (major, minor, patch + 1)
    raise ValueError(f"bump is {bump!r}, one of {', '.join(BUMPS)}")


def combine(fragments):
    """One release from several notes (quick merges): the highest bump, the intros and each
    section's items in the notes' order."""
    bump = max((f.bump for f in fragments), key=BUMPS.index)
    versions = [f.version for f in fragments if f.version is not None]
    sections = {}
    for name in SECTIONS:
        lines = []
        for fragment in fragments:
            lines += fragment.sections.get(name, [])
        if lines:
            sections[name] = lines
    return Fragment(
        path=", ".join(f.path for f in fragments),
        bump=bump,
        version=max(versions) if versions else None,
        intro="\n\n".join(f.intro for f in fragments if f.intro),
        sections=sections,
    )


def release_date(today, changelog_text):
    """Today, but never before the section the new one goes above (changelog.py checks it)."""
    found = changelog.releases(changelog_text)
    return max(today, found[0][1]) if found else today


def render_section(version, date, fragment, prs, repo):
    lines = [f"## {version} - {date}", "", fragment.intro]
    if prs:
        lines.append(", ".join(f"[#{n}](https://github.com/{repo}/pull/{n})" for n in prs))
    for name, body in fragment.sections.items():
        lines += ["", f"### {name}", ""] + body
    return "\n".join(lines) + "\n"


def insert_section(changelog_text, section):
    """The new section goes above the first release, after the preamble."""
    match = re.search(r"^## ", changelog_text, re.M)
    if not match:
        return changelog_text.rstrip("\n") + "\n\n" + section
    return changelog_text[:match.start()] + section + "\n" + changelog_text[match.start():]


def replace_token(text, version):
    return BARE_TOKEN.subn(version, text)


def has_bare_token(text):
    return BARE_TOKEN.search(text) is not None


def is_skipped(path):
    path = path.replace(os.sep, "/")
    return any(path == entry or (entry.endswith("/") and path.startswith(entry)) for entry in SKIPPED)


def _text_of(full_path):
    """The file's text, or None for a binary file (a NUL in its first 8 KB) or one not UTF-8."""
    with open(full_path, "rb") as file:
        data = file.read()
    if b"\0" in data[:8192]:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return None


def replace_in_tree(root, paths, version):
    """Replaces the bare token in each tracked text file that is not skipped; the changed paths."""
    changed = []
    for path in paths:
        full = os.path.join(root, path)
        if is_skipped(path) or not os.path.isfile(full):
            continue
        text = _text_of(full)
        if text is None:
            continue
        new, count = replace_token(text, version)
        if count:
            with open(full, "w", encoding="utf-8", newline="") as file:
                file.write(new)
            changed.append(path)
    return changed
