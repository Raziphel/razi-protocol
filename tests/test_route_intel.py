"""Regression checks for native tooltip enrichments and matching map risk colours."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class RouteIntelIntegrationTests(unittest.TestCase):
    def test_final_stage_no_runtime_polling(self):
        final=(ROOT/"data-final-fixes.lua").read_text()
        self.assertLess(final.index('require("prototypes.system.route_icons").data_final_fixes()'),
                        final.index('require("prototypes.system.route_intel").data_final_fixes()'))
        self.assertLess(final.index('require("prototypes.system.route_intel").data_final_fixes()'),
                        final.index('require("prototypes.system.route_highlights").data_final_fixes()'))
        self.assertIn("custom_tooltip_fields", (ROOT/"prototypes/system/route_intel.lua").read_text())
    def test_native_owner_preserved_and_legend_shared(self):
        tooltip=(ROOT/"prototypes/system/route_intel.lua").read_text()
        high=(ROOT/"prototypes/system/route_highlights.lua").read_text()
        self.assertIn("local hazards=require(",tooltip)
        self.assertIn("local hazards = require(",high)
        self.assertIn("hazards.color(route)",high)
        self.assertNotIn("route.localised_description=",tooltip)
        self.assertNotIn("data:extend",tooltip)
        self.assertIn("razi-route-intelligence",(ROOT/"settings.lua").read_text())
    def test_deep_space_guides_added(self):
        manifest=(ROOT/"prototypes/system/route_highlight_manifest.lua").read_text()
        for start in ("secretas","vesta"):
            self.assertIn(f'from="{start}",to="solar-system-edge"',manifest)
if __name__=="__main__":
    unittest.main()
