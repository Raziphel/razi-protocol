"""Guard middle-frontier manufacturing integration and research gates."""
import re
import unittest
from tools.journal_locale import load_journal_locale
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf8")

class MiddleFrontierTests(unittest.TestCase):
    def test_four_guarded_production_rules(self):
        source=read("prototypes/compat/middle_frontier_industry.lua")
        self.assertEqual(len(re.findall(r'\bname="razi-middle-[^"]+"',source)),4)
        self.assertEqual(source.count("require_supplier_provenance=true"),4)
        self.assertEqual(source.count("max_bonus_fraction=0.25"),4)
        self.assertEqual(source.count("not_after="),4)
        self.assertIn("register_additional(rules)",source)
        self.assertNotIn("data:extend",source)

    def test_stage_promotion_preserves_optional_modes(self):
        gates=read("prototypes/technology/industrial_partnership_gates.lua")
        self.assertIn('"vibrant-discovery","vespera-discovery"',gates)
        self.assertIn('"beetlejuice-discovery","umbra-discovery"',gates)
        self.assertIn("if not mode.enabled() then return end",gates)
        self.assertIn("depends_on(candidate,gate)",gates)
        self.assertNotIn("research_all_technologies",gates)
        hook=read("data-final-fixes.lua")
        a=hook.index('require("prototypes.compat.middle_frontier_industry").data_final_fixes()')
        b=hook.index('require("prototypes.technology.industrial_partnership_gates").data_final_fixes()')
        c=hook.index('require("prototypes.technology.planetary_science_weave").data_final_fixes()')
        self.assertTrue(a<b<c)

    def test_every_new_factory_has_a_real_codex_milestone(self):
        workshop=read("prototypes/compat/middle_frontier_industry.lua")
        codex=read("scripts/razi_journal_industry.lua")
        prod=read("locale/en/production.cfg")
        lore=load_journal_locale(ROOT)
        for id,quest in (
            ("razi-middle-fulgora-resilient-capacitors","alliance-middle-fulgora"),
            ("razi-middle-aquilo-capacitor-controls","alliance-middle-aquilo"),
            ("razi-middle-paracelsin-shielded-coils","alliance-middle-paracelsin"),
            ("razi-middle-rubia-conductive-frames","alliance-middle-rubia")):
            self.assertIn('name="'+id+'"',workshop)
            self.assertIn('tech="'+id+'"',codex)
            self.assertIn('id="'+quest+'"',codex)
            self.assertEqual(prod.count(id+"="),4)
            for section in ("journal-title","journal-story","journal-tip"):
                block=lore.split("["+section+"]",1)[1].split("\n[",1)[0]
                self.assertRegex(block,rf"(?m)^{re.escape(quest)}=")

if __name__=="__main__":
    unittest.main()
