"""Static regression for optional multi-world industry registration."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
def src(p):
    return (ROOT/p).read_text(encoding="utf-8")

class GalacticIndustryTests(unittest.TestCase):
    def test_catalog_and_settings_hooks(self):
        mod=src("prototypes/compat/galactic_industry_bridges.lua")
        names=re.findall(r'\bname="(razi-network-[^"]+)"',mod)
        self.assertEqual(len(names),13)
        self.assertEqual(len(set(names)),13)
        self.assertEqual(mod.count("max_bonus_fraction=0.25"),13)
        self.assertEqual(mod.count("deep_only=true"),4)
        self.assertEqual(mod.count("require_supplier_provenance=true"),13)
        entry=src("data-final-fixes.lua")
        self.assertEqual(entry.count(
            'require("prototypes.compat.galactic_industry_bridges").data_final_fixes()'),1)
    def test_provenance_and_bonus_guards(self):
        engine=src("prototypes/compat/planet_production_exchanges.lua")
        self.assertIn("rule.require_supplier_provenance",engine)
        self.assertIn("rule.max_bonus_fraction",engine)
        self.assertIn("(rule.time_multiplier or 1.3)",engine)
        self.assertIn('name="razi-galactic-vulcanus-bioptic-casting"',engine)
    def test_all_recipes_have_four_locale_entries(self):
        lang=src("locale/en/production.cfg")
        mod=src("prototypes/compat/galactic_industry_bridges.lua")
        for name in re.findall(r'\bname="(razi-network-[^"]+)"',mod):
            self.assertEqual(lang.count(name+"="),4)
        self.assertEqual(lang.count("razi-galactic-vulcanus-bioptic-casting="),4)
    def test_no_new_mandatory_research_or_worldgen(self):
        m=src("prototypes/compat/galactic_industry_bridges.lua")
        for token in ("unlock-space-location","map_gen_settings",
                      "on_nth_tick","type=\"planet\""):
            self.assertNotIn(token,m)

if __name__=="__main__":
    unittest.main()
