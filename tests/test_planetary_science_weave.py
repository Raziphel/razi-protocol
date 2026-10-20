"""Freight must not acquire another research-card tax after registration."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class MaterialFirstFreight(unittest.TestCase):
    def test_postprocessing_is_inert_and_preserves_source_research(self):
        weave=read("prototypes/technology/planetary_science_weave.lua")
        self.assertIn("local M={rules={}}",weave)
        self.assertIn("function M.data_final_fixes()",weave)
        self.assertIn("return 0",weave)
        for forbidden in ("tech.unit.ingredients[#", "tech.prerequisites[#",
                          "data:extend", "set_technology_unit_ingredients",
                          "script.on_tick"):
            self.assertNotIn(forbidden,weave)

    def test_industry_unlocks_use_materials_and_ordinary_science(self):
        policy=read("prototypes/compat/industry_portfolio.lua")
        exchange=read("prototypes/compat/planet_production_exchanges.lua")
        components=read("prototypes/compat/network_components.lua")
        flux=read("prototypes/compat/fluxworks_industry_exchanges.lua")
        self.assertIn("function M.science(rule)",policy)
        self.assertIn('{"chemical-science-pack","production-science-pack"}',policy)
        self.assertIn('{"production-science-pack","utility-science-pack"}',policy)
        self.assertIn("portfolio.keep(rule.name)",exchange)
        self.assertIn("local science=portfolio.science(rule)",exchange)
        self.assertIn("local science=portfolio.science(part)",components)
        self.assertIn("import.amount=math.ceil(import.amount*1.5)",exchange)
        self.assertIn("for _,pack in ipairs(research_packs(spec))",flux)

    def test_four_network_components_have_real_freight(self):
        components=read("prototypes/compat/network_components.lua")
        self.assertIn('name="razi-network-precision-matrix"',components)
        self.assertIn('name="razi-network-extreme-lattice"',components)
        self.assertIn('name="razi-network-panglia-optic-bond"',components)
        self.assertIn('name="razi-network-umbra-pressure-frame"',components)
        self.assertIn('{type="item",name="holmium-plate",amount=2}',components)
        self.assertNotIn('name="planet-crucible-science-pack",amount=1',components)
        self.assertIn("count=980,energy=20,output=8",components)
        self.assertNotIn("count=980,energy=20,output=8,deep_only=true",components)

    def test_stable_data_stage_entrypoint(self):
        contents=read("data-final-fixes.lua")
        self.assertEqual(contents.count(
            'require("prototypes.technology.planetary_science_weave").data_final_fixes()'),1)
        self.assertLess(contents.index(
            'require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()'),
            contents.index(
            'require("prototypes.technology.planetary_science_weave").data_final_fixes()'))

if __name__=="__main__":
    unittest.main()
