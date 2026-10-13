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
    def test_read_only_receiver_bridge_and_caching(self):
        runtime=read("scripts/galactic_dyson_runtime.lua")
        self.assertIn('place_result',runtime)
        self.assertIn('force.get_entity_count(name)',runtime)
        self.assertIn('surface.count_entities_filtered{',runtime)
        self.assertIn('M.cache_ticks=600',runtime)
        self.assertIn('satellite_count=nil',runtime)
        self.assertIn('allocated_mw=nil',runtime)
        self.assertNotIn('script.on_nth_tick',runtime)
        self.assertNotIn('remote.call(',runtime)
        ui=read("scripts/galactic_dyson.lua")
        self.assertIn('runtime.snapshot(player.force)',ui)
        self.assertIn('razi-dyson-works-',ui)
        self.assertIn('dyson-source-telemetry-unknown',ui)
        ops=read("scripts/galactic_operations.lua")
        self.assertIn('dyson_runtime.invalidate(player.force)',ops)
    def test_small_static_gui_sprites_and_map_layers(self):
        sprite=read("prototypes/ui/dyson_stages.lua")
        self.assertEqual(sprite.count('{"survey"'),1)
        self.assertEqual(sprite.count('{"mastery"'),1)
        self.assertIn('scale=.5',sprite)
        self.assertIn('for stage=0,6 do',sprite)
        self.assertIn('x=stage*256',sprite)
        self.assertIn('calidus-dyson-stages.png',sprite)
        self.assertIn('calidus-star.png',
                      read("prototypes/system/calidus_sun.lua"))
        self.assertIn('prototypes.system.calidus_sun',
                      read("data-updates.lua"))
        backdrop=read("prototypes/system/starmap_background.lua")
        self.assertIn('razi-starmap-galactic-ornaments',backdrop)
        self.assertIn('system.name=="calidus" and 9.8',backdrop)
        self.assertIn('strength=.62',backdrop)
    def test_map_ui_and_localization(self):
        script=read("scripts/galactic_operations.lua")
        self.assertIn('add_button(tabs,L("dyson-tab"),"tab","dyson")',script)
        self.assertIn('if p.tab=="dyson" then dyson.render(body,player);return end',script)
        lang=read("locale/en/galactic_operations.cfg")
        self.assertIn("dyson-stage-progress=",lang)
        self.assertIn("dyson-art-stage=",lang)
        self.assertIn("dyson-map-progress=",lang)
        self.assertIn("M.on_dyson_research(event)",read("control.lua"))
        self.assertIn("on_dyson_research",script)
        self.assertIn("razi_ops_dyson_stage",script)
        self.assertIn("dyson-satellites=",lang)
        self.assertIn("dyson-safety=",lang)
        for key in ("razi-dyson-milestone-weave","razi-dyson-calidus-layout"):
            self.assertIn(key,read("settings.lua"))
            self.assertIn(key+"=",read("locale/en/settings.cfg"))
if __name__=="__main__":
    unittest.main()
