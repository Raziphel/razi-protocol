"""Regression for staged system cards and buildable Razi labs."""
import json
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def read(filename):
    return (ROOT / filename).read_text(encoding="utf-8")

class TechCardProgressionTests(unittest.TestCase):
    def test_eight_cards_keep_early_science_behind_accessible_worlds(self):
        source=read("prototypes/compat/lab_cards.lua")
        # Inspect each definition, not the global optional modded-science list.
        for card,forbidden in (
            ("solaris-tech-card","electrochemical-science-pack"),
            ("vibrant-tech-card","paracelsin-galvanization-science-pack"),
            ("vespera-tech-card","hydraulic-science-pack"),
            ("deep-space-tech-card","space-logistic-science-pack"),
            ("deep-space-tech-card","pulsar-science-pack")
        ):
            definition=re.search(
                r'\bname = "' + re.escape(card) + r'".*?fallback_ingredients',
                source,re.S)
            self.assertIsNotNone(definition,card)
            # Comments can name removed sources; only ingredient quotes count.
            ingredient_body=definition.group().split("ingredients = {",1)[1].split("}",1)[0]
            self.assertNotIn('"' + forbidden + '"',ingredient_body)

    def test_four_real_labs_and_five_science_tiers(self):
        source=read("prototypes/compat/system_card_laboratories.lua")
        for tier,name in enumerate((
            "razi-frontier-lab","razi-constellation-lab",
            "razi-astral-lab","razi-deep-space-lab"),start=2):
            self.assertRegex(source,
                r'id="' + name + r'",tier=' + str(tier))
        for id,value in (
            ("calidus-tech-card",1),("solaris-tech-card",2),
            ("nyxaris-tech-card",2),("vibrant-tech-card",3),
            ("vespera-tech-card",3),("beetlejuice-tech-card",4),
            ("umbra-tech-card",4),("deep-space-tech-card",5)):
            self.assertIn('rank["'+id+'"]='+str(value),source)
        self.assertIn('["lab"]=1',source)
        self.assertIn('["kr-singularity-lab"]=4',source)
        self.assertIn('["omega-lab"]=5',source)
        self.assertIn("restore_research_coverage()",source)
        self.assertIn("accepts(lab,noncards)",source)
        self.assertNotIn("research_all_technologies",source)

    def test_multiplex_recipes_are_optional_and_not_productivity_stacking(self):
        source=read("prototypes/compat/system_card_manufacturing.lua")
        pairs=re.findall(r'name="(razi-[\w-]+-multiplex-cards)",card="([^"]+)"',source)
        self.assertEqual(len(pairs),5)
        self.assertEqual(len(set(pairs)),5)
        self.assertIn('part.amount=part.amount*2',source)
        self.assertIn('name=rule.card,amount=3',source)
        self.assertIn("allow_productivity=false",source)
        self.assertIn("not recipes[rule.name]",source)
        self.assertIn("valid_base(base,rule.card)",source)
        self.assertNotIn('source-recipe=',source)

    def test_registrations_locales_and_docs(self):
        root=read("data-final-fixes.lua")
        self.assertLess(
            root.index('require("prototypes.compat.corrundum_k2so_lab_inputs").data_final_fixes()'),
            root.index('require("prototypes.compat.system_card_manufacturing").data_final_fixes()'))
        self.assertLess(
            root.index('require("prototypes.compat.system_card_manufacturing").data_final_fixes()'),
            root.index('require("prototypes.compat.system_card_laboratories").data_final_fixes()'))
        names=read("locale/en/names.cfg")
        for lab in ("razi-frontier-lab","razi-constellation-lab",
                    "razi-astral-lab","razi-deep-space-lab"):
            self.assertGreaterEqual(names.count(lab+"="),5)
        for recipe in ("razi-solaris-multiplex-cards","razi-nyxaris-multiplex-cards",
                       "razi-vibrant-multiplex-cards","razi-vespera-multiplex-cards",
                       "razi-deep-space-multiplex-cards"):
            self.assertEqual(names.count(recipe+"="),2)
        journal=read("scripts/razi_journal_data.lua")
        stories=read("locale/en/razi_journal.cfg")
        for quest in ("lab-frontier","lab-constellation","lab-astral",
                      "lab-deep-space"):
            self.assertIn('id="'+quest+'"',journal)
            self.assertEqual(stories.count(quest+"="),3)
        self.assertIn('self.assertEqual(len(quests),223)',
                      read("tests/test_razi_journal.py"))
        info=json.loads(read("info.json"))
        self.assertEqual(info["version"],"2.1.54")
        self.assertEqual(info["factorio_version"],"2.1")
        self.assertIn("laboratory tiers",read("docs/RESEARCH_TREE_BALANCE.md").lower())

if __name__=="__main__":
    unittest.main()
