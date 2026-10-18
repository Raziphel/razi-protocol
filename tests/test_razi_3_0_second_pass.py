"""Second-pass source checks and synthetic crafting-navigation fixtures."""
import unittest
from pathlib import Path
from scripts.audit_crafting_navigation import analyze,barrel_recipe
from scripts.audit_campaign_consistency import inspect
ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def sample():
    filling={
        "subgroup":"fill-barrel",
        "ingredients":[{"type":"fluid","name":"water","amount":50},
                       {"type":"item","name":"empty-barrel","amount":1}],
        "results":[{"type":"item","name":"water-barrel","amount":1}]}
    emptying={
        "subgroup":"empty-barrel",
        "ingredients":[{"type":"item","name":"water-barrel","amount":1}],
        "results":[{"type":"fluid","name":"water","amount":50},
                   {"type":"item","name":"empty-barrel","amount":1}]}
    return {"raw":{
        "item-group":{"fluids":{},"intermediate-products":{}},
        "item-subgroup":{
            "fill-barrel":{"group":"fluids"},
            "empty-barrel":{"group":"fluids"},
            "custom":{"group":"production"},
            "bio":{"group":"intermediate-products"}},
        "item":{"bioflux":{"spoil_ticks":3600,"subgroup":"bio"}},
        "recipe":{
            "fill-water-barrel":filling,
            "empty-water-barrel":emptying,
            "fill-fake-barrel":{"subgroup":"fill-barrel","ingredients":[],"results":[]},
            "fill-custom-barrel":{**filling,"subgroup":"custom"},
            "organic-processing":{
                "subgroup":"bio","results":[{"type":"item","name":"bioflux","amount":1}]},
            "unknown-spoilage":{
                "subgroup":"bio","results":[{"type":"item","name":"not-registered","amount":1}]},
        }}}

class CraftingNavigationSecondPassTests(unittest.TestCase):
    def test_actual_barrel_components_not_just_names(self):
        recipes=sample()["raw"]["recipe"]
        self.assertTrue(barrel_recipe("fill-water-barrel",recipes["fill-water-barrel"]))
        self.assertTrue(barrel_recipe("empty-water-barrel",recipes["empty-water-barrel"]))
        self.assertFalse(barrel_recipe("fill-fake-barrel",recipes["fill-fake-barrel"]))
        self.assertFalse(barrel_recipe("other-name",recipes["fill-water-barrel"]))

    def test_audit_preserves_source_categories(self):
        report=analyze(sample())
        self.assertEqual(report["total_recipes"],6)
        self.assertEqual(report["verified_barrel_candidates"],
                         ["empty-water-barrel","fill-water-barrel"])
        self.assertEqual(report["barrel_named_but_unverified"],["fill-fake-barrel"])
        self.assertEqual(report["barrel_recipes_with_custom_groups"],
                         ["fill-custom-barrel"])
        self.assertEqual(report["optional_spoilable_candidates"],
                         ["organic-processing"])
        self.assertTrue(report["barrel_group_available"])

    def test_links_only_target_real_journal_quests(self):
        info=inspect(ROOT)
        self.assertEqual(info["related_quest_targets_missing"],[])
        self.assertEqual(info["duplicate_related_targets"],[])
        source=read("scripts/razi_journal.lua")
        self.assertIn("industrial_briefs.related(quest,defs.by_id)",source)
        self.assertIn("M.available(player.force,candidate,context)",source)
        self.assertIn('razi_journal_action="guidance-select"',source)

    def test_crafting_navigation_remains_nonmechanical(self):
        source=read("prototypes/compat/crafting_navigation.lua")
        for banned in ("recipe.ingredients=","recipe.results=",
                       "recipe.category=","recipe.enabled="):
            self.assertNotIn(banned,source)
        self.assertIn("source_fluid_group(recipe)",source)
        self.assertIn("barrel_recipe(name,recipe)",source)
        self.assertIn('enabled("razi-group-spoilable-recipes",false)',source)

if __name__=="__main__":
    unittest.main()
