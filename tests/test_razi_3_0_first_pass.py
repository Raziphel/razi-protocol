"""Regression guards for the 3.0 narrative, recipe and content pilots."""
from pathlib import Path
import unittest
from scripts.audit_campaign_consistency import inspect
from tools.journal_locale import load_journal_locale,validate

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class RaziThreePilotTests(unittest.TestCase):
    def test_all_records_and_industrial_briefs_are_source_gated(self):
        report=inspect(ROOT)
        self.assertEqual(report["record_count"],25)
        self.assertEqual(report["brief_count"],12)
        for key in ("duplicate_quest_ids","duplicate_record_ids",
                    "record_unlocks_without_quests","briefs_without_quests",
                    "locale_errors"):
            self.assertEqual(report[key],[],key)

    def test_new_locale_joins_existing_validator(self):
        count,problems=validate(ROOT)
        self.assertGreater(count,0)
        self.assertEqual(problems,[])
        text=load_journal_locale(ROOT)
        self.assertIn("corp-welcome=RAZI / 01",text)
        self.assertIn("industrial-brief-heading=INDUSTRIAL OPPORTUNITY",text)

    def test_archive_and_dossier_use_existing_user_interface(self):
        records=read("scripts/razi_journal_records.lua")
        journal=read("scripts/razi_journal.lua")
        self.assertIn('require("scripts.razi_journal_corporate")',records)
        self.assertIn("industrial_briefs.for_quest(quest)",journal)
        self.assertIn('{"razi-industries-brief."..brief}',journal)
        self.assertNotIn("script.on_nth_tick",read("scripts/razi_journal_corporate.lua"))

    def test_recipe_reorganization_has_no_crafting_changes(self):
        source=read("prototypes/compat/crafting_navigation.lua")
        self.assertIn('recipe.subgroup="razi-fluid-barreling"',source)
        self.assertIn('recipe.subgroup="razi-perishable-products"',source)
        for unsafe in ("recipe.category=","recipe.ingredients=",
                       "recipe.results=","recipe.enabled="):
            self.assertNotIn(unsafe,source)
        self.assertIn('name="razi-group-spoilable-recipes"',read("settings.lua"))
        self.assertIn('default_value=false',read("settings.lua"))
        self.assertIn(
            'require("prototypes.compat.crafting_navigation").data_final_fixes()',
            read("data-final-fixes.lua"))

if __name__=="__main__":
    unittest.main()
