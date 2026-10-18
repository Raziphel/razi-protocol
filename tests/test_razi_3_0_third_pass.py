"""Pass 3: optional factory partnership integrity and player-facing links."""
from pathlib import Path
import unittest

from scripts.audit_industry_portfolio import analyze, catalog

ROOT=Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT/path).read_text(encoding="utf-8")


def fixture():
    return {"raw":{
        "technology":{
            "razi-frontier-sample":{
                "effects":[{"type":"unlock-recipe","recipe":"razi-frontier-sample"}],
                "unit":{"ingredients":[["calidus-tech-card",1]]},
                "prerequisites":["planet-discovery-moshine"]}},
        "recipe":{
            "razi-frontier-sample":{
                "enabled":False,
                "categories":["crafting"],
                "allow_productivity":False,
                "auto_recycle":False,
                "ingredients":[{"type":"item","name":"bioflux","amount":2}],
                "results":[{"type":"item","name":"silicon-cell","amount":5}]}},
        "lab":{"advanced":{"inputs":["calidus-tech-card"]}},
        "assembling-machine":{"machine":{"crafting_categories":["crafting"]}}
    }}


class IndustrialPortfolioTests(unittest.TestCase):
    def test_catalog_is_sourced_from_existing_quest_definitions(self):
        entries=catalog()
        self.assertEqual(len(entries),31)
        self.assertEqual(len(set(entries.values())),31)
        self.assertIn("alliance-frontier-moshine-silicon",entries)

    def test_safe_recipe_is_a_valid_candidate_not_proven_profitable(self):
        report=analyze(fixture(),{"sample":"razi-frontier-sample"})
        self.assertEqual(report["counts"]["verified-prototype-shape"],1)
        self.assertEqual(report["counts"]["review"],0)
        self.assertEqual(report["rows"][0]["ingredient_types"],["item"])
        self.assertTrue(report["lab_catalog_present"])
        self.assertTrue(report["machine_catalog_present"])

    def test_missing_optional_mod_is_not_a_hard_failure(self):
        report=analyze(fixture(),{
            "present":"razi-frontier-sample",
            "uninstalled":"razi-not-installed"})
        self.assertEqual(report["registered"],1)
        self.assertEqual(report["counts"]["not-registered"],1)
        self.assertEqual(report["counts"]["review"],0)

    def test_unlock_crafting_and_freight_warnings(self):
        raw=fixture()
        recipe=raw["raw"]["recipe"]["razi-frontier-sample"]
        recipe["allow_productivity"]=True
        recipe["results"].append({"type":"item","name":"bioflux","amount":1})
        raw["raw"]["technology"]["razi-frontier-sample"]["effects"]=[]
        result=analyze(raw,{"sample":"razi-frontier-sample"})
        self.assertEqual(result["counts"]["review"],1)
        issues=result["rows"][0]["issues"]
        self.assertIn("premium-recipe-allows-productivity",issues)
        self.assertIn("self-consuming-output",issues)
        self.assertIn("missing-own-recipe-unlock",issues)

    def test_native_byproduct_guards_skip_nondeterministic_templates(self):
        engine=source("prototypes/compat/planet_production_exchanges.lua")
        self.assertIn("for _, result in ipairs(base.results) do",engine)
        self.assertIn('type(result.amount)~="number"',engine)
        self.assertIn("result.amount_min~=nil or result.amount_max~=nil",engine)
        self.assertIn("result.probability~=nil",engine)
        self.assertIn("product.amount = product.amount * rule.batch",engine)

    def test_cargo_network_uses_installed_prototypes_and_existing_journal(self):
        module=source("scripts/razi_industry_portfolio.lua")
        cargo=source("scripts/galactic_trade.lua")
        self.assertIn('require("scripts.razi_journal_industry")',module)
        self.assertIn("prototypes and prototypes.recipe",module)
        self.assertIn("cargo.state(tech)",module)
        self.assertIn("portfolio.snapshot(player.force,8)",cargo)
        self.assertIn('razi_journal_action="guidance-select"',cargo)
        self.assertNotIn("script.on_nth_tick",module)
        self.assertNotIn("player.insert(",cargo)


if __name__=="__main__":
    unittest.main()
