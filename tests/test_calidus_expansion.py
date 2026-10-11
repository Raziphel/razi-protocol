"""Lightweight structural checks for the Calidus home-system additions."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class CalidusTests(unittest.TestCase):
    def test_data_stage_registration(self):
        self.assertIn('require("prototypes.system.calidus_expansion").data()',source("data.lua"))
        self.assertIn('require("prototypes.system.calidus_expansion").data_final_fixes()',
                      source("data-final-fixes.lua"))
    def test_no_new_surface_or_science(self):
        mod=source("prototypes/system/calidus_expansion.lua")
        self.assertIn('type = "space-location"',mod)
        self.assertNotIn('type = "planet"',mod)
        self.assertNotIn('map_gen_settings',mod)
        self.assertIn('belt_edge_resources(0.55)',mod)
        self.assertIn('unlock-space-location',mod)
    def test_travel_and_visibility(self):
        route=source("prototypes/system/route_reconcile.lua")
        for a,b,k in (("nauvis","razi-calidus-drift",12000),
                      ("razi-calidus-drift","sye-calidus",17500),
                      ("muluna","sye-calidus",14000)):
            self.assertIn(f'{{"{a}", "{b}", {k}, "starter"}}',route)
        self.assertIn('["razi-calidus-drift"] = "calidus"',route)
        self.assertIn('"razi-calidus-drift"',
                      source("scripts/galactic_catalog.lua"))
        self.assertIn('"razi-calidus-drift","star",33,0.865',
                      source("prototypes/system/galaxy_layout.lua"))

if __name__=="__main__":
    unittest.main()
