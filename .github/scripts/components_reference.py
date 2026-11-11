#!/usr/bin/env python3
"""The component reference for agents and people (8.9.0, benchmark round 4: Astryx's
`astryx component <Name>`).

One entry per Gallery page, read from the Gallery and the sources so it cannot drift from them:
the section, what the component is for, since which version, which apps use it, its styles, its
usage notes and do / don't lines (`ComponentPage`), the file it lives in, its doc comment, its
public initialisers and its skeleton. An app session greps docs/components.md for `### Name`
instead of reading docs/design-system.md whole; docs/components.json is the same as data.

    python3 .github/scripts/components_reference.py write   # regenerate both files
    python3 .github/scripts/components_reference.py check   # CI: fails when they are stale
"""

import json
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SCREENS = os.path.join(ROOT, "Gallery", "Gallery", "Screens")
ROOT_VIEW = os.path.join(ROOT, "Gallery", "Gallery", "RootView.swift")
SOURCES = os.path.join(ROOT, "Sources")
MARKDOWN = os.path.join(ROOT, "docs", "components.md")
JSON = os.path.join(ROOT, "docs", "components.json")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gallery_badges import tokens  # noqa: E402  (a page's code names)

STRING = r'"((?:[^"\\]|\\.)*)"'


def closing(text, i, opening, close):
    depth = 0
    in_string = False
    j = i
    while j < len(text):
        ch = text[j]
        if in_string:
            if ch == "\\":
                j += 2
                continue
            if ch == '"':
                in_string = False
        elif ch == '"':
            in_string = True
        elif ch == opening:
            depth += 1
        elif ch == close:
            depth -= 1
            if depth == 0:
                return j
        j += 1
    return len(text) - 1


def unescape(text):
    return text.replace('\\"', '"').replace("\\\\", "\\")


def strings_of(head, key):
    """The string literals of `key: [ … ]` in a page's arguments."""
    m = re.search(r"\b" + key + r":\s*\[", head)
    if not m:
        return []
    end = closing(head, m.end() - 1, "[", "]")
    return [unescape(s) for s in re.findall(STRING, head[m.end():end])]


def string_of(head, key):
    m = re.search(r"\b" + key + r":\s*" + STRING, head)
    return unescape(m.group(1)) if m else None


def screen_order():
    """The screens' type names in the Gallery's order (its home screen)."""
    text = open(ROOT_VIEW, encoding="utf-8").read()
    return re.findall(r"row\((\w+Screen)\.title", text)


def pages():
    """Every ComponentPage, by section in the Gallery's order."""
    result = []
    files = {f[:-6]: os.path.join(SCREENS, f) for f in os.listdir(SCREENS) if f.endswith(".swift")}
    for screen in screen_order():
        path = files.get(screen)
        if not path:
            continue
        text = open(path, encoding="utf-8").read()
        title_match = re.search(r'static let title = "([^"]+)"', text)
        section = title_match.group(1) if title_match else screen
        for match in re.finditer(r'ComponentPage\(\s*name: ' + STRING, text):
            start = match.start() + len("ComponentPage")
            head = text[start:closing(text, start, "(", ")")]
            apps = re.search(r"apps: \[([^\]]*)\]", head)
            result.append({
                "name": unescape(match.group(1)),
                "section": section,
                "summary": string_of(head, "summary") or "",
                "since": string_of(head, "since"),
                "apps": sorted({"Tenra" if a == "tenra" else "Dalada"
                                for a in re.findall(r"\.(tenra|dalada)", apps.group(1))}) if apps else [],
                "styles": strings_of(head, "styles"),
                "notes": strings_of(head, "notes"),
                "dos": strings_of(head, "dos"),
                "donts": strings_of(head, "donts"),
            })
    return result


def load_sources():
    texts = {}
    for dirpath, _, files in os.walk(SOURCES):
        for name in sorted(files):
            if name.endswith(".swift"):
                path = os.path.join(dirpath, name)
                texts[os.path.relpath(path, ROOT).replace(os.sep, "/")] = open(path, encoding="utf-8").read()
    return texts


def doc_comment(text, index):
    """The `///` lines right above `index`, up to the first blank `///` line or code."""
    lines = text[:index].rstrip().split("\n")
    comment = []
    for line in reversed(lines):
        stripped = line.strip()
        if stripped.startswith("@") and not comment:
            continue
        if not stripped.startswith("///"):
            break
        comment.append(stripped[3:].strip())
    comment.reverse()
    paragraph = []
    for line in comment:
        if not line or line.startswith("```") or line.startswith("- "):
            if paragraph:
                break
            continue
        paragraph.append(line)
    return " ".join(paragraph)


def signature(code):
    """A declaration on one line: "init(_ title: String, icon: String? = nil)"."""
    code = " ".join(code.split())
    code = re.sub(r"([(<\[])\s+", r"\1", code)
    return re.sub(r",?\s+([)>\]])", r"\1", code)


def declaration(texts, name):
    """(file, doc, public initialisers) of a public type, or a public modifier `.name`."""
    if name.startswith("."):
        func = re.escape(name[1:])
        for path, text in texts.items():
            m = re.search(r"\n[ \t]*(?:public\s+|nonisolated\s+|@\w+\s+)*func\s+" + func + r"\b[^{]*", text)
            if m and ("public extension" in text[:m.start()].split("\nextension")[-1] or "public func" in m.group(0)):
                found = re.sub(r"^(?:public\s+|nonisolated\s+)+", "", signature(m.group(0)))
                return path, doc_comment(text, m.start() + 1), [found]
        return None
    for path, text in texts.items():
        m = re.search(r"\bpublic\s+(?:final\s+)?(?:struct|enum|class|protocol)\s+" + re.escape(name) + r"\b[^{]*\{", text)
        if not m:
            continue
        end = closing(text, m.end() - 1, "{", "}")
        body = text[m.end():end]
        inits = []
        for init in re.finditer(r"\bpublic\s+(?:nonisolated\s+)?init\s*(?:<[^>]*>)?\(", body):
            close = closing(body, init.end() - 1, "(", ")")
            inits.append(signature("init(" + body[init.end():close] + ")"))
        # Initialisers in extensions of the type, in the same file.
        for ext in re.finditer(r"\n(?:public\s+)?extension\s+" + re.escape(name) + r"\b[^{]*\{", text):
            ext_end = closing(text, ext.end() - 1, "{", "}")
            ext_body = text[ext.end():ext_end]
            public_ext = text[ext.start():ext.end()].strip().startswith("public")
            for init in re.finditer(r"(?<![.\w])(?:public\s+)?(?:nonisolated\s+)?init\s*(?:<[^>]*>)?\(", ext_body):
                prefix = ext_body[max(0, init.start() - 12):init.start()]
                if not public_ext and "public" not in ext_body[init.start():init.end()] and "public" not in prefix:
                    continue
                close = closing(ext_body, init.end() - 1, "(", ")")
                inits.append(signature("init(" + ext_body[init.end():close] + ")"))
        return path, doc_comment(text, m.start()), inits
    return None


def entries():
    texts = load_sources()
    all_text = "\n".join(texts.values())
    result = []
    for page in pages():
        code = []
        for token in tokens(page["name"]):
            found = declaration(texts, token)
            if not found:
                continue
            path, doc, inits = found
            skeleton = token + "Skeleton" if not token.startswith(".") and re.search(
                r"\bpublic\s+struct\s+" + re.escape(token) + r"Skeleton\b", all_text) else None
            code.append({"name": token, "file": path, "doc": doc, "initialisers": inits, "skeleton": skeleton})
        result.append({**page, "code": code})
    return result


def markdown(items):
    out = [
        "# DesignKit components",
        "",
        "Generated by `.github/scripts/components_reference.py` from the Gallery's pages and the",
        "sources; CI fails when it is stale (`python3 .github/scripts/components_reference.py write`).",
        "One entry per Gallery page, by section: what it is for, since when, which apps use it, its",
        "styles, its rules, do and don't, where it lives, its initialisers and its skeleton. The full",
        "rules are in [design-system.md](design-system.md); this is the index to grep (`### Name`).",
        "",
    ]
    section = None
    for item in items:
        if item["section"] != section:
            section = item["section"]
            out += [f"## {section}", ""]
        out += [f"### {item['name']}", "", item["summary"], ""]
        facts = []
        if item["since"]:
            facts.append(f"Since {item['since']}")
        facts.append("Apps: " + (", ".join(item["apps"]) if item["apps"] else "none yet"))
        if item["styles"]:
            facts.append("Styles: " + ", ".join(f"`.{s}`" for s in item["styles"]))
        out += [" · ".join(facts), ""]
        for code in item["code"]:
            line = f"- `{code['name']}` in `{code['file']}`"
            if code["skeleton"]:
                line += f"; skeleton `{code['skeleton']}`"
            out.append(line)
            if code["doc"]:
                out.append(f"  {code['doc']}")
        if item["code"]:
            out.append("")
        inits = [i for code in item["code"] for i in code["initialisers"]]
        if inits:
            out += ["```swift"] + inits + ["```", ""]
        if item["notes"]:
            out += [f"- {n}" for n in item["notes"]] + [""]
        if item["dos"] or item["donts"]:
            out += [f"- Do: {d}" for d in item["dos"]] + [f"- Don't: {d}" for d in item["donts"]] + [""]
    return "\n".join(out).rstrip() + "\n"


def main(argv):
    if not argv or argv[0] not in ("write", "check"):
        print(__doc__)
        return 2
    items = entries()
    text = markdown(items)
    data = json.dumps(items, indent=2, ensure_ascii=False) + "\n"
    if argv[0] == "write":
        open(MARKDOWN, "w", encoding="utf-8").write(text)
        open(JSON, "w", encoding="utf-8").write(data)
        print(f"Wrote {len(items)} components to docs/components.md and docs/components.json.")
        return 0
    stale = [path for path, want in ((MARKDOWN, text), (JSON, data))
             if not os.path.exists(path) or open(path, encoding="utf-8").read() != want]
    if stale:
        for path in stale:
            rel = os.path.relpath(path, ROOT)
            print(f"::error file={rel}::{rel} is stale: run python3 .github/scripts/components_reference.py write")
        return 1
    print(f"docs/components.md and docs/components.json are current ({len(items)} components).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
