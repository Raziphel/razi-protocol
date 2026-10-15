"""Static contracts for Razi's source-safe three-system asteroid belts."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")


class BeltEcologyTests(unittest.TestCase):
    def test_replaces_old_mod_without_adding_a_dependency(self):
        info=json.loads(read("info.json"))
        self.assertIn("! AsteroidBelt",info["dependencies"])
        self.assertNotIn("AsteroidBelt >= 1.2.11",info["dependencies"])
        self.assertIn('require "prototypes.system.asteroid_belts"',read("data.lua"))

    def test_umbra_and_legacy_vibrant_belts_are_real(self):
        belts=read("prototypes/system/asteroid_belts.lua")
        tech=read("prototypes/technology/asteroid_belts.lua")
        reconcile=read("prototypes/system/route_reconcile.lua")
        final=read("prototypes/system/belt_expeditions.lua")
        for system in ("vibrant","umbra"):
            self.assertIn('system="'+system+'"',belts)
            self.assertIn('system="'+system+'"',final)
        for marker in ("razi-umbra-belt-inner",
                       "razi-umbra-belt-outer"):
            self.assertIn(marker,reconcile)
        self.assertIn('name="space-discovery-asteroid-belt"',tech)
        self.assertNotIn('razi-vespera-belt',belts+tech+reconcile+final)
        self.assertIn('name="asteroid-belt-inner-edge-asteroid-belt-outer-edge"',belts)
        self.assertIn('profiles.enrich_belt_crossing(route,belt.system)',final)

    def test_real_harvesting_not_runtime_spawns(self):
        profiles=read("prototypes/system/asteroid_profiles.lua")
        final=read("prototypes/system/belt_expeditions.lua")
        self.assertIn("function M.belt_edge_resources(intensity,system)",profiles)
        self.assertIn("function M.enrich_belt_crossing(route,system)",profiles)
        self.assertIn('["asteroid-chunk"]',profiles)
        self.assertIn("type=\"asteroid-chunk\"",profiles)
        self.assertIn("original and copy(original)",profiles)
        self.assertIn('enriched[route]=true',profiles)
        self.assertNotIn("script.on_event",final)
        self.assertNotIn("script.on_nth_tick",final)

    def test_final_pass_waits_for_authoritative_route_cleanup(self):
        entry=read("data-final-fixes.lua")
        a=entry.index('require("prototypes.system.route_authority").data_final_fixes()')
        b=entry.index('require("prototypes.system.belt_expeditions").data_final_fixes()')
        c=entry.index('require("prototypes.system.route_icons").data_final_fixes()')
        self.assertLess(a,b)
        self.assertLess(b,c)

if __name__=="__main__":
    unittest.main()
