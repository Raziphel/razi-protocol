"""Protect the unified Journal project UI and existing save data."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text()
class ProjectsTests(unittest.TestCase):
    def test_single_window_and_legacy_hotkey(self):
        control=read("control.lua")
        journal=read("scripts/razi_journal.lua")
        self.assertIn('razi_journal.open_project(player)',control)
        self.assertNotIn('galactic_operations.sync_all_map_buttons',control)
        self.assertIn('retire_operations(player)',control)
        self.assertIn('for _,view in ipairs({"quests","projects","archive","systems"})',journal)
        self.assertIn('projects.render(body,player,p,size)',journal)
        self.assertIn('p.view="projects"',journal)
    def test_source_data_and_delivery_validation(self):
        ui=read("scripts/razi_journal.lua")
        projects=read("scripts/razi_journal_projects.lua")
        self.assertIn('dyson.render(content,player,options)',projects)
        self.assertIn('trade.render(content,player,p,{embedded=true,width=size.width-83})',projects)
        self.assertIn('convergence.render(content,player,options)',projects)
        self.assertIn('platform_reader(content,player,width-68,p.project,current)',projects)
        self.assertIn('local ids={"platform","voyage","skybridge","beltbreaker","dyson","array","transceiver","nexus-trials","ark","convergence"}',projects)
        self.assertNotIn('local ids={"dyson","cargo","recovery","transceiver","convergence"}',projects)
        self.assertIn('convergence.deliver(player,tags.value)',ui)
        self.assertIn('projects.valid_cargo(player.force,chain,target)',ui)
        self.assertIn('for _,stage in ipairs(convergence.stages)',ui)
        self.assertNotIn('create_surface(',projects)
        self.assertNotIn('on_nth_tick',projects)
    def test_project_status_and_guidance_match_real_events(self):
        projects=read("scripts/razi_journal_projects.lua")
        journal=read("scripts/razi_journal.lua")
        locale=read("locale/en/razi_journal_interface.cfg")
        self.assertIn('return active and 1 or 0,1,tech',projects)
        self.assertIn('return (facts[id] and 1 or 0),1,facts',projects)
        self.assertNotIn('(tech.researched or active) and 1 or 0,1',projects)
        self.assertIn('local function next_action(force,id,status)',projects)
        self.assertIn('local status=known_status or {status_for(force,id)}',projects)
        self.assertIn('function M.next_quest(force,id,known_status)',projects)
        self.assertIn('platform_projects.snapshot(player.force)',projects)
        self.assertIn('dossiers',read("prototypes/system/route_intel.lua"))
        self.assertIn('razi_journal_action="project-next"',projects)
        self.assertIn('action=="project-next"',journal)
        self.assertIn('action=="project-cycle"',journal)
        self.assertIn('function M.adjacent(force,id,step,known_visible)',projects)
        self.assertIn('function M.cargo_available(force)',projects)
        self.assertIn('razi_journal_action="project-cycle"',projects)
        self.assertIn('projects.next_quest(player.force,p.project)',journal)
        self.assertIn('project-measures-dyson=',locale)
        self.assertIn('project-measures-platform=',locale)
        self.assertIn('project-measures-voyage=',locale)
        self.assertNotIn('project-cargo=',locale)
        self.assertNotIn('project-recovery=',locale)
        self.assertIn('project-measures-transceiver=',locale)
        self.assertIn('project-measures-convergence=',locale)
        self.assertIn('project-context-convergence=',locale)
        self.assertIn('project-next-convergence-receiver=',locale)
        self.assertIn('if current>=3 then',projects)
        self.assertIn('project-back',journal)
        self.assertIn('M.open_project(player,"cargo",chain,target)',journal)
        self.assertIn('if id=="platform" then return true end',projects)
        self.assertIn('if id=="voyage" then return platform_projects.snapshot(force).platform end',projects)
        self.assertIn('name="planet-discovery-sunorbit"',projects)
        self.assertIn('if not known_status and not M.visible(force,id)',projects)
        self.assertIn('if current>=5 then',projects)
        self.assertIn('convergence.dyson_readiness(force)',projects)
        self.assertIn('scroll.tags={razi_scroll_context=p.project}',projects)
        self.assertNotIn('on_tick',projects)

    def test_project_dossier_spacing_uses_flow_style(self):
        """FrameStyle cannot accept FlowStyle.vertical_spacing in Factorio."""
        projects=read("scripts/razi_journal_projects.lua")
        self.assertIn('local next=content.add{type="frame",direction="vertical",',projects)
        self.assertIn('local next_body=next.add{type="flow",direction="vertical"}',projects)
        self.assertIn('next_body.style.vertical_spacing=4',projects)
        self.assertNotIn('next.style.vertical_spacing=',projects)
        for snippet in (
            'local eyebrow=next_body.add{',
            'local guidance=next_body.add{',
            'next_body.add{type="button",caption=L("project-open-next")',
            'local perspective=next_body.add{',
        ):
            self.assertIn(snippet,projects)

    def test_embedded_views_have_one_scroller(self):
        for p in ("scripts/galactic_dyson.lua",
                  "scripts/galactic_trade.lua","scripts/razi_convergence.lua"):
            self.assertIn("options.embedded",read(p))
        self.assertIn('horizontal_scroll_policy="never"',
                      read("scripts/razi_journal_projects.lua"))
if __name__=="__main__":
    unittest.main()
