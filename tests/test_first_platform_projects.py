"""Physical Projects and legacy logistics references contract."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def source(p): return (ROOT/p).read_text(encoding="utf-8")
class FirstPlatformProjects(unittest.TestCase):
    def test_project_index(self):
        p=source("scripts/razi_journal_projects.lua")
        self.assertIn('local ids={"platform","voyage","skybridge","beltbreaker","dyson","array","transceiver","ark","convergence"}',p)
        self.assertNotIn('local ids={"dyson","cargo","recovery","transceiver","convergence"}',p)
        self.assertIn('function M.cargo_available(force)',p)
        self.assertIn('local function cargo_reference(parent,player,p,size)',p)
        self.assertIn('trade.render(content,player,p,{embedded=true,width=size.width-83})',p)
        self.assertIn('platform_reader(content,player,width-68,p.project,current)',p)
        self.assertNotIn('recovery_reader(',p)
    def test_real_platform_ownership(self):
        p=source("scripts/razi_platform_projects.lua")
        for key in ("platform.hub","hub.valid==true","platform.completed_trips>0",
                    "storage.razi_project_milestones","function M.observe(platform)",
                    "function M.snapshot(force)","function M.forces_merged(event)"):
            self.assertIn(key,p)
        self.assertNotIn('create_space_platform',p)
        self.assertNotIn('script.on_tick',p)
    def test_migration_and_native_events(self):
        c=source("control.lua")
        j=source("scripts/razi_journal.lua")
        for key in ("on_space_platform_built_entity","on_space_platform_built_tile",
                    "on_space_platform_changed_state"):
            self.assertIn("defines.events."+key,c)
        self.assertIn("platform_projects.forces_merged(event)",c)
        self.assertIn('view="quests",project="platform"',j)
        self.assertIn('value.project=="cargo"',j)
        self.assertIn('id=="recovery"',j)
        self.assertIn("project-back",j)
        self.assertIn('M.open_project(player,"cargo",chain,target)',j)
    def test_copy(self):
        s=source("locale/en/razi_journal_interface.cfg")
        for name in ("platform","voyage","dyson","transceiver","convergence"):
            for prefix in ("project-","project-caption-","project-progress-",
                           "project-context-","project-measures-"):
                self.assertIn(prefix+name+"=",s)
        self.assertNotIn("project-cargo=",s)
        self.assertNotIn("project-recovery=",s)
if __name__=="__main__": unittest.main()
