"""Expanded Orbital Catapult industry routes stay local and source-owned."""
import re
from pathlib import Path
import unittest
from scripts.audit_campaign_consistency import inspect

ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding="utf-8")

class OrbitalRegionalExpansion(unittest.TestCase):
    def test_six_pairs_are_local_to_three_chapters(self):
        text=read("prototypes/compat/orbital_catapult.lua")
        tuples=re.findall(
            r'\{"(razi-[a-z-]+-catapult)","([a-z-]+)","([a-z-]+)"\}',
            text)
        self.assertEqual(len(tuples),12)
        self.assertEqual(len(set(x[0] for x in tuples)),12)
        clusters={"solaris":{"vulcanus","castra"},
                  "nyxaris":{"gleba","moshine"},
                  "vespera":{"muria","rubia","aquilo","maraxsis"}}
        directions={(source,target) for _,source,target in tuples}
        for _,source,target in tuples:
            self.assertTrue(any(source in world and target in world
                                for world in clusters.values()))
            self.assertIn((target,source),directions)
        self.assertEqual(len(directions),12)
        self.assertIn("M.regional_links",text)
        self.assertIn("function M.active_links(local_enabled,regional_enabled)",text)
        self.assertIn("function M.definitions(raw,loaded,enabled,regional_enabled)",text)
        for old in ("razi-muria-aquilo-catapult",
                    "razi-aquilo-muria-catapult"):
            self.assertIn(old,text)

    def test_independent_default_on_startup_option(self):
        settings=read("settings.lua")
        match=re.search(
            r'name="razi-orbital-catapult-regional-links",\s*'
            r'setting_type="startup",default_value=true',
            settings)
        self.assertIsNotNone(match)
        for path in ("locale/en/settings.cfg","locale/ru/settings.cfg"):
            locale=read(path)
            self.assertIn("razi-orbital-catapult-regional-links=",locale)
            self.assertIn("Regional orbital freight corridors",locale)
        source=read("prototypes/compat/orbital_catapult.lua")
        self.assertIn('settings.startup["razi-orbital-catapult-regional-links"]',
                      source)

    def test_link_destinations_have_real_native_research(self):
        quests=read("scripts/razi_journal_data.lua")
        for world in ("vulcanus","castra","gleba","moshine",
                      "muria","rubia","aquilo","maraxsis"):
            self.assertRegex(quests,
                r'id="'+world+r'",chapter="[a-z-]+",tech="planet-discovery-'+world+r'"')

    def test_quest_briefs_are_complete(self):
        summary=inspect(ROOT)
        self.assertEqual(summary["brief_count"],15)
        for key in ("briefs_without_quests","links_without_briefs",
                    "related_quest_targets_missing","locale_errors"):
            self.assertEqual(summary[key],[],key)
        source=read("scripts/razi_planet_briefs.lua")
        for world in ("vulcanus","maraxsis"):
            self.assertIn(f'{world}="{world}"',source)
        locale=read("locale/en/razi_journal_corporate.cfg")
        self.assertIn("vulcanus=FOUNDRY FREIGHT",locale)
        self.assertIn("maraxsis=UNDERSEA SUPPLY",locale)

    def test_guidance_does_not_fake_transport_or_research(self):
        runtime=read("scripts/razi_catapult_network.lua")
        ui=read("scripts/galactic_trade.lua")
        self.assertIn("manifest.active_links(enabled,regional)",runtime)
        self.assertIn("if hide and not (from and to) then",runtime)
        self.assertIn("table.sort(result.entries",runtime)
        self.assertIn("catapult-network-region",ui)
        for bad in ("script.on_nth_tick","inventory.insert",
                    "force.research_all_technologies",
                    "player.teleport","on_tick"):
            self.assertNotIn(bad,runtime)
        workflow=read(".github/workflows/check.yml")
        self.assertIn("test_razi_catapult_expansion.lua",workflow)
        self.assertIn("test_razi_catapult_regional.lua",workflow)
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotIn("\n  push:",workflow)

if __name__=="__main__": unittest.main()
