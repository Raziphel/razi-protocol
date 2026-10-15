"""Guard Razi's canonical in-game title, without ineffective sort punctuation.

Factorio owns cross-mod settings grouping. Never rename the mod's ID to
manipulate presentation; it would break save and dependency identity.
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SettingsTitleHintTests(unittest.TestCase):
    def test_canonical_display_title_and_mod_identity(self):
        metadata = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        self.assertEqual(metadata["name"], "razi-protocol")
        self.assertEqual(metadata["title"], "Razi Protocol")
        locale = (ROOT / "locale/en/settings.cfg").read_text(encoding="utf-8")
        self.assertIn("[mod-name]\nrazi-protocol=Razi Protocol\n", locale)
        self.assertNotIn("razi-protocol=! Razi Protocol", locale)
        self.assertEqual(locale.count("[mod-name]"), 1)

    def test_setting_names_and_priorities_remain_in_their_original_file(self):
        source = (ROOT / "settings.lua").read_text(encoding="utf-8")
        names = re.findall(r'razi-[a-z0-9-]+', source)
        self.assertIn("razi-planetary-interdependence", names)
        self.assertIn("razi-starmap-background-style", names)
        self.assertIn("razi-route-overlay-mode", names)
        self.assertNotIn("data.raw", source)
        self.assertNotIn("data:extend({{", source)


if __name__ == "__main__":
    unittest.main()
