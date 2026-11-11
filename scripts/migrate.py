#!/usr/bin/env python3
"""Moves an app's code to a new major DesignKit (8.9.0, benchmark round 4: Astryx's
`upgrade --from X --apply`).

Each major has a rules file, scripts/migrations/<X.0.0>.json, written from its
docs/migration-X.0.md:

- "rewrite": a regex and its replacement, for what changes the same way everywhere (a renamed
  skeleton, a removed argument);
- "todo": a regex and a note; the line gets `// TODO(DesignKit X.0): <note>` above it, where a
  person (or an agent) decides (a removed row whose arguments move into an accessory).

Run it from the app's root, dry first:

    python3 <DesignKit>/scripts/migrate.py --from 7.4.0 --to 8.0.0 --source Tenra          # what would change
    python3 <DesignKit>/scripts/migrate.py --from 7.4.0 --to 8.0.0 --source Tenra --apply  # change it

Every major after --from up to --to runs, in order. It prints each file it changes with its
rewrites and TODOs, then the totals. A TODO already above a line is not added twice, so it can
run again. Build, read the TODOs, follow docs/migration-X.0.md for them, and remove them.
"""

import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RULES = os.path.join(HERE, "migrations")
EXCLUDES = ("/.build/", "/DerivedData/", "/Pods/")


def version(text):
    parts = [int(p) for p in text.split(".")]
    return tuple(parts + [0] * (3 - len(parts)))


def majors(start, end):
    """The rules files of the majors after `start` up to `end`, in order."""
    found = []
    for name in os.listdir(RULES):
        if name.endswith(".json"):
            v = version(name[:-5])
            if start < v <= end:
                found.append((v, os.path.join(RULES, name)))
    return [path for _, path in sorted(found)]


def load(path):
    with open(path, encoding="utf-8") as f:
        rules = json.load(f)
    major = os.path.basename(path)[:-5].split(".")[0] + ".0"
    rewrites = [(re.compile(r["pattern"]), r["replace"], r.get("note", "")) for r in rules.get("rewrite", [])]
    todos = [(re.compile(t["pattern"]), t["note"]) for t in rules.get("todo", [])]
    return major, rewrites, todos


def migrate_text(text, major, rewrites, todos):
    """(new text, [rewrite notes], [todo notes])."""
    done, marked = [], []
    for pattern, replace, note in rewrites:
        text, count = pattern.subn(replace, text)
        if count:
            done.append(f"{count} × {note or pattern.pattern}")
    lines = text.split("\n")
    out = []
    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if not stripped.startswith("//"):
            for pattern, note in todos:
                if pattern.search(line):
                    mark = f"// TODO(DesignKit {major}): {note}"
                    if not (out and out[-1].strip() == mark):
                        out.append(line[: len(line) - len(stripped)] + mark)
                        marked.append(f"line {i + 1}: {note}")
        out.append(line)
    return "\n".join(out), done, marked


def swift_files(root, sources):
    for source in sources:
        for dirpath, dirs, files in os.walk(os.path.join(root, source)):
            dirs[:] = sorted(d for d in dirs if not d.startswith("."))
            for name in sorted(files):
                path = os.path.join(dirpath, name)
                rel = os.path.relpath(path, root).replace(os.sep, "/")
                if name.endswith(".swift") and not any(x in "/" + rel for x in EXCLUDES):
                    yield rel, path


def main(argv):
    parser = argparse.ArgumentParser(description="Move an app's code to a new major DesignKit.")
    parser.add_argument("--from", dest="start", required=True, help="the DesignKit version the app is on")
    parser.add_argument("--to", dest="end", required=True, help="the DesignKit version it moves to")
    parser.add_argument("--root", default=os.getcwd(), help="the app's root (default: the current folder)")
    parser.add_argument("--source", action="append", required=True, help="a folder of Swift code (repeatable)")
    parser.add_argument("--apply", action="store_true", help="write the changes (default: only list them)")
    args = parser.parse_args(argv)

    files = majors(version(args.start), version(args.end))
    if not files:
        print(f"No major between {args.start} and {args.end} has migration rules: nothing to do.")
        return 0
    rule_sets = [load(path) for path in files]
    print("Majors: " + ", ".join(major for major, _, _ in rule_sets))

    changed = rewritten = todo_count = 0
    for rel, path in swift_files(os.path.abspath(args.root), args.source):
        with open(path, encoding="utf-8") as f:
            original = f.read()
        text, notes = original, []
        for major, rewrites, todos in rule_sets:
            text, done, marked = migrate_text(text, major, rewrites, todos)
            notes += [f"  rewrite {d}" for d in done] + [f"  TODO {m}" for m in marked]
            rewritten += len(done)
            todo_count += len(marked)
        if text != original:
            changed += 1
            print(rel)
            print("\n".join(notes))
            if args.apply:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(text)
    verb = "Changed" if args.apply else "Would change"
    print(f"{verb} {changed} files: {rewritten} rewrites, {todo_count} TODOs.")
    if not args.apply and changed:
        print("Run again with --apply to write them.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
