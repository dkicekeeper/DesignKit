#!/usr/bin/env python3
"""Tests of scripts/migrate.py (8.9.0) on a small app built in a temporary folder.
Run: python3 scripts/test_migrate.py (CI's Changelog job runs it)."""

import contextlib
import io
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import migrate  # noqa: E402

OLD = """struct Settings: View {
    var body: some View {
        FormSection(header: "Alerts", style: .glass) {
            ToggleSettingsRow(icon: "moon", title: "Quiet", isOn: $quiet)
            Divider()
            SliderRowSkeleton(showsHint: true)
        }
        SectionHeader("Data", style: .compact)
    }
}
"""


def run(root, *args):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        status = migrate.main(["--root", root, "--source", "App", *args])
    return status, out.getvalue()


class MigrateTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        os.makedirs(os.path.join(self.dir.name, "App"))
        self.path = os.path.join(self.dir.name, "App", "Settings.swift")
        with open(self.path, "w") as f:
            f.write(OLD)

    def tearDown(self):
        self.dir.cleanup()

    def text(self):
        with open(self.path) as f:
            return f.read()

    def test_a_dry_run_writes_nothing(self):
        status, out = run(self.dir.name, "--from", "6.1.0", "--to", "8.0.0")
        self.assertEqual(status, 0)
        self.assertIn("Would change 1 files", out)
        self.assertEqual(self.text(), OLD)

    def test_apply_rewrites_and_marks(self):
        run(self.dir.name, "--from", "6.1.0", "--to", "8.0.0", "--apply")
        text = self.text()
        self.assertIn('FormSection(header: "Alerts") {', text)
        self.assertIn('SectionHeader("Data")', text)
        self.assertIn("UniversalRowSkeleton.slider(showsHint: true)", text)
        self.assertIn("// TODO(DesignKit 7.0): ToggleSettingsRow → UniversalRow", text)
        self.assertIn("// TODO(DesignKit 8.0): Inside a FormSection, remove the Divider", text)

    def test_running_twice_adds_no_second_todo(self):
        run(self.dir.name, "--from", "6.1.0", "--to", "8.0.0", "--apply")
        once = self.text()
        run(self.dir.name, "--from", "6.1.0", "--to", "8.0.0", "--apply")
        self.assertEqual(self.text(), once)

    def test_only_the_majors_in_range_run(self):
        run(self.dir.name, "--from", "7.0.0", "--to", "8.0.0", "--apply")
        self.assertNotIn("DesignKit 7.0", self.text())
        self.assertIn("DesignKit 8.0", self.text())

    def test_every_rules_file_is_valid(self):
        for name in os.listdir(os.path.join(HERE, "migrations")):
            with open(os.path.join(HERE, "migrations", name)) as f:
                rules = json.load(f)
            self.assertTrue(os.path.exists(os.path.join(HERE, "..", rules["guide"])), name)
            migrate.load(os.path.join(HERE, "migrations", name))


if __name__ == "__main__":
    unittest.main()
