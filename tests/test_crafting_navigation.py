"""Static integration guards for Factorio 2.1's machine-only menu cleanup."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

class CraftingNavigationIntegrationTests(unittest.TestCase):
    def test_final_pass_runs_after_all_late_recipe_producers(self):
        script = read("data-final-fixes.lua")
        call = 'require("prototypes.compat.crafting_navigation").data_final_fixes()'
        self.assertEqual(script.count(call), 1)
        self.assertGreater(script.index(call),
                           script.index('require("temporary.factorio_2_1_22.loader")'))

    def test_data_pass_never_removes_machines_or_recipe_unlocks(self):
        script = read("prototypes/compat/crafting_navigation.lua")
        self.assertIn("recipe.hide_from_player_crafting = true", script)
        for mutation in ("recipe.category =", "recipe.categories =",
                         "recipe.ingredients =", "recipe.results =",
                         "recipe.hidden = true", "recipe.enabled ="):
            self.assertNotIn(mutation, script)

    def test_modes_and_settings_are_localized(self):
        settings = read("settings.lua")
        self.assertIn('name="razi-hand-crafting-cleanup"', settings)
        self.assertIn('allowed_values={"off","razi","all"}', settings)
        self.assertIn('setting_type="startup",default_value="all"', settings)
        for language in ("en", "ru"):
            locale = read(f"locale/{language}/settings.cfg")
            for suffix in ("", "-off", "-razi", "-all"):
                self.assertIn(f"razi-hand-crafting-cleanup{suffix}=", locale)

    def test_runtime_fixture_covers_scope_and_optional_grouping(self):
        fixture = read("tests/lua/test_crafting_navigation.lua")
        for expected in ('fixture("all",true,true)', 'fixture("razi",false,true)',
                         'fixture("off",false,false)', "fluid-mixed",
                         "hybrid-machine", "special-hand", "sandbox-only"):
            self.assertIn(expected, fixture)

if __name__ == "__main__":
    unittest.main()
