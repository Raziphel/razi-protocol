"""Verify compatibility registry entries remain explicit and discoverable."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class TestCompatibilityRegistry(unittest.TestCase):
    def test_registry_modules_are_real_and_unique(self):
        reg = json.loads((ROOT / "compat/registry.json").read_text(encoding="utf-8"))
        info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        deps = {line.lstrip("?~! ").split(" ", 1)[0] for line in info["dependencies"]}
        identifiers = set()
        for entry in reg["patches"]:
            with self.subTest(patch=entry["id"]):
                self.assertNotIn(entry["id"], identifiers)
                identifiers.add(entry["id"])
                self.assertTrue((ROOT / entry["module"]).is_file())
                self.assertTrue((ROOT / entry["fixture"]).is_file())
                self.assertTrue(entry["purpose"])
                self.assertIn(entry["upstream_status"], {
                    "needs-review", "reported-upstream-unknown-release",
                    "fixed-upstream-pending-verification", "local-only"})
                for mod in entry["upstream_mods"]:
                    self.assertIn(mod, deps)

if __name__ == "__main__":
    unittest.main()
