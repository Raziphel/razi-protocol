"""Factorio control loading prohibits require() during runtime GUI events."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def source(name):
    return (ROOT / "scripts" / name).read_text()

class RuntimeImportTests(unittest.TestCase):
    def test_gui_dependencies_preloaded(self):
        cases = (
            ("razi_journal_projects.lua",
             'local frontier=require("scripts.razi_journal_frontier")',
             'name=require('),
            ("galactic_atlas.lua",
             'local trade_catalog=require("scripts.galactic_trade_catalog")',
             'local catalog=require('),
            ("galactic_campaign.lua",
             'local galactic_catalog=require("scripts.galactic_catalog")',
             'local catalog=require('),
        )
        for filename, eager, forbidden in cases:
            with self.subTest(filename=filename):
                text = source(filename)
                self.assertIn(eager, text)
                self.assertNotIn(forbidden, text)

if __name__ == "__main__":
    unittest.main()
