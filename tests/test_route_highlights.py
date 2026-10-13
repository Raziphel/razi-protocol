"""Native route coloring ownership regression for the external renderer."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class RouteOverlayTests(unittest.TestCase):
    def test_optional_non_ordered_overlay_avoids_dependency_cycle(self):
        info=json.loads(source("info.json"))
        deps=info["dependencies"]
        self.assertEqual(info["factorio_version"],"2.1")
        self.assertIn("~ space-route-overlay >= 0.2.7",deps)
        self.assertFalse(any(
            d.startswith(("space-route-overlay ", "? space-route-overlay",
                          "+ space-route-overlay", "(?) space-route-overlay"))
            for d in deps))

    def test_old_sprite_renderer_can_never_draw(self):
        source_code=source("prototypes/system/route_highlights.lua")
        final=source("data-final-fixes.lua")
        self.assertNotIn('require("prototypes.system.route_highlights").data_final_fixes()',final)
        self.assertNotIn("directional-strokes",final)
        self.assertNotIn('table.insert(sprite.layers',source_code)
        self.assertNotIn("utility-sprites",source_code)
        self.assertNotIn("sprite.layers",source_code)
        self.assertIn("return 0",source_code)
        self.assertIn("return {}",source_code)

    def test_retire_inert_route_setting_but_retain_tooltips(self):
        self.assertNotIn("razi-route-highlight-style",source("settings.lua"))
        self.assertNotIn("razi-route-highlight-style=",source("locale/en/settings.cfg"))
        self.assertIn("razi-route-intelligence",source("settings.lua"))
        self.assertIn('require("prototypes.system.route_intel").data_final_fixes()',
                      source("data-final-fixes.lua"))

    def test_sources_preserve_native_route_ownership(self):
        source_code=source("prototypes/system/route_highlights.lua")
        self.assertNotIn("data:extend",source_code)
        self.assertNotIn("data.raw",source_code)
        self.assertNotIn("route.shape=",source_code)
        self.assertNotIn("route.length=",source_code)
        self.assertIn('require("prototypes.system.route_hazards")',source_code)

if __name__=="__main__":
    unittest.main()
