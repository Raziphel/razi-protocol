"""Orbital Catapult Vespera integration: dependency and authored corridor audit."""
from pathlib import Path
import json
import re
import unittest
from scripts.audit_campaign_consistency import inspect

ROOT=Path(__file__).resolve().parents[1]
def content(path):
    return (ROOT/path).read_text(encoding="utf-8")

class OrbitalCatapultTests(unittest.TestCase):
    def test_required_order_independent_upstream_dependency(self):
        meta=json.loads(content("info.json"))
        self.assertEqual(meta["name"],"razi-protocol")
        self.assertIn("~ orbital-cannon >= 0.15.0",meta["dependencies"])
        self.assertNotIn("orbital-cannon >= 0.15.0",meta["dependencies"])
        self.assertFalse(any("! orbital-cannon" in x for x in meta["dependencies"]))
        self.assertIn("PlanetsLib >= 2.0.9",meta["dependencies"])

    def test_six_curated_bidirectional_neighbor_corridors(self):
        code=content("prototypes/compat/orbital_catapult.lua")
        records=re.findall(
            r'\{"(razi-[a-z-]+-catapult)","([a-z-]+)","([a-z-]+)"\}',
            code)
        self.assertEqual(len(records),12)
        self.assertEqual(len(set(item[0] for item in records)),12)
        edges={(a,b) for _,a,b in records}
        expected={("muria","aquilo"),("aquilo","muria"),
                  ("muria","rubia"),("rubia","muria"),
                  ("rubia","aquilo"),("aquilo","rubia"),
                  ("vulcanus","castra"),("castra","vulcanus"),
                  ("gleba","moshine"),("moshine","gleba"),
                  ("rubia","maraxsis"),("maraxsis","rubia")}
        self.assertEqual(edges,expected)
        for a,b in edges:
            self.assertIn((b,a),edges)
        self.assertIn("source~=target",code)
        self.assertIn("planets[source] and planets[target]",code)
        self.assertIn("not (occupied and occupied[name])",code)
        self.assertIn('link_type="transport"',code)

    def test_existing_setting_now_enabled_without_new_save_key(self):
        settings=content("settings.lua")
        m=re.search(r'name="razi-orbital-catapult-local-links"(.{0,90})',settings)
        self.assertIsNotNone(m)
        self.assertIn('setting_type="startup"',m.group(1))
        self.assertIn("default_value=true",m.group(1))
        for path in ("locale/en/settings.cfg","locale/ru/settings.cfg"):
            text=content(path)
            self.assertIn("razi-orbital-catapult-local-links=",text)
            self.assertIn("ON by default",text)
            self.assertNotIn("Experimental Muria-Aquilo",text)

    def test_no_native_research_or_space_route_mutation(self):
        source=content("prototypes/compat/orbital_catapult.lua")
        self.assertNotIn('data.raw["space-connection"]=',source)
        for fragment in ("prerequisites=", "recipe.ingredients=",
                         "recipe.results=", "game.forces",
                         "player.teleport"):
            self.assertNotIn(fragment,source)
        self.assertIn('require("prototypes.compat.orbital_catapult").data()',
                      content("data.lua"))

    def test_journal_routes_tied_to_existing_quests(self):
        report=inspect(ROOT)
        self.assertEqual(report["brief_count"],15)
        for key in ("briefs_without_quests","links_without_briefs",
                    "related_quest_targets_missing","locale_errors"):
            self.assertEqual(report[key],[],key)
        source=content("scripts/razi_planet_briefs.lua")
        self.assertIn('muria="muria"',source)
        locale=content("locale/en/razi_journal_corporate.cfg")
        self.assertIn("muria=VESPERA SHORT-HAUL LOGISTICS",locale)

    def test_manual_workflow_keeps_upstream_fixture(self):
        code=content(".github/workflows/check.yml")
        self.assertIn("test_orbital_catapult.lua",code)
        self.assertIn("workflow_dispatch:",code)
        self.assertNotIn("\n  push:",code)

if __name__=="__main__":
    unittest.main()
