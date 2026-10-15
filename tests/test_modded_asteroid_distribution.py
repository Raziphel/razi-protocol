"""Static compatibility checks for original mod asteroid families."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

def text(path):
    return (ROOT/path).read_text(encoding="utf-8")

class ModdedAsteroidDistributionTests(unittest.TestCase):
    def test_preserves_originals_and_requires_real_prototypes(self):
        source=text("prototypes/system/modded_asteroid_distribution.lua")
        self.assertIn('data.raw["asteroid-chunk"]',source)
        self.assertIn('data.raw.asteroid',source)
        self.assertIn('has_definition(source,name)',source)
        self.assertIn('local result={}',source)
        self.assertIn('done[route]=true',source)
        self.assertIn('if has_enemy(name) then add(name,"entity",rate,"auric") end',source)
        self.assertNotIn('data:extend(',source)
        self.assertNotIn('script.on_event',source)

    def test_imersite_midgame_and_auric_late_game_only(self):
        source=text("prototypes/system/modded_asteroid_distribution.lua")
        self.assertIn('"imersite-asteroid-chunk","imersium-asteroid-chunk"',source)
        self.assertIn('"asteroid-belt-inner-edge"',source)
        self.assertIn('"asteroid-belt-outer-edge"',source)
        self.assertIn('has_endpoint(route,"aquilo")',source)
        self.assertIn('has_endpoint(route,"fulgora")',source)
        self.assertIn('has_endpoint(route,"secretas")',source)
        self.assertIn('has_endpoint(route,"solar-system-edge")',source)
        self.assertIn('size=="huge" and stage>=10',source)
        self.assertIn('add_orbit_chunk("fulgora",imersite,.0010)',source)
        self.assertNotIn('add_orbit_chunk("nauvis"',source)
        self.assertNotIn('add("foliax-charged-promethium',source)

    def test_auric_gradient_tracks_secretas_not_middle_of_space(self):
        source=text("prototypes/system/modded_asteroid_distribution.lua")
        self.assertIn('local toward=route.to=="secretas"',source)
        self.assertIn('local near_moon=',source)
        self.assertIn('local weights={1.00,.94,.72,.37,.14,.06}',source)
        self.assertIn('local weight=weights[toward and (7-index) or index]',source)
        self.assertIn('source=="auric"',source)
        self.assertIn('math.max(weight,.52)',source)

    def test_aquilo_priority_over_fulgora_trace(self):
        source=text("prototypes/system/modded_asteroid_distribution.lua")
        self.assertLess(
            source.index('if has_endpoint(route,"aquilo") then return .008'),
            source.index('if has_endpoint(route,"fulgora") then return .0010'))
        self.assertIn('Modified routes:',source)

    def test_installed_prototype_audit_without_random_spawning(self):
        source=text("prototypes/system/modded_asteroid_distribution.lua")
        self.assertIn('function M.data_final_fixes()',source)
        self.assertIn('M.classify_unknowns=classify_unknowns',source)
        self.assertIn('Discovered families:',source)

    def test_runs_after_route_authority_before_quality_carriers(self):
        final=text("data-final-fixes.lua")
        integrate='require("prototypes.system.modded_asteroid_distribution").data_final_fixes()'
        self.assertIn(integrate,final)
        self.assertLess(
            final.index('require("prototypes.system.route_authority").data_final_fixes()'),
            final.index(integrate))
        self.assertLess(
            final.index(integrate),
            final.index('require("prototypes.system.route_intel").data_final_fixes()'))
        self.assertLess(
            final.index(integrate),
            final.index('require("prototypes.system.quality_asteroids").data_final_fixes()'))

    def test_quality_support_kept_for_custom_hostiles(self):
        source=text("prototypes/system/quality_asteroids.lua")
        self.assertIn("is_enemy(entry,entities)",source)
        self.assertIn("proxy_for(entry.asteroid,entities)",source)
        self.assertIn('def.asteroid=proxy',source)
        self.assertIn('def.type="entity"',source)

if __name__=="__main__":
    unittest.main()
