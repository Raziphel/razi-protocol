"""The native Factorio route is the only continuous rendered path."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class RouteArtTests(unittest.TestCase):
    def test_real_route_geometry_ribbons_and_no_legacy_duplicate_paths(self):
        source_lua=source("prototypes/system/route_highlights.lua")
        ribbons=source("prototypes/system/route_ribbons.lua")
        self.assertIn("M.route_path=route_path",source_lua)
        self.assertIn("M.is_major=is_major",source_lua)
        self.assertIn("route_ribbons",source_lua)
        self.assertIn("function M.strokes_for_connection(owner,route,mode,scope)",ribbons)
        self.assertIn("local TARGET_SPAN=3.6",ribbons)
        self.assertIn("local ANGLES,CELL,COLS=128,64,16",ribbons)
        self.assertIn("shift={(a.x+b.x)*16,(a.y+b.y)*16}",ribbons)
        self.assertIn("scale=d*32/UNIT",ribbons)
        self.assertIn("local ROUTE_LIMIT,LAYER_BUDGET=128,2400",ribbons)
        self.assertIn("if sprite.filename==SHEET then return 0 end",ribbons)
        self.assertIn("function M.data_final_fixes(owner)",ribbons)
        self.assertNotIn("rendered_span",ribbons)
        self.assertNotIn("directional-strokes.png\"}",ribbons)
        self.assertNotIn("script.on_event",ribbons)


    def test_aegis_inner_routes_are_colored_without_duplicate_travel_links(self):
        overlay=source("prototypes/system/route_highlights.lua")
        ribbons=source("prototypes/system/route_ribbons.lua")
        bellicos=source("prototypes/system/bellicos.lua")

        # Regression: the old blanket native_aegis_corridor filter was
        # responsible for the two grey connections in the user's starmap.
        self.assertNotIn("native_aegis_corridor(route)",ribbons)
        self.assertIn("local function aegis_spine(route)",overlay)
        self.assertIn('normalized=="nearbellicosorbit"',overlay)
        self.assertIn('normalized=="bellicosnearorbit"',overlay)
        self.assertIn('normalized:find("warden",1,true)',overlay)
        self.assertIn("if aegis_rim(route) or aegis_spine(route)",overlay)
        self.assertIn("or aegis_rim(route) or aegis_spine(route)",overlay)
        self.assertIn("or owner.is_aegis_spine(route)",ribbons)

        # Uses the single retained native straight-line connection.
        self.assertIn('route.shape="line"',bellicos)
        self.assertIn('local sample,length=owner.route_path(route,a,b)',ribbons)
        self.assertIn('if sprite.filename==SHEET then return 0 end',ribbons)
        self.assertIn("function bellicos.dedupe_internal_routes()",bellicos)
        self.assertIn("preserved.preserve_custom(keeper.route,duplicate.route)",bellicos)
        final=source("data-final-fixes.lua")
        self.assertLess(
            final.index('require("prototypes.system.bellicos").dedupe_internal_routes()'),
            final.index('require("prototypes.system.route_highlights").data_final_fixes()'))
        self.assertIn(
            'require("prototypes.system.bellicos").dedupe_internal_routes()',
            final.split('require("prototypes.system.bellicos").retire_far_gate()')[-1])

    def test_route_markers_use_ten_stage_quality_colors(self):
        overlay=source("prototypes/system/route_highlights.lua")
        ladder=source("scripts/razi_asteroid_difficulty.lua")
        tooltip=source("prototypes/system/route_intel.lua")
        self.assertIn("quality.route_color(M.route_color_level(route))",overlay)
        self.assertIn("function M.route_color_level(route)",overlay)
        self.assertNotIn("danger_colors",overlay)
        self.assertNotIn("threat_tier",overlay)
        self.assertIn("ladder.route_level(",source("prototypes/system/route_ribbons.lua"))
        self.assertIn("M.route_colors={",ladder)
        self.assertIn("M.route_color_hex={",ladder)
        self.assertIn("quality_levels.route_color_richtext(hi)",tooltip)
        self.assertIn('field("danger"',tooltip)
        self.assertNotIn('field("quality-hazard"',tooltip)
        self.assertNotIn("filename=SHEET",overlay)

    def test_keep_native_icons_and_hover_data(self):
        self.assertIn("custom_tooltip_fields",
                      source("prototypes/system/route_intel.lua"))
        self.assertIn("! space-route-overlay",
                      json.loads(source("info.json"))["dependencies"])
        self.assertTrue((ROOT/"graphics/icons/routes/asteroid-route.png").exists())
        self.assertTrue((ROOT/"graphics/route-highlights/route-ribbons.png").exists())
        self.assertTrue((ROOT/"scripts/generate_route_ribbons.js").exists())
        settings=source("settings.lua")
        for key in ("razi-route-overlay-mode","razi-route-overlay-scope"):
            self.assertIn(key,settings)
        self.assertIn('default_value="danger"',settings)
        self.assertIn('default_value="all",allowed_values={"major","all"}',settings)

if __name__=="__main__":
    unittest.main()
