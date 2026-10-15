"""Static contract for optional planet recovery while preserving core safety."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class OptionalRecovery(unittest.TestCase):
    def test_new_worlds_are_manual_opt_in_only(self):
        deps=json.loads(source("info.json"))["dependencies"]
        for dep in ("nulla >= 1.0.2", "PlanetAthos >= 1.1.3"):
            self.assertIn(dep,deps)
            self.assertNotIn("+ "+dep,deps)
        self.assertIn("! biological-machines-planet-wit",deps)
        self.assertIn("! outer-rim",deps)

    def test_source_fix_is_early_and_no_fake_furnace(self):
        updates=source("data-updates.lua")
        hook='require("prototypes.compat.nulla_guard").data_updates()'
        self.assertIn(hook,updates)
        self.assertIn('require("prototypes.compat.athos_cycle_guard").repair()',updates)
        early=source("data.lua")
        self.assertIn('require("prototypes.compat.athos_cycle_guard").repair("before-athos-data-updates")',early)
        # Every mod's data.lua precedes PlanetAthos's data-updates.lua.
        self.assertGreater(early.index('repair("before-athos-data-updates")'),
                           early.index('require "prototypes.technology.asteroid_belts"'))
        self.assertTrue(early.rstrip().endswith(
            'require("prototypes.compat.athos_cycle_guard").repair("before-athos-data-updates")'))
        self.assertIn('stage=stage or "late"',
                      source("prototypes/compat/athos_cycle_guard.lua"))
        self.assertNotIn('["electric-furnace"]=',source("prototypes/compat/nulla_guard.lua"))
        self.assertIn('pcall(require,"__nulla__/lib")',source("prototypes/compat/nulla_guard.lua"))
        self.assertIn('if type(prototype)~="table" then return end',source("prototypes/compat/nulla_guard.lua"))

    def test_late_research_guard_is_source_scoped(self):
        fixes=source("data-final-fixes.lua")
        self.assertIn('require("prototypes.compat.athos_cycle_guard").repair()',fixes)
        module=source("prototypes/compat/athos_cycle_guard.lua")
        self.assertIn('if owned(name) then',module)
        self.assertIn('if in_cycle[parent] then',module)
        self.assertIn('Unrelated cycle left unchanged:',module)
        self.assertIn('child="space-platform-thruster",parent="space-science-pack"',module)
        self.assertIn('child="nyxaris-discovery",parent="lithium-processing"',module)
        self.assertIn('known_bootstrap_edge(techs,in_cycle)',module)
        self.assertIn('if not in_cycle[witness]',module)
        self.assertIn('M.bootstrap_repairs=bootstrap_repairs',module)
        self.assertIn('M.find_cycle=find_cycle',module)
        self.assertIn('{"athos","muria",24000,"cryogenic"}',source("prototypes/system/route_authority.lua"))
        self.assertIn('{"planet","athos","vespera",33,0.565}',source("prototypes/system/galaxy_layout.lua"))

if __name__=="__main__":
    unittest.main()
