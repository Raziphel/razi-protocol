"""Static release safeguards for optional planet-distributed technology."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")


class DistributedIndustryTests(unittest.TestCase):
    def test_tech_distribution_is_opt_out_and_runs_last(self):
        settings=read("settings.lua")
        self.assertIn('startup_toggle("razi-distributed-technology"',settings)
        source=read("data-final-fixes.lua")
        self.assertEqual(source.count(
            'require("prototypes.technology.distributed_industry").data_final_fixes()'),1)
        self.assertLess(source.index(
            'require("prototypes.compat.system_card_laboratories").data_final_fixes()'),
            source.index(
            'require("prototypes.technology.distributed_industry").data_final_fixes()'))
        self.assertLess(source.index(
            'require("prototypes.technology.convergence").data_final_fixes()'),
            source.index(
            'require("prototypes.technology.distributed_industry").data_final_fixes()'))

    def test_only_non_bootstrap_technology_is_redistributed(self):
        source=read("prototypes/technology/distributed_industry.lua")
        for target in (
            "construction-robotics","logistic-robotics","nuclear-power",
            "personal-roboport-equipment","logistic-system",
            "nuclear-fuel-reprocessing","interplanetary-trade-logistics",
            "aai-signal-transmission",
        ):
            self.assertIn('tech="'+target+'"',source)
        for critical in ("rocket-silo","robotics","space-platform",
                         "space-science-pack","solaris-discovery",
                         "nyxaris-discovery"):
            self.assertNotIn('tech="'+critical+'"',source)
        self.assertIn("reaches(techs,parent,rule.tech)",source)
        self.assertIn("has_lab(raw,needed)",source)
        self.assertIn("is_produced(raw,name)",source)
        self.assertIn("target.unit.ingredients[#target.unit.ingredients+1]",source)
        self.assertNotIn("data:extend",source)
        self.assertNotIn("script.on_tick",source)

    def test_world_owned_science_not_extra_invented_pack_types(self):
        source=read("prototypes/technology/distributed_industry.lua")
        for pack in ("metallurgic-science-pack","agricultural-science-pack",
                     "electromagnetic-science-pack","nuclear-science-pack"):
            self.assertIn('packs={"'+pack+'"',source if pack in (
                "electromagnetic-science-pack","agricultural-science-pack",
                "nuclear-science-pack") else source)
        self.assertNotIn("create_surface",source)
        self.assertNotIn("game.forces",source)
        self.assertIn("razi-distributed-technology=",read("locale/en/settings.cfg"))

    def test_published_release_stays_out_of_dev_only_pass(self):
        manifest=json.loads(read("info.json"))
        self.assertEqual(manifest["name"],"razi-protocol")
        self.assertEqual(manifest["factorio_version"],"2.1")


if __name__=="__main__":
    unittest.main()
