"""Convergence endgame: source materials, real deliveries and real victory."""
import json
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class ConvergenceTests(unittest.TestCase):
    def test_research_is_post_edge_and_not_an_early_transceiver_victory(self):
        proto=read("prototypes/technology/convergence.lua")
        self.assertIn('"stellar-discovery-solar-system-edge"',proto)
        self.assertIn('"razi-intergalactic-transceiver-signal"',proto)
        self.assertIn('"slp-dyson-sphere","discovery-aegis-outer"',proto)
        self.assertIn('"beetlejuice-tech-card"',proto)
        self.assertIn('"umbra-tech-card"',proto)
        self.assertIn('"deep-space-tech-card"',proto)
        self.assertIn("if not supported(chosen) then",proto)
        self.assertIn("if fallback then return unit(fallback) end",proto)
        self.assertIn("not ancestors(tech,candidate,goal)",proto)
        self.assertIn('if not (commission_science and final_science) then',proto)
        self.assertNotIn('type="lab"',proto)
        self.assertNotIn('type="planet"',proto)

    def test_five_genuinely_manufactured_non_productivity_manifests(self):
        proto=read("prototypes/technology/convergence.lua")
        entries=re.findall(r'\{id="([^"]+)",item="([^"]+)",count=(\d+)',proto)
        self.assertEqual(entries,[
            ("stellar","razi-convergence-stellar-mandate","8"),
            ("industry","razi-convergence-industrial-mandate","10"),
            ("deep-space","razi-convergence-deep-space-mandate","6"),
            ("resonance","razi-convergence-resonance-mandate","4"),
            ("ignition","razi-convergence-ignition-mandate","1")
        ])
        self.assertIn('categories={"crafting"}',proto)
        self.assertIn("allow_productivity=false",proto)
        self.assertIn("auto_recycle=false",proto)
        self.assertIn("allow_decomposition=false",proto)
        self.assertIn("products[part[1]]",proto)
        self.assertIn('local unlock=unlock_tech[rule.unlock or M.commission]',proto)
        self.assertIn("unlock.effects[#unlock.effects+1]",proto)
        self.assertNotIn("create_surface",proto)

    def test_real_player_cargo_and_force_owned_platform(self):
        runtime=read("scripts/razi_convergence.lua")
        self.assertIn("player.character",runtime)
        self.assertIn("player.controller_type==defines.controllers.remote",runtime)
        self.assertIn("character.surface",runtime)
        self.assertIn("platform.force==player.force",runtime)
        self.assertIn("platform.space_location",runtime)
        self.assertIn('["solar-system-edge"]=true',runtime)
        self.assertIn("player.get_main_inventory()",runtime)
        self.assertIn("inv.get_item_count(rule.item)",runtime)
        self.assertIn("inv.remove{name=rule.item,count=offered}",runtime)
        self.assertIn('saved.delivered[id]=math.min(rule.count,',runtime)
        self.assertIn("storage.razi_convergence",runtime)
        self.assertIn('if saved.victory then return #M.stages+1 end',runtime)
        self.assertIn("function M.repair_recipe_unlocks(force)",runtime)
        self.assertIn('"convergence-legacy-victory"',runtime)
        self.assertIn('quest.id=="convergence-ignition-research"',
                      read("scripts/razi_journal.lua"))
        self.assertIn('type="progressbar"',runtime)
        self.assertIn('"convergence-carried"',runtime)
        self.assertIn('carried>0 and where~=nil',runtime)
        self.assertIn("function M.forces_merged(event)",runtime)
        self.assertNotIn("on_nth_tick",runtime)
        self.assertNotIn("platform.schedule=",runtime)

    def test_dyson_coupling_and_saved_final_transmission(self):
        runtime=read("scripts/razi_convergence.lua")
        ops=read("scripts/galactic_operations.lua")
        control=read("control.lua")
        source=read("scripts/galactic_dyson_runtime.lua")
        locale=read("locale/en/galactic_operations.cfg")
        self.assertIn("dyson_runtime.resolve_receiver_names(prototypes)",runtime)
        self.assertIn("force.get_entity_count(name)",runtime)
        self.assertIn('return false,"convergence-need-receiver"',runtime)
        self.assertIn("if not M.dyson_readiness(force) then",runtime)
        self.assertIn("M.transmission_duration=720",runtime)
        self.assertIn("function M.advance(tick)",runtime)
        self.assertIn("function M.restore_pending()",runtime)
        self.assertIn("storage.razi_convergence_pending",runtime)
        self.assertIn("function M.refresh_convergence(force)",ops)
        self.assertIn('research.name~="razi-convergence-ignition"',ops)
        self.assertIn("convergence.restore_pending()",control)
        self.assertIn("convergence.advance(event.tick)",control)
        self.assertIn("galactic_operations.refresh_convergence(force)",control)
        self.assertIn('events:on_nth_tick(60,function(event)',control)
        self.assertIn('column_count=width>=560 and 5',runtime)
        self.assertIn("get_entity_count",source)
        for key in ("convergence-dyson-title","convergence-dyson-ready",
                    "convergence-dyson-missing","convergence-tile-complete",
                    "convergence-transmission-heading",
                    "convergence-transmission-sealed",
                    "convergence-transmission-dyson",
                    "convergence-transmission-resonance",
                    "convergence-transmission-alignment",
                    "convergence-transmission-started",
                    "convergence-need-receiver"):
            self.assertIn(key+"=",locale)

    def test_native_game_victory_waits_for_delivery(self):
        runtime=read("scripts/razi_convergence.lua")
        self.assertIn("function M.deliver(player,id)",runtime)
        self.assertIn("function M.completed(force,id)",runtime)
        self.assertIn("and M.current(force)>#M.stages",runtime)
        self.assertIn("if saved.victory then return end",runtime)
        self.assertIn("game.set_win_ending_info{",runtime)
        self.assertIn("game.reset_game_state()",runtime)
        self.assertIn("game.set_game_state{game_finished=true,player_won=true,",runtime)
        self.assertIn("can_continue=true",runtime)
        self.assertIn("saved.victory_tick=game.tick",runtime)
        # Commissioning itself must not call victory.
        self.assertNotIn("set_game_state",read("prototypes/technology/convergence.lua"))

    def test_real_ui_codex_locale_and_research_registration(self):
        final=read("data-final-fixes.lua")
        self.assertLess(
            final.index('require("prototypes.compat.system_card_laboratories").data_final_fixes()'),
            final.index('require("prototypes.technology.convergence").data_final_fixes()'))
        control=read("control.lua")
        self.assertIn('local convergence = require("scripts.razi_convergence")',control)
        self.assertIn("convergence.forces_merged",control)
        self.assertIn("convergence.repair_recipe_unlocks(force)",control)
        self.assertIn('remote.interfaces["space_finish_script"]',control)
        self.assertIn('remote.call("space_finish_script","set_no_victory",true)',control)
        ops=read("scripts/galactic_operations.lua")
        self.assertIn('if p.tab=="convergence" then convergence.render(body,player)',ops)
        self.assertIn('function M.open_convergence(player)',ops)
        self.assertIn('action=="convergence-deliver"',ops)
        journal=read("scripts/razi_journal.lua")
        self.assertIn('if quest.convergence then',journal)
        self.assertIn('operations.open_convergence(player)',journal)
        defs=read("scripts/razi_journal_data.lua")
        for id in ("convergence-commission","convergence-stellar",
                   "convergence-industry","convergence-synchronization",
                   "convergence-deep-space","convergence-resonance",
                   "convergence-ignition-research","convergence-ignition",
                   "convergence-victory"):
            self.assertIn('id="'+id+'"',defs)
            for section in ("journal-title","journal-story","journal-tip"):
                text=read("locale/en/razi_journal.cfg").split(
                    "["+section+"]",1)[1].split("\n[",1)[0]
                self.assertRegex(text,rf"(?m)^{re.escape(id)}=")
        self.assertIn("self.assertEqual(len(quests),228)",
                      read("tests/test_razi_journal.py"))
        self.assertIn("check(#defs.quests==228",
                      read("tests/lua/test_razi_journal.lua"))
        names=read("locale/en/names.cfg")
        ops_locale=read("locale/en/galactic_operations.cfg")
        for phase in ("stellar","industrial","deep-space","resonance","ignition"):
            name="razi-convergence-"+phase+"-mandate"
            self.assertGreaterEqual(names.count(name+"="),4)
        for key in ("convergence-heading=",
                    "convergence-stage-stellar=",
                    "convergence-stage-resonance=",
                    "convergence-stage-ignition=",
                    "convergence-submit=",
                    "convergence-victory-title="):
            self.assertIn(key,ops_locale)
        self.assertEqual(json.loads(read("info.json"))["version"],"2.1.59")

if __name__=="__main__":
    unittest.main()
