"""Static tests for shared manufacturing interfaces and recipe economics."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
def src(path):
    return (ROOT/path).read_text(encoding="utf8")

class SharedManufacturingTests(unittest.TestCase):
    def test_components_and_premium_alternatives(self):
        source=src("prototypes/compat/network_components.lua")
        components=re.findall(r'name="(razi-network-(?:precision-matrix|extreme-lattice))"',source)
        self.assertGreaterEqual(len(components),2)
        self.assertIn('name="razi-network-precision-matrix"',source)
        self.assertIn('name="razi-network-extreme-lattice"',source)
        self.assertIn('max_bonus_fraction=0.25',source)
        self.assertIn('batch=options.batch or 4,bonus=options.bonus or 1',source)
        self.assertEqual(source.count('batch=8,bonus=2'),2)
        self.assertIn('factory.register_k2so_balanced(balanced_k2)',source)
        self.assertIn('factory.register_additional(balanced_modded)',source)
        self.assertIn('factory.register_additional(deep_modded)',source)
        self.assertEqual(source.count('upgrade("razi-network-'),10)
    def test_different_source_settings_stay_independent(self):
        engine=src("prototypes/compat/planet_production_exchanges.lua")
        self.assertIn('function M.register_k2so_balanced(rules)',engine)
        self.assertIn('enabled("razi-enable-k2so-production-exchanges")',engine)
        module=src("prototypes/compat/network_components.lua")
        self.assertIn('enabled("razi-enable-modded-planet-exchanges")',module)
        self.assertIn('if not mode.enabled()',module)
    def test_registration_before_production_and_after(self):
        file=src("data-final-fixes.lua")
        comp='require("prototypes.compat.network_components").data_final_fixes()'
        after='require("prototypes.compat.network_components").register_premium()'
        base='require("prototypes.compat.planet_production_exchanges").data_final_fixes()'
        self.assertEqual(file.count(comp),1)
        self.assertEqual(file.count(after),1)
        self.assertLess(file.index(comp),file.index(base))
        self.assertLess(file.index(base),file.index(after))
    def test_locale_items_recipes_techs(self):
        module=src("prototypes/compat/network_components.lua")
        names={"razi-network-precision-matrix","razi-network-extreme-lattice",
               "razi-network-panglia-optic-bond",
               "razi-network-umbra-pressure-frame"}
        names.update(re.findall(r'upgrade\("(razi-network-[^"]+)"',module))
        self.assertEqual(len(names),14)
        text=src("locale/en/production.cfg")
        for name in names:
            self.assertEqual(text.count(name+"="),6 if name in (
                "razi-network-precision-matrix","razi-network-extreme-lattice",
                "razi-network-panglia-optic-bond",
                "razi-network-umbra-pressure-frame") else 4)
        for name in ("razi-network-precision-matrix","razi-network-extreme-lattice",
                     "razi-network-panglia-optic-bond",
                     "razi-network-umbra-pressure-frame"):
            self.assertEqual(text.count(name+"="),6)
    def test_native_tech_and_recipe_unchanged(self):
        s=src("prototypes/compat/network_components.lua")
        self.assertNotIn('data.raw.planet[',s)
        self.assertNotIn('on_nth_tick',s)
        self.assertIn('allow_productivity=false',s)
        self.assertIn('auto_recycle=false',s)
        self.assertIn('source_unlock(',s)
        engine=src("prototypes/compat/planet_production_exchanges.lua")
        self.assertIn("marker.icons and marker.icons[1]",engine)

if __name__=="__main__":
    unittest.main()
