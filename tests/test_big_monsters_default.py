"""Confirm Big-Monsters' default uses the real setting ID and stays optional."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

class BigMonstersDefault(unittest.TestCase):
    def test_default_overrides_only_the_source_runtime_global(self):
        settings=(ROOT/"settings-final-fixes.lua").read_text(encoding="utf-8")
        self.assertIn('["bm-event-days"]',settings)
        self.assertIn('mods["Big-Monsters"]',settings)
        self.assertIn('big_monsters_interval.setting_type == "runtime-global"',settings)
        self.assertIn('big_monsters_interval.default_value = 0',settings)
        self.assertNotIn('big_monsters_interval.forced_value',settings)
        self.assertNotIn('big_monsters_interval.hidden',settings)
        self.assertIn('adjust_maraxsis.forced_value = false',settings)

if __name__=="__main__":
    unittest.main()
