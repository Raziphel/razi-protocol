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

if __name__ == "__main__":
    unittest.main()
