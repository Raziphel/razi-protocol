"""Campaign-wide route danger coverage, including endgame annexes.

This static regression reviews every authored route specification and all
major optional terminal locations. It intentionally runs without Factorio
or the enormous dependency modpack, complementing the Lua runtime tests.
"""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def level_map():
    text=read("scripts/razi_asteroid_difficulty.lua")
    raw=text.split("local exceptional={",1)[1].split("\n}",1)[0]
    found={}
    for name,rank in re.findall(r'\["([^"]+)"\]\s*=\s*(\d+)',raw):
        found[name]=int(rank)
    for name,rank in re.findall(r'(?m)^\s*([a-z][a-z0-9_-]+)\s*=\s*(\d+)',raw):
        found[name]=int(rank)
    return found

def curated():
    raw=read("prototypes/system/route_reconcile.lua")
    raw=raw.split("local route_specifications = {",1)[1]
    raw=raw.split("-- Only Umbra keeps",1)[0]
    return [(a,b,int(km),profile) for a,b,km,profile in
        re.findall(r'\{"([^"]+)",\s*"([^"]+)",\s*(\d+),\s*"([^"]+)"\}',raw)]

class RouteDifficultyProgression(unittest.TestCase):
    def test_complete_curated_network(self):
        levels=level_map()
        rows=curated()
        self.assertGreaterEqual(len(rows),50)
        worlds={name for a,b,_,_ in rows for name in (a,b)}
        self.assertGreaterEqual(len(worlds),41)
        self.assertEqual(sorted(worlds-set(levels)),[])
        self.assertEqual({max(levels[a],levels[b]) for a,b,_,_ in rows},
                         set(range(1,11)))

    def test_late_game_has_no_midgame_reset(self):
        levels=level_map()
        for name in ("aquilo","maraxsis","athos"):
            self.assertGreaterEqual(levels[name],7,name)
        for name in ("secretas","frozeta","linox-planet_linox"):
            self.assertGreaterEqual(levels[name],8,name)
        for name in ("vesta","obsidiax","crucible-orbit"):
            self.assertGreaterEqual(levels[name],9,name)
        for name in ("solar-system-edge","nexus","black-hole",
                     "shattered-planet","oort-cloud","sol",
                     "calidus-bellicos-stargate-bellicos",
                     "aegis-outer-edge","point-warden",
                     "skewer_lost_beyond"):
            self.assertEqual(levels[name],10,name)
        self.assertEqual(levels["calidus-bellicos-stargate-calidus"],6)

    def test_optional_world_graph_shared_with_runtime(self):
        difficulty=read("scripts/razi_asteroid_difficulty.lua")
        runtime=read("scripts/razi_quality_asteroids.lua")
        data_final=read("data-final-fixes.lua")
        for fragment in ("function M.prepare_routes(routes)",
                         "table.sort(edges","levels=next_levels",
                         "inferred[name]=level"):
            self.assertIn(fragment,difficulty)
        self.assertIn("engine.prepare_routes(prototypes.space_connection)",runtime)
        self.assertIn('require("scripts.razi_asteroid_difficulty").prepare_routes(',
                      data_final)
        self.assertLess(data_final.index("prepare_routes("),
                        data_final.index('require("prototypes.system.route_intel")'))

    def test_exact_native_2_1_arcs_and_color_gradient(self):
        overlay=read("prototypes/system/route_highlights.lua")
        renderer=read("prototypes/system/route_ribbons.lua")
        self.assertIn('if route.shape=="line" then',overlay)
        self.assertIn("if not cx then cx,cy=0,0 end",overlay)
        self.assertIn("ladder.route_level(",renderer)
        self.assertIn("local midpoint=(start+finish)/2",renderer)
        self.assertIn("local ROUTE_LIMIT,LAYER_BUDGET=128,2400",renderer)
        self.assertIn("shift={(a.x+b.x)*16,(a.y+b.y)*16}",renderer)
        self.assertNotIn("script.on_event",renderer)

if __name__=="__main__":
    unittest.main()
