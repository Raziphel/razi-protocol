"""Keep source-mod science integration optional, guarded and visible."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


class PlanetaryScienceWeaveTests(unittest.TestCase):
    def setUp(self):
        self.script=(ROOT/"prototypes/technology/planetary_science_weave.lua").read_text()
        self.entry=(ROOT/"data-final-fixes.lua").read_text()

    def test_all_target_technologies_are_optional_razi_industries(self):
        rules=re.findall(
            r'\{"(razi-network-[^"]+)","([^"]+)","([^"]+)"(?:,true)?\}',
            self.script)
        self.assertEqual(len(rules),18)
        allowed={
            "thermodynamic-science-pack",
            "electrochemical-science-pack",
            "cryogenic-science-pack",
            "rubia-biofusion-science-pack",
            "linox-item_linox-science-pack",
            "bioluminescent-science-pack",
            "gas-manipulation-science-pack",
            "planet-crucible-science-pack",
        }
        self.assertEqual({science for _,science,_ in rules},allowed)
        network=(ROOT/"prototypes/compat/network_components.lua").read_text()
        for target,pack,owner in rules:
            self.assertIn(target,network)
            self.assertTrue(owner.startswith("planet-discovery-")
                            or owner.startswith("linox-technology_"))
            self.assertNotEqual(target,owner)
        self.assertEqual(self.script.count('",true}'),5)

    def test_existing_research_and_lab_paths_are_not_rewritten(self):
        s=self.script
        for text in (
            "ancestor(target,owner)",
            "and not tech.research_trigger",
            "pack_exists(pack)",
            "source_surface(recipe,owner)",
            "inputs_exist(recipe)",
            "not ancestor(source,target)",
            "accepted(tech.unit.ingredients,pack)",
            "tech.unit.ingredients[#tech.unit.ingredients+1]={pack,1}",
            "if not mode.enabled() then return end",
            "if not rule[4] or mode.deep() then",
        ):
            self.assertIn(text,s)
        self.assertNotIn("data:extend",s)
        self.assertNotIn("lab.inputs[#",s)
        self.assertNotIn("script.on_tick",s)
        self.assertNotIn("set_technology_unit_ingredients",s)

    def test_final_pass_runs_after_factory_and_arrival_checks(self):
        polish='require("prototypes.technology.research_tree_polish").data_final_fixes()'
        weave='require("prototypes.technology.planetary_science_weave").data_final_fixes()'
        arrival='require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()'
        self.assertEqual(self.entry.count(weave),1)
        self.assertGreater(self.entry.index(weave),self.entry.index(polish))
        self.assertGreater(self.entry.index(weave),self.entry.rfind(arrival))

    def test_new_sciences_are_listed_in_cargo_technology_inspectors(self):
        panel=(ROOT/"scripts/galactic_trade.lua").read_text()
        locale=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        self.assertIn("tech.research_unit_ingredients",panel)
        self.assertIn("tech.research_unit_count",panel)
        self.assertIn("science_requirements(card,row.technology,width-20)",panel)
        self.assertIn("science_requirements(parent,consumer.technology,width)",panel)
        self.assertEqual(locale.count("trade-components="),1)
        for key in ("trade-science-heading","trade-science-units",
                    "trade-science-more"):
            self.assertIn(key+"=",locale)

    def test_source_lua_fixtures_cover_every_failure_class(self):
        tests=(ROOT/"tests/lua/test_planetary_science_weave.lua").read_text()
        for phrase in (
            "missing source science",
            "Native producer unlock",
            "Lab incompatibility",
            "Science unlocked only after target",
            "An unrelated world",
            "absent inputs",
            "incompatible surface conditions",
            "Repeated science weaving",
            "Off mode",
        ):
            # The source fixture uses natural prose instead of API names.
            self.assertIn(phrase.lower(),tests.lower())


if __name__=="__main__":
    unittest.main()
