"""Calidus Drift is retired from the active Razi Protocol map."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

class CalidusRetirementTests(unittest.TestCase):
    def test_no_registration(self):
        self.assertNotIn("calidus_expansion",source("data.lua"))
        self.assertNotIn("calidus_expansion",source("data-final-fixes.lua"))
        self.assertFalse((ROOT/"prototypes/system/calidus_expansion.lua").exists())

    def test_no_map_location(self):
        for path in ("prototypes/system/galaxy_layout.lua",
                     "prototypes/system/starmap_background.lua",
                     "scripts/galactic_catalog.lua",
                     "prototypes/system/planet_descriptions.lua",
                     "locale/en/names.cfg","locale/ru/names.cfg"):
            self.assertNotIn("razi-calidus-drift",source(path),path)

    def test_legacy_cleanup(self):
        route=source("prototypes/system/route_reconcile.lua")
        self.assertIn('route.from=="razi-calidus-drift"',route)
        self.assertIn('route.to=="razi-calidus-drift"',route)
        self.assertNotIn('{"razi-calidus-drift", "sye-calidus"',route)
        self.assertIn('{"nauvis", "sye-calidus", 25000, "starter"}',route)

if __name__=="__main__":
    unittest.main()
