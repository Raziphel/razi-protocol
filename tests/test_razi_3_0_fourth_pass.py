"""Pass 4: source-backed freight break-even and recipe safety regression."""
from __future__ import annotations
import unittest

from scripts import audit_exchange_economy
from scripts.audit_freight_break_even import analyze, shortest_route, validate_prices

def factory_fixture():
    return {"raw": {
        "recipe": {
            "vesta-foundation": {
                "energy_required": 2,
                "ingredients": [{"type":"fluid","name":"nitrogen","amount":1000}],
                "results": [{"type":"item","name":"vesta-foundation","amount":10}],
            },
            "razi-vesta-frontier-foundations": {
                "energy_required": 8.96,
                "ingredients": [
                    {"type":"fluid","name":"nitrogen","amount":4000},
                    {"type":"item","name":"imported-frame","amount":1},
                ],
                "results": [{"type":"item","name":"vesta-foundation","amount":48}],
                "allow_productivity": False, "auto_recycle": False,
            },
        },
        "space-connection": {
            "ab": {"from":"a","to":"b","length":4000},
            "bc": {"from":"b","to":"c","length":5000},
            "ac-invalid":{"from":"a","to":"c","length":-1},
        },
    }}


class FourthPassTests(unittest.TestCase):
    def test_no_costs_are_made_up(self):
        report = analyze(factory_fixture())
        row=report["recipes"]["razi-vesta-frontier-foundations"]
        self.assertEqual(row["status"], "needs-input-values")
        self.assertIsNone(row["maximum_freight_credits_per_craft"])
        self.assertIsNone(row["scenario_verdict"])
        self.assertEqual(row["bonus_output"],8)

    def test_real_input_cost_and_time_budget(self):
        prices={"item:vesta-foundation": 2.0,
                "item:imported-frame": 5.0}
        shipping={"razi-vesta-frontier-foundations": 3.0}
        report=analyze(factory_fixture(),prices,shipping,0.25)
        row=report["recipes"]["razi-vesta-frontier-foundations"]
        # 8 output * 2 credits - 5 import credits - 0.96 s * .25 credits.
        self.assertAlmostEqual(row["maximum_freight_credits_per_craft"],10.76)
        self.assertAlmostEqual(row["scenario_margin_credits_per_craft"],7.76)
        self.assertEqual(row["scenario_verdict"],"within-assumed-budget")
        self.assertEqual(row["extra_imports_per_craft"],
                         {"item:imported-frame":1})

    def test_expensive_transport_breaks_the_scenario(self):
        row=analyze(factory_fixture(),
                    {"item:vesta-foundation":2.0,"item:imported-frame":5.0},
                    {"razi-vesta-frontier-foundations":12.0},
                    0.25)["recipes"]["razi-vesta-frontier-foundations"]
        self.assertEqual(row["scenario_verdict"],"over-assumed-budget")
        self.assertAlmostEqual(row["scenario_margin_credits_per_craft"],-1.24)

    def test_unknown_import_price_never_defaults_to_free(self):
        row=analyze(factory_fixture(),{"item:vesta-foundation":2})[
            "recipes"]["razi-vesta-frontier-foundations"]
        self.assertEqual(row["missing_input_values"],["item:imported-frame"])
        self.assertIsNone(row["maximum_freight_credits_per_craft"])

    def test_premium_cannot_discount_native_recipe_for_fake_profit(self):
        fixture=factory_fixture()
        premium=fixture["raw"]["recipe"]["razi-vesta-frontier-foundations"]
        premium["ingredients"][0]["amount"]=3000
        row=audit_exchange_economy.inspect(fixture["raw"])[
            "razi-vesta-frontier-foundations"]
        self.assertEqual(row["status"],"review")
        self.assertEqual(row["missing_native_inputs_per_craft"],
                         {"fluid:nitrogen":1000})
        result=analyze(fixture,
                       {"item:vesta-foundation":10,"item:imported-frame":1},
                       {"razi-vesta-frontier-foundations":1})
        report=result["recipes"]["razi-vesta-frontier-foundations"]
        self.assertIsNone(report["scenario_margin_credits_per_craft"])
        self.assertIsNone(report["scenario_verdict"])
        self.assertIn("Freight recipe discounts or removes native inputs",
                      report["integrity_issues"])

    def test_native_byproducts_must_be_preserved(self):
        fixture=factory_fixture()
        fixture["raw"]["recipe"]["vesta-foundation"]["results"].append(
            {"type":"fluid","name":"recovered-gas","amount":2})
        row=audit_exchange_economy.inspect(fixture["raw"])[
            "razi-vesta-frontier-foundations"]
        self.assertEqual(row["status"],"review")
        self.assertEqual(row["missing_native_byproducts_per_craft"],
                         {"fluid:recovered-gas":8})
        priced=analyze(fixture,
                       {"item:vesta-foundation":10,"item:imported-frame":1},
                       {"razi-vesta-frontier-foundations":0})
        self.assertIsNone(priced["recipes"]["razi-vesta-frontier-foundations"]
                          ["scenario_verdict"])

    def test_routes_are_known_kilometres_not_freight_cost(self):
        raw=factory_fixture()["raw"]
        route=shortest_route(raw,"a","c")
        self.assertEqual(route["kilometres"],9000)
        self.assertEqual(route["route"],["a","b","c"])
        self.assertEqual(shortest_route(raw,"x","c")["kilometres"],None)
        report=analyze(factory_fixture(), lanes=[("a","c")])
        self.assertEqual(report["route_context"][0]["kilometres"],9000)
        self.assertIsNone(report["recipes"]["razi-vesta-frontier-foundations"]
                          ["maximum_freight_credits_per_craft"])

    def test_invalid_price_inputs_fail_closed(self):
        for invalid in (-1,float("nan"),float("inf"),True,"cheap"):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    validate_prices({"item:frame":invalid},"values")

    def test_machine_slots_are_checked_before_recipe_registration(self):
        from pathlib import Path
        source=(Path(__file__).resolve().parents[1]/
                "prototypes/compat/planet_production_exchanges.lua"
                ).read_text(encoding="utf-8")
        self.assertIn("distinct_ingredient_count(ingredients)",source)
        self.assertIn("candidate.machine.ingredient_count",source)
        self.assertIn("capacity>=required_ingredients",source)
        native_test=(Path(__file__).resolve().parents[1]/
                     "tests/lua/test_planet_production_exchanges.lua"
                     ).read_text(encoding="utf-8")
        self.assertIn("electromagnetic_ingredient_limit=4",native_test)
        self.assertIn("electromagnetic_ingredient_limit=5",native_test)


if __name__=="__main__":
    unittest.main()
