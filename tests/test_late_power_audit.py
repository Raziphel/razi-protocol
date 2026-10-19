"""Regression fixtures for cross-mod late-power bypass detection."""
import unittest

from scripts import audit_late_power as audit


def tech(*parents, effects=None):
    return {"enabled": True, "prerequisites": list(parents),
            "effects": effects or []}


def fixture():
    t = {
        "foundation": tech("cryogenic-science-pack",
                           "planet-discovery-paracelsin",
                           "planet-discovery-maraxsis"),
        "fusion-reactor": tech("cryogenic-science-pack",
                               "planet-discovery-cubium",
                               "planet-discovery-tenebris"),
        "legendary-quality": tech("epic-quality",
                                  "razi-outer-frontier-mastery"),
    }
    for value in set(v for parents in audit.RULES.values()
                     for v in parents):
        t[value] = tech()
    t["cryogenic-science-pack"] = tech()
    t["epic-quality"] = tech()
    return {"technology": t, "recipe": {
        "foundation": {"enabled": False},
        "fusion-reactor": {"enabled": False},
    }}


class LatePowerTests(unittest.TestCase):
    def test_complete_tech_graph(self):
        report = audit.inspect(fixture())
        self.assertEqual(report["reviews"], 0)
        self.assertTrue(all(r["status"] == "staged-in-technology-graph"
                            for r in report["rows"]))

    def test_staging_can_be_transitive(self):
        raw = fixture()
        raw["technology"]["legendary-quality"] = tech("outer-quality-gate")
        raw["technology"]["outer-quality-gate"] = tech(
            "razi-outer-frontier-mastery")
        self.assertEqual(audit.inspect(raw)["reviews"], 0)

    def test_missing_gate_and_disabled_world(self):
        raw = fixture()
        raw["technology"]["fusion-reactor"] = tech(
            "planet-discovery-cubium")
        raw["technology"]["planet-discovery-tenebris"]["enabled"] = False
        issues = audit.inspect(raw)["rows"][1]["issues"]
        self.assertTrue(any(i.startswith("missing-staged-gates:")
                            for i in issues))
        self.assertIn("unavailable-gate:planet-discovery-tenebris", issues)

    def test_alternative_unlock_and_enabled_recipe(self):
        raw = fixture()
        raw["recipe"]["foundation"]["enabled"] = True
        raw["technology"]["other-foundation"] = tech(
            effects=[{"type": "unlock-recipe", "recipe": "foundation"}])
        issues = audit.inspect(raw)["rows"][0]["issues"]
        self.assertIn("recipe-enabled-before-research", issues)
        self.assertIn("alternative-recipe-unlock:other-foundation", issues)

    def test_quality_unlock_and_cycle_detected(self):
        raw = fixture()
        raw["technology"]["bonus"] = tech(
            effects=[{"type": "unlock-quality", "quality": "legendary"}])
        raw["technology"]["razi-outer-frontier-mastery"] = tech(
            "legendary-quality")
        issues = audit.inspect(raw)["rows"][2]["issues"]
        self.assertTrue(any(i.startswith("research-cycle:") for i in issues))
        self.assertIn("alternative-quality-unlock:bonus", issues)

    def test_absent_source_and_setting_off_are_not_automatically_errors(self):
        raw = fixture()
        del raw["technology"]["fusion-reactor"]
        report = audit.inspect(raw)
        self.assertEqual(report["rows"][1]["status"], "unavailable")
        self.assertEqual(report["reviews"], 0)

    def test_ancestry_contains_no_duplicate_false_cycle(self):
        t = {"final": tech("left", "right"),
             "left": tech("shared"), "right": tech("shared"),
             "shared": tech()}
        family, loops = audit.ancestors(t, "final")
        self.assertEqual(family, {"left", "right", "shared"})
        self.assertFalse(loops)


if __name__ == "__main__":
    unittest.main()
