"""The native Factorio route is the only continuous rendered path."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class RouteArtTests(unittest.TestCase):
    def test_single_native_route_and_no_stretched_repeats(self):
        s=source("prototypes/system/route_highlights.lua")
        self.assertIn("function M.marker_for_connection(route,mode,scope)",s)
        self.assertIn("local MARKER_LIMIT=36",s)
        self.assertIn("if n>=MARKER_LIMIT then break end",s)
        self.assertIn("hazards.is_belt_crossing(connection)",s)
        self.assertIn("local at,length=route_path(route,a,b)",s)
        self.assertIn("obsolete(atlas.layers[i])",s)
        self.assertNotIn("filename=SHEET",s)
        self.assertNotIn("rendered_span",s)
        self.assertNotIn("MAX_SEGMENTS",s)
        self.assertNotIn("data:extend",s)
        self.assertNotIn("script.on_event",s)

    def test_route_markers_use_ten_stage_quality_colors(self):
        overlay=source("prototypes/system/route_highlights.lua")
        ladder=source("scripts/razi_asteroid_difficulty.lua")
        tooltip=source("prototypes/system/route_intel.lua")
        self.assertIn("quality.route_color(grade)",overlay)
        self.assertIn("function M.route_color_level(route)",overlay)
        self.assertIn("local grade=M.route_color_level(route)",overlay)
        self.assertIn('a=grade and math.min(.64,.24+.038*grade)',overlay)
        self.assertIn("M.route_colors={",ladder)
        self.assertIn("M.route_color_hex={",ladder)
        self.assertIn("quality_levels.route_color_richtext(hi)",tooltip)
        self.assertIn('field("quality-hazard"',tooltip)
        self.assertNotIn("filename=SHEET",overlay)

    def test_keep_native_icons_and_hover_data(self):
        self.assertIn("custom_tooltip_fields",
                      source("prototypes/system/route_intel.lua"))
        self.assertIn("! space-route-overlay",
                      json.loads(source("info.json"))["dependencies"])
        self.assertTrue((ROOT/"graphics/icons/routes/asteroid-route.png").exists())
        settings=source("settings.lua")
        for key in ("razi-route-overlay-mode","razi-route-overlay-scope"):
            self.assertIn(key,settings)
        self.assertIn('default_value="danger"',settings)

if __name__=="__main__":
    unittest.main()
