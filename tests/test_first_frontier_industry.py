"""Static regression for the early Solaris/Nyxaris/Calidus freight triangle."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

NAMES = (
    "razi-frontier-moshine-biometal-silicon",
    "razi-frontier-gleba-photofiber",
    "razi-frontier-castra-composite-rounds",
)
QUESTS = (
    "alliance-frontier-moshine-silicon",
    "alliance-frontier-gleba-carbon",
    "alliance-frontier-castra-ballistics",
)

class FirstFrontierIndustryTests(unittest.TestCase):
    def test_only_optional_industry_is_registered(self):
        source = read("prototypes/compat/first_frontier_industry.lua")
        hooks = read("data-final-fixes.lua")
        self.assertEqual(len(re.findall(r'\bname="razi-frontier-[^"]+"', source)), 3)
        self.assertEqual(source.count("require_supplier_provenance=true"), 3)
        self.assertEqual(source.count("max_bonus_fraction=0.25"), 3)
        self.assertEqual(source.count("keep_native_category=true"), 3)
        self.assertIn('production.register_additional(rules)', source)
        self.assertEqual(
            hooks.count('require("prototypes.compat.first_frontier_industry").data_final_fixes()'), 1)
        self.assertLess(hooks.index('require("prototypes.compat.first_frontier_industry").data_final_fixes()'),
                        hooks.index('require("prototypes.technology.planetary_science_weave").data_final_fixes()'))
        for forbidden in ('unlock-space-location', 'data:extend', 'script.on_nth_tick',
                          'on_tick', 'map_gen_settings', 'research_all_technologies'):
            self.assertNotIn(forbidden, source)

    def test_locales_and_milestones_cover_every_factory(self):
        prod = read("locale/en/production.cfg")
        journal = read("locale/en/razi_journal.cfg")
        entries = read("scripts/razi_journal_industry.lua")
        for name, quest in zip(NAMES, QUESTS):
            self.assertEqual(prod.count(name + "="), 4, name)
            self.assertIn('id="' + quest + '"', entries)
            self.assertIn('tech="' + name + '"', entries)
            for section in ("journal-title", "journal-story", "journal-tip"):
                body=journal.split("[" + section + "]", 1)[1].split("\n[", 1)[0]
                self.assertRegex(body, rf"(?m)^{re.escape(quest)}=")

    def test_campaign_gates_remain_untouched(self):
        source = read("prototypes/compat/first_frontier_industry.lua")
        for mandatory in ('vibrant-discovery', 'vespera-discovery',
                          'beetlejuice-discovery', 'umbra-discovery'):
            self.assertNotIn(mandatory, source)
        self.assertIn('optional=true', read("scripts/razi_journal_industry.lua"))

if __name__ == "__main__":
    unittest.main()
