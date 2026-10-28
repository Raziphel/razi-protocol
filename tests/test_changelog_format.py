"""Guard Factorio's in-game changelog parser contract on the 3.0 branch.

Factorio requires an exact 99-dash separator immediately before *every*
Version line, including the first. A missing separator disables the in-game
Changelog button even though the mod portal can display the text.
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECTION = "-" * 99
VERSION = re.compile(r"Version: (\d+)\.(\d+)\.(\d+)$")


class ChangelogFormatTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lines = (ROOT / "changelog.txt").read_text(encoding="utf-8").splitlines()

    def test_every_version_has_exact_separator(self):
        starts = [i for i, line in enumerate(self.lines) if line.startswith("Version: ")]
        self.assertTrue(starts)
        for i in starts:
            with self.subTest(line=i + 1):
                self.assertGreater(i, 0)
                self.assertEqual(self.lines[i - 1], SECTION)
                self.assertRegex(self.lines[i], VERSION)
        self.assertEqual(sum(line == SECTION for line in self.lines), len(starts))
        for i, line in enumerate(self.lines):
            if line == SECTION:
                with self.subTest(separator_line=i + 1):
                    self.assertLess(i + 1, len(self.lines))
                    self.assertRegex(self.lines[i + 1], VERSION)

    def test_unique_versions_and_current_manifest(self):
        versions = [VERSION.fullmatch(line).group(0).removeprefix("Version: ")
                    for line in self.lines if VERSION.fullmatch(line)]
        self.assertEqual(len(versions), len(set(versions)))
        manifest = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        self.assertEqual(versions[0], manifest["version"])

    def test_no_tabs_trailing_spaces_or_orphan_entries(self):
        active_category = False
        for i, line in enumerate(self.lines):
            with self.subTest(line=i + 1):
                self.assertNotIn("\t", line)
                self.assertEqual(line, line.rstrip(" "))
                if not line or line == SECTION or line.startswith("Date: "):
                    continue
                if VERSION.fullmatch(line):
                    active_category = False
                elif re.fullmatch(r"  [^ ].*:", line):
                    active_category = True
                elif line.startswith("    - ") or line.startswith("      "):
                    self.assertTrue(active_category, "entry without category")
                else:
                    self.fail("invalid changelog line structure")


if __name__ == "__main__":
    unittest.main()
