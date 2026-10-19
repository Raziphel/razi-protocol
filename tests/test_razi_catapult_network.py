"""Razi 3.0 Orbital Catapult route dossier and spoiler integration."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(name): return (ROOT/name).read_text(encoding="utf-8")
def locale_keys(path,section):
    text=read(path)
    token=f"[{section}]"
    assert token in text
    s=text.split(token,1)[1].split("\n[",1)[0]
    return set(re.findall(r"^([a-z0-9-]+)=",s,re.M))

class RegionalFreightTests(unittest.TestCase):
    def test_ui_uses_real_source_manifest_without_made_up_deliveries(self):
        report=read("scripts/razi_catapult_network.lua")
        self.assertIn('require("prototypes.compat.orbital_catapult")',report)
        self.assertIn('planet-discovery-muria',report)
        self.assertIn('planet-discovery-rubia',report)
        self.assertIn('planet-discovery-aquilo',report)
        self.assertIn('if hide and not (from and to) then',report)
        self.assertIn('if planet_protos[a] and planet_protos[b]',report)
        self.assertIn('game and game.planets',report)
        self.assertNotIn('prototypes.planet',report)
        self.assertNotIn('prototypes.space_location',report)
        for fixture in ('tests/lua/test_razi_catapult_network.lua',
                        'tests/lua/test_razi_catapult_regional.lua'):
            test=read(fixture)
            self.assertIn('game={planets=',test)
            self.assertIn('Unexpected LuaPrototypes field:',test)
        self.assertIn('result.concealed=result.concealed+1',report)
        for bad in ("on_nth_tick","script.on_event","player.teleport(",
                    "force.research_all_technologies(","inventory.insert("):
            self.assertNotIn(bad,report)
        self.assertIn("state=from and to and",report)

    def test_cargo_dossier_does_not_claim_live_transport(self):
        source=read("scripts/galactic_trade.lua")
        self.assertIn('require("scripts.razi_catapult_network")',source)
        self.assertIn("catapults.snapshot(player.force)",source)
        self.assertIn("catapult_dossier(scroll,player,size.width)",source)
        self.assertIn('catapult-network-unrevealed',source)
        self.assertIn('catapult-network-build',source)
        self.assertIn('catapult-network-safety',source)
        self.assertNotIn('catapults.on_tick(',source)

    def test_planet_quest_dossiers_show_only_visible_corridors(self):
        journal=read("scripts/razi_journal.lua")
        self.assertIn("catapults.snapshot(player.force)",journal)
        self.assertIn("catapults.for_world(network,quest.id)",journal)
        self.assertIn('quest.id=="muria"',journal)
        self.assertIn('quest.id=="rubia"',journal)
        self.assertIn('quest.id=="aquilo"',journal)
        self.assertIn('catapult-local-neighbor',journal)

    def test_every_ui_locale_key_is_defined(self):
        a=read("scripts/galactic_trade.lua")
        b=read("scripts/razi_journal.lua")
        ops=locale_keys("locale/en/galactic_operations.cfg","razi-ops")
        journal=locale_keys("locale/en/razi_journal_interface.cfg","journal-ui")
        for name in ("catapult-network-heading","catapult-network-intro",
                     "catapult-network-unrevealed","catapult-network-none",
                     "catapult-network-disabled","catapult-network-pair",
                     "catapult-network-surveyed","catapult-network-research",
                     "catapult-network-build","catapult-network-safety",
                     "catapult-network-purpose-cold-resupply",
                     "catapult-network-purpose-materials-transfer",
                     "catapult-network-purpose-cryo-materials"):
            self.assertIn(name,ops,name)
        for name in ("catapult-local-heading","catapult-local-neighbor",
                     "catapult-local-surveyed","catapult-local-pending",
                     "catapult-local-note"):
            self.assertIn(name,journal,name)

    def test_existing_route_ids_stay_unchanged(self):
        api=read("prototypes/compat/orbital_catapult.lua")
        self.assertIn('"razi-muria-aquilo-catapult"',api)
        self.assertIn('"razi-aquilo-muria-catapult"',api)
        ids=re.findall(r'\{"(razi-[a-z-]+-catapult)"',api)
        self.assertEqual(len(ids),12)
        self.assertEqual(len(set(ids)),6)

    def test_manual_regression_suite_includes_route_dossier(self):
        workflow=read(".github/workflows/check.yml")
        self.assertIn("test_razi_catapult_network.lua",workflow)
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotIn("\n  push:",workflow)

if __name__=="__main__":unittest.main()
