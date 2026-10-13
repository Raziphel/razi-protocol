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
        self.assertEqual(result["worlds_checked"], 0)
        self.assertEqual(result["focus"]["Panglia"]["status"], "not-installed")
        self.assertEqual(result["focus"]["Linox"]["status"], "not-installed")

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
