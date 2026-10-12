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
    def test_planetary_finale_coverage_reports_gaps(self):
        fixture={"technology":{
          "razi-stable-intergalactic-singularity":{
            "prerequisites":["planet-discovery-fulgora"]},
          "planet-discovery-fulgora":{"effects":[
            {"type":"unlock-space-location","space_location":"fulgora"}]},
          "moon-discovery-cerys":{"effects":[
            {"type":"unlock-space-location","space_location":"cerys"}]}},
          "planet":{"fulgora":{},"cerys":{},"bm-wit":{}}}
        s=MODULE.analyze(fixture)["planetary_milestone_coverage"]
        self.assertEqual(s["catalogued_worlds_present"],3)
        self.assertEqual(s["on_singularity_path"],1)
        self.assertIn("cerys",s["missing_from_finale"])
        self.assertIn("bm-wit",s["no_native_research_unlock"])

if __name__=="__main__":
    unittest.main()
