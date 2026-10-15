"""Contracts for the first-party quality asteroid escalation system."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class QualityAsteroidContracts(unittest.TestCase):
    def test_native_dependencies_and_load_order(self):
        info=json.loads(read("info.json"))
        self.assertIn("! quality-asteroids",info["dependencies"])
        self.assertIn("! Quality-Asteroids-Expanded",info["dependencies"])
        final=read("data-final-fixes.lua")
        install='require("prototypes.system.quality_asteroids").data_final_fixes()'
        self.assertIn(install,final)
        for previous in (
            'require("prototypes.system.route_authority").data_final_fixes()',
            'require("prototypes.system.route_intel").data_final_fixes()',
            'require("prototypes.system.route_highlights").data_final_fixes()'):
            self.assertLess(final.index(previous),final.index(install))

    def test_event_driven_once_per_asteroid(self):
        source=read("control.lua")
        runtime=read("scripts/razi_quality_asteroids.lua")
        self.assertIn("defines.events.on_script_trigger_effect",source)
        self.assertIn("quality_asteroids.on_script_trigger_effect",source)
        self.assertIn("source.destroy()",runtime)
        self.assertIn("created.valid",runtime)
        self.assertNotIn("on_nth_tick",runtime)
        self.assertNotIn("on_tick",runtime)
        self.assertNotIn("find_entities",runtime)
        self.assertNotIn("dying_trigger_effect",runtime)

    def test_ten_stage_quality_and_chunk_guards(self):
        ladder=read("scripts/razi_asteroid_difficulty.lua")
        prototype=read("prototypes/system/quality_asteroids.lua")
        self.assertIn('{"normal","uncommon","rare","epic","legendary"}',ladder)
        self.assertIn('{0,0,0,0,1}',ladder)
        self.assertIn('["deep-space"]=10',ladder)
        self.assertIn('("razi-quality-asteroids",true)',prototype)
        self.assertIn('def.type=="entity"',prototype)
        self.assertIn('def.type="entity"',prototype)
        self.assertIn('def.asteroid=proxy',prototype)
        self.assertIn('clone(entry)',prototype)
        self.assertIn('if not route.hidden',prototype)
        self.assertNotIn("dying_trigger_effect",prototype)

    def test_settings_and_tooltips(self):
        settings=read("settings.lua")
        self.assertIn('name="razi-quality-asteroids"',settings)
        self.assertIn('name="razi-asteroid-difficulty-scale"',settings)
        self.assertIn('allowed_values={"balanced","challenging","relentless"}',settings)
        route=read("prototypes/system/route_intel.lua")
        self.assertIn("quality_levels.route_range",route)
        self.assertIn('field("quality-hazard"',route)
        for key in ("quality-hazard=","quality-stages=","quality-stage="):
            self.assertIn(key,read("locale/en/routes.cfg"))
        for key in ("razi-quality-asteroids=","razi-asteroid-difficulty-scale="):
            self.assertIn(key,read("locale/en/settings.cfg"))

if __name__=="__main__":
    unittest.main()
