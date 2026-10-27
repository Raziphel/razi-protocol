"""Regression contracts for dynamic science cards (Factorio loading still needed)."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
class AutoTechCardTests(unittest.TestCase):
    def test_final_run_after_research_edits(self):
        final=read("data-final-fixes.lua")
        self.assertEqual(final.count('require("prototypes.compat.auto_tech_cards").data_final_fixes()'),1)
        self.assertLess(final.index('require("prototypes.technology.distributed_industry").data_final_fixes()'),
                        final.index('require("prototypes.compat.auto_tech_cards").data_final_fixes()'))
    def test_dynamic_science_and_lab_scanning(self):
        src=read("prototypes/compat/auto_tech_cards.lua")
        for token in ("data.raw.technology", "data.raw.lab",
                      "lab_inputs[name] and original and not original.hidden",
                      "register_native_labs(mapping)", "change_research(mapping)"):
            self.assertIn(token,src)
    def test_no_science_inflation_or_spoil_reset(self):
        src=read("prototypes/compat/auto_tech_cards.lua")
        for token in ("table.deepcopy(original)","amount=1",
                      "reset_freshness_on_craft=false",
                      "allow_productivity=false","auto_recycle=false",
                      "seen[native_name]=true"):
            self.assertIn(token,src)
        self.assertNotIn("data.raw.tool[name]=nil",src)
        self.assertNotIn("data.raw.item[name]=nil",src)
    def test_opt_out(self):
        self.assertIn('name="razi-auto-tech-cards"',read("settings.lua"))
        self.assertIn("flag.value==false",read("prototypes/compat/auto_tech_cards.lua"))
        self.assertIn("razi-auto-tech-cards=",read("locale/en/settings.cfg"))
if __name__=="__main__": unittest.main()
