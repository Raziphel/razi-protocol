"""Guard Codex bursts and campaign dependency logic with source checks."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

class CampaignStabilityTests(unittest.TestCase):
    def test_discovery_helpers_are_defined_by_the_gate_module(self):
        gates=source("prototypes/technology/seven_system_gates.lua")
        fixtures=source("tests/lua/test_galaxy.lua")
        for helper in ("science_pack_exists", "add_existing_prerequisites"):
            self.assertRegex(gates,rf"local function {helper}\(")
            self.assertNotIn(f'rawset(_G, "{helper}", function',fixtures)
        self.assertIn("not reaches(parent, name)",gates)
        self.assertIn("not reaches(prerequisite, name)",gates)
        self.assertIn('panglia_planet_discovery_panglia',gates)
        self.assertIn('space-discovery-asteroid-belt',gates)

    def test_bulk_research_does_not_redraw_each_unlock(self):
        codex=source("scripts/razi_journal.lua")
        control=source("control.lua")
        self.assertIn('RESEARCH_BURST_LIMIT=12',codex)
        self.assertIn('RESEARCH_BURST_QUIET=180',codex)
        handler=codex.split('function M.on_research(event)',1)[1].split(
            'function M.flush_research_refreshes()',1)[0]
        self.assertNotIn('draw(',handler)
        self.assertNotIn('render_tracker(',handler)
        self.assertIn('state.count=math.min(',handler)
        self.assertIn('pending[force.name]=state',handler)
        self.assertIn('refresh_force(game.forces[force_name])',codex)
        self.assertIn('script.on_nth_tick(30, function(event)',control)
        self.assertIn('razi_journal.flush_research_refreshes()',control)
        self.assertIn('storage.razi_journal_pending_forces={player=true}',
                      source("tests/lua/test_razi_journal.lua"))

    def test_staged_cheat_never_calls_synchronous_mass_research(self):
        control=source("control.lua")
        helper=source("scripts/razi_safe_cheat.lua")
        journal=source("scripts/razi_journal.lua")
        self.assertIn('commands.add_command("razi-cheat",',control)
        self.assertIn('script.on_nth_tick(6, razi_safe_cheat.tick)',control)
        self.assertIn('function M.command(event)',helper)
        self.assertIn('function M.tick()',helper)
        self.assertIn('tech.researched=true',helper)
        self.assertIn('tech.prerequisites or {}',helper)
        self.assertIn('player.admin',helper)
        self.assertIn('function M.defer_research_refresh(force)',journal)
        self.assertNotIn('research_all_technologies(',helper)
        self.assertNotIn('enable_all_recipes(',helper)
        self.assertNotIn('research_recursive(',helper)

    def test_campaign_checks_still_exercise_real_source_research(self):
        fixture=source("tests/lua/test_galaxy.lua")
        for token in (
            "Gateway research acquired a cycle through optional source research",
            "Safe upstream mastery was not restored",
            "Panglia native data-cell and foundry research was overwritten",
            "Nyxaris still requires Solaris completion",
            "Vespera unlocked without Solaris mastery",
            "Outer mastery does not require Beetlejuice",
            "Outer mastery does not require Umbra",
        ):
            self.assertIn(token,fixture)

if __name__=="__main__":
    unittest.main()
