"""Structural safeguards for Razi's Aquilo research power pacing."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class AquiloBreakthroughTests(unittest.TestCase):
    def test_staging_runs_after_research_changes(self):
        loader = read("data-final-fixes.lua")
        anchor = 'require("prototypes.technology.aquilo_breakthroughs").data_final_fixes()'
        self.assertEqual(loader.count(anchor), 1)
        self.assertLess(loader.index(
            'require("prototypes.technology.distributed_industry").data_final_fixes()'),
            loader.index(anchor))
        self.assertLess(loader.index(anchor), loader.index(
            'require("prototypes.compat.prototype_sanity").restore_secretas_science_bootstrap()'))

    def test_default_on_and_localized_opt_out(self):
        settings = read("settings.lua")
        self.assertIn('startup_toggle("razi-stage-aquilo-breakthroughs"', settings)
        locale = read("locale/en/settings.cfg")
        self.assertEqual(locale.count("razi-stage-aquilo-breakthroughs="), 2)

    def test_only_optional_endgame_technologies_are_retimed(self):
        source = read("prototypes/technology/aquilo_breakthroughs.lua")
        for tech in ("foundation", "fusion-reactor", "legendary-quality"):
            self.assertIn('tech = "' + tech + '"', source)
        for required in ("planet-discovery-paracelsin", "planet-discovery-maraxsis",
                         "planet-discovery-cubium", "planet-discovery-tenebris",
                         "razi-outer-frontier-mastery"):
            self.assertIn('"' + required + '"', source)
        self.assertIn('reaches(techs, parent, rule.tech)', source)
        self.assertIn('option.value == false', source)
        for prohibited in ("data:extend", "script.on_tick", "research_trigger =",
                           "target.unit =", "target.effects ="):
            self.assertNotIn(prohibited, source)

    def test_engine_behavior_has_lua_fixture(self):
        fixture = read("tests/lua/test_aquilo_breakthroughs.lua")
        self.assertIn("M.data_final_fixes()", fixture)
        self.assertIn("M.apply(cycle, M.rules[2])", fixture)
        self.assertIn("M.apply(missing, M.rules[1])", fixture)
        self.assertIn("value = false", fixture)


if __name__ == "__main__":
    unittest.main()
