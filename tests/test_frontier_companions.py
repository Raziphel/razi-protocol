"""Static/offline companion dependency and integration safeguards."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class CompanionIntegrationTests(unittest.TestCase):
    MODS={
        "Various_Cargo_Bays",
        "space-age-railway-expansion",
        "shield-generators",
        "CircuitLaunchableRockets",
        "CargoBayLimitResearch",
        "platform-logistics-overhaul"
    }
    def test_recommendations_not_requirements(self):
        info=json.loads(read("info.json"))
        deps=info["dependencies"]
        policy=json.loads(read("compat/dependency_policy.json"))["dependencies"]
        for mod in self.MODS:
            self.assertEqual(sum(s.startswith("+ "+mod+" >=") for s in deps),1)
            self.assertEqual(sum(row["mod"]==mod and row["type"]=="recommended"
                                 for row in policy),1)
            self.assertFalse(any(s.startswith(mod+" >=") for s in deps))
        self.assertFalse(any("orbital-cannon" in entry for entry in deps),
                         "Upstream requires only ~; that would force installation")
    def test_source_safe_research(self):
        src=read("prototypes/compat/frontier_companions.lua")
        final=read("data-final-fixes.lua")
        self.assertIn('mods[M.sources.rail]',src)
        self.assertIn('mods[M.sources.shield]',src)
        self.assertIn('distributed.apply(raw,rule)',src)
        self.assertIn('if option and option.value==false then return end',src)
        self.assertIn('"vespera-tech-card"',src)
        self.assertIn('"beetlejuice-tech-card"',src)
        self.assertIn('"electromagnetic-science-pack"',src)
        self.assertNotIn('data:extend',src)
        self.assertNotIn('game.forces',src)
        self.assertLess(final.index("distributed_industry"),final.index(
            'require("prototypes.compat.frontier_companions")'))
    def test_catapult_opt_in_and_route_scope(self):
        source=read("prototypes/compat/orbital_catapult.lua")
        settings=read("settings.lua")
        self.assertIn('mods["orbital-cannon"]',source)
        self.assertIn('source=spec[2],target=spec[3]',source)
        self.assertIn('type="orbital-cannon-link"',source)
        self.assertIn('name="razi-orbital-catapult-local-links"',settings)
        self.assertIn('default_value=false',settings)
        self.assertNotIn('rubia',source)
        self.assertNotIn('razi-vespera-belt-inner',source)
        self.assertIn('require("prototypes.compat.orbital_catapult").data()',
                      read("data.lua"))
    def test_journal_and_configuration_do_not_require_mods(self):
        trade=read("scripts/galactic_trade.lua")
        self.assertIn('script and script.active_mods or {}',trade)
        self.assertIn('companion-ledger-heading',trade)
        self.assertIn('razi-companion-science-weave',
                      read("locale/en/settings.cfg"))
        self.assertNotIn('script.on_tick',trade)
        self.assertNotIn('remote.call',trade)

if __name__=="__main__":
    unittest.main()
