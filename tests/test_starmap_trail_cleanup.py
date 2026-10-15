"""Guard the absolute final render-stage cleanup against regressions."""
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
class StarmapTrailCleanupTests(unittest.TestCase):
    def test_must_be_the_last_data_final_fixes_pass(self):
        final=read("data-final-fixes.lua").strip()
        self.assertTrue(final.endswith('require("prototypes.system.starmap_trail_cleanup").data_final_fixes()'))
        self.assertGreater(final.index('starmap_trail_cleanup'),
                           final.index('route_highlights").data_final_fixes()'))
    def test_graphics_only_restriction(self):
        src=read("prototypes/system/starmap_trail_cleanup.lua")
        self.assertIn('"__orbital-cannon__/"',src)
        self.assertIn('"__orbital_cannon__/"',src)
        self.assertIn('layer.planetslib_orbit_name',src)
        self.assertIn('table.remove(layers,i)',src)
        self.assertIn('type(layer.filenames)=="table"',src)
        self.assertIn('layer.stripes',src)
        self.assertNotIn('routes[',src)
        self.assertNotIn('data:extend',src)
        self.assertNotIn('script.on_',src)
        self.assertNotIn('game.tick',src)
    def test_no_dependency_or_modlist_changes(self):
        info=json.loads(read("info.json"))
        self.assertGreaterEqual(tuple(map(int,info["version"].split("."))),(2,1,88))
        self.assertIn("carna >= 0.3.22",info["dependencies"])
        self.assertIn("Velora >= 2.2.2",info["dependencies"])
        self.assertFalse(any(d=="! orbital-cannon" for d in info["dependencies"]))
if __name__=="__main__": unittest.main()
