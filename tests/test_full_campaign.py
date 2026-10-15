"""The one-command full-campaign audit should preserve advisory/strict boundaries."""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


auditor = load("razi_full_campaign", "audit_full_campaign.py")
source_tests = load("razi_audit_fixture", "../tests/test_audit_prototypes.py")


class FullCampaignTests(unittest.TestCase):
    def test_complete_fixture_has_no_definite_blockers(self):
        raw = source_tests.fixture()
        result = auditor.examine(raw)
        self.assertEqual(result["prototype_issues"], [])
        self.assertEqual(result["blocked_discoveries"], [])
        self.assertEqual(result["economy_issues"], {})
        self.assertEqual(result["research_errors"], [])
        self.assertEqual(len(result["research_tree"]["paired_entries"]),3)
        self.assertIn("industry_research_prices",result["research_tree"])
        self.assertIn("planetary_science_reuse",result["research_tree"])
        self.assertEqual(result["research_tree"]["native_arrival_errors"], [])
        self.assertIn("razi-network-frame-vesta-foundations",result["economy"])
        self.assertEqual(result["worlds_checked"], 0)
        self.assertEqual(result["focus"]["Panglia"]["status"], "not-installed")
        self.assertEqual(result["focus"]["Linox"]["status"], "not-installed")

    def test_research_polish_only_runs_after_source_arrival_guards(self):
        file=(ROOT/"data-final-fixes.lua").read_text(encoding="utf8")
        new='require("prototypes.technology.research_tree_polish").data_final_fixes()'
        last_guard='require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()'
        self.assertEqual(file.count(new),1)
        self.assertGreater(file.index(new),file.rfind(last_guard))
        self.assertGreater(file.index(new),file.index(
            'require("prototypes.compat.network_components").register_premium()'))
        polish=(ROOT/"prototypes/technology/research_tree_polish.lua").read_text(
            encoding="utf8")
        self.assertIn("M.safe_link(target,parent)",polish)
        self.assertIn("mode.deep()",polish)
        self.assertIn('node.essential=true',polish)
        self.assertNotIn("data:extend",polish)
        self.assertNotIn('["solaris-discovery"]=',polish)

    def test_post_integration_arrival_guards_run_last(self):
        entrypoint = (ROOT / "data-final-fixes.lua").read_text(encoding="utf-8")
        for name in ("linox_science_guard", "outer_science_arrival_guard"):
            call = ('require("prototypes.compat.' + name
                    + '").data_final_fixes()')
            self.assertEqual(entrypoint.count(call), 2)
            self.assertGreater(
                entrypoint.rfind(call),
                entrypoint.index(
                    'require("prototypes.compat.network_components").register_premium()'))

    def test_unknown_world_does_not_fail_the_audit(self):
        raw = source_tests.fixture()
        raw["planet"]["sideworld"] = {}
        report = auditor.examine(raw)
        self.assertEqual(report["planets"]["sideworld"]["status"],
                         "no-visible-native-unlock")
        self.assertFalse(report["blocked_discoveries"])

    def test_all_planets_receive_sorted_static_review_priorities(self):
        raw=source_tests.fixture()
        raw["planet"]["unmapped"]={}
        raw["planet"]["review-scripted"]={}
        report=auditor.examine(raw)
        rows={row["planet"]:row for row in report["planet_review_queue"]}
        self.assertEqual(set(rows),{"unmapped","review-scripted"})
        self.assertEqual(rows["unmapped"]["priority"],"review")
        self.assertEqual(rows["unmapped"]["discovery_status"],
                         "no-visible-native-unlock")
        self.assertFalse(rows["unmapped"]["has_listed_route"])
        self.assertIn("No listed route to Nauvis",
                      "; ".join(rows["unmapped"]["notes"]))
        self.assertEqual([r["planet"] for r in report["planet_review_queue"]],
                         ["review-scripted","unmapped"])

    def test_blocked_real_world_is_reported(self):
        raw = source_tests.fixture()
        raw["planet"]["panglia"] = {"surface_properties": {"pressure": 1401}}
        raw["technology"]["panglia_planet_discovery_panglia"] = {
            "unit": {"ingredients": [["data-cell", 1]]},
            "effects": [{"type": "unlock-space-location",
                         "space_location": "panglia"}]}
        raw["technology"]["late-data"] = {
            "prerequisites": ["panglia_planet_discovery_panglia"],
            "effects": [{"type": "unlock-recipe", "recipe": "data-cell"}]}
        raw["recipe"]["data-cell"] = {
            "enabled": False, "ingredients": [{"name": "iron-ore"}],
            "results": [{"name": "data-cell"}]}
        report = auditor.examine(raw)
        self.assertIn("panglia", report["blocked_discoveries"])
        self.assertEqual(report["focus"]["Panglia"]["status"], "blocked")
        raw["recipe"]["early-data"] = {
            "enabled": True, "ingredients": [],
            "results": [{"name": "data-cell"}]}
        self.assertNotIn("panglia",
                         auditor.examine(raw)["blocked_discoveries"])


if __name__ == "__main__":
    unittest.main()
