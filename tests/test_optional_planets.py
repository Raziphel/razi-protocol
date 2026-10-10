"""Validate optional-planet manifest names, references and required boundary."""
import json
import re
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODS = {
    "Igrys": "solaris",
    "planet-rabbasca": "calidus",
    "foliax": "nyxaris",
    "obsidiax": "vespera",
    "carna": "umbra",
    "PlanetAthos": "solaris",
}

class OptionalPlanetTests(unittest.TestCase):
    def test_six_integrations_are_optional(self):
        dependencies = json.loads((ROOT / "info.json").read_text())["dependencies"]
        names = [dep.split()[1] for dep in dependencies if dep.startswith("? ")]
        source = (ROOT / "prototypes/system/optional_planets.lua").read_text()
        for mod, host in MODS.items():
            with self.subTest(mod=mod):
                self.assertEqual(names.count(mod), 1)
                self.assertIn('{"' + mod + '",', source)
                self.assertIn('"' + host + '"', source)

    def test_optional_science_is_not_required_for_milestones(self):
        gates = (ROOT / "prototypes/technology/seven_system_gates.lua").read_text()
        cards = (ROOT / "prototypes/compat/lab_cards.lua").read_text()
        for optional_name in ("igrys-mineral-science-pack",
                              "athletic-science-pack", "particulate-science-pack"):
            self.assertNotIn(optional_name, gates)
            self.assertNotIn(optional_name, cards)

    def test_optional_is_last_route_pass(self):
        fixes = (ROOT / "data-final-fixes.lua").read_text()
        self.assertLess(fixes.index('route_reconcile"),'),
                        fixes.index('optional_planets").data_final_fixes()'))

if __name__ == "__main__":
    unittest.main()
