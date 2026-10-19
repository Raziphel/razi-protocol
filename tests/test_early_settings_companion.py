"""Regression contracts for the tiny optional early startup settings host."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAME = "00-razi-protocol-settings"
DIR = ROOT / "companion" / NAME


class EarlySettingsCompanionTests(unittest.TestCase):
    def test_companion_is_base_only_and_optional(self):
        parent = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        shim = json.loads((DIR / "info.json").read_text(encoding="utf-8"))
        self.assertEqual(shim["name"], NAME)
        self.assertEqual(shim["dependencies"], ["base >= 2.1.0"])
        self.assertEqual(parent["name"], "razi-protocol")
        self.assertIn(f"? {NAME} >= 1.1.0", parent["dependencies"])
        self.assertGreaterEqual(tuple(map(int, shim["version"].split("."))), (1, 1, 0))

    def test_current_settings_export_without_duplicate_registration(self):
        original = (ROOT / "settings.lua").read_text(encoding="utf-8")
        self.assertIn('local definitions = {', original)
        self.assertIn('if exporting then return definitions end', original)
        self.assertIn('if not companion_version or setting.setting_type ~= "startup"', original)
        self.assertIn('companion_version == "1.0.0"', original)
        self.assertIn('data:extend(local_settings)', original)
        self.assertIn('name="razi-stage-aquilo-breakthroughs"', original)
        names = re.findall(r'(?:name\\s*=\\s*|startup_toggle\\()"(razi-[a-z0-9-]+)"', original)
        self.assertEqual(len(names), 63)
        self.assertEqual(len(names), len(set(names)))

    def test_companion_registers_only_startup_with_livedefinitions(self):
        shim = (DIR / "settings.lua").read_text(encoding="utf-8")
        self.assertIn('pcall(require, "__razi-protocol__/settings")', shim)
        self.assertIn('rawset(_G, key, previous)', shim)
        self.assertIn('entry.setting_type == "startup"', shim)
        self.assertNotIn('razi-quality-asteroids', shim)
        self.assertNotIn('runtime-global', shim)

    def test_locale_is_delegated_to_protocol(self):
        for lang in ("en", "ru"):
            original = (ROOT / "locale" / lang / "settings.cfg").read_text(encoding="utf-8")
            shim = (DIR / "locale" / lang / "settings.cfg").read_text(encoding="utf-8")
            self.assertIn("[mod-setting-name]", original)
            self.assertEqual(shim.count("[mod-name]"), 1)
            self.assertNotIn("[mod-setting-name]", shim)


if __name__ == "__main__":
    unittest.main()
