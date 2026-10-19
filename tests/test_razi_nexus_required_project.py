"""Nexus Bosses is mandatory, with a real Ninefold Signal Project."""
import json,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
class NexusBossesProjectTests(unittest.TestCase):
    def test_hard_required_without_circular_load_order(self):
        dep=json.loads(read("info.json"))["dependencies"]
        self.assertIn("~ nexus-bosses >= 2.4.0",dep)
        self.assertFalse(any(x=="nexus-bosses" for x in dep))
        # Nexus Bosses itself declares ? razi-protocol. ~ requires
        # the source while letting its optional order stay acyclic.
    def test_exact_nine_native_source_kills(self):
        bridge=read("scripts/razi_nexus_trials.lua")
        for boss in ("arachnid-queen","watcher","rogue-spidertron",
                     "twin-maws","colossus","plague-hulk",
                     "storm-guardian","devourer","last-commander"):
            self.assertIn('"'+boss+'"',bridge)
        self.assertIn('pcall(remote.call,"nexus-bosses","get_state")',bridge)
        self.assertIn('snapshot.defeated[force.name]',bridge)
        self.assertIn('defeated[id]==true',bridge)
        self.assertIn('if type(defeated)~="table" then return nil end',bridge)
        self.assertNotIn('script.on_tick',bridge)
    def test_project_and_codex(self):
        source=read("scripts/razi_journal_projects.lua")
        for value in ('["nexus-trials"]="technology/nexus-convergence"',
                      'function M.visible(force,id)',
                      'local nexus_trials=require("scripts.razi_nexus_trials")',
                      'nexus_trials_reader(content,player,width-68,current)',
                      'razi_journal_action="nexus-codex"'):
            self.assertIn(value,source)
        self.assertIn('if id=="nexus-trials" then',source)
        self.assertIn('project-next-nexus-boss',source)
        journal=read("scripts/razi_journal.lua")
        self.assertIn('p.project=="nexus-trials"',journal)
        self.assertIn('if p.nexus_revision~=revision then draw(player)',journal)
    def test_convergence_final_gate(self):
        conv=read("scripts/razi_convergence.lua")
        self.assertIn('local nexus=M.nexus_status(force)',conv)
        self.assertIn('if not nexus then',conv)
        self.assertIn('if nexus.count<nexus.total then',conv)
        self.assertIn('return false,"convergence-need-nexus-source"',conv)
        self.assertIn('return false,"convergence-need-nexus-trials"',conv)
        self.assertLess(conv.index('return false,"convergence-need-nexus-trials"'),
                        conv.index('return false,"convergence-need-witnesses"'))
        self.assertIn('if saved.victory then return #M.stages+1 end',conv)
    def test_localization(self):
        en=read("locale/en/razi_journal_interface.cfg")
        ops=read("locale/en/galactic_operations.cfg")
        for k in ("project-nexus-trials","project-progress-nexus-trials",
                  "project-nexus-circle","project-nexus-open-codex",
                  "project-next-nexus-boss"):
            self.assertIn(k+"=",en)
        for k in ("convergence-nexus-heading","convergence-nexus-count",
                  "convergence-need-nexus-source","convergence-need-nexus-trials"):
            self.assertIn(k+"=",ops)
if __name__=="__main__":
    unittest.main()
