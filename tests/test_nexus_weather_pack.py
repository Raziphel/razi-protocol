"""Static contract for source-owned Nexus trials and 2.1 weather support."""
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

class NexusWeatherIntegration(unittest.TestCase):
    def test_dependency_stack(self):
        info=json.loads(read("info.json"))
        deps=info["dependencies"]
        required=("Nexus-Updated",
                  "celestial-weather-updated","celestial-weather-additions-updated",
                  "Nexus-Threat-Updated","Big-Monsters")
        for mod in required:
            self.assertTrue(any(d.startswith(mod+" >=") for d in deps),mod)
        # Both add-ons declare `? razi-protocol`, so listing either here would
        # create an impossible two-way load-order dependency. They are enabled
        # by the curated profile and deliberately load after Razi instead.
        for profile_mod in ("nexus-rebalanced","nexus-bosses"):
            self.assertFalse(any(d.lstrip("?+~ ").split(" >=")[0] == profile_mod
                                 for d in deps),profile_mod)
        self.assertIn("? outer-rim",deps)
        self.assertIn("planet-muluna >= 2.7.25",deps)
        self.assertIn("! biological-machines-planet-wit",deps)
        self.assertIn("! shchierbin",deps)
    def test_source_owns_boss_stages(self):
        journal=read("scripts/razi_journal_expansion.lua")
        for name in ("nexus-whisper","nexus-chorus","nexus-convergence",
                     "nexus-silence","nexus-signal-bearing"):
            self.assertIn('tech="'+name+'"',journal)
        # Neither cloned trophies nor a competing key/research system.
        for source in ("prototypes/compat/nexus_endgame.lua",
                       "prototypes/technology/transceiver_endgame.lua"):
            self.assertNotIn('name = "nexus-warp-key"',read(source))
        self.assertIn('["Nexus-Updated"]',read("prototypes/compat/nexus_endgame.lua"))
    def test_no_auto_ci(self):
        workflow=read(".github/workflows/check.yml")
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotRegex(workflow,r"(?m)^\s+(?:push|pull_request):")
    def test_starmap_belt_preserved(self):
        routes=read("prototypes/system/route_reconcile.lua")
        self.assertIn('bypasses_vibrant_belt',routes)
        self.assertIn('{"asteroid-belt-outer-edge", "paracelsin"',routes)

if __name__=="__main__":
    unittest.main()
