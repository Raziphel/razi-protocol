"""Razi Protocol's native settings remain stable when hosted by RAZI Library."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SettingsHostingTests(unittest.TestCase):
    def test_legacy_setting_ids_remain_in_canonical_source(self):
        source = (ROOT / "settings.lua").read_text(encoding="utf-8")
        self.assertIn('local declared_settings = {', source)
        self.assertIn('if exporting then return declared_settings end', source)
        self.assertIn('hosted["razi-protocol"] == true', source)
        self.assertIn('spec.setting_type ~= "startup"', source)
        self.assertIn('if #own_settings > 0 then data:extend(own_settings) end', source)
        self.assertIn('mods["00-razi-protocol-settings"]', source)
        self.assertIn('razi-hide-spoilers', source)
        self.assertIn('razi-clean-startup-chat', source)
        self.assertIn('razi-planetary-interdependence', source)
        self.assertNotIn('data.raw', source)

    def test_library_dependency_stays_backwards_compatible(self):
        meta = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        self.assertEqual(meta["name"], "razi-protocol")
        self.assertIn("razi_lib >= 1.2.0", meta["dependencies"])
        self.assertEqual(meta["title"], "Razi Protocol")

    def test_ids_have_no_localized_duplicate(self):
        locale = (ROOT / "locale/en/settings.cfg").read_text(encoding="utf-8")
        self.assertIn("[mod-name]\nrazi-protocol=Razi Protocol\n", locale)
        names = re.findall(r"^(razi-[\w-]+)=", locale.split("[mod-setting-name]", 1)[1].split("[string-mod-setting]", 1)[0], re.M)
        self.assertGreater(len(names), 40)
        self.assertEqual(len(names), len(set(names)))


if __name__ == "__main__":
    unittest.main()
