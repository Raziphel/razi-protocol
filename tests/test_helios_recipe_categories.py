"""Guard every Project HELIOS recipe against removed Factorio 2.1 fields."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
BUILDERS = (
    "prototypes/compat/helios_engineering.lua",
    "prototypes/compat/helios_structures.lua",
)

class HeliosRecipeCategoriesTests(unittest.TestCase):
    def test_all_new_helios_recipes_use_21_categories(self):
        for filename in BUILDERS:
            with self.subTest(filename=filename):
                code = (ROOT / filename).read_text(encoding="utf-8")
                # Removed in Factorio 2.1. Also reject the legacy optional list.
                self.assertIsNone(re.search(r'(?<![\w])category\s*=', code))
                self.assertIsNone(re.search(r'(?<![\w])additional_categories\s*=', code))
                self.assertRegex(code, r'categories\s*=\s*\{\s*"advanced-crafting"\s*\}')

    def test_lua_fixtures_assert_actual_recipe_arrays(self):
        tests = (
            ROOT / "tests/lua/test_helios_engineering.lua",
            ROOT / "tests/lua/test_helios_structures.lua",
        )
        for path in tests:
            with self.subTest(path=path.name):
                code = path.read_text(encoding="utf-8")
                self.assertIn('.categories[1]=="advanced-crafting"', code)

if __name__ == "__main__":
    unittest.main()
