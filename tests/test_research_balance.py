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

    def test_no_technology_table_is_safe_advisory(self):
        report=audit.examine({})
        self.assertEqual(report["errors"],[])
        self.assertEqual(report["paired_entries"][0]["status"],"not-installed")
        self.assertEqual(report["science_usage"],{})


if __name__=="__main__":
    unittest.main()
