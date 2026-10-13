"""Route tooltips remain Razi-owned after visual overlay handoff."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

class RouteIntelIntegrationTests(unittest.TestCase):
    def test_tooltips_are_registered_without_stroke_renderer(self):
        final=(ROOT/"data-final-fixes.lua").read_text()
        self.assertLess(final.index('require("prototypes.system.route_icons").data_final_fixes()'),
                        final.index('require("prototypes.system.route_intel").data_final_fixes()'))
        self.assertNotIn('require("prototypes.system.route_highlights").data_final_fixes()',final)
        self.assertIn("custom_tooltip_fields",
                      (ROOT/"prototypes/system/route_intel.lua").read_text())

    def test_native_owner_and_hazard_intelligence(self):
        tooltip=(ROOT/"prototypes/system/route_intel.lua").read_text()
        hazards=(ROOT/"prototypes/system/route_hazards.lua").read_text()
        self.assertIn("local hazards=require(",tooltip)
        self.assertIn("function M.inspect(route)",hazards)
        self.assertNotIn("route.localised_description=",tooltip)
        self.assertNotIn("data:extend",tooltip)
        self.assertIn("razi-route-intelligence",
                      (ROOT/"settings.lua").read_text())

    def test_deep_space_travel_is_retained(self):
        routes=(ROOT/"prototypes/system/route_reconcile.lua").read_text()
        for source in ("secretas","vesta"):
            self.assertIn(f'{{"{source}", "solar-system-edge",',routes)

if __name__=="__main__":
    unittest.main()
