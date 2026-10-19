"""A.5 source-only interface assertions; run with the repository test suite."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


class SupplyPlannerContract(unittest.TestCase):
    def test_optional_recipe_and_source_region_guards(self):
        module = source("scripts/razi_supply_planner.lua")
        self.assertIn('require("scripts.razi_industry_portfolio")', module)
        self.assertIn('row.quest.tech==id', module)
        self.assertIn('"planet-discovery-"..site', module)
        self.assertIn('tech.researched==true', module)
        self.assertIn('route.target==destination', module)
        self.assertIn('entry.source_researched', module)
        self.assertIn('entry.target_researched', module)
        self.assertIn('freight.route(force,id)', module)

    def test_no_fabricated_material_or_shipments(self):
        module = source("scripts.razi_freight_orders.lua".replace(".", "/", 1)
                        if False else "scripts/razi_supply_planner.lua")
        self.assertIn("recipe.ingredients", module)
        self.assertIn("recipe.products", module)
        self.assertIn("ingredient.quality_min", module)
        self.assertIn('kind~="item"', module)
        self.assertIn('freight.positive_count(row.count)', module)
        for unsafe in ("remote.call", "get_inventory()", "on_tick",
                       "on_nth_tick", "script.on_event",
                       "create_entity", "insert{name=", "remove{name="):
            self.assertNotIn(unsafe, module)

    def test_atomic_bulk_guard_and_unchanged_draft(self):
        orders = source("scripts/razi_freight_orders.lua")
        body = orders.split("function M.add_many", 1)[1].split(
            "function M.add_spec", 1
        )[0]
        self.assertIn("#s.orders+#specs>LIMIT", body)
        self.assertIn("for _,spec in ipairs(specs)", body)
        self.assertIn("local prepared={}", body)
        self.assertIn("for _,spec in ipairs(prepared)", body)
        self.assertLess(body.index("for _,spec in ipairs(specs)"),
                        body.index("for _,spec in ipairs(prepared)"))
        self.assertNotIn("s.draft=", body)
        self.assertIn("function M.plan_all(", source("scripts/razi_supply_planner.lua"))

    def test_user_actions_and_l10n(self):
        journal = source("scripts/razi_journal.lua")
        supply = source("scripts/razi_supply_planner.lua")
        trade = source("scripts/galactic_trade.lua")
        locale = source("locale/en/razi_freight_readiness.cfg")
        self.assertIn('current=="supply"', trade)
        self.assertIn('native=="supply-plan-all"', journal)
        self.assertIn('native=="supply-route"', journal)
        self.assertIn('native=="supply-plan"', journal)
        self.assertIn('native=="supply-recalculate"', journal)
        self.assertIn('ra zi_ops_action=="supply-recipe"'.replace("ra zi_", "razi_"), journal)
        self.assertIn('ra zi_ops_action=="supply-batches"'.replace("ra zi_", "razi_"), journal)
        self.assertIn('tags={razi_ops_action="supply-plan-all"}', supply)
        self.assertIn('tags={razi_ops_action="supply-freight"}', supply)
        keys = set(re.findall(r'^([\w-]+)=', locale, re.MULTILINE))
        uses = set(re.findall(r'L\("(supply-[\w-]+)"', supply))
        uses.update(re.findall(r'L\("(logistics-tab-supply)"', trade))
        self.assertFalse(uses - keys, "Missing supply locale: " + str(uses - keys))


if __name__ == "__main__":
    unittest.main()
