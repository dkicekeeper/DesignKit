#!/usr/bin/env python3
"""The Gallery's app badges against the apps' own code (5.2.0).

Each ComponentPage names the apps that use its component (`apps: [.tenra, .dalada]`). This reads
every page of Gallery/Gallery/Screens, looks for the component's names in each app's Swift
sources, and fails when a badge names an app that does not use the component or misses one that
does, so the badges follow the apps instead of what they used once.

    python3 .github/scripts/gallery_badges.py check --tenra ../Tenra --dalada ../Dalada
    python3 .github/scripts/gallery_badges.py fix   --tenra ../Tenra --dalada ../Dalada

A component's names are the page's name split at " · ", "/" and "," ("Rating · RatingPicker" is
Rating and RatingPicker; ".popIn · .riseIn" two modifiers), without what follows "(" or ":".
A name the apps reach by another one (a modifier over a view, a helper) is in ALIASES. A use is a
whole word outside comments and string literals, in a file that does not declare a type of that name itself (an app's
own view of the same name is not DesignKit's), or the name after its module
(`DesignComponents.StreakCard`, as an app's adapter of the same name calls it).
"""

import argparse
import os
import re
import sys

SCREENS = "Gallery/Gallery/Screens"
APPS = ("tenra", "dalada")

# The code names of a page whose name is not one ("Springs" is AppAnimation's named animations).
REPLACES = {
    "Springs": ["AppAnimation"],
    "Durations": ["AppAnimation.fast", "AppAnimation.standard", "AppAnimation.slow"],
}

# What an app writes for a page whose own name it does not use (or not only).
ALIASES = {
    "SearchSuggestions": [".dsSearchSuggestions", "SearchSuggestionRow", "SearchSuggestionsContent", "RecentSearches"],
    "DateButtons": [".dateButtonsSafeArea"],
    "SkeletonReveal": [".skeletonReveal"],
    "Skeleton primitives": ["Skeleton", "SkeletonText", ".shimmer", ".skeletonLoadingLabel"],
    "Springs by purpose": ["AppAnimation.snappy", "AppAnimation.smooth", "AppAnimation.bouncy", "AppAnimation.expressive", "MotionBudget"],
    "Symbol motion": [".symbolMagicReplace", ".symbolBounce", ".symbolPulse", ".symbolWiggle", ".symbolBreathe", ".symbolDrawOn"],
    "HapticCue": [".hapticCue"],
    "AmountRow: a list of limits": ["AmountRow"],
    "MessageComposer": [".messageComposerAccessory", "MessageComposerAccessory"],
    "HeroBackground": [".heroBackground", ".heroScrollEdge"],
    ".heroBackground": [".heroScrollEdge"],
    "LoadMoreFooter": [".onReachEnd"],
    "ShimmerModifier": [".shimmer"],
}

COMMENT = re.compile(r"//.*")
# String literals, multi-line ones first: a place called "Springs" is not the Springs page.
STRING = re.compile(r'"""[\s\S]*?"""|"(?:[^"\\\n]|\\.)*"')
DECLARATION = r"\b(?:struct|class|enum|protocol|actor|typealias)\s+{name}\b"


def pages(root):
    """(file, name, apps, start, end) of every ComponentPage; start…end spans its apps list."""
    found = []
    directory = os.path.join(root, SCREENS)
    for file in sorted(os.listdir(directory)):
        if not file.endswith(".swift"):
            continue
        path = os.path.join(directory, file)
        text = open(path, encoding="utf-8").read()
        for match in re.finditer(r'ComponentPage\(\s*name: "([^"]+)"', text):
            name = match.group(1)
            # The page's arguments up to its preview closure.
            head_end = text.find(") {", match.end())
            head = text[match.end():head_end]
            apps_match = re.search(r"apps: \[([^\]]*)\]", head)
            apps = set(re.findall(r"\.(tenra|dalada)", apps_match.group(1))) if apps_match else set()
            span = (match.end() + apps_match.start(), match.end() + apps_match.end()) if apps_match else None
            # A new badge goes after `since:`, or after `summary:` on a page without one.
            anchor = re.search(r'since: "[^"]*"', head) or re.search(r'summary: "(?:[^"\\]|\\.)*"', head)
            insert_at = match.end() + anchor.end() if anchor else None
            found.append({"file": path, "name": name, "apps": apps, "span": span, "insert_at": insert_at})
    return found


def tokens(name):
    """The code names of a page."""
    if name in REPLACES:
        return REPLACES[name]
    parts = re.split(r"\s+·\s+|/|,", name)
    result = []
    for part in parts:
        part = re.split(r"[(:]", part)[0].strip()
        if part and " " not in part:
            result.append(part)
    return result + ALIASES.get(name, [])


def load_sources(root):
    """Each Swift file of an app, without comments, skipping build products."""
    sources = []
    for directory, subdirectories, files in os.walk(root):
        subdirectories[:] = [d for d in subdirectories if d not in (".git", ".build", "build", "DerivedData", "Pods")]
        for file in files:
            if file.endswith(".swift"):
                text = open(os.path.join(directory, file), encoding="utf-8", errors="replace").read()
                sources.append(COMMENT.sub("", STRING.sub('""', text)))
    return sources


def uses(sources, token):
    if token.startswith("."):
        pattern = re.compile(r"\." + re.escape(token[1:]) + r"\b")
        return any(pattern.search(text) for text in sources)
    word = token.split(".")[-1]
    pattern = re.compile(r"(?<![\w.])" + re.escape(token) + r"\b")
    # An app's adapter of the same name calls DesignKit's by its module.
    qualified = re.compile(r"\b(?:DesignComponents|DesignSupport|DesignTokens)\." + re.escape(token) + r"\b")
    declaration = re.compile(DECLARATION.format(name=re.escape(word)))
    return any(
        qualified.search(text) or (pattern.search(text) and not declaration.search(text))
        for text in sources
    )


def audit(root, app_roots):
    sources = {app: load_sources(path) for app, path in app_roots.items()}
    report = []
    for page in pages(root):
        names = tokens(page["name"])
        real = {app for app in APPS if any(uses(sources[app], token) for token in names)}
        if real != page["apps"]:
            report.append((page, real))
    return report


def badge(apps):
    return "apps: [" + ", ".join("." + app for app in APPS if app in apps) + "]"


def fix(report):
    # From the end of each file, so earlier offsets stay valid.
    by_file = {}
    for page, real in report:
        by_file.setdefault(page["file"], []).append((page, real))
    for path, items in by_file.items():
        text = open(path, encoding="utf-8").read()
        for page, real in sorted(items, key=lambda item: -(item[0]["span"] or (item[0]["insert_at"] or 0, 0))[0]):
            if page["span"]:
                start, end = page["span"]
                replacement = badge(real) if real else ""
                if not real:
                    # Drop the argument with its line; as the last argument, the comma before it too.
                    line_start = text.rfind("\n", 0, start)
                    line_end = text.find("\n", end)
                    is_last = not text[end:line_end].strip().startswith(",")
                    text = text[:line_start] + text[line_end:]
                    if is_last and text[:line_start].endswith(","):
                        text = text[:line_start - 1] + text[line_start:]
                    continue
                text = text[:start] + replacement + text[end:]
            elif real and page["insert_at"]:
                at = page["insert_at"]
                line_start = text.rfind("\n", 0, at) + 1
                indent = re.match(r"[ \t]*", text[line_start:]).group(0)
                if text[at:at + 1] == ",":
                    text = text[:at + 1] + "\n" + indent + badge(real) + "," + text[at + 1:]
                else:
                    # The anchor was the last argument.
                    text = text[:at] + ",\n" + indent + badge(real) + text[at:]
        open(path, "w", encoding="utf-8").write(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["check", "fix"])
    parser.add_argument("--tenra", required=True, help="a checkout of Tenra")
    parser.add_argument("--dalada", required=True, help="a checkout of Dalada")
    parser.add_argument("--root", default=".", help="DesignKit's checkout")
    args = parser.parse_args()

    report = audit(args.root, {"tenra": args.tenra, "dalada": args.dalada})
    if args.command == "fix":
        fix(report)
        print(f"{len(report)} badges rewritten")
        return 0
    if not report:
        print("Every Gallery badge matches the apps' code.")
        return 0
    print(f"{len(report)} Gallery pages name other apps than the ones whose code uses them:")
    for page, real in report:
        have = ", ".join(sorted(page["apps"])) or "none"
        want = ", ".join(sorted(real)) or "none"
        print(f"  {os.path.relpath(page['file'], args.root)}: {page['name']}: badge {have}, used by {want}")
    print("Set each page's `apps:` to the apps that use it (gallery_badges.py fix does it), or add the")
    print("name the apps use to ALIASES in .github/scripts/gallery_badges.py.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
