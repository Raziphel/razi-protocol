"""Catch Factorio GUI style crashes and distant Aegis starmap regressions."""
import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class ExpeditionRegressionTests(unittest.TestCase):
    def test_horizontal_flows_never_receive_vertical_spacing(self):
        lua=read("scripts/galactic_trade.lua")
        # Both narrow/regular layouts are built by the same Project click.
        self.assertIn('if narrow then\n      metadata.style.vertical_spacing=3',lua)
        self.assertIn('else\n      metadata.style.horizontal_spacing=12',lua)
        self.assertIn('if narrow then\n    actions.style.vertical_spacing=4',lua)
        self.assertIn('else\n    actions.style.horizontal_spacing=12',lua)

    def test_source_art_survives_before_planetslib_sprite_baking(self):
        lua=read("prototypes/system/bellicos.lua")
        self.assertIn("for key,value in pairs(body.orbit or {}) do",lua)
        self.assertIn("orbit[key]=value",lua)
        self.assertIn("for _,kind in ipairs",lua)
        self.assertIn("local function reconcile_baked_art()",lua)
        self.assertIn("local origin=target.parent_position",lua)
        self.assertIn("function bellicos.data_updates()",lua)
        self.assertIn('require("prototypes.system.bellicos").data_updates()',read("data-updates.lua"))
        cleanup=read("prototypes/system/galaxy_layout.lua")
        self.assertIn('local bellicos_art=name=="pulsar"',cleanup)
        self.assertIn('deep_space_no_rings[name] and not bellicos_art',cleanup)

    def test_green_beetlejuice_and_far_north_sky(self):
        lua=read("prototypes/system/starmap_background.lua")
        self.assertIn('tint={r=.18,g=1,b=.28}',lua)
        self.assertNotIn('tint={r=1,g=.46,b=.61}',lua)
        self.assertIn('tile(0,col,variant,sky_exposure[6][col]*.94)',lua)
        self.assertIn('local x,y=layout.anchor_position("solar-system-edge")',lua)
        self.assertIn('name="bellicos",tint=',lua)

if __name__=="__main__":
    unittest.main()
