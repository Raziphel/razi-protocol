"""Protect opt-in asteroid performance experiments against defaults or regressions."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def get(path):
    return (ROOT/path).read_text(encoding="utf-8")

OPTIONS=(
    "razi-performance-asteroid-particles",
    "razi-performance-weapon-particles",
    "razi-performance-reduced-fragments",
    "razi-performance-outer-hostile-density"
)

class AsteroidPerformanceContracts(unittest.TestCase):
    def test_all_four_independently_off_by_default(self):
        settings=get("settings.lua")
        import re
        for option in OPTIONS:
            self.assertRegex(settings,
                rf'name="{option}"\s*,\s*setting_type="startup",default_value=false')
            self.assertIn(option+"=",get("locale/en/settings.cfg"))

    def test_native_final_stage_only_after_quality_and_auric(self):
        final=get("data-final-fixes.lua")
        perf='require("prototypes.system.asteroid_performance").data_final_fixes()'
        self.assertIn(perf,final)
        self.assertLess(final.index("modded_asteroid_distribution"),final.index(perf))
        self.assertLess(final.index("quality_asteroids"),final.index(perf))
        self.assertTrue(final.rstrip().endswith(perf))

    def test_no_tick_handlers_and_performance_guards(self):
        src=get("prototypes/system/asteroid_performance.lua")
        self.assertIn('if not (debris or weapon or fragments or density) then return 0 end',src)
        self.assertIn('if already then return 0 end',src)
        self.assertIn('for _,group in ipairs({"asteroid","asteroid-chunk"})',src)
        self.assertIn('create-trivial-smoke',src)
        self.assertIn('create-particle',src)
        self.assertIn('create-asteroid-chunk',src)
        self.assertIn('if ladder.location_level(name)>=8 then apply(location) end',src)
        self.assertNotIn("script.on_event",src)
        self.assertNotIn("on_tick",src)
        self.assertNotIn("data:extend({",src)

    def test_effects_are_preserved_when_opted_out(self):
        src=get("prototypes/system/asteroid_performance.lua")
        self.assertIn('return item~=nil and item.value==true',src)
        self.assertIn('if not (debris or weapon or fragments or density) then return 0 end',src)
        self.assertIn('return changed and rebuilt or node,removed,halved',src)
        self.assertIn('if r>0 or f>0 then proto[key]=altered end',src)

    def test_native_fragments_and_chunks_do_not_cross(self):
        src=get("prototypes/system/asteroid_performance.lua")
        self.assertIn('({metallic=true,carbonic=true,oxide=true,promethium=true})',src)
        self.assertIn('changed.probability=(changed.probability or 1)*.5',src)
        self.assertIn('asteroid[entry.asteroid]',src)
        self.assertIn('edited.probability=edited.probability*.72',src)
        self.assertIn('if peak>=8 then apply(route) end',src)
        self.assertNotIn("minable.results",src)
        self.assertNotIn("modded_asteroid_distribution",src)

if __name__=="__main__":
    unittest.main()
