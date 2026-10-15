"""Validate integrated-planet manifest names, references and required boundary."""
import json
import re
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODS = {
    "Igrys": "solaris",
    "planet-rabbasca": "calidus",
    "foliax": "nyxaris",
    "obsidiax": "umbra",
    "carna": "umbra",
}

class OptionalPlanetTests(unittest.TestCase):
    def test_five_integrations_are_declared(self):
        dependencies = json.loads((ROOT / "info.json").read_text())["dependencies"]
        names = [dep.lstrip("?+ ").split(" >= ")[0] for dep in dependencies
                 if not dep.startswith("!")]
        source = (ROOT / "prototypes/system/optional_planets.lua").read_text()
        for mod, host in MODS.items():
            with self.subTest(mod=mod):
                self.assertEqual(names.count(mod), 1)
                self.assertIn('{"' + mod + '",', source)
                self.assertIn('"' + host + '"', source)

    def test_integrated_planets_and_athos_are_required(self):
        dependencies = json.loads((ROOT / "info.json").read_text())["dependencies"]
        by_name = {dep.lstrip("?+ ").split(" >= ")[0]: dep for dep in dependencies
                   if not dep.startswith("!")}
        for mod in ("Igrys", "foliax", "obsidiax", "carna"):
            self.assertIn(mod, by_name)
            self.assertFalse(by_name[mod].startswith(("? ", "+ ")))
        self.assertEqual(by_name["planet-rabbasca"], "? planet-rabbasca >= 0.22.2")
        self.assertIn("PlanetAthos >= 1.1.3", dependencies)
        self.assertNotIn("? PlanetAthos >= 1.1.3", dependencies)

    def test_abacayba_remains_recommended_not_required(self):
        deps=json.loads((ROOT/"info.json").read_text())["dependencies"]
        self.assertIn("+ Abacayba_Moon_of_Nauvis >= 0.0.42",deps)
        policy=json.loads((ROOT/"compat/dependency_policy.json").read_text())
        match=[x for x in policy["dependencies"]
               if x["mod"]=="Abacayba_Moon_of_Nauvis"]
        self.assertEqual(len(match),1)
        self.assertEqual(match[0]["type"],"recommended")

    def test_optional_science_is_not_required_for_milestones(self):
        gates = (ROOT / "prototypes/technology/seven_system_gates.lua").read_text()
        cards = (ROOT / "prototypes/compat/lab_cards.lua").read_text()
        for optional_name in ("igrys-mineral-science-pack",
                              "athletic-science-pack", "particulate-science-pack"):
            self.assertNotIn(optional_name, gates)
            self.assertNotIn(optional_name, cards)

    def test_optional_is_last_route_pass(self):
        fixes = (ROOT / "data-final-fixes.lua").read_text()
        self.assertLess(fixes.index('route_reconcile").data_final_fixes()'),
                        fixes.index('optional_planets").data_final_fixes()'))

if __name__ == "__main__":
    unittest.main()
