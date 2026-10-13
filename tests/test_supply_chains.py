"""Post-load supply-chain tracing tests for Aquilo and outer worlds."""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "razi_supply", ROOT / "scripts" / "audit_supply_chains.py")
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)

def example():
    return {
        "technology": {
            "solaris-discovery": {"effects": [{
                "type": "unlock-space-location", "space_location": "vulcanus"}]},
            "vespera-discovery": {"prerequisites": ["solaris-discovery"]},
            "planet-discovery-aquilo": {
                "prerequisites": ["vespera-discovery"],
                "unit": {"ingredients": [["vespera-tech-card", 1]]},
                "effects": [{
                    "type": "unlock-space-location", "space_location": "aquilo"}]},
            "kr-cryogenic-research": {
                "prerequisites": ["planet-discovery-aquilo"],
                "effects": [{"type": "unlock-recipe",
                             "recipe": "kr-cryogenic-research-data"}]},
            "planet-discovery-crucible": {
                "prerequisites": ["planet-discovery-aquilo"],
                "effects": [{
                    "type": "unlock-space-location", "space_location": "crucible"}]},
            "planet-discovery-vesta": {
                "prerequisites": ["planet-discovery-crucible"],
                "effects": [{
                    "type": "unlock-space-location", "space_location": "vesta"}]},
        },
        "planet": {
            "nauvis": {"surface_properties": {"pressure": 1000}},
            "vulcanus": {"surface_properties": {"pressure": 4000}},
            "aquilo": {"surface_properties": {"pressure": 300}},
            "crucible": {"surface_properties": {"pressure": 9000}},
            "vesta": {"surface_properties": {"pressure": 400}},
        },
        "recipe": {
            "vespera-tech-card": {
                "enabled": True,
                "ingredients": [{"type": "item", "name": "kr-cryogenic-research-data"}],
                "results": [{"type": "item", "name": "vespera-tech-card"}]},
            "kr-cryogenic-research-data": {
                "enabled": False, "categories": ["cryogenics"],
                "ingredients": [{"type": "item", "name": "ice"}],
                "results": [{"type": "item", "name": "kr-cryogenic-research-data"}]},
            "gas-manipulation-science-pack": {
                "enabled": True, "categories": ["chemistry"],
                "ingredients": [{"type": "fluid", "name": "kr-hydrogen", "amount": 20}],
                "results": [{"type": "item",
                             "name": "gas-manipulation-science-pack"}]},
            "kr-hydrogen": {
                "enabled": True,
                "results": [{"type": "fluid", "name": "kr-hydrogen"}]},
            "planet-crucible-science-pack": {
                "enabled": True, "categories": ["high-pressure"],
                "ingredients": [{"type": "item", "name": "iron-ore"}],
                "results": [{"type": "item",
                             "name": "planet-crucible-science-pack"}]},
        },
        "item": {"ice": {}, "iron-ore": {},
                 "gas-manipulation-science-pack": {},
                 "planet-crucible-science-pack": {},
                 "kr-cryogenic-research-data": {}},
        "fluid": {"kr-hydrogen": {}},
        "resource": {"iron": {"minable": {"result": "iron-ore"}},
                     "ice-rock": {"minable": {"result": "ice"}}},
        "assembling-machine": {
            "cryogenic-plant": {"crafting_categories": ["cryogenics"]},
            "chemical-plant": {"crafting_categories": ["chemistry"]},
            "pressure-forge": {"crafting_categories": ["high-pressure"],
                               "surface_conditions": [
                                   {"property": "pressure", "min": 8000}]},
        }
    }

class SupplyTests(unittest.TestCase):
    def test_late_unlock_is_caught_before_its_goal(self):
        raw = example()
        result = audit.SupplyTrace(raw).analyze()
        science = result["Aquilo"]["before_discovery_science"][0]
        self.assertEqual(science["status"], "blocked")
        child = science["best"]["inputs"][0]
        self.assertEqual(child["item"], "kr-cryogenic-research-data")
        self.assertEqual(child["status"], "blocked")
        self.assertEqual(child["best"]["status"], "future-unlock")
        self.assertIn("kr-cryogenic-research",
                      child["best"]["unlockers"])

    def test_after_arrival_unlock_can_produce_its_data(self):
        raw = example()
        # An independent unlock available by arrival is a normal prerequisite.
        raw["technology"]["planet-discovery-aquilo"]["prerequisites"] = [
            "vespera-discovery", "kr-cryogenic-research"]
        raw["technology"]["kr-cryogenic-research"]["prerequisites"] = [
            "vespera-discovery"]
        result = audit.SupplyTrace(raw).analyze()
        self.assertEqual(result["Aquilo"]["before_discovery_science"][0]["status"],
                         "traceable")
        self.assertEqual(result["Aquilo"]["after_discovery_production"][0]["status"],
                         "traceable")

    def test_high_pressure_machine_restrictions(self):
        raw = example()
        result = audit.SupplyTrace(raw).analyze()
        self.assertEqual(result["Crucible"]["after_discovery_production"][0]["status"],
                         "traceable")
        raw["assembling-machine"]["pressure-forge"]["surface_conditions"] = [
            {"property": "pressure", "max": 100}]
        result = audit.SupplyTrace(raw).analyze()
        self.assertEqual(result["Crucible"]["after_discovery_production"][0]["status"],
                         "blocked")
        self.assertEqual(result["Crucible"]["after_discovery_production"][0]["best"]["status"],
                         "no-machine")

    def test_independent_research_is_not_reported_as_impossible(self):
        raw = example()
        raw["technology"]["kr-cryogenic-research"]["prerequisites"] = [
            "vespera-discovery"]
        result = audit.SupplyTrace(raw).analyze()
        science = result["Aquilo"]["before_discovery_science"][0]
        self.assertEqual(science["status"], "unverified")
        self.assertEqual(science["best"]["inputs"][0]["best"]["status"],
                         "independent-research")

    def test_alternative_recipe_bypasses_locked_producer(self):
        raw = example()
        raw["recipe"]["alternate-cryogenic-data"] = {
            "enabled": True, "category": "crafting",
            "results": [{"name": "kr-cryogenic-research-data"}]}
        report = audit.SupplyTrace(raw).analyze()
        self.assertEqual(report["Aquilo"]["before_discovery_science"][0]["status"],
                         "traceable")

    def test_recipe_without_bootstrap_flags_cycle(self):
        raw = example()
        raw["recipe"]["kr-hydrogen"] = {
            "enabled": True,
            "ingredients": [{"type": "fluid", "name": "kr-hydrogen"}],
            "results": [{"type": "fluid", "name": "kr-hydrogen"}]}
        result = audit.SupplyTrace(raw).analyze()
        self.assertEqual(result["Vesta"]["after_discovery_production"][1]["status"],
                         "blocked")

    def test_absent_optional_world_is_skipped(self):
        raw = example()
        del raw["technology"]["planet-discovery-vesta"]
        result = audit.SupplyTrace(raw).analyze()
        self.assertNotIn("Vesta", result)
        self.assertIn("Crucible", result)

    def test_unknown_base_material_never_claims_playtest(self):
        raw = example()
        report = audit.SupplyTrace(raw).analyze()
        self.assertEqual(report["Vesta"]["after_discovery_production"][0]["status"],
                         "traceable")
        self.assertIn("not proven", report["Vesta"]["caveat"])

    def test_every_installed_planet_has_discovery_report(self):
        raw = example()
        reports = audit.SupplyTrace(raw).audit_planets()
        self.assertNotIn("nauvis", reports)
        for world in ("aquilo", "crucible", "vesta", "vulcanus"):
            self.assertIn(world, reports)
        self.assertEqual(reports["vesta"]["unlockers"][0]["technology"],
                         "planet-discovery-vesta")

    def test_panglia_native_data_cell_bootstrap_caught(self):
        raw = example()
        raw["planet"]["panglia"] = {"surface_properties": {"pressure": 1401}}
        raw["technology"]["panglia_planet_discovery_panglia"] = {
            "unit": {"ingredients": [["panglia-data-cell", 1]]},
            "effects": [{"type": "unlock-space-location",
                         "space_location": "panglia"}]}
        raw["technology"]["panglia-data-after-arrival"] = {
            "prerequisites": ["panglia_planet_discovery_panglia"],
            "effects": [{"type": "unlock-recipe",
                         "recipe": "panglia-data-cell"}]}
        raw["recipe"]["panglia-data-cell"] = {
            "enabled": False, "ingredients": [{"name": "ice"}],
            "results": [{"name": "panglia-data-cell"}]}
        report = audit.SupplyTrace(raw).audit_planets()
        self.assertEqual(report["panglia"]["status"], "blocked")
        self.assertEqual(report["panglia"]["unlockers"][0]["science"][0]["best"]["status"],
                         "future-unlock")
        raw["recipe"]["early-panglia-data"] = {
            "enabled": True, "category": "crafting",
            "ingredients": [{"name": "ice"}],
            "results": [{"name": "panglia-data-cell"}]}
        report = audit.SupplyTrace(raw).audit_planets()
        self.assertEqual(report["panglia"]["status"], "traceable")

    def test_alternative_discovery_stops_false_block(self):
        raw = example()
        raw["technology"]["aquilo-alternative"] = {
            "unit": {"ingredients": [["ice", 1]]},
            "effects": [{"type": "unlock-space-location",
                         "space_location": "aquilo"}]}
        status = audit.SupplyTrace(raw).audit_planets()["aquilo"]
        self.assertEqual(status["status"], "traceable")
        self.assertEqual(len(status["unlockers"]), 2)

    def test_surface_property_missing_is_uncertain_not_legal(self):
        self.assertIsNone(audit.surface_allowed(
            {"surface_conditions": [{"property": "magnetic-field", "min": 90}]},
            {"pressure": 1000}))
        raw = example()
        raw["recipe"]["planet-crucible-science-pack"]["surface_conditions"] = [
            {"property": "magnetic-field", "min": 90}]
        result = audit.SupplyTrace(raw).analyze()["Crucible"]
        node = result["after_discovery_production"][0]
        self.assertEqual(node["status"], "unverified")

    def test_missing_native_unlock_remains_advisory(self):
        raw = example()
        raw["planet"]["unmapped-sideworld"] = {"surface_properties": {}}
        report = audit.SupplyTrace(raw).audit_planets()
        self.assertEqual(report["unmapped-sideworld"]["status"],
                         "no-visible-native-unlock")

if __name__ == "__main__":
    unittest.main()
