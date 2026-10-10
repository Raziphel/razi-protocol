"""Regression tests for the post-data-stage prototype auditor."""
import importlib.util
import unittest
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "scripts" / "audit_prototypes.py"
spec = importlib.util.spec_from_file_location("razi_audit", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def fixture():
    tech = {name: {"unit": {"ingredients": [["calidus-tech-card", 1]]}}
            for name in module.CAMPAIGN_TECHNOLOGIES}
    tech["solaris-discovery"] = {
        "unit": {"ingredients": [["calidus-tech-card", 1]]},
        "prerequisites": [],
    }
    tech["nyxaris-discovery"]["prerequisites"] = ["solaris-discovery"]
    tech["vibrant-discovery"]["prerequisites"] = ["nyxaris-discovery"]
    tech["beetlejuice-discovery"]["prerequisites"] = ["vibrant-discovery"]
    tech["card-factory"] = {
        "unit": {"ingredients": [["space-science-pack", 1]]},
        "effects": [{"type": "unlock-recipe", "recipe": name}
                    for name in module.SYSTEM_CARDS],
    }
    places = ["nauvis"] + list(module.SYSTEM_LOCATIONS)
    return {
        "technology": tech,
        "tool": {card: {} for card in module.SYSTEM_CARDS},
        "recipe": {card: {"enabled": False} for card in module.SYSTEM_CARDS},
        "lab": {"test-lab": {"inputs": ["calidus-tech-card"]}},
        "planet": {"nauvis": {}},
        "space-location": {place: {} for place in module.SYSTEM_LOCATIONS},
        "space-connection": {
            f"link-{index}": {"from": before, "to": after}
            for index, (before, after) in enumerate(zip(places, places[1:]))
        },
    }


class TestRaziAudit(unittest.TestCase):
    def test_good_dump(self):
        self.assertEqual(module.audit(fixture()), [])

    def test_missing_prerequisite(self):
        raw = fixture()
        raw["technology"]["nyxaris-discovery"]["prerequisites"] = ["removed-planet"]
        self.assertTrue(any("missing removed-planet" in msg for msg in module.audit(raw)))

    def test_research_cycle(self):
        raw = fixture()
        raw["technology"]["solaris-discovery"]["prerequisites"] = ["nyxaris-discovery"]
        self.assertTrue(any("cycle" in msg for msg in module.audit(raw)))

    def test_science_requires_one_compatible_lab(self):
        raw = fixture()
        raw["technology"]["nyxaris-discovery"]["unit"]["ingredients"].append(
            ["nyxaris-tech-card", 1])
        raw["lab"]["other-lab"] = {"inputs": ["nyxaris-tech-card"]}
        self.assertTrue(any("No single lab" in msg for msg in module.audit(raw)))

    def test_broken_route(self):
        raw = fixture()
        raw["space-connection"]["link-2"]["to"] = "nonexistent"
        issues = module.audit(raw)
        self.assertTrue(any("invalid to" in msg for msg in issues))
        self.assertTrue(any("No space route" in msg for msg in issues))

    def test_orphaned_system_card(self):
        raw = fixture()
        raw["technology"]["card-factory"]["effects"].pop()
        self.assertTrue(any("No technology unlocks" in msg for msg in module.audit(raw)))

    def test_card_cannot_unlock_itself(self):
        raw = fixture()
        raw["technology"]["card-factory"]["unit"]["ingredients"] = [
            ["calidus-tech-card", 1]]
        issues = module.audit(raw)
        self.assertTrue(any("recipe unlock deadlock" in issue
                            for issue in issues))

    def test_card_unlock_after_consumer_is_deadlock(self):
        raw = fixture()
        raw["technology"]["card-factory"]["prerequisites"] = ["vibrant-discovery"]
        raw["technology"]["vibrant-discovery"]["unit"]["ingredients"] = [
            ["nyxaris-tech-card", 1]]
        issues = module.audit(raw)
        self.assertTrue(any("nyxaris-tech-card" in issue and "deadlock" in issue
                            for issue in issues))

    def test_alternative_unlock_avoids_deadlock(self):
        raw = fixture()
        raw["technology"]["card-factory"]["unit"]["ingredients"] = [
            ["calidus-tech-card", 1]]
        raw["technology"]["early-card-factory"] = {
            "unit": {"ingredients": [["space-science-pack", 1]]},
            "effects": [{"type": "unlock-recipe", "recipe": "calidus-tech-card"}],
        }
        self.assertEqual(module.audit(raw), [])

    def test_new_optional_planet_integration(self):
        raw = fixture()
        raw["planet"]["igrys"] = {
            "orbit": {"parent": {"type": "space-location", "name": "solaris"}}}
        raw["space-location"]["solaris"] = {}
        raw["space-connection"]["igrys-entry"] = {
            "from": "sye-solaris", "to": "igrys"}
        raw["technology"]["planet-discovery-igrys"] = {
            "prerequisites": ["solaris-discovery"],
            "unit": {"ingredients": [["calidus-tech-card", 1]]},
            "effects": [{"type": "unlock-space-location", "space_location": "igrys"}],
        }
        self.assertEqual(module.audit(raw), [])

        del raw["space-connection"]["igrys-entry"]
        self.assertTrue(any("igrys lacks route" in issue
                            for issue in module.audit(raw)))

    def test_optional_planet_has_valid_research_gate(self):
        raw = fixture()
        raw["planet"]["rabbasca"] = {
            "orbit": {"parent": {"type": "planet", "name": "gleba"}}}
        raw["planet"]["gleba"] = {}
        raw["space-connection"]["gleba-rabbasca"] = {
            "from": "gleba", "to": "rabbasca"}
        raw["technology"]["planet-discovery-gleba"] = {
            "unit": {"ingredients": [["calidus-tech-card", 1]]}}
        raw["technology"]["planet-discovery-rabbasca"] = {
            "prerequisites": ["planet-discovery-gleba"],
            "effects": [{"type": "unlock-space-location", "space_location": "rabbasca"}]}
        self.assertEqual(module.audit(raw), [])
        raw["technology"]["planet-discovery-rabbasca"]["prerequisites"] = []
        self.assertTrue(any("rabbasca discovery lacks" in issue
                            for issue in module.audit(raw)))

    def test_optional_extra_route(self):
        raw = fixture()
        raw["planet"]["optional-planet"] = {}
        self.assertTrue(any("optional-planet" in msg
                            for msg in module.audit(raw, ["optional-planet"])))
        raw["space-connection"]["optional"] = {
            "from": "nauvis", "to": "optional-planet"}
        self.assertEqual(module.audit(raw, ["optional-planet"]), [])

    def test_empty_factorio_arrays_are_maps(self):
        raw = fixture()
        raw["technology"]["solaris-discovery"]["prerequisites"] = {}
        raw["technology"]["card-factory"]["effects"] = {}
        self.assertTrue(any("No technology unlocks" in msg for msg in module.audit(raw)))


if __name__ == "__main__":
    unittest.main()
