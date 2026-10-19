"""Exclusive Convergence victory across supported installed source mods."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name): return (ROOT/name).read_text(encoding="utf-8")
class ExclusiveVictoryTests(unittest.TestCase):
    def test_only_supported_remote_interfaces_touched(self):
        guard=read("scripts/razi_victory_guard.lua")
        for name in ("space_finish_script","kr-intergalactic-transceiver","silo_script"):
            self.assertIn('"'+name+'"',guard)
        self.assertIn('pcall(remote.call,interface,"set_no_victory",true)',guard)
        self.assertIn('function M.inspect()',guard)
        self.assertIn('function M.enforce()',guard)
        self.assertNotIn("remote.add_interface",guard)
        self.assertNotIn('getmetatable(game)',guard)
        self.assertNotIn("game.set_game_state",guard.split("function M.enforce()",1)[1].split("function M.prepare()",1)[0].replace("an arbitrary\n-- mod's game.set_game_state call.",""))
    def test_do_not_rewrite_undocumented_mod_endings(self):
        guard=read("scripts/razi_victory_guard.lua")
        self.assertIn('if api and api.set_no_victory then',guard)
        self.assertIn('elseif api then',guard)
        self.assertIn('state="unverified"',guard)
        self.assertIn('state="unsupported"',guard)
        self.assertIn('state="absent"',guard)
        self.assertIn('state="unmanaged"',guard)
        self.assertIn('not known[name]',guard)
    def test_existing_victory_and_convergence_are_preserved(self):
        guard=read("scripts/razi_victory_guard.lua")
        self.assertIn('inherited_finished=(game.finished==true',guard)
        self.assertIn('if state.inherited_finished or convergence_won() then return false end',guard)
        self.assertIn('game.reset_game_state()',guard)
        self.assertIn('function M.recover_unexpected()',guard)
        conv=read("scripts/razi_convergence.lua")
        self.assertIn('saved.victory=true',conv)
        self.assertIn('game.set_game_state{game_finished=true,player_won=true,',conv)
    def test_guard_is_wired_across_loads_and_kept_alive(self):
        control=read("control.lua")
        self.assertIn('victory_guard.prepare()',control)
        self.assertIn('victory_guard.enforce()',control)
        self.assertIn('victory_guard.recover_unexpected()',control)
        self.assertIn('events:on_nth_tick(600, function()',control)
        self.assertIn('events:on_nth_tick(60,function(event)',control)
        self.assertIn('commands.add_command("razi-victory-audit"',control)
        self.assertIn('if player and not player.admin then',control)
        self.assertIn('victory_guard.inspect()',control)
        self.assertIn('victory_guard.recoveries()',control)
    def test_other_mod_gameplay_kept(self):
        control=read("control.lua")
        self.assertIn('convergence.advance(event.tick)',control)
        self.assertIn('check_existing_transceivers()',control)
        self.assertIn('razi_journal.refresh_nexus_visible()',control)
        self.assertNotIn('tech.enabled=false',read("scripts/razi_victory_guard.lua"))
        self.assertNotIn('destroy()',read("scripts/razi_victory_guard.lua"))
if __name__=="__main__":
    unittest.main()
