"""Pass 6: source-backed frontier pacing and factory presentation contracts."""
import unittest
from pathlib import Path
from scripts.audit_frontier_pacing import inspect, RULES

ROOT=Path(__file__).resolve().parents[1]
def src(path):
    return (ROOT/path).read_text(encoding="utf-8")

def fixture(amount=15,premium_seconds=8.96,arrival="planet-discovery-moshine"):
    name="razi-frontier-moshine-biometal-silicon"
    native="silicon-cell"
    return {"raw":{
        "recipe":{
            native:{"energy_required":2,
                "ingredients":[{"type":"item","name":"iron-plate","amount":2}],
                "results":[{"type":"item","name":native,"amount":3}]},
            name:{"energy_required":premium_seconds,"enabled":False,
                "allow_productivity":False,"auto_recycle":False,
                "ingredients":[{"type":"item","name":"iron-plate","amount":8},
                               {"type":"item","name":"rare-metals","amount":2}],
                "results":[{"type":"item","name":native,"amount":amount}]}
        },
        "technology":{
            name:{"prerequisites":[arrival],
                "effects":[{"type":"unlock-recipe","recipe":name}],
                "unit":{"count":560,"ingredients":[["solaris-tech-card",1],
                                                  ["nyxaris-tech-card",1]]}}
        }
    }}

def first(data):
    return next(x for x in inspect(data)["rows"]
                if x["name"]=="razi-frontier-moshine-biometal-silicon")

class FrontierPacingTests(unittest.TestCase):
    def test_seven_existing_factory_rules(self):
        self.assertEqual(len(RULES["first"]),3)
        self.assertEqual(len(RULES["middle"]),4)

    def test_positive_per_machine_margin_without_shipping_claim(self):
        result=first(fixture())
        self.assertEqual(result["status"],"verified-prototype-shape")
        self.assertAlmostEqual(result["bonus_fraction"],.25)
        self.assertGreater(result["machine_throughput_ratio"],1.04)

    def test_below_margin_is_flagged(self):
        self.assertIn("less-than-four-percent-machine-margin",
                      first(fixture(amount=14))["issues"])

    def test_gating_behind_later_system_is_flagged(self):
        self.assertIn("late-stage-ancestor",
                      first(fixture(arrival="vibrant-discovery"))["issues"])

    def test_native_materials_preserved(self):
        document=fixture()
        name="razi-frontier-moshine-biometal-silicon"
        document["raw"]["recipe"][name]["ingredients"][0]["amount"]=4
        self.assertIn("native-inputs-reduced",first(document)["issues"])

    def test_optional_mod_absence_is_not_a_failure(self):
        report=inspect({"raw":{"recipe":{},"technology":{}}})
        self.assertEqual(report["stages"]["first"]["installed"],0)
        self.assertTrue(all(x["status"]=="not-installed" for x in report["rows"]))

    def test_early_middle_minimum_rate_is_still_capped(self):
        engine=src("prototypes/compat/planet_production_exchanges.lua")
        for name in ("rule.min_throughput_ratio",
                     "math.ceil(base_output*","rule.max_bonus_fraction"):
            self.assertIn(name,engine)
        self.assertEqual(src("prototypes/compat/first_frontier_industry.lua")
                         .count("min_throughput_ratio=1.04"),3)
        self.assertEqual(src("prototypes/compat/middle_frontier_industry.lua")
                         .count("min_throughput_ratio=1.04"),4)

    def test_cargo_freight_comparison_is_read_only(self):
        output=src("scripts/razi_factory_comparison.lua")
        card=src("scripts/galactic_trade.lua")
        self.assertIn("local source,bonus_recipe=recipes[spec[1]],recipes[name]",output)
        self.assertIn("if key~=product",output)
        self.assertIn("trade-portfolio-gross",card)
        self.assertIn("trade-portfolio-blocker",card)
        self.assertNotIn("on_nth_tick",output)
        self.assertNotIn("player.insert(",card)

if __name__=="__main__":
    unittest.main()
