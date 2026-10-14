"""Razi-owned, data-stage starmap route renderer regressions."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(name):
    return (ROOT/name).read_text(encoding="utf-8")

class BuiltInOverlayTests(unittest.TestCase):
    def test_no_external_overlay_dependency(self):
        info=json.loads(read("info.json"))
        self.assertEqual(info["factorio_version"],"2.1")
        self.assertIn("! space-route-overlay",info["dependencies"])
        self.assertNotIn("~ space-route-overlay >= 0.2.7",info["dependencies"])
        self.assertFalse(any(d.startswith("? space-route-overlay") or
            d.startswith("space-route-overlay >=")
            for d in info["dependencies"]))

    def test_rendered_after_native_positions_and_route_tooltips(self):
        source=read("data-final-fixes.lua")
        layout='require("prototypes.system.galaxy_layout").confirm_critical_positions()'
        overlay='require("prototypes.system.route_highlights").data_final_fixes()'
        tooltips='require("prototypes.system.route_intel").data_final_fixes()'
        self.assertLess(source.index(tooltips),source.index(overlay))
        self.assertLess(source.index(layout),source.index(overlay))

    def test_builtin_style_switches_and_directional_atlas(self):
        settings=read("settings.lua")
        self.assertIn('name="razi-route-overlay-mode"',settings)
        self.assertIn('name="razi-route-overlay-scope"',settings)
        self.assertIn('default_value="danger"',settings)
        source=read("prototypes/system/route_highlights.lua")
        self.assertIn('local SHEET="__razi-protocol__/graphics/route-highlights/directional-strokes.png"',source)
        self.assertIn("local SEGMENT=6",source)
        self.assertIn("local LAYER_BUDGET=650",source)
        self.assertIn('local scope=startup["razi-route-overlay-scope"]',source)
        self.assertIn('hazards.color(route)',source)
        self.assertIn('if route.shape=="line" then',source)
        self.assertIn("if not cx then",source)
        self.assertIn("if abs(sweep)>.95 then return nil end",source)
        self.assertIn('trim=math.min(2.2/distance,.16)',source)
        self.assertIn('table.sort(names)',source)
        self.assertIn("if layer.filename==SHEET then return 0 end",source)

    def test_belt_navigational_palettes_are_specific_and_subtle(self):
        source=read("prototypes/system/route_highlights.lua")
        self.assertIn("local belt_strokes={",source)
        self.assertIn("vibrant={r=.76,g=.59,b=.95}",source)
        self.assertIn("vespera={r=.72,g=.84,b=.96}",source)
        self.assertIn("umbra={r=.97,g=.54,b=.41}",source)
        self.assertIn('a:find("razi%-vespera%-belt")',source)
        self.assertIn('a:find("razi%-umbra%-belt")',source)
        self.assertIn("if hazards.is_belt_crossing(route) then alpha=.37 end",source)
        self.assertIn('if mode~="chapter" then return hazards.color(route) end',source)

    def test_never_edit_real_routes_or_add_runtime_work(self):
        source=read("prototypes/system/route_highlights.lua")
        self.assertNotIn("data:extend",source)
        # Comparisons such as route.shape=="line" are read-only.
        # Reject assignments without mistaking equality checks for edits.
        self.assertNotRegex(source,r"route\\.(?:shape|length)\\s*=(?!=)")
        self.assertNotIn("script.on_event",source)
        self.assertNotIn("game.tick",source)
        self.assertNotIn('require("space-route-overlay")',source)
        self.assertTrue((ROOT/"graphics/route-highlights/directional-strokes.png").is_file())

if __name__=="__main__":
    unittest.main()
