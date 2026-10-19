"""Great Projects must represent native hardware and real journeys."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")
class GreatProjects(unittest.TestCase):
    def test_implemented_and_wired(self):
        ui=read("scripts/razi_journal_projects.lua")
        self.assertIn('local ids={"platform","voyage","skybridge","beltbreaker","dyson","array","transceiver","nexus-trials","ark","convergence"}',ui)
        for name in ("skybridge","beltbreaker","array","ark"):
            self.assertIn('great_project_reader(content,player,width-68,"'+name+'",current)',ui)
            self.assertIn('great_projects.'+name+'(force)',ui)
        self.assertIn('great_projects.sign(player,tags.a,tags.b)',read("scripts/razi_journal.lua"))
        self.assertIn('great_projects.deliver(player)',read("scripts/razi_journal.lua"))
        self.assertIn('great_projects.forces_merged(event)',read("control.lua"))
        self.assertIn('great_projects.flush_pending(game.forces)',read("control.lua"))
    def test_physical_proofs_and_original_gameplay(self):
        runtime=read("scripts/razi_great_projects.lua")
        for text in ('native_catapults()', 'surface.count_entities_filtered',
                     'completed_trips or 0','contains_pair(previous.from,previous.to,ends)',
                     'platform.space_connection','M.ark_weight=1000000',
                     'entity.energy>0','storage.razi_great_projects',
                     'function M.forces_merged(event)'):
            self.assertIn(text,runtime)
        self.assertNotIn('script.on_tick',runtime)
        self.assertNotIn('create_space_platform',runtime)
        self.assertNotIn('set_recipe',runtime)
        self.assertNotIn('research.researched=true',runtime)
    def test_new_buildable_receiver(self):
        prototypes=read("prototypes/technology/razi_great_projects.lua")
        self.assertIn('table.deepcopy(source)',prototypes)
        self.assertIn('relay.name="razi-archive-relay"',prototypes)
        self.assertIn('energy_usage="1MW"',prototypes)
        self.assertIn('name="razi-archive-array"',prototypes)
        self.assertIn('name="razi-skybridge-consignment"',prototypes)
        self.assertIn('require("prototypes.technology.razi_great_projects").data()',read("data.lua"))
    def test_archive_has_persistent_fragments(self):
        journal=read("scripts/razi_journal.lua")
        runtime=read("scripts/razi_great_projects.lua")
        self.assertIn('action=="array-record"',journal)
        self.assertIn('great_projects.recovered(player.force)',journal)
        self.assertIn('saved.archive_recovered=math.max(',runtime)
        loc=read("locale/en/razi_journal_interface.cfg")
        for name in ("skybridge","beltbreaker","array","ark"):
            for prefix in ("project-","project-caption-","project-progress-",
                           "project-context-","project-measures-","project-next-"):
                self.assertIn(prefix+name+"=",loc) if prefix!="project-next-" else None
        for i in range(1,4):
            self.assertIn("archive-array-title-"+str(i)+"=",loc)
            self.assertIn("archive-array-record-"+str(i)+"=",loc)
if __name__=="__main__":
    unittest.main()
