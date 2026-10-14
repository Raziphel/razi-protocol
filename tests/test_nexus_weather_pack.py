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
        # Nexus is a curated world; its atmosphere, threat and monster
        # companions are optional, and the upstream boss add-on installs
        # its own full enemy dependency chain when enabled.
        self.assertTrue(any(d.startswith("Nexus-Updated >=") for d in deps))
        # Nexus itself requires Nexus Threat, so declaring it here is redundant.
        self.assertNotIn("Nexus-Threat-Updated >= 1.1.0",deps)
        recommended=("celestial-weather-updated",
                     "celestial-weather-additions-updated",
                     "Big-Monsters")
        for mod in recommended:
            self.assertTrue(any(d.startswith("+ "+mod+" >=")
                                for d in deps),mod)
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
        for boss in ("arachnid-queen","watcher","rogue-spidertron",
                     "twin-maws","colossus","plague-hulk",
                     "storm-guardian","devourer","last-commander"):
            self.assertIn('boss="'+boss+'"',journal)
        for tech in ("photon-electronics","advanced-magnetic-shielding",
                     "nexus-storm-prediction","omega-substation",
                     "omega-accumulator","omega-beacon"):
            self.assertIn('tech="'+tech+'"',journal)
        bridge=read("scripts/razi_nexus_trials.lua")
        self.assertIn('pcall(remote.call,"nexus-bosses","get_state")',bridge)
        self.assertIn('pcall(remote.call,"nexus-bosses","open_codex"',bridge)
        self.assertNotIn('set_ignore_player_presence',bridge)
        self.assertNotIn('mark_defeated',bridge)
        # Neither cloned trophies nor a competing key/research system.
        for source in ("prototypes/compat/nexus_endgame.lua",
                       "prototypes/technology/transceiver_endgame.lua"):
            self.assertNotIn('name = "nexus-warp-key"',read(source))
        self.assertIn('["Nexus-Updated"]',read("prototypes/compat/nexus_endgame.lua"))
    def test_native_codex_and_weather_atlas(self):
        atlas=read("scripts/galactic_atlas.lua")
        operations=read("scripts/galactic_operations.lua")
        journal=read("scripts/razi_journal.lua")
        guide=read("scripts/razi_weather_guide.lua")
        self.assertIn('trials.snapshot(player.force)',atlas)
        self.assertIn('weather.for_quest({world=id})',atlas)
        self.assertIn('action=="nexus-codex"',operations)
        self.assertIn('action=="nexus-codex"',journal)
        self.assertIn('function M.refresh_nexus_visible()',journal)
        self.assertNotIn('script.on_nth_tick',journal)
        for planet in ("panglia","muria","vesta","rubia","paracelsin",
                       "cubium","rabbasca","igrys","khemia","carna","pelagos"):
            self.assertIn(planet+'={',guide)
        self.assertIn('settings.startup[config[2]]',guide)

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
