"""Ensure optional freight has distinct, bounded gameplay and clear tooltips."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def src(path):
    return (ROOT/path).read_text(encoding="utf-8")

class ExchangeIdentity(unittest.TestCase):
    def setUp(self):
        self.policy=src("prototypes/compat/industry_portfolio.lua")
        self.engine=src("prototypes/compat/planet_production_exchanges.lua")
        self.locale=src("locale/en/production.cfg")

    def test_every_curated_exchange_has_one_mechanical_identity(self):
        retained=self.policy.split("local retained={",1)[1].split("\n}",1)[0]
        profiles=self.policy.split("local profiles={",1)[1].split("\n}",1)[0]
        ids=re.findall(r'\["(razi-[^"]+)"\]=true',retained)
        assignments=re.findall(
            r'\["(razi-[^"]+)"\]=\{\s*kind="(catalytic|accelerated|bulk)"',
            profiles)
        self.assertEqual(len(ids),15)
        self.assertEqual(dict(assignments).keys(),set(ids))
        self.assertEqual(len(assignments),15)
        self.assertEqual(
            {kind:sum(k==kind for _,k in assignments)
             for kind in ("catalytic","accelerated","bulk")},
            {"catalytic":5,"accelerated":6,"bulk":4})

    def test_physical_catalysts_do_not_edit_native_recipe(self):
        self.assertIn("alternative = deepcopy(base)",self.engine)
        self.assertIn("portfolio.conserve(alternative.ingredients,profile)",self.engine)
        self.assertIn("in ipairs(alternative.ingredients)",self.engine)
        self.assertIn("profile.type or",self.policy)
        self.assertIn("math.floor(ingredient.amount*profile.fraction)",self.policy)
        self.assertIn("return false,0",self.policy)

    def test_acceleration_is_bounded_and_deep_uses_cargo(self):
        self.assertIn("amount*1.17",self.policy)
        self.assertIn("math.max(1.06,minimum)",self.policy)
        self.assertIn("import.amount=math.ceil(import.amount*1.5)",self.engine)
        self.assertIn("alternative.allow_productivity = false",self.engine)
        self.assertIn("alternative.auto_recycle = false",self.engine)

    def test_tooltips_explain_effects(self):
        self.assertIn('"razi-industry-profile." .. profile.kind',self.engine)
        for key in ("catalytic","accelerated","bulk"):
            self.assertRegex(self.locale,rf"(?m)^{key}=.+")
        for keyword in ("native", "Imported", "source"):
            self.assertIn(keyword,self.locale)

if __name__=="__main__":
    unittest.main()
