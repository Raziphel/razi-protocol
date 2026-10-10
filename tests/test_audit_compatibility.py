"""Compatibility audit tests using reduced post-load prototype fixtures."""
import importlib.util
from pathlib import Path
import unittest

MODULE = Path(__file__).resolve().parents[1] / "scripts/audit_compatibility.py"
spec = importlib.util.spec_from_file_location("compat_audit", MODULE)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)

def fixture():
    return {
        "tool": {"calidus-tech-card": {}},
        "item": {"automation-science-pack": {}},
        "fluid": {"kr-oxygen": {}, "ammonia": {}, "kr-ammonia": {}},
        "planet": {"paracelsin": {}, "rubia": {}},
        "recipe": {
            "calidus-tech-card": {
                "ingredients": [{"type": "item", "name": "automation-science-pack", "amount": 1}],
                "results": [{"type": "item", "name": "calidus-tech-card", "amount": 1}],
            },
            "make-oxygen": {"results": [{"type": "fluid", "name": "kr-oxygen", "amount": 100}]},
            "make-ammonia": {"results": [{"type": "fluid", "name": "ammonia", "amount": 1}]},
            "make-k2-ammonia": {"results": [{"type": "fluid", "name": "kr-ammonia", "amount": 1}]},
        },
        "technology": {
            "oxygen-tech": {"research_trigger": {"type": "craft-fluid", "fluid": "kr-oxygen"}},
            "ammonia-tech": {"research_trigger": {"type": "craft-fluid", "fluid": "ammonia"}},
        },
    }

class CompatibilityAuditTests(unittest.TestCase):
    def test_good_fixture_has_no_findings(self):
        self.assertEqual(audit.audit(fixture()), ([], []))

    def test_missing_system_card_ingredient_is_error(self):
        raw = fixture()
        raw["recipe"]["calidus-tech-card"]["ingredients"][0]["name"] = "absent"
        self.assertTrue(any("missing item ingredient absent" in issue
                            for issue in audit.audit(raw)[0]))

    def test_missing_system_card_result_is_error(self):
        raw = fixture()
        raw["recipe"]["calidus-tech-card"]["results"][0]["name"] = "absent"
        self.assertTrue(any("produces missing" in issue for issue in audit.audit(raw)[0]))

    def test_recycling_productivity_is_advisory(self):
        raw = fixture()
        raw["recipe"]["tin-recycling"] = {
            "allow_productivity": True, "results": [{"name": "automation-science-pack"}]}
        errors, warnings = audit.audit(raw)
        self.assertFalse(errors)
        self.assertTrue(any("productivity" in issue for issue in warnings))

    def test_water_loop_limit_is_warning(self):
        raw = fixture()
        raw["recipe"]["ske_h2o"] = {"maximum_productivity": 1}
        self.assertTrue(any("Water-loop" in issue for issue in audit.audit(raw)[1]))

    def test_research_trigger_needs_produced_name(self):
        raw = fixture()
        raw["technology"]["oxygen-tech"]["research_trigger"]["fluid"] = "oxygen"
        self.assertTrue(any("Unproducible fluid research trigger" in issue
                            for issue in audit.audit(raw)[0]))
        # Keep old names when they remain producible.
        self.assertFalse(any("ammonia-tech" in issue for issue in audit.audit(raw)[0]))

    def test_recipe_restrictions_without_surface_lock(self):
        raw = fixture()
        raw["recipe"]["galvanization-research-data"] = {"results": [{"name": "automation-science-pack"}]}
        self.assertTrue(any("Missing surface conditions" in issue
                            for issue in audit.audit(raw)[1]))

    def test_k2so_machine_category_regression(self):
        raw = fixture()
        raw["assembling-machine"] = {
            "chemical-plant": {
                "crafting_categories": ["chemistry", "chemistry-or-cryogenics"],
                "fluid_boxes": [{"production_type": "input"},
                                {"production_type": "output"}]},
            "kr-advanced-chemical-plant": {
                "crafting_categories": ["chemistry", "kr-advanced-chemistry"],
                "fluid_boxes": [{"production_type": "input"},
                                {"production_type": "output"}]},
        }
        self.assertTrue(any("chemistry-or-cryogenics" in message
                            for message in audit.audit(raw)[1]))
        raw["assembling-machine"]["kr-advanced-chemical-plant"][
            "crafting_categories"].append("chemistry-or-cryogenics")
        self.assertFalse(any("K2SO machine" in message
                             for message in audit.audit(raw)[1]))

    def test_k2so_card_data_requires_reachable_machine_and_surface(self):
        raw = fixture()
        raw["tool"]["solaris-tech-card"] = {}
        raw["item"]["kr-metallurgic-research-data"] = {}
        raw["planet"]["vulcanus"] = {"surface_properties": {"pressure": 4000}}
        raw["recipe"]["kr-metallurgic-research-data"] = {
            "categories": ["metallurgy"],
            "results": [{"name": "kr-metallurgic-research-data"}],
            "surface_conditions": [{"property": "pressure", "min": 100, "max": 300}]
        }
        raw["recipe"]["solaris-tech-card"] = {
            "ingredients": [{"name": "automation-science-pack", "type": "item"}],
            "results": [{"name": "solaris-tech-card", "type": "item"}]
        }
        _, warnings = audit.audit(raw)
        self.assertTrue(any("system-card research link" in issue
                            for issue in warnings))
        self.assertTrue(any("no compatible crafting machine" in issue
                            for issue in warnings))
        self.assertTrue(any("excludes source planet vulcanus" in issue
                            for issue in warnings))

        raw["recipe"]["solaris-tech-card"]["ingredients"].append(
            {"name": "kr-metallurgic-research-data", "type": "item"})
        raw["assembling-machine"] = {
            "foundry": {"crafting_categories": ["metallurgy"]}
        }
        raw["recipe"]["kr-metallurgic-research-data"]["surface_conditions"] = [
            {"property": "pressure", "min": 4000, "max": 4000}]
        self.assertFalse(any("K2SO" in issue for issue in audit.audit(raw)[1]))

if __name__ == "__main__":
    unittest.main()
