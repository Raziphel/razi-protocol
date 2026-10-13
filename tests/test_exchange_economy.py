"""Economy checks for the native-vs-freight production comparison."""
import importlib.util
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "razi_exchange_economy", Path(__file__).resolve().parents[1]
    / "scripts" / "audit_exchange_economy.py")
economy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(economy)


def sample():
    return {
        "recipe": {
            "vesta-foundation": {
                "energy_required": 2,
                "ingredients": [{"type": "fluid", "name": "vesta_nitrogen",
                                 "amount": 1000}],
                "results": [{"type": "item", "name": "vesta-foundation",
                             "amount": 10}],
            },
            "razi-network-frame-vesta-foundations": {
                "energy_required": 8.96,
                "ingredients": [
                    {"type": "fluid", "name": "vesta_nitrogen", "amount": 4000},
                    {"type": "item", "name": "razi-network-umbra-pressure-frame",
                     "amount": 1},
                ],
                "results": [{"type": "item", "name": "vesta-foundation",
                             "amount": 48}],
                "allow_productivity": False,
                "auto_recycle": False,
            },
        },
        "technology": {
            "razi-network-frame-vesta-foundations": {
                "unit": {"count": 960, "ingredients": [
                    ["beetlejuice-tech-card", 1], ["umbra-tech-card", 1]]}
            }
        }
    }


class ExchangeEconomyTests(unittest.TestCase):
    def test_bulk_foundation_bonus_is_worth_making(self):
        data = economy.inspect(sample())
        row = data["razi-network-frame-vesta-foundations"]
        self.assertEqual(row["status"], "passes-budget")
        self.assertEqual(row["bonus_output"], 8)
        self.assertAlmostEqual(row["bonus_fraction"], .2)
        self.assertGreater(row["machine_throughput_change"], .07)
        self.assertEqual(row["extra_imports_per_craft"],
                         {"item:razi-network-umbra-pressure-frame": 1})
        self.assertEqual(row["research_units"], 960)
        self.assertEqual(economy.problems(data), {})

    def test_uncapped_free_output_is_flagged(self):
        raw = sample()
        raw["recipe"]["razi-network-frame-vesta-foundations"]["results"][0][
            "amount"] = 61
        findings = economy.problems(economy.inspect(raw))
        self.assertIn("razi-network-frame-vesta-foundations", findings)
        self.assertIn("Extra output exceeds guarded bonus ceiling",
                      findings["razi-network-frame-vesta-foundations"])

    def test_slow_factory_gets_review_even_with_bonus(self):
        raw = sample()
        raw["recipe"]["razi-network-frame-vesta-foundations"][
            "energy_required"] = 11
        findings = economy.problems(economy.inspect(raw))
        self.assertIn("Slower output per machine than the native recipe",
                      findings["razi-network-frame-vesta-foundations"])

    def test_no_import_is_an_exploit(self):
        raw = sample()
        raw["recipe"]["razi-network-frame-vesta-foundations"]["ingredients"] = [
            {"type": "fluid", "name": "vesta_nitrogen", "amount": 4000}]
        findings = economy.problems(economy.inspect(raw))
        self.assertIn("Freight recipe adds no real imported ingredient",
                      findings["razi-network-frame-vesta-foundations"])

    def test_optional_content_and_uncertain_results(self):
        raw = sample()
        del raw["recipe"]["razi-network-frame-vesta-foundations"]
        self.assertEqual(
            economy.inspect(raw)["razi-network-frame-vesta-foundations"]["status"],
            "not-registered")
        raw = sample()
        raw["recipe"]["vesta-foundation"]["results"][0]["amount_min"] = 8
        self.assertEqual(
            economy.inspect(raw)["razi-network-frame-vesta-foundations"]["status"],
            "unverified")

    def test_implicit_factorio_half_second_is_used(self):
        raw = sample()
        raw["recipe"]["vesta-foundation"]["energy_required"] = None
        # Prototype defaults are represented as an absent field, not null.
        del raw["recipe"]["vesta-foundation"]["energy_required"]
        raw["recipe"]["razi-network-frame-vesta-foundations"][
            "energy_required"] = 2.24
        row = economy.inspect(raw)["razi-network-frame-vesta-foundations"]
        self.assertEqual(row["status"], "passes-budget")
        self.assertGreater(row["machine_throughput_change"], 0)


if __name__ == "__main__":
    unittest.main()
