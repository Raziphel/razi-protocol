"""Guard native lab tiers and preserved card recipes without inventing labs."""
import json
import re
import unittest
from tools.journal_locale import load_journal_locale
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class SystemCardProgressionTests(unittest.TestCase):
    def test_original_card_production_stays_available(self):
        source=read("prototypes/compat/lab_cards.lua")
        for card,forbidden in (
            ("solaris-tech-card","electrochemical-science-pack"),
            ("vibrant-tech-card","paracelsin-galvanization-science-pack"),
            ("vespera-tech-card","planet-crucible-science-pack"),
            ("deep-space-tech-card","space-logistic-science-pack")):
            body=re.search(r'\bname = "'+re.escape(card)+
                r'".*?fallback_ingredients',source,re.S)
            self.assertIsNotNone(body)
            items=body.group().split("ingredients = {",1)[1].split("}",1)[0]
            self.assertNotIn('"'+forbidden+'"',items)
        self.assertIn('upsert_system_card(card)',source)
        self.assertIn('system_card_definitions',source)

    def test_system_cards_use_chapter_completion_unlocks(self):
        source=read("prototypes/compat/lab_cards.lua")
        expected={
            "solaris":"planet-discovery-corrundum",
            "nyxaris":"panglia_planet_discovery_panglia",
            "vibrant":"planet-discovery-paracelsin",
            "vespera":"planet-discovery-maraxsis",
            "beetlejuice":"linox-technology_planet-discovery-linox",
            "umbra":"planet-discovery-vesta",
        }
        for system,completion in expected.items():
            block=re.search(r'name = "'+system+
                r'-tech-card".*?(?=\\n\\t\\{\\n\\t\\tname = "|\\n\\}\\n\\nlocal modded_science_ids)',
                source,re.S)
            self.assertIsNotNone(block,system)
            self.assertRegex(block.group(),
                r'unlock_technology_candidates = \\{[\\s\\S]*?"'+
                re.escape(completion)+r'"')
            self.assertLess(block.group().find('"'+completion+'"'),
                block.group().find('fallback_ingredients'))
        # Optional Frozeta must not become the sole gate to the core card.
        self.assertNotIn('unlock_technology_candidates = {"planet-discovery-frozeta"',
                         source)

    def test_system_cards_combine_native_chapter_sciences(self):
        source=read("prototypes/compat/lab_cards.lua")
        expected={
            "solaris":("battlefield-science-pack",
                       "planetaris-compression-science-pack",
                       "planetaris-polishing-science-pack"),
            "nyxaris":("agricultural-science-pack",
                       "thermodynamic-science-pack",
                       "apicultural-science-pack",
                       "aerospace-science-pack"),
            "vibrant":("electromagnetic-science-pack",
                       "ribbonia-alien-science-pack",
                       "electrochemical-science-pack"),
            "vespera":("muriatic-science-pack",
                       "cryogenic-science-pack",
                       "rubia-biofusion-science-pack",
                       "hydraulic-science-pack"),
            "beetlejuice":("golden-science-pack",
                           "linox-item_linox-science-pack"),
            "umbra":("bioluminescent-science-pack",
                     "planet-crucible-science-pack",
                     "gas-manipulation-science-pack"),
        }
        for system,packs in expected.items():
            block=re.search(r'name = "'+system+
                r'-tech-card".*?fallback_ingredients',source,re.S)
            self.assertIsNotNone(block,system)
            ingredients=block.group().split("ingredients = {",1)[1].split("}",1)[0]
            for pack in packs:
                self.assertIn('"'+pack+'"',ingredients,(system,pack))

    def test_middle_frontier_science_cannot_be_skipped(self):
        gates=read("prototypes/technology/seven_system_gates.lua")
        section=gates.split("local exotic_mastery = {",1)[1].split("}",1)[0]
        for name in ("fulgora","paracelsin","aquilo","maraxsis"):
            self.assertIn('"planet-discovery-'+name+'"',section)

    def test_eight_card_manufacturing_tiers(self):
        source=read("prototypes/compat/lab_cards.lua")
        for card,seconds,native_amount in (
            ("calidus",10,1),("solaris",12,1),("nyxaris",12,1),
            ("vibrant",16,1),("vespera",16,1),
            ("beetlejuice",22,2),("umbra",22,2),
            ("deep-space",28,2)):
            match=re.search(r'name = "'+card+r'-tech-card".*?'
                            r'craft_time = (\d+), regional_science_amount = (\d+)',
                            source,re.S)
            self.assertIsNotNone(match,card)
            self.assertEqual((int(match.group(1)),int(match.group(2))),
                             (seconds,native_amount))
        self.assertIn('science_pack:match("%-tech%-card$")',source)
        self.assertIn(':set_energy(card.craft_time or 10)',source)

    def test_first_frontier_prices_preserve_parallel_entry(self):
        gates=read("prototypes/technology/seven_system_gates.lua")
        self.assertIn('calidus, 650)',gates)
        for name in ("arig","hyarion"):
            self.assertRegex(gates,r'planet-discovery-'+name+
                             r'".*?calidus, 650\)')
        self.assertIn('{"planet-discovery-arig", "planet-discovery-hyarion"}, calidus, 800)',gates)
        self.assertIn('{"planet-discovery-tellus"}, calidus, 950)',gates)
        self.assertIn('replace_requirements(name, {"nyxaris-discovery"}, calidus, 800)',gates)
        self.assertIn('add_existing_prerequisites("panglia_planet_discovery_panglia"',gates)

    def test_no_razi_owned_lab_prototypes(self):
        source=read("prototypes/compat/system_card_laboratories.lua")
        for name in ("razi-frontier-lab","razi-constellation-lab",
                     "razi-astral-lab","razi-deep-space-lab"):
            self.assertNotIn(name,source)
            self.assertNotIn(name+'=',read("locale/en/names.cfg"))
            self.assertNotIn('tech="'+name+'"',
                             read("scripts/razi_journal_data.lua"))
        self.assertNotIn("data:extend",source)
        self.assertIn('["kr-advanced-lab"]=2',source)
        self.assertIn('["thermodynamics-lab"]=3',source)
        self.assertIn('["kr-singularity-lab"]=4',source)
        self.assertIn('["omega-lab"]=5',source)
        self.assertIn("restore_science()",source)

    def test_retired_lab_save_migration(self):
        migration=json.loads(read("migrations/2.1.55-native-labs.json"))
        for kind in ("item","entity"):
            self.assertEqual(len(migration[kind]),4)
            self.assertTrue(all(target=="lab"
                for old,target in migration[kind]))
        self.assertNotIn('lab-frontier=',
            load_journal_locale(ROOT))
        self.assertIn('self.assertEqual(len(quests),219)',
                      read("tests/test_razi_journal.py"))

    def test_transceiver_is_new_edge_gateway(self):
        source=read("prototypes/technology/deep_space_arrival.lua")
        self.assertIn('"razi-intergalactic-transceiver-signal"',source)
        self.assertIn('"stellar-discovery-solar-system-edge"',source)
        self.assertIn('pre_edge_science(entry[3])',source)
        self.assertIn('reachable(parent,"stellar-discovery-solar-system-edge")',source)
        self.assertIn('not found then',source)
        hook=read("data-final-fixes.lua")
        self.assertLess(hook.index(
            'require("prototypes.technology.seven_system_gates").data_final_fixes()'),
            hook.index(
            'require("prototypes.technology.deep_space_arrival").data_final_fixes()'))
        self.assertLess(hook.index(
            'require("prototypes.technology.deep_space_arrival").data_final_fixes()'),
            hook.index(
            'require("prototypes.technology.planetary_unification").data_final_fixes()'))

    def test_original_transceiver_victory_is_not_the_finale(self):
        control=read("control.lua")
        self.assertIn("preserve_deep_space_campaign()",control)
        guard=read("scripts/razi_victory_guard.lua")
        self.assertIn('api.set_no_victory',guard)
        self.assertIn('"kr-intergalactic-transceiver"',guard)
        self.assertIn('pcall(remote.call,interface,"set_no_victory",true)',guard)
        self.assertNotIn('set_game_state(',control)

    def test_settings_limit_and_version(self):
        settings=read("settings.lua")
        self.assertIn('razi-planetary-interdependence',settings)
        self.assertGreaterEqual(tuple(map(int,json.loads(read("info.json"))["version"].split("."))),(2,1,74))

if __name__=="__main__":
    unittest.main()
