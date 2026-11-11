#!/usr/bin/env python3
"""Tests of scripts/designkit_lint.py (8.9.0): each rule on a small Swift app it builds in a
temporary folder. Run: python3 scripts/test_designkit_lint.py (CI's Changelog job runs it)."""

import contextlib
import io
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import designkit_lint  # noqa: E402


def run(root, *args):
    """(exit status, printed text) of the lint on an app at `root`."""
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        status = designkit_lint.main([*args, "--root", root, "--source", "App"])
    return status, out.getvalue()


class AppFolder:
    def __init__(self, files, baseline=None):
        self.dir = tempfile.TemporaryDirectory()
        for name, text in files.items():
            path = os.path.join(self.dir.name, "App", name)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                f.write(text)
        if baseline is not None:
            os.makedirs(os.path.join(self.dir.name, "scripts"))
            with open(os.path.join(self.dir.name, "scripts", "design-lint-baseline.json"), "w") as f:
                json.dump(baseline, f)

    def __enter__(self):
        return self.dir.name

    def __exit__(self, *exc):
        self.dir.cleanup()


CLEAN = """
struct Screen: View {
    var body: some View {
        FormSection {
            UniversalRow("Name", icon: "person", accessory: .info("Ann"))
            UniversalRow("Quiet hours", icon: "moon", accessory: .toggle($quiet))
        }
        .padding(AppSpacing.lg)
        .foregroundStyle(AppColors.Text.primary)
    }
}
"""


class TokensTests(unittest.TestCase):
    def test_clean_code_passes(self):
        with AppFolder({"Screen.swift": CLEAN}) as root:
            self.assertEqual(run(root, "all")[0], 0)

    def test_each_raw_value_is_found(self):
        code = """
        Text("a").foregroundStyle(.red).font(.headline).padding(12)
        VStack(spacing: 8) {}
        RoundedRectangle(cornerRadius: 10)
        withAnimation(.spring(response: 0.3)) {}
        Color(red: 0.2, green: 0.3, blue: 0.4)
        List { row.swipeActions { Button("Delete") {} } }
        Form { Toggle("On", isOn: $on) }
        """
        with AppFolder({"Raw.swift": code}) as root:
            status, text = run(root, "tokens")
            self.assertEqual(status, 1)
            for rule in ("system-color", "system-font", "raw-padding", "raw-spacing", "raw-radius",
                         "raw-animation", "raw-color", "swipe-actions", "system-form"):
                self.assertIn(f"design-lint {rule}", text, rule)

    def test_form_section_is_not_a_form(self):
        with AppFolder({"Screen.swift": "FormSection { }\nEditForm { }\n"}) as root:
            self.assertEqual(run(root, "tokens")[0], 0)

    def test_the_baseline_allows_what_it_counts(self):
        code = 'Text("a").font(.headline)\n'
        with AppFolder({"Old.swift": code}, baseline={"App/Old.swift": {"system-font": 1}}) as root:
            self.assertEqual(run(root, "tokens")[0], 0)
        with AppFolder({"Old.swift": code * 2}, baseline={"App/Old.swift": {"system-font": 1}}) as root:
            self.assertEqual(run(root, "tokens")[0], 1)

    def test_an_ignore_mark_and_previews_pass(self):
        code = 'Text("a").font(.headline) // design-lint:ignore a Live Activity\n' \
               '#Preview {\n    Text("b").padding(12)\n}\n'
        with AppFolder({"Screen.swift": code}) as root:
            self.assertEqual(run(root, "tokens")[0], 0)

    def test_update_baseline_writes_the_counts(self):
        with AppFolder({"Old.swift": 'Text("a").font(.headline)\n'}) as root:
            os.makedirs(os.path.join(root, "scripts"))
            self.assertEqual(run(root, "tokens", "--update-baseline")[0], 0)
            with open(os.path.join(root, "scripts", "design-lint-baseline.json")) as f:
                self.assertEqual(json.load(f), {"App/Old.swift": {"system-font": 1}})


class SectionRowsTests(unittest.TestCase):
    def test_a_row_without_padding_fails(self):
        code = """
        struct Screen: View {
            var body: some View {
                FormSection {
                    HStack { Text("Backups"); Spacer() }
                    UniversalRow("Name", accessory: .info("Ann"))
                }
            }
        }
        """
        with AppFolder({"Screen.swift": code}) as root:
            status, text = run(root, "section-rows")
            self.assertEqual(status, 1)
            self.assertIn("no-padding", text)

    def test_a_link_around_an_icon_row_needs_the_inset(self):
        code = """
        struct Screen: View {
            var body: some View {
                FormSection {
                    NavigationLink { Detail() } label: {
                        HStack { Icon("doc"); Text("Backups") }
                            .padding(.vertical, AppSpacing.md)
                    }
                    UniversalRow("Name", accessory: .info("Ann"))
                }
            }
        }
        """
        with AppFolder({"Screen.swift": code}) as root:
            status, text = run(root, "section-rows")
            self.assertEqual(status, 1)
            self.assertIn("inset-lost", text)

    def test_designkit_rows_pass(self):
        with AppFolder({"Screen.swift": CLEAN}) as root:
            self.assertEqual(run(root, "section-rows")[0], 0)


if __name__ == "__main__":
    unittest.main()
