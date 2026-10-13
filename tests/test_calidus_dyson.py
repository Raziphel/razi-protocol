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
        self.assertIn("survey=0",sprite)
        self.assertIn("mastery=6",sprite)
        self.assertIn('scale=.5',sprite)
        self.assertIn('for stage=0,6 do',sprite)
        self.assertIn('x=stage*256',sprite)
        self.assertIn('calidus-dyson-stages.png',sprite)
        self.assertIn('CalidusStar.png',
                      read("prototypes/system/calidus_sun.lua"))
        self.assertIn('prototypes.system.calidus_sun',
                      read("data-updates.lua"))
        layout=read("prototypes/system/galaxy_layout.lua")
        self.assertIn('proto.origin=nil',layout)
        self.assertIn('Khemia %s ABSOLUTE',layout)
        self.assertIn('body.draw_orbit==false',layout)
        self.assertTrue((ROOT/"graphics/icons/CalidusStar.png").is_file())
        compat=read("prototypes/compat/calidus_dyson.lua")
        self.assertIn('location.draw_orbit=false',compat)
        backdrop=read("prototypes/system/starmap_background.lua")
        self.assertIn('razi-starmap-galactic-ornaments',backdrop)
        self.assertIn('system.name=="calidus" and 2.1',backdrop)
        self.assertIn('strength=.38',backdrop)
        for filename,expected_width in (("calidus-dyson-stages.png",1792),):
            raw=(ROOT/"graphics/starmap/razi"/filename).read_bytes()
            self.assertEqual(raw[:8],b"\x89PNG\r\n\x1a\n")
            self.assertEqual(int.from_bytes(raw[16:20],"big"),expected_width)
            self.assertEqual(int.from_bytes(raw[20:24],"big"),256)
    def test_map_ui_and_localization(self):
        script=read("scripts/galactic_operations.lua")
        self.assertIn('{"dyson","dyson-tab"}',script)
        self.assertIn('if p.tab=="dyson" then dyson.render(body,player);return end',script)
        lang=read("locale/en/galactic_operations.cfg")
        self.assertIn("dyson-stage-progress=",lang)
        self.assertIn("dyson-art-stage=",lang)
        self.assertIn("dyson-map-progress=",lang)
        self.assertIn("galactic_operations.on_dyson_research(event)",
                      read("control.lua"))
        self.assertIn("on_dyson_research",script)
        self.assertIn("razi_ops_dyson_stage",script)
        self.assertIn("dyson-satellites=",lang)
        self.assertIn("dyson-safety=",lang)
        for key in ("razi-dyson-milestone-weave","razi-dyson-calidus-layout"):
            self.assertIn(key,read("settings.lua"))
            self.assertIn(key+"=",read("locale/en/settings.cfg"))
if __name__=="__main__":
    unittest.main()
