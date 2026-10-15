"""Guard required Athos/Nulla journal and research against regressions."""
from pathlib import Path
import json
import unittest
from tools.journal_locale import load_journal_locale

ROOT=Path(__file__).resolve().parents[1]
def read(p):
    return (ROOT/p).read_text(encoding="utf-8")

class FrontierRecoveryTests(unittest.TestCase):
    def test_both_worlds_are_required_in_exact_manifest(self):
        info=json.loads(read("info.json"))
        deps=info["dependencies"]
        self.assertGreaterEqual(tuple(map(int,info["version"].split("."))),(2,1,81))
        for name,minimum in (("nulla","1.0.2"),("PlanetAthos","1.1.3")):
            self.assertIn(f"{name} >= {minimum}",deps)
            self.assertFalse(any(d.startswith(("? "+name,"+ "+name,"! "+name))
                                 for d in deps),name)
        self.assertEqual(len(deps),97)
        self.assertIn("! outer-rim",deps)

    def test_native_science_and_late_lab_only(self):
        bridge=read("prototypes/compat/frontier_recovery.lua")
        self.assertIn('source_science("particulate-science-pack")',bridge)
        self.assertIn('raw("technology","robotic-science-pack")',bridge)
        self.assertIn('{"robotic-science-pack",1}',bridge)
        self.assertIn('{"particulate-science-pack",1}',bridge)
        self.assertIn('{"cryogenic-science-pack",1}',bridge)
        self.assertIn('{"omega-lab","kr-singularity-lab","pressure-lab"}',bridge)
        self.assertIn('mastery.prerequisites[#mastery.prerequisites+1]=id',bridge)
        self.assertIn('if not (nulla and athos and robots and particulate and lab and mastery',bridge)
        self.assertNotIn('type="lab"',bridge)
        self.assertNotIn('type="tool"',bridge)
        fixes=read("data-final-fixes.lua")
        self.assertIn('require("prototypes.compat.frontier_recovery").data_final_fixes()',fixes)
        self.assertGreater(
            fixes.index('require("prototypes.compat.frontier_recovery").data_final_fixes()'),
            fixes.index('require("prototypes.compat.system_card_laboratories").data_final_fixes()'))

    def test_real_codex_and_project_goals(self):
        main=read("scripts/razi_journal_data.lua")
        native=read("scripts/razi_journal_frontier.lua")
        projects=read("scripts/razi_journal_projects.lua")
        locale=load_journal_locale(ROOT)
        for id in ("athos","nulla","nulla-electromagnetic",
                   "nulla-robotic-science","frontier-recovery-charter"):
            self.assertIn(f'id="{id}"',main+native)
            for section in ("journal-title","journal-tip","journal-story"):
                block=locale.split(f"[{section}]",1)[1].split("\n[",1)[0]
                self.assertIn(f"\n{id}=",block)
        self.assertIn('id="athos-particulate"',native)
        self.assertIn('style="clickable_label"',projects)
        self.assertIn('local ids={"dyson","cargo","recovery"',projects)
        self.assertIn('razi_journal_action="select"',projects)
        self.assertIn('return done,#recovery_stages',projects)
        unification=read("prototypes/technology/planetary_unification.lua")
        self.assertIn('"igrys","athos"',unification)
        self.assertIn('"muria","aquilo","nulla"',unification)

if __name__=="__main__":
    unittest.main()
