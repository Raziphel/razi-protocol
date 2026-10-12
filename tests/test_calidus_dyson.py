"""Static checks on Calidus Dyson engineering and source ownership."""
from pathlib import Path
import json
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):
    return (ROOT/p).read_text(encoding="utf8")
class DysonIntegrationTests(unittest.TestCase):
    def test_explicit_required_21_source_mods(self):
        deps=json.loads(read("info.json"))["dependencies"]
        self.assertIn("slp-dyson-sphere-reworked-fork >= 1.0.5",deps)
        self.assertIn("k2-dyson-sphere-rebalance >= 0.1.2",deps)
        self.assertLess(deps.index("slp-dyson-sphere-reworked-fork >= 1.0.5"),
                        deps.index("k2-dyson-sphere-rebalance >= 0.1.2"))
    def test_native_satellite_control_not_forked(self):
        src=read("prototypes/compat/calidus_dyson.lua")
        self.assertIn("planet-discovery-sunorbit",src)
        self.assertIn("slp-solar-system-sun2",src)
        self.assertIn("slp-dyson-sphere-grounded",src)
        self.assertIn("ds-energy-loader-mk3",src)
        self.assertIn('effect.type=="unlock-space-location"',src)
        self.assertIn("depends(prerequisite,target)",src)
        self.assertNotIn("script.on_event",src)
        self.assertNotIn("on_nth_tick",src)
        self.assertNotIn("slp-sun-science-pack",src)
        self.assertNotIn("data.raw.recipe[",src)
    def test_single_data_stage_registration(self):
        src=read("data-final-fixes.lua")
        for action in ("data_final_fixes","connect_calidus"):
            self.assertEqual(src.count(
               'require("prototypes.compat.calidus_dyson").'+action+'()'),1)
        self.assertLess(src.index(
          'require("prototypes.compat.calidus_dyson").data_final_fixes()'),
          src.index(
          'require("prototypes.compat.calidus_dyson").connect_calidus()'))
    def test_map_ui_and_localization(self):
        script=read("scripts/galactic_operations.lua")
        self.assertIn('add_button(tabs,L("dyson-tab"),"tab","dyson")',script)
        self.assertIn('if p.tab=="dyson" then dyson.render(body,player);return end',script)
        lang=read("locale/en/galactic_operations.cfg")
        self.assertIn("dyson-stage-progress=",lang)
        self.assertIn("dyson-satellites=",lang)
        self.assertIn("dyson-safety=",lang)
        for key in ("razi-dyson-milestone-weave","razi-dyson-calidus-layout"):
            self.assertIn(key,read("settings.lua"))
            self.assertIn(key+"=",read("locale/en/settings.cfg"))
if __name__=="__main__":
    unittest.main()
