"""Guard the load-time indexes and invariants against future regressions."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

class DataStageFastPaths(unittest.TestCase):
    def test_unlock_index_is_shared_between_exchange_catalogues(self):
        text=source("prototypes/compat/planet_production_exchanges.lua")
        self.assertIn("local indexed_technologies, unlockers_by_recipe",text)
        self.assertIn("native_unlockers()[recipe_name]",text)
        self.assertIn("table.sort(matches)",text)
        self.assertIn("depends_on(name, gate)",text)
        self.assertIn("for _, supplied in ipairs(rule.supplier_recipes",text)

    def test_campaign_producers_scanned_once_and_live_techs_checked(self):
        text=source("prototypes/technology/campaign_weave.lua")
        self.assertIn("index_variant(rawget(recipe, \"normal\")",text)
        self.assertIn("index_variant(rawget(recipe, \"expensive\")",text)
        self.assertIn("build_indexes()",text)
        self.assertIn("producers_by_pack[pack]",text)
        self.assertIn("depends_on(name, target_name)",text)
        self.assertIn("has_compatible_lab",text)
        self.assertNotIn("for recipe_name, recipe in pairs(data.raw.recipe or {}) do\n    if (produces",text)

    def test_routes_indexed_after_bypass_pruning(self):
        text=source("prototypes/system/route_reconcile.lua")
        self.assertIn("local routes_by_pair = {}",text)
        self.assertIn("routes_by_pair[pair] or {}",text)
        self.assertIn("hazard_profiles.preserve_custom(routes[keep_name], connection)",text)
        self.assertIn("hazard_profiles.apply(route, hazard)",text)
        self.assertIn("routes_by_pair[pair] = {route_name}",text)
        self.assertIn('hazard_profiles.cap_sizes(connection, "small")',text)

    def test_no_client_setting_claim(self):
        text=source("docs/STARTUP_PERFORMANCE.md")
        self.assertIn("client-side prototype/sprite caches",text)
        self.assertIn("cache-prototype-data",text)

if __name__=="__main__":
    unittest.main()
