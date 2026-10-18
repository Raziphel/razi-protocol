"""Loaded-prototype midgame factory audits: source and supply safeguards."""
import unittest

from scripts.audit_midgame_partnerships import analyze,PARTNERSHIPS

NAME="razi-middle-fulgora-resilient-capacitors"

def example():
    native={
      "supercapacitor":{
        "ingredients":[{"name":"holmium-plate","amount":2}],
        "results":[{"name":"supercapacitor","amount":2}]},
      "kr-energy-control-unit":{
        "results":[{"name":"kr-energy-control-unit","amount":1}]},
      "optical-cable":{
        "results":[{"name":"optical-cable","amount":1}]}
    }
    native[NAME]={
      "ingredients":[{"name":"holmium-plate","amount":8},
                     {"name":"kr-energy-control-unit","amount":1},
                     {"name":"optical-cable","amount":2}],
      "results":[{"name":"supercapacitor","amount":10}],
      "enabled":False
    }
    return {"raw":{
      "recipe":native,
      "technology":{
        NAME:{
          "prerequisites":["planet-discovery-fulgora",
                           "planet-discovery-aquilo"],
          "unit":{"count":680,"ingredients":[["vibrant-tech-card",1],
                                              ["vespera-tech-card",1]]},
          "effects":[{"type":"unlock-recipe","recipe":NAME}]}
      },
      "lab":{"advanced":{"inputs":["vibrant-tech-card",
                                     "vespera-tech-card"]}}
    }}


def row(data):
    return next(x for x in analyze(data)["rows"] if x["name"]==NAME)


class MidgameTests(unittest.TestCase):
    def test_all_four_midgame_world_partnerships_present(self):
        self.assertEqual(len(PARTNERSHIPS),4)
        self.assertTrue(all(x.startswith("razi-middle-") for x in PARTNERSHIPS))

    def test_valid_native_supplier_and_technology(self):
        record=row(example())
        self.assertEqual(record["status"],"prototype-verified")
        self.assertEqual(record["issues"],[])
        self.assertEqual(record["research_units"],680)

    def test_missing_optional_world_is_not_a_failure(self):
        report=analyze({"raw":{"recipe":{},"technology":{}}})
        self.assertEqual(report["installed"],0)
        self.assertEqual(report["needs_review"],0)

    def test_supplier_without_actual_output_is_flagged(self):
        fixture=example()
        fixture["raw"]["recipe"]["optical-cable"]["results"]=[
          {"name":"copper-cable","amount":1}]
        self.assertIn("no-native-supplier:optical-cable",row(fixture)["issues"])

    def test_premium_without_import_is_flagged(self):
        fixture=example()
        fixture["raw"]["recipe"][NAME]["ingredients"]=[
          x for x in fixture["raw"]["recipe"][NAME]["ingredients"]
          if x["name"]!="optical-cable"]
        self.assertIn("missing-import:optical-cable",row(fixture)["issues"])

    def test_import_already_in_native_recipe_must_be_additional(self):
        fixture=example()
        fixture["raw"]["recipe"]["supercapacitor"]["ingredients"].append(
            {"name":"optical-cable","amount":1})
        # Four native runs already require four optical cables. The
        # premium recipe provides only two: it is not a real freight import.
        record=row(fixture)
        self.assertIn("missing-import:optical-cable",record["issues"])
        self.assertIn("original-inputs-not-preserved",record["issues"])

    def test_missing_original_inputs_are_flagged(self):
        fixture=example()
        fixture["raw"]["recipe"][NAME]["ingredients"][0]["amount"]=4
        self.assertIn("original-inputs-not-preserved",row(fixture)["issues"])

    def test_original_byproducts_cannot_disappear(self):
        fixture=example()
        fixture["raw"]["recipe"]["supercapacitor"]["results"].append(
            {"type":"fluid","name":"source-byproduct","amount":2})
        self.assertIn("original-byproducts-not-preserved",
                      row(fixture)["issues"])

    def test_late_stage_dependency_is_flagged(self):
        fixture=example()
        fixture["raw"]["technology"][NAME]["prerequisites"]=[
          "beetlejuice-discovery"]
        self.assertIn("late-system-prerequisite:beetlejuice-discovery",
                      row(fixture)["issues"])

    def test_installed_lab_must_support_both_science_cards(self):
        fixture=example()
        fixture["raw"]["lab"]["advanced"]["inputs"]=["vibrant-tech-card"]
        self.assertIn("no-single-lab-supports-research",row(fixture)["issues"])

    def test_missing_unlock_is_flagged(self):
        fixture=example()
        fixture["raw"]["technology"][NAME]["effects"]=[]
        self.assertIn("research-does-not-unlock-recipe",row(fixture)["issues"])


if __name__=="__main__":
    unittest.main()
