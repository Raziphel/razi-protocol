"""Research-tree visibility is cosmetic, not research-rebalancing."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def src(p):
    return (ROOT/p).read_text(encoding="utf8")
class NativeTreeTests(unittest.TestCase):
    def test_only_owned_research_nodes_are_polished(self):
        text=src("prototypes/technology/tech_tree_visibility.lua")
        self.assertIn("t.essential=true",text)
        self.assertIn('t.order=string.format("f[razi-campaign]-%02d",index)',text)
        for no in ("t.unit=","t.prerequisites=","t.effects="):
            self.assertNotIn(no,text)
        self.assertIn('"razi-outer-frontier-mastery"',text)
    def test_data_stage_wired(self):
        self.assertEqual(src("data-final-fixes.lua").count(
            'require("prototypes.technology.tech_tree_visibility").data_final_fixes()'),1)
if __name__=="__main__":
    unittest.main()
