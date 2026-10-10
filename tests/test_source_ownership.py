"""Ensure the seven-system ownership boundary cannot regress to old Muria logic."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class TestSourceOwnership(unittest.TestCase):
    def test_muria_is_owned_by_final_route_pass(self):
        data = (ROOT / "data.lua").read_text(encoding="utf-8")
        fixes = (ROOT / "data-final-fixes.lua").read_text(encoding="utf-8")
        self.assertNotIn('require "prototypes.system.muria"', data)
        self.assertNotIn('deleteRoutesBetween("sye-vibrant", "muria")', fixes)
        self.assertNotIn('name ~= "muria-aquilo"', fixes)
        self.assertFalse((ROOT / "prototypes/system/muria.lua").exists())
        self.assertIn('require("prototypes.system.route_reconcile")', fixes)
        self.assertIn('"sye-vespera", "muria"', (
            ROOT / "prototypes/system/route_reconcile.lua").read_text(encoding="utf-8"))

    def test_optional_weather_dependencies_are_optional(self):
        import json
        info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        self.assertIn("? celestial-weather-updated", info["dependencies"])
        self.assertIn("? celestial-weather-additions-updated", info["dependencies"])

if __name__ == "__main__":
    unittest.main()
