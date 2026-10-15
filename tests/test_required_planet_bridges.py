"""Protect the required-planet selection from broken 2.0 dependencies."""
from pathlib import Path
import json
import unittest

ROOT=Path(__file__).resolve().parents[1]
def contents(p):
    return (ROOT/p).read_text(encoding="utf-8")
class RequiredWorldTests(unittest.TestCase):
    def test_supported_worlds_are_required(self):
        deps=json.loads(contents("info.json"))["dependencies"]
        by_name={d.lstrip("?+ ").split(" >= ")[0]:d for d in deps
                 if d.strip() and not d.startswith("!")}
        names=["Cerys-Moon-of-Fulgora","Igrys","planet-rabbasca","foliax","obsidiax","carna","Velora","alchemy-khemia","Arcanyx","biological-machines-planet-balack","panglia_planet"]
        for name in names:
            self.assertIn(name,by_name)
            self.assertFalse(by_name[name].startswith(("? ","+ ")),name)
        self.assertEqual(len(names),11)
        for retired in ('biological-machines-planet-wit',):
            self.assertIn('! '+retired,deps)
            self.assertFalse(any(d.startswith(retired+' >=') for d in deps))
        self.assertIn('nulla >= 1.0.2',deps)
        self.assertIn('PlanetAthos >= 1.1.3',deps)
        self.assertIn('? moon-eneas >= 1.0.10',deps)
        self.assertIn('? shchierbin >= 0.3.19',deps)
        self.assertIn('planet-muluna >= 2.7.25',deps)
        self.assertIn('panglia_planet >= 0.7.2',deps)
    def test_unsupported_planet_ports_not_advertised(self):
        deps=json.loads(contents("info.json"))["dependencies"]
        for name in ("dea-dia-system","pelagos"):
            self.assertFalse(any(d==name or d.startswith(("+ "+name,"? "+name,"(?) "+name)) for d in deps))
        self.assertIn("+ planet-ferrum >= 0.1.4",deps)
    def test_safe_staged_unification(self):
        code=contents("prototypes/technology/planetary_unification.lua")
        self.assertIn('razi-stable-intergalactic-singularity',code)
        self.assertIn('unlock-space-location',code)
        self.assertIn("not reaches(candidate,",code)
        self.assertIn('"cerys"',code)
        self.assertIn('"bm-balack"',code)
        self.assertNotIn("unit.ingredients",code)
        entry=contents("data-final-fixes.lua")
        self.assertEqual(entry.count(
            'require("prototypes.technology.planetary_unification").data_final_fixes()'),1)
if __name__=="__main__":
    unittest.main()
