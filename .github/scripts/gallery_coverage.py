#!/usr/bin/env python3
"""Which Gallery pages show their code and cases yet (8.22.3).

A component page can show the call that draws its preview as the controls set it
(`ComponentPage(code:)`) and ready data from life (`ComponentPage(cases:)`). The pages of the
components every app uses have them; the others get them when they are next touched. This lists
the pages without them, the most used first, in CI's run summary. It never fails a build.

    python3 .github/scripts/gallery_coverage.py            # the summary, on standard output
    python3 .github/scripts/gallery_coverage.py --strict   # fails when a page of all three apps has no code
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from components_reference import SCREENS, STRING, closing, screen_order  # noqa: E402


def pages():
    """(name, section, number of apps, has code, has cases) of every ComponentPage."""
    result = []
    files = {f[:-6]: os.path.join(SCREENS, f) for f in os.listdir(SCREENS) if f.endswith(".swift")}
    for screen in screen_order():
        path = files.get(screen)
        if not path:
            continue
        text = open(path, encoding="utf-8").read()
        title = re.search(r'static let title = "([^"]+)"', text)
        section = title.group(1) if title else screen
        for match in re.finditer(r'ComponentPage\(\s*name: ' + STRING, text):
            start = match.start() + len("ComponentPage")
            head = text[start:closing(text, start, "(", ")")]
            # The arguments without their string literals, so a note that says "code:" is not one.
            bare = re.sub(STRING, '""', head)
            apps = re.search(r"apps: \[([^\]]*)\]", bare)
            count = len(set(re.findall(r"\.(tenra|dalada|platina)\b", apps.group(1)))) if apps else 0
            result.append((match.group(1), section, count,
                           re.search(r"\bcode:\s", bare) is not None,
                           re.search(r"\bcases:\s", bare) is not None))
    return result


def summary(items):
    with_code = [p for p in items if p[3]]
    with_cases = [p for p in items if p[4]]
    missing = sorted((p for p in items if not p[3]), key=lambda p: (-p[2], p[1], p[0]))
    lines = [
        "### Gallery pages with code and cases",
        "",
        f"{len(with_code)} of {len(items)} pages show their code, {len(with_cases)} their cases.",
        "",
    ]
    if missing:
        lines.append("Pages without code, the most used first (the apps that use the component):")
        lines.append("")
        for name, section, count, _, _ in missing:
            lines.append(f"- `{name}` ({section}, {count} app{'s' if count != 1 else ''})")
    return "\n".join(lines) + "\n"


def main(argv):
    items = pages()
    text = summary(items)
    print(text)
    target = os.environ.get("GITHUB_STEP_SUMMARY")
    if target:
        with open(target, "a", encoding="utf-8") as handle:
            handle.write(text)
    if "--strict" in argv:
        bare = [p[0] for p in items if p[2] == 3 and not p[3]]
        if bare:
            for name in bare:
                print(f"::error::The page of {name}, which all three apps use, shows no code (ComponentPage(code:)).")
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
