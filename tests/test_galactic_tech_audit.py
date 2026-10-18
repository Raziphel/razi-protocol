"""Synthetic research-graph regression; no Factorio installation needed."""
import importlib.util
from pathlib import Path
import unittest

PATH=Path(__file__).resolve().parents[1]/"scripts"/"audit_tech_tree.py"
SPEC=importlib.util.spec_from_file_location("audit_tech_tree",PATH)
MODULE=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

class TechGraphAuditTests(unittest.TestCase):
    def test_empty_graph(self):
        s=MODULE.analyze({"technology":{},"planet":{}})
        self.assertEqual(s["prerequisite_cycles"],[])
        self.assertEqual(s["missing_prerequisites"],{})
    def test_cycle_missing_and_incompatible_lab(self):
        s=MODULE.analyze({"technology":{
            "a":{"prerequisites":["b"],"unit":{"ingredients":[["a-pack",1],["b-pack",1]]}},
            "b":{"prerequisites":["a"]},
            "c":{"prerequisites":["unknown"]}},
            "lab":{"test":{"inputs":["a-pack"]}},
            "planet":{"nauvis":{}}})
        self.assertEqual(len(s["prerequisite_cycles"]),1)
        self.assertEqual(s["missing_prerequisites"]["c"],["unknown"])
        self.assertIn("a",s["unresearchable_science_combinations"])
        self.assertEqual(s["locations_without_research_unlock"],["nauvis"])
    def test_valid_lab_and_normal_discovery(self):
        s=MODULE.analyze({"technology":{"discover":{"effects":[
          {"type":"unlock-space-location","space_location":"x"}],
          "unit":{"ingredients":[{"name":"science","amount":1}]}}},
          "lab":{"lab":{"inputs":["science"]}},"planet":{"x":{}}})
        self.assertEqual(s["locations_without_research_unlock"],[])
        self.assertEqual(s["unresearchable_science_combinations"],{})
    def test_missing_research_items_and_recipe_unlocks(self):
        s=MODULE.analyze({"technology":{
            "razi-test":{
                "unit":{"ingredients":[["existent-pack",1],["lost-pack",1]]},
                "effects":[{"type":"unlock-recipe","recipe":"razi-missing-recipe"}]
            },
            "native-test":{
                "effects":[{"type":"unlock-recipe","recipe":"native-external"}]
            }},
            "tool":{"existent-pack":{}},
            "recipe":{"real-recipe":{}}})
        self.assertEqual(s["research_science_items_missing"]["razi-test"],
                         ["lost-pack"])
        self.assertEqual(s["razi_unlock_effect_recipes_missing"]["razi-test"],
                         ["razi-missing-recipe"])
        self.assertNotIn("native-test",s["razi_unlock_effect_recipes_missing"])

    def test_partial_item_catalog_skips_missing_science_warning(self):
        s=MODULE.analyze({"technology":{
            "sample":{"unit":{"ingredients":[["not-in-partial-fixture",1]]}}}})
        self.assertEqual(s["research_science_items_missing"],{})
        self.assertFalse(s["science_item_catalog_available"])

    def test_planetary_finale_coverage_reports_gaps(self):
        fixture={"technology":{
          "razi-stable-intergalactic-singularity":{
            "prerequisites":["planet-discovery-fulgora"]},
          "planet-discovery-fulgora":{"effects":[
            {"type":"unlock-space-location","space_location":"fulgora"}]},
          "moon-discovery-cerys":{"effects":[
            {"type":"unlock-space-location","space_location":"cerys"}]}},
          "planet":{"fulgora":{},"cerys":{},"bm-balack":{}}}
        s=MODULE.analyze(fixture)["planetary_milestone_coverage"]
        self.assertEqual(s["catalogued_worlds_present"],3)
        self.assertEqual(s["on_singularity_path"],1)
        self.assertIn("cerys",s["missing_from_finale"])
        self.assertIn("bm-balack",s["no_native_research_unlock"])

if __name__=="__main__":
    unittest.main()
