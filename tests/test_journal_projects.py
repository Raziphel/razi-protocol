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
        self.assertIn('for _,view in ipairs({"quests","projects","archive"})',journal)
        self.assertIn('projects.render(body,player,p,size)',journal)
        self.assertIn('p.view="projects"',journal)
    def test_source_data_and_delivery_validation(self):
        ui=read("scripts/razi_journal.lua")
        projects=read("scripts/razi_journal_projects.lua")
        self.assertIn('dyson.render(content,player,options)',projects)
        self.assertIn('trade.render(content,player,p,options)',projects)
        self.assertIn('convergence.render(content,player,options)',projects)
        self.assertIn('recovery_reader(content,player,width-68,statuses.recovery[3])',projects)
        self.assertIn('function recovery_status(force)',projects)
        self.assertIn('razi_journal_action="select"',projects)
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
        self.assertNotIn('(tech.researched or active) and 1 or 0,1',projects)
        self.assertIn('local function next_action(force,id,status)',projects)
        self.assertIn('local function recovery_status(force)',projects)
        self.assertIn('return done,#recovery_stages,states',projects)
        self.assertIn('local status=known_status or {status_for(force,id)}',projects)
        self.assertIn('function M.next_quest(force,id)',projects)
        self.assertIn('dossiers',read("prototypes/system/route_intel.lua"))
        self.assertIn('razi_journal_action="project-next"',projects)
        self.assertIn('action=="project-next"',journal)
        self.assertIn('projects.next_quest(player.force,p.project)',journal)
        self.assertIn('project-measures-dyson=',locale)
        self.assertIn('project-measures-cargo=',locale)
        self.assertIn('project-measures-transceiver=',locale)
        self.assertIn('project-measures-convergence=',locale)
        self.assertIn('scroll.tags={razi_scroll_context=p.project}',projects)
        self.assertNotIn('on_tick',projects)

    def test_embedded_views_have_one_scroller(self):
        for p in ("scripts/galactic_dyson.lua",
                  "scripts/galactic_trade.lua","scripts/razi_convergence.lua"):
            self.assertIn("options.embedded",read(p))
        self.assertIn('horizontal_scroll_policy="never"',
                      read("scripts/razi_journal_projects.lua"))
if __name__=="__main__":
    unittest.main()
