#!/usr/bin/env python3
"""DesignKit lint for the apps that use DesignKit (8.9.0).

The rules of DesignKit as checks, in one place: an app's CI runs this script from the DesignKit
version it pins, so a rule the owner sets in a review reaches both apps with the next bump
instead of living in two copies (Tenra's and Dalada's `design_lint.py` and
`section_rows_lint.py` before). Benchmark round 4: Astryx's `doctor`.

Two checks:

tokens        No raw design values in the app's Swift code: colours, fonts, spacing, corner
              radii and animations come from DesignKit tokens (AppColors, AppTypography,
              AppSpacing, AppRadius, AppAnimation) and its components; no `.swipeActions` (a
              list's actions are a long press and the toolbar since 8.0.0) and no system `Form`
              (forms are `FormSection` cards). The count per file and rule is compared with the
              app's baseline JSON: more is a new raw value and fails, fewer asks to lower the
              baseline (`--update-baseline`), a file not in it must have none.
              A justified exception: `// design-lint:ignore <reason>` on the line.

section-rows  Every row of a glass section (`FormSection`, `CardList(layout: .section)`) pads
              itself vertically and starts its divider at its text (8.0.0, 8.1.0): fails on
              `no-padding`, `inset-lost` (a link around an icon row without `.rowDividerInset`)
              and `inset-missing` (an app's own icon row without it). Rows it cannot read are
              listed with `--report`, never failed.
              A justified exception: `// section-rows-lint:ignore <reason>` on the row's first line.

Usage (from the app's root; DesignKit's checkout is wherever the app's CI puts it):

    python3 <DesignKit>/scripts/designkit_lint.py all --source Tenra
    python3 <DesignKit>/scripts/designkit_lint.py all \
        --source ios/Dalada --source ios/DaladaWidgets --source ios/Packages/DaladaKit/Sources
    python3 <DesignKit>/scripts/designkit_lint.py tokens --source Tenra --report
    python3 <DesignKit>/scripts/designkit_lint.py tokens --source Tenra --update-baseline

Options: --root (the app's root, the current folder by default), --source (repeat for each
folder), --exclude (a path fragment to skip, repeatable; Debug, Experiments, Previews and tests
are skipped by default), --baseline (scripts/design-lint-baseline.json under the root).
"""

import argparse
import collections
import json
import os
import re
import sys

DEFAULT_EXCLUDES = ("/Debug/", "/Experiments/", "Previews.swift", "/Tests/", "Tests.swift", "/.build/")
DEFAULT_BASELINE = os.path.join("scripts", "design-lint-baseline.json")


def swift_files(root, sources, excludes):
    """(path relative to the root, absolute path) of every Swift file in the sources."""
    for source in sources:
        for dirpath, dirs, files in os.walk(os.path.join(root, source)):
            dirs[:] = sorted(d for d in dirs if not d.startswith("."))
            for name in sorted(files):
                if not name.endswith(".swift"):
                    continue
                path = os.path.join(dirpath, name)
                rel = os.path.relpath(path, root).replace(os.sep, "/")
                if any(x in "/" + rel for x in excludes):
                    continue
                yield rel, path


# MARK: - tokens

TOKENS_IGNORE_MARK = "design-lint:ignore"

TOKEN_RULES = {
    # Literal colours: Color(red: 0.2, …), Color(hex: "#…"), UIColor(white: 0.9, …), #colorLiteral.
    # Use AppColors / CategoryColors. A colour built from data (Color(hex: category.colorHex)) passes.
    "raw-color": re.compile(
        r'\b(?:Color|UIColor)\(\s*(?:red|green|blue|white|hue)\s*:\s*[\d.]'
        r'|\b(?:Color|UIColor)\(\s*hex\s*:\s*"'
        r'|#colorLiteral'
    ),
    # System palette colours (.red, Color.blue, …) in styling modifiers. Use AppColors
    # (accent, Status.*, Text.*, income, expense, …).
    "system-color": re.compile(
        r'(?:foregroundStyle|foregroundColor|tint|background|fill|stroke|strokeBorder)'
        r'\(\s*(?:Color)?\.(?:red|blue|green|orange|yellow|purple|pink|gray|grey|mint|teal|cyan|indigo|brown)\b'
    ),
    # System text styles and literal font sizes. Use AppTypography (Inter, Dynamic Type).
    # `.font(.system(size: AppIconSize.md))` sizes an SF Symbol with a token and passes.
    "system-font": re.compile(
        r'\.font\(\s*(?:Font)?\.(?:system\(\s*size:\s*[\d.]|largeTitle\b|title\b|title2\b|title3\b'
        r'|headline\b|subheadline\b|body\b|callout\b|footnote\b|caption\b|caption2\b)'
        r'|\bFont\.custom\('
    ),
    # Literal padding. Use AppSpacing.
    "raw-padding": re.compile(r'\.padding\(\s*(?:\.[a-zA-Z]+\s*,\s*|\[[^\]]*\]\s*,\s*)?[1-9]\d*(?:\.\d+)?\s*\)'),
    # Literal stack spacing (0 is allowed). Use AppSpacing.
    "raw-spacing": re.compile(r'\bspacing:\s*[1-9]\d*(?:\.\d+)?\b'),
    # Literal corner radius. Use AppRadius.
    "raw-radius": re.compile(r'\bcornerRadius:\s*[1-9]\d*(?:\.\d+)?\b|\.cornerRadius\(\s*[1-9]'),
    # Hand-tuned curves. Use AppAnimation / AppMotion.
    "raw-animation": re.compile(
        r'\.(?:easeIn|easeOut|easeInOut|linear)\(\s*duration:\s*[\d.]'
        r'|\.spring\(\s*(?:response|duration|bounce)\s*:'
        r'|\.interpolatingSpring\('
    ),
    # Swipe actions on rows (8.0.0): a list's actions are a long press (Edit, Delete) and the
    # toolbar (select, reorder, add) of a CardList.
    "swipe-actions": re.compile(r'\.swipeActions\s*[({]'),
    # The system Form (design-system.md §8): a form is FormSection glass cards.
    "system-form": re.compile(r'(?:^|[^\w.])Form\s*\{'),
}


def scan_tokens(root, sources, excludes):
    """{file: {rule: [(line, text), …]}}"""
    hits = collections.defaultdict(lambda: collections.defaultdict(list))
    for rel, path in swift_files(root, sources, excludes):
        with open(path, encoding="utf-8", errors="replace") as source:
            in_preview = False
            for number, line in enumerate(source, 1):
                stripped = line.strip()
                # #Preview blocks are not product UI; they end at the next top-level "}".
                if stripped.startswith("#Preview"):
                    in_preview = True
                if in_preview:
                    if line.startswith("}"):
                        in_preview = False
                    continue
                if stripped.startswith("//") or TOKENS_IGNORE_MARK in line:
                    continue
                for rule, pattern in TOKEN_RULES.items():
                    for _ in pattern.finditer(line):
                        hits[rel][rule].append((number, stripped))
    return hits


def check_tokens(args):
    hits = scan_tokens(args.root, args.source, args.exclude)
    current = {rel: {rule: len(lines) for rule, lines in sorted(rules.items())}
               for rel, rules in sorted(hits.items())}
    baseline_path = os.path.join(args.root, args.baseline)

    if args.update_baseline:
        with open(baseline_path, "w", encoding="utf-8") as out:
            json.dump(current, out, indent=2, sort_keys=True, ensure_ascii=False)
            out.write("\n")
        total = sum(sum(rules.values()) for rules in current.values())
        print(f"Baseline written: {total} raw values in {len(current)} files.")
        return 0

    if args.report:
        by_rule = collections.defaultdict(list)
        for rel, rules in sorted(hits.items()):
            for rule, lines in rules.items():
                by_rule[rule].extend(f"{rel}:{n}: {text}" for n, text in lines)
        for rule in TOKEN_RULES:
            print(f"\n{rule} ({len(by_rule[rule])})")
            for entry in by_rule[rule]:
                print(f"  {entry}")
        return 0

    try:
        with open(baseline_path, encoding="utf-8") as source:
            baseline = json.load(source)
    except FileNotFoundError:
        baseline = {}

    failures = 0
    improved = []
    for rel, rules in current.items():
        for rule, count in rules.items():
            allowed = baseline.get(rel, {}).get(rule, 0)
            if count > allowed:
                failures += count - allowed
                for number, text in hits[rel][rule]:
                    print(f"::error file={rel},line={number},title=design-lint {rule}::"
                          f"{count} raw value(s), baseline allows {allowed}: {text}")
            elif count < allowed:
                improved.append(f"{rel} {rule}: {allowed} → {count}")
    for rel, rules in baseline.items():
        for rule, allowed in rules.items():
            if rel not in current or rule not in current[rel]:
                improved.append(f"{rel} {rule}: {allowed} → 0")

    total = sum(sum(rules.values()) for rules in current.values())
    print(f"design-lint: {total} raw design values in {len(current)} files (baseline "
          f"{sum(sum(r.values()) for r in baseline.values())}).")
    if improved:
        print("Fewer than the baseline (run with --update-baseline to lock it in):")
        for entry in improved:
            print(f"  {entry}")
    if failures:
        print(f"\n{failures} new raw design value(s). Use DesignKit tokens (AppColors, AppTypography, "
              "AppSpacing, AppRadius, AppAnimation) and components (CardList's long press and toolbar, "
              "FormSection), or mark a justified exception with `// design-lint:ignore <reason>`.")
        return 1
    return 0


# MARK: - section-rows (moved from the apps' section_rows_lint.py)

ROWS_IGNORE_MARK = "section-rows-lint:ignore"

# DesignKit views that pad themselves vertically in a section.
SELF_PADDED = {
    "UniversalRow", "UniversalRowSkeleton", "ItemRow", "ItemRowSkeleton", "ChecklistRow",
    "ChecklistRowSkeleton", "ChecklistSummaryRow", "ChecklistSummaryRowSkeleton",
    "FormTextField", "SliderRow", "StepperRow", "TransactionCard", "TransactionRow",
    "TransactionRowSkeleton", "SkeletonRow", "InlineStatusText", "ScheduleRow", "NetAmountRow",
    "InfoRow", "PersonRow", "PersonRowSkeleton", "DownloadRow", "SearchSuggestionRow",
    "SegmentedPicker", "ChipPicker", "TagInput", "MessageComposer",
}
# DesignKit views made for a List: no vertical padding of their own.
NO_PADDING = {"CommentRow", "CurrencyRow", "ThumbnailRow", "MetaLine", "AmountRowListStyle"}
WRAPPERS = {"Button", "NavigationLink", "Link", "ShareLink", "Menu", "PhotosPicker"}
LEADING_ICON = re.compile(
    r"^\s*(Icon|Image|SelectionIndicator|PersonAvatar|Avatar|RemotePhoto|BrandLogo)\s*\(")
PADDING = re.compile(
    r"\.padding\((\.vertical|\.top|\.bottom|\[\s*\.vertical|AppSpacing\.\w+\s*\)|EdgeInsets)"
    r"|\.cardContentPadding\(\)|\.frame\(minHeight")
NOT_ROWS = {"let", "var", "EmptyView", "RowDivider", "Divider", "Spacer", "ForEach", "if",
            "else", "switch", "case", "default", "Group", "Section", "?"}
SECTION = re.compile(
    r"FormSection\b(\((?:[^(){}]|\([^()]*\))*\))?\s*\{"
    r"|CardList\((?:[^(){}]|\([^()]*\))*layout:\s*\.section(?:[^(){}]|\([^()]*\))*\)\s*\{")


def closing(s, i, open_ch, close_ch):
    depth = 0
    for j in range(i, len(s)):
        if s[j] == open_ch:
            depth += 1
        elif s[j] == close_ch:
            depth -= 1
            if depth == 0:
                return j
    return len(s) - 1


def blank_strings_and_comments(s):
    """Same length, so offsets and lines stay; keeps the ignore marks."""
    s = re.sub(r'"""[\s\S]*?"""', lambda m: re.sub(r"[^\n]", "x", m.group(0)), s)
    s = re.sub(r'"(?:[^"\\\n]|\\.)*"', lambda m: '"' + "x" * (len(m.group(0)) - 2) + '"', s)
    return re.sub(r"//(?!\s*" + ROWS_IGNORE_MARK + r")[^\n]*", lambda m: " " * len(m.group(0)), s)


class App:
    def __init__(self, texts):
        self.texts = texts
        self.structs = {}  # name -> body
        self.helpers = {}  # (file, name) -> [bodies]
        for path, text in texts.items():
            for m in re.finditer(r"\bstruct\s+([A-Z]\w*)[^{]*\{", text):
                self.structs.setdefault(m.group(1), text[m.end(): closing(text, m.end() - 1, "{", "}")])
            for m in re.finditer(
                    r"\bfunc\s+([a-z]\w*)\s*(?:<[^>]*>)?\(((?:[^()]|\([^()]*\))*)\)\s*->\s*some View\s*\{"
                    r"|\bvar\s+([a-z]\w*)\s*:\s*some View\s*\{", text):
                name = m.group(1) or m.group(3)
                if name != "body":
                    end = closing(text, m.end() - 1, "{", "}")
                    params = re.findall(r"(?:^|,)\s*(?:(\w+)\s+)?(\w+)\s*:", m.group(2) or "")
                    self.helpers.setdefault((path, name), []).append((params, text[m.end(): end]))

    def body(self, path, name, call=""):
        if (path, name) in self.helpers:
            overloads = self.helpers[(path, name)]
            if len(overloads) > 1 and call:
                # Overloads by type: the one whose parameter has the argument's name or label.
                args = call[call.find("(") + 1:] if "(" in call else ""
                first = re.match(r"\s*(?:(\w+)\s*:\s*)?(\w+)", args)
                if first:
                    label, value = first.group(1), first.group(2)
                    chosen = [b for params, b in overloads
                              if params and (params[0][0] == label if label else params[0][1] == value)]
                    if chosen:
                        return chosen
            return [b for _, b in overloads]
        struct = self.structs.get(name)
        if struct:
            m = re.search(r"var body: some View\s*\{", struct)
            if m:
                return [struct[m.end(): closing(struct, m.end() - 1, "{", "}")]]
        return None

    def first_views(self, path, name, seen=(), call=""):
        """The view statements of a helper's or a row struct's body, or None."""
        if name in seen:
            return None
        bodies = self.body(path, name, call)
        if bodies is None:
            return None
        out = []
        for b in bodies:
            b = re.sub(r"^\s*(let|var)\s[^\n]*\n", "", b.strip() + "\n", flags=re.M)
            b = re.sub(r"^\s*return\s+", "", b.strip())
            out += [v for v in statements(b) if head_of(v) not in NOT_ROWS]
        return out

    def padded(self, path, stmt, seen=()):
        """True, False, or None when the row is a view this lint does not know."""
        head = head_of(stmt)
        if PADDING.search(outer(stmt)):
            return True
        args = stmt[stmt.find("("): closing(stmt, stmt.find("("), "(", ")") + 1] if "(" in stmt[:80] else ""
        if re.search(r"verticalPadding:\s*0\b", args):
            # A row told not to pad (its own or an app's row struct that passes it on).
            return False
        if head in WRAPPERS:
            label = label_of(stmt)
            if label is None:
                return None
            return self.padded(path, label, seen)
        if head == "ItemRow" or head == "ChecklistRow" or head.endswith("Skeleton") and head in SELF_PADDED:
            return not re.search(r"verticalPadding:\s*0\b", stmt)
        if head in SELF_PADDED:
            return True
        if head == "AmountRow":
            return "style: .list" not in stmt
        if head in NO_PADDING:
            return False
        if head in ("HStack", "ZStack"):
            # As tall as its tallest view: padded when a view in it pads itself.
            inner = stmt[stmt.find("{") + 1: closing(stmt, stmt.find("{"), "{", "}")] if "{" in stmt else ""
            return any(self.padded(path, v, seen) is True for v in statements(inner)
                       if head_of(v) not in NOT_ROWS)
        if head in ("VStack", "Text", "Label", "LabeledContent"):
            return False
        views = self.first_views(path, head, seen, stmt)
        if views is None:
            return None
        results = [self.padded(path, v, seen + (head,)) for v in views]
        if any(r is False for r in results):
            return False
        if all(r is True for r in results):
            return True
        return None

    def effective(self, path, stmt, mods="", seen=()):
        """A row with helpers and row structs replaced by their views: [(view, modifiers)]."""
        head = head_of(stmt)
        mods = mods + outer(stmt)
        if head in WRAPPERS or head in SELF_PADDED or head in NO_PADDING or head in seen \
                or head in ("HStack", "VStack", "ZStack", "Label", "Text"):
            return [(stmt, mods)]
        views = self.first_views(path, head, seen, stmt)
        if not views:
            return [(stmt, mods)]
        out = []
        for v in views:
            out += self.effective(path, v, mods, seen + (head,))
        return out

    def leading_icon(self, path, stmt, seen=()):
        head = head_of(stmt)
        if head == "ItemRow":
            return bool(re.search(r"leading:\s*\.(symbol|glyph)", stmt))
        if head == "UniversalRow":
            args = stmt[stmt.find("("): closing(stmt, stmt.find("("), "(", ")")] if "(" in stmt else ""
            return bool(re.search(r"\b(leadingIcon|icon):", args))
        if head in ("HStack", "Label"):
            inner = stmt[stmt.find("{") + 1:] if "{" in stmt else ""
            return bool(LEADING_ICON.match(inner.lstrip() + "\n")) or bool(
                re.match(r"\s*Button\s*\{[\s\S]*?\}\s*label:\s*\{\s*(Icon|Image|SelectionIndicator)\b", inner))
        if head in WRAPPERS or head in SELF_PADDED or head in NO_PADDING:
            return False
        views = self.first_views(path, head, seen, stmt)
        return bool(views) and any(self.leading_icon(path, v, seen + (head,)) for v in views)


def statements(block):
    """The view statements of a builder block, with ForEach / if / else bodies flattened."""
    block = re.sub(r"^\s*\(?[\w$]+(?:\s*,\s*[\w$]+)*\)?\s+in\b", "", block)
    out, i, n = [], 0, len(block)
    while i < n:
        i = re.compile(r"\s*").match(block, i).end()
        if i >= n:
            break
        if re.match(r"(ForEach\b|if\b|else\b|\} else\b|switch\b|case\b|Group\s*\{)", block[i:]):
            j = i
            if block.startswith("ForEach", i):
                # Past its arguments, which may hold a closure (a filter).
                p = block.find("(", i)
                if p >= 0:
                    j = closing(block, p, "(", ")")
            j = block.find("{", j)
            if j < 0:
                break
            k = closing(block, j, "{", "}")
            inner = block[j + 1: k]
            if block[i:].startswith("switch"):
                inner = re.sub(r"^\s*(case [^:\n]*|default):", "", inner, flags=re.M)
            out += statements(inner)
            i = k + 1
            continue
        if block[i] in "}{)":
            i += 1
            continue
        j = i
        while j < n:
            ch = block[j]
            if ch == "(":
                j = closing(block, j, "(", ")") + 1
                continue
            if ch == "{":
                j = closing(block, j, "{", "}") + 1
                continue
            if ch == "\n":
                rest = block[j:].lstrip()
                if rest.startswith(".") or rest.startswith("label:") or rest.startswith("} label:"):
                    j += 1
                    continue
                break
            j += 1
        out.append(block[i:j])
        i = j
    return out


def head_of(stmt):
    m = re.match(r"\s*([A-Za-z_]\w*)", stmt)
    return m.group(1) if m else "?"


def outer(stmt):
    """The statement without its closures' bodies: the modifiers of the outermost view."""
    out, i = [], 0
    while i < len(stmt):
        if stmt[i] == "{":
            i = closing(stmt, i, "{", "}") + 1
            out.append("{}")
        else:
            out.append(stmt[i])
            i += 1
    return "".join(out)


def label_of(stmt):
    """A link's label view: its `label:` closure, or its single trailing closure."""
    m = re.search(r"label:\s*\{", stmt)
    if not m:
        m = re.match(r"\s*\w+\s*(\((?:[^()]|\([^()]*\))*\))?\s*\{", stmt)
        if not m:
            return None
    start = m.end() - 1
    inner = stmt[start + 1: closing(stmt, start, "{", "}")]
    views = statements(inner)
    return views[0] if views else None



def check_section_rows(args):
    texts = {}
    for rel, path in swift_files(args.root, args.source, args.exclude):
        with open(path, encoding="utf-8") as source:
            texts[rel] = blank_strings_and_comments(source.read())
    app = App(texts)
    failures, unknown = [], []
    for path, s in sorted(texts.items()):
        for m in SECTION.finditer(s):
            start = m.end() - 1
            block = s[start + 1: closing(s, start, "{", "}")]
            rows = [r for r in statements(block) if head_of(r) not in NOT_ROWS]
            # A CardList's closure is one row per item; a FormSection's rows are its statements.
            many = len(rows) > 1 or "ForEach" in block or m.group(0).startswith("CardList")
            line = s.count("\n", 0, m.start()) + 1
            for row in rows:
                first = row.strip().splitlines()[0]
                if ROWS_IGNORE_MARK in row.split("\n")[0] or ROWS_IGNORE_MARK in first:
                    continue
                where = f"{path}:{line + block[:block.find(first)].count(chr(10)) if first in block else line}"
                padded = app.padded(path, row)
                if padded is False:
                    failures.append(f"{where}: no-padding: {first.strip()[:80]}")
                elif padded is None:
                    unknown.append(f"{where}: {first.strip()[:80]}")
                if not many:
                    continue
                for view, mods in app.effective(path, row):
                    head = head_of(view)
                    if ".rowDividerInset" in mods:
                        continue
                    if head in WRAPPERS:
                        label = label_of(view)
                        if label is not None and app.leading_icon(path, label):
                            failures.append(f"{where}: inset-lost: {first.strip()[:80]}")
                            break
                    elif head not in SELF_PADDED and head not in NO_PADDING \
                            and ".rowDividerInset" not in view and app.leading_icon(path, view):
                        failures.append(f"{where}: inset-missing: {first.strip()[:80]}")
                        break
    if args.report and unknown:
        print(f"{len(unknown)} section rows not read (not checked):")
        for u in unknown:
            print("  " + u)
    if failures:
        print(f"{len(failures)} section rows break the glass section's rules (DesignKit 8.1.0):")
        for f in failures:
            print("  " + f)
        print("no-padding: pad the row (.padding(.vertical, AppSpacing.md)) or use a row that pads itself.")
        print("inset-lost: put .rowDividerInset(<icon and the space after it>) on the link, not in its label.")
        print("inset-missing: put .rowDividerInset(<icon and the space after it>) on the row.")
        print(f"A justified exception: // {ROWS_IGNORE_MARK} <reason> on the row's first line.")
        return 1
    print("section-rows-lint: every row of a glass section pads itself and keeps its divider inset.")
    return 0


# MARK: - main

def parse(argv):
    parser = argparse.ArgumentParser(description="DesignKit's rules as checks for an app's Swift code.")
    parser.add_argument("check", choices=("tokens", "section-rows", "all"))
    parser.add_argument("--root", default=os.getcwd(), help="the app's root (default: the current folder)")
    parser.add_argument("--source", action="append", default=[], required=True,
                        help="a folder of the app's Swift code, relative to the root (repeatable)")
    parser.add_argument("--exclude", action="append", default=list(DEFAULT_EXCLUDES),
                        help="a path fragment to skip (repeatable)")
    parser.add_argument("--baseline", default=DEFAULT_BASELINE,
                        help="the tokens baseline, relative to the root")
    parser.add_argument("--report", action="store_true", help="list every hit / every row not read")
    parser.add_argument("--update-baseline", action="store_true", help="write the current token counts")
    return parser.parse_args(argv)


def main(argv):
    args = parse(argv)
    args.root = os.path.abspath(args.root)
    status = 0
    if args.check in ("tokens", "all"):
        status |= check_tokens(args)
    if args.check in ("section-rows", "all") and not args.update_baseline:
        status |= check_section_rows(args)
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
