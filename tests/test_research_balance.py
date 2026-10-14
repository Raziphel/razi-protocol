"""Focused research-pacing checks using synthetic loaded Factorio prototypes."""
import importlib.util
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def load(path):
    spec=importlib.util.spec_from_file_location(
        "razi_research_balance",ROOT/"scripts"/path)
    mod=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

audit=load("audit_research_balance.py")

def fixture():
    techs={}
    for left,right in audit.PAIRS:
        techs[left]={"prerequisites":[],"unit":{
            "count":1000,"ingredients":[["calidus-tech-card",1]]}}
        techs[right]={"prerequisites":[],"unit":{
            "count":1000,"ingredients":[["calidus-tech-card",1]]}}
    techs["razi-network-precision-matrix"]={
        "prerequisites":["solaris-discovery"],
        "unit":{"count":420,"ingredients":[["solaris-tech-card",1],
                                           ["nyxaris-tech-card",1]]}}
    techs["razi-network-extreme-lattice"]={
        "prerequisites":["razi-network-precision-matrix"],
        "unit":{"count":680,"ingredients":[["vibrant-tech-card",1],
                                           ["vespera-tech-card",1]]}}
    return {"technology":techs,
            "tool":{name:{} for name in (
                "calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
                "vibrant-tech-card","vespera-tech-card")},
            "lab":{"advanced":{"inputs":[
                "calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
                "vibrant-tech-card","vespera-tech-card"]}}}


class ResearchBalanceTests(unittest.TestCase):
    def test_parallel_systems_remain_equal_independent(self):
        report=audit.examine(fixture())
        self.assertEqual(len(report["paired_entries"]),3)
        self.assertEqual(report["errors"],[])
        self.assertFalse(report["advisories"])
        self.assertEqual(report["paired_entries"][0]["status"],"independent")
        self.assertEqual(report["paired_entries"][1]["cost_ratio"],1.0)
        self.assertEqual(len(report["industry_research_prices"]),2)
        self.assertEqual(report["science_usage"]["solaris-tech-card"],1)

    def test_forbidden_gate_dependency_is_a_hard_error(self):
        raw=fixture()
        raw["technology"]["nyxaris-discovery"]["prerequisites"]=[
            "solaris-discovery"]
        result=audit.examine(raw)
        self.assertEqual(result["paired_entries"][0]["status"],"coupled")
        self.assertTrue(any(x["code"]=="paired-gates-dependent"
                            for x in result["errors"]))

    def test_gate_price_gap_is_only_advisory(self):
        raw=fixture()
        raw["technology"]["vespera-discovery"]["unit"]["count"]=2200
        result=audit.examine(raw)
        self.assertEqual(result["errors"],[])
        self.assertTrue(any(x["code"]=="uneven-paired-entry"
                            for x in result["advisories"]))

    def test_mismatched_laboratory_science_is_reported(self):
        raw=fixture()
        raw["lab"]["advanced"]["inputs"]=["calidus-tech-card"]
        report=audit.examine(raw)
        self.assertIn("razi-network-precision-matrix",
                      report["unresearchable_lab_combinations"])
        self.assertTrue(any(x["code"]=="no-shared-science-lab"
                            for x in report["errors"]))

    def test_lab_coverage_identifies_existing_native_labs(self):
        raw=fixture()
        result=audit.examine(raw)
        self.assertEqual(result["science_lab_coverage"][
            "razi-network-precision-matrix"],["advanced"])
        raw["lab"]["advanced"]["inputs"]=["calidus-tech-card"]
        result=audit.examine(raw)
        self.assertEqual(result["science_lab_coverage"][
            "razi-network-precision-matrix"],[])
        self.assertIn("razi-network-precision-matrix",
                      result["unresearchable_lab_combinations"])

    def test_stage_card_demand_counts_research_units_not_technologies(self):
        raw=fixture()
        raw["technology"]["solaris-discovery"]["unit"]["count"]=650
        raw["technology"]["nyxaris-discovery"]["unit"]["count"]=650
        report=audit.examine(raw)
        self.assertEqual(report["stage_card_demand"]["calidus"],
                         {"cards":{"calidus-tech-card":1300},
                          "direct_card_items":1300})
        self.assertEqual(report["stage_card_demand"]["middle"][
            "direct_card_items"],2000)
        self.assertFalse(report["stage_card_demand"]["finale"]["cards"])

    def test_missing_prototype_and_disabled_optional_world(self):
        raw=fixture()
        del raw["tool"]["vespera-tech-card"]
        raw["technology"]["razi-network-extreme-lattice"]["enabled"]=False
        report=audit.examine(raw)
        self.assertNotIn("razi-network-extreme-lattice",
                         report["missing_science_prototypes"])
        self.assertEqual(report["errors"],[])

    def test_science_pack_item_absence(self):
        raw=fixture()
        del raw["tool"]["nyxaris-tech-card"]
        report=audit.examine(raw)
        self.assertIn("razi-network-precision-matrix",
                      report["missing_science_prototypes"])
        self.assertTrue(any(x["code"]=="unknown-science-item"
                            for x in report["errors"]))

    def test_research_price_spike_is_only_advisory(self):
        raw=fixture()
        raw["technology"]["razi-network-extreme-lattice"]["unit"]["count"]=12000
        report=audit.examine(raw)
        self.assertEqual(report["errors"],[])
        self.assertTrue(any(x["code"]=="factory-price-spike"
                            for x in report["advisories"]))

    def test_native_planet_must_not_need_its_own_science(self):
        raw=fixture()
        raw["technology"]["planet-discovery-vesta"]={
            "prerequisites":["vesta-preparation"],
            "unit":{"count":500,"ingredients":[["vibrant-tech-card",1]]}}
        raw["technology"]["vesta-preparation"]={
            "unit":{"count":600,
                    "ingredients":[["gas-manipulation-science-pack",1]]}}
        report=audit.examine(raw)
        self.assertEqual(len(report["native_arrival_errors"]),1)
        self.assertEqual(report["native_arrival_errors"][0]["code"],
                         "own-world-science-before-arrival")
        self.assertEqual(report["native_arrival_errors"][0]["techs"],
                         ["vesta-preparation"])
        raw["technology"]["vesta-preparation"]["unit"]["ingredients"]=[
            ["vibrant-tech-card",1]]
        self.assertFalse(audit.examine(raw)["native_arrival_errors"])

    def test_native_pack_reuse_is_counted_without_claiming_manufacturing(self):
        raw=fixture()
        raw["tool"]["thermodynamic-science-pack"]={}
        raw["lab"]["advanced"]["inputs"].append(
            "thermodynamic-science-pack")
        raw["technology"]["razi-network-precision-matrix"]["unit"][
            "ingredients"].append(["thermodynamic-science-pack",1])
        report=audit.examine(raw)
        self.assertEqual(report["planetary_science_reuse"],
                         {"thermodynamic-science-pack":1})
        self.assertEqual(report["errors"],[])
        self.assertIn("thermodynamic-science-pack",
                      report["science_usage"])

    def test_tiered_card_manufacturing_report(self):
        raw=fixture()
        raw["recipe"]={
            "calidus-tech-card":{"ingredients":[
                {"name":"automation-science-pack","amount":1}],
                "energy_required":10},
            "solaris-tech-card":{"ingredients":[
                {"name":"calidus-tech-card","amount":1},
                {"name":"metallurgic-science-pack","amount":2}],
                "energy_required":12},
        }
        report=audit.examine(raw)
        self.assertEqual(report["errors"],[])
        rows={r["card"]:r for r in report["system_card_manufacturing"]}
        self.assertEqual(rows["solaris-tech-card"]["required_cards"],
                         ["calidus-tech-card"])
        self.assertEqual(rows["solaris-tech-card"]["other_inputs"],
                         ["metallurgic-science-pack"])
        self.assertEqual(rows["solaris-tech-card"]["total_ingredient_items"],3)

    def test_frontier_branches_count_direct_cards_not_native_panglia(self):
        raw=fixture()
        for system,names in audit.FRONTIER_BRANCHES.items():
            for name in names:
                raw["technology"][name]={"unit":{
                    "count":100,"ingredients":[["calidus-tech-card",1]]}}
        raw["technology"]["panglia_planet_discovery_panglia"]={
            "unit":{"count":3000,"ingredients":[["data-cell",1]]}}
        result=audit.examine(raw)
        self.assertEqual(result["first_frontier_card_demand"]["solaris"][
            "direct_card_items"],600)
        self.assertEqual(result["first_frontier_card_demand"]["nyxaris"][
            "direct_card_items"],300)
        self.assertNotIn("data-cell",str(result["first_frontier_card_demand"]))

    def test_freight_card_alternatives_have_bounded_value(self):
        raw=fixture()
        raw["recipe"]={
            "beetlejuice-tech-card":{
                "energy_required":22,"ingredients":[
                    {"name":"vibrant-tech-card","amount":1},
                    {"name":"vespera-tech-card","amount":1}],
                "results":[{"name":"beetlejuice-tech-card","amount":1}]},
            "razi-beetlejuice-multiplex-cards":{
                "energy_required":22*4*1.15,
                "allow_productivity":False,"auto_recycle":False,
                "allow_decomposition":False,
                "ingredients":[
                    {"name":"vibrant-tech-card","amount":4},
                    {"name":"vespera-tech-card","amount":4},
                    {"name":"gold-plate","amount":6},
                    {"name":"rare-earth-powder","amount":4}],
                "results":[{"name":"beetlejuice-tech-card","amount":5}]},
        }
        result=audit.examine(raw)
        self.assertEqual(result["errors"],[])
        self.assertEqual(result["multiplex_card_economy"][0]["status"],
                         "within-budget")
        self.assertAlmostEqual(
            result["multiplex_card_economy"][0]["gross_bonus_fraction"],0.25)
        self.assertGreater(result["multiplex_card_economy"][0][
            "machine_throughput_change"],0)
        self.assertLess(result["multiplex_card_economy"][0][
            "machine_throughput_change"],0.10)

    def test_freight_cards_cannot_skip_native_batches_or_amplify_bonus(self):
        raw=fixture()
        raw["recipe"]={
            "umbra-tech-card":{"energy_required":22,
                "ingredients":[{"name":"vespera-tech-card","amount":1}],
                "results":[{"name":"umbra-tech-card","amount":1}]},
            "razi-umbra-multiplex-cards":{
                "energy_required":22,"allow_productivity":True,
                "auto_recycle":True,
                "ingredients":[{"name":"vespera-tech-card","amount":2}],
                "results":[{"name":"umbra-tech-card","amount":5}]},
        }
        report=audit.examine(raw)
        self.assertEqual(report["multiplex_card_economy"][0]["status"],"review")
        self.assertTrue(any(item["code"]=="multiplex-economy-invalid"
                            for item in report["errors"]))

    def test_card_manufacturing_cycle_is_a_hard_error(self):
        raw=fixture()
        raw["recipe"]={
            "solaris-tech-card":{"ingredients":[["nyxaris-tech-card",1]]},
            "nyxaris-tech-card":{"ingredients":[["solaris-tech-card",1]]},
        }
        report=audit.examine(raw)
        cycles=[i for i in report["errors"]
                if i["code"]=="system-card-recipe-cycle"]
        self.assertEqual(len(cycles),1)
        self.assertEqual(set(cycles[0]["targets"]),
                         {"solaris-tech-card","nyxaris-tech-card"})

    def test_no_technology_table_is_safe_advisory(self):
        report=audit.examine({})
        self.assertEqual(report["errors"],[])
        self.assertEqual(report["paired_entries"][0]["status"],"not-installed")
        self.assertEqual(report["science_usage"],{})


if __name__=="__main__":
    unittest.main()
