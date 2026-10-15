#!/usr/bin/env python3
"""Guard the curated Factorio 2.1 compatibility dependency policy."""
import json
import unittest
from pathlib import Path

INFO = Path(__file__).resolve().parents[1] / "info.json"


class K2SOCompatibilityDependencies(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.info = json.loads(INFO.read_text(encoding="utf-8"))
        cls.deps = cls.info["dependencies"]

    def test_source_compatibility_bridges_required(self):
        expected = {
            "nulls-k2so-tweaks", "xy-k2so-enhancements-nulls-fork",
            "castra-krastorio-compatibility-plus",
            "corrundum-krastorio-compatibility-plus",
            "rubia-krastorio-compatibility-plus",
            "paracelsin-krastorio-compatibility-plus",
            "k2so-cubium-compatibility-fork",
        }
        names = {dep.split()[0] for dep in self.deps
                 if not dep.startswith(("? ", "! ", "~ "))}
        self.assertFalse(expected - names, sorted(expected - names))
        self.assertIn("corrundum-krastorio-compatibility-plus >= 1.1.2", self.deps)
        self.assertIn("rubia-krastorio-compatibility-plus >= 1.3.1", self.deps)

    def test_secretas_patch_is_recommended_outer_rim_is_excluded(self):
        self.assertIn("+ secretas-orbit-patch >= 1.1.3", self.deps)
        self.assertIn("! outer-rim", self.deps)
        self.assertIn("! kry-asteroid-belt", self.deps)

    def test_no_20_only_secretas_krastorio_dependency(self):
        self.assertEqual(self.info["factorio_version"], "2.1")
        self.assertFalse(any("secretas-krastorio-compatibility-plus" in d for d in self.deps))

    def test_unique_mod_names(self):
        names = [d.lstrip("?!~ ()").split()[0] for d in self.deps]
        self.assertEqual(len(names), len(set(names)))


if __name__ == "__main__":
    unittest.main()
