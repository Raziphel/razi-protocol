"""Static regression for Alex's modpack exchange review."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class IndustryProgressionGuards(unittest.TestCase):
    def test_missing_surface_property_uses_registered_default(self):
        engine=read("prototypes/compat/planet_production_exchanges.lua")
        self.assertIn('raw("surface-property",condition.property)',engine)
        self.assertIn("property and property.default_value",engine)
        self.assertIn('if type(value) ~= "number" then return false end',engine)
        self.assertIn("matches_surface(candidate.machine,world)",engine)

    def test_castra_uses_current_source_category(self):
        source=read("prototypes/compat/first_frontier_industry.lua")
        portfolio=read("prototypes/compat/industry_portfolio.lua")
        self.assertIn('native_category("piercing-rounds-magazine","castra-crafting")',source)
        self.assertIn('"razi-frontier-castra-composite-rounds"',source)
        self.assertIn('["razi-frontier-castra-composite-rounds"]=true',portfolio)

    def test_unlockers_follow_real_native_graph(self):
        engine=read("prototypes/compat/planet_production_exchanges.lua")
        network=read("prototypes/compat/network_components.lua")
        for source in (engine,network):
            self.assertIn("table.sort(candidates,function(a,b)",source)
            self.assertIn("ancestor",source)
            self.assertIn("if a_before_b~=b_before_a then return a_before_b end"
                          if source==engine else "if ab~=ba then return ab end",source)
        self.assertNotIn('return (index[recipe_name] or {})[1]',network)

    def test_supplier_science_tier_sets_research_count(self):
        engine=read("prototypes/compat/planet_production_exchanges.lua")
        network=read("prototypes/compat/network_components.lua")
        portfolio=read("prototypes/compat/industry_portfolio.lua")
        self.assertIn('"electromagnetic-science-pack"]=950',portfolio)
        self.assertIn("portfolio.science_floor(node)",engine)
        self.assertIn("portfolio.science_floor(node)",network)
        self.assertIn("gated_research_count(rule,prerequisite_list)",engine)
        self.assertIn("research_count(part.count,prerequisites)",network)
        self.assertIn('"razi-outer-frontier-mastery",1950',engine)

    def test_required_journal_technologies_remain_usable(self):
        portfolio=read("prototypes/compat/industry_portfolio.lua")
        journal=read("scripts/razi_journal_industry.lua")
        for tech in (
            "razi-network-bond-linox-refining",
            "razi-frontier-castra-composite-rounds",
            "razi-network-bond-paracelsin-coils",
            "razi-network-frame-vesta-foundations",
        ):
            self.assertIn('["'+tech+'"]=true',portfolio)
            self.assertIn('tech="'+tech+'"',journal)

    def test_mocked_lua_scenarios_exist(self):
        production=read("tests/lua/test_planet_production_exchanges.lua")
        modded=read("tests/lua/test_modded_planet_exchanges.lua")
        castra=read("tests/lua/test_first_frontier_industry.lua")
        self.assertIn("Absent Aquilo override must use the Cerys property default_value",production)
        self.assertIn("Duplicate unlockers must select earliest legitimate native research",production)
        self.assertIn("Post-Vibrant exchanges must not use early-Solaris research pricing",production)
        self.assertIn("Optical-cable supplier science must raise its Razi exchange",modded)
        self.assertIn("Castra piercing rounds must retain castra-crafting",castra)

if __name__=="__main__":
    unittest.main()
