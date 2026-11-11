#!/usr/bin/env python3
"""Puts docs/agents.md into an app's CLAUDE.md between its markers (8.9.0).

    python3 <DesignKit>/scripts/sync_agents_block.py CLAUDE.md

The block sits between `<!-- designkit:agents:start -->` and `<!-- designkit:agents:end -->`,
with the DesignKit version it came from; everything around it is the app's own. With no markers
in the file the block is added at its end. The app's DesignKit update workflow runs it after it
moves the pin, so the block always matches the version the app builds with. Exit status 0 when
the file is current or was updated; `--check` exits 1 instead of writing when it is stale.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "..", "docs", "agents.md")
VERSION = os.path.join(HERE, "..", "VERSION")
START = "<!-- designkit:agents:start -->"
END = "<!-- designkit:agents:end -->"


def block():
    with open(SOURCE, encoding="utf-8") as f:
        text = f.read().strip()
    with open(VERSION, encoding="utf-8") as f:
        version = f.read().strip()
    # The app's file has its own title: the guide's heading drops a level.
    text = re.sub(r"^(#+) ", lambda m: "#" + m.group(1) + " ", text, flags=re.M)
    note = f"<!-- From DesignKit {version}, docs/agents.md. Do not edit here: the DesignKit update workflow rewrites it. -->"
    return f"{START}\n{note}\n\n{text}\n\n{END}"


def synced(text):
    new = block()
    pattern = re.compile(re.escape(START) + r"[\s\S]*?" + re.escape(END))
    if pattern.search(text):
        return pattern.sub(lambda _: new, text, count=1)
    return text.rstrip() + "\n\n" + new + "\n"


def main(argv):
    check = "--check" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if len(paths) != 1:
        print(__doc__)
        return 2
    path = paths[0]
    with open(path, encoding="utf-8") as f:
        text = f.read()
    new = synced(text)
    if new == text:
        print(f"{path}: the DesignKit block is current.")
        return 0
    if check:
        print(f"{path}: the DesignKit block is stale; run scripts/sync_agents_block.py {path}")
        return 1
    with open(path, "w", encoding="utf-8") as f:
        f.write(new)
    print(f"{path}: the DesignKit block is updated.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
