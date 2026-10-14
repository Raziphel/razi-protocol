"""Guard native lab tiers and preserved card recipes without inventing labs."""
import json
import re
import unittest
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
            ("vespera-tech-card","hydraulic-science-pack"),
            ("deep-space-tech-card","space-logistic-science-pack")):
            body=re.search(r'\bname = "'+re.escape(card)+
                r'".*?fallback_ingredients',source,re.S)
            self.assertIsNotNone(body)
            items=body.group().split("ingredients = {",1)[1].split("}",1)[0]
            self.assertNotIn('"'+forbidden+'"',items)
        self.assertIn('upsert_system_card(card)',source)
        self.assertIn('system_card_definitions',source)

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
            read("locale/en/razi_journal.cfg"))
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
        self.assertIn('api["set_no_victory"]',control)
        self.assertIn('remote.call("kr-intergalactic-transceiver",',control)
        self.assertIn('"set_no_victory",true)',control)
        self.assertNotIn('set_game_state(',control)

    def test_settings_limit_and_version(self):
        settings=read("settings.lua")
        self.assertIn('razi-planetary-interdependence',settings)
        self.assertEqual(json.loads(read("info.json"))["version"],"2.1.74")

if __name__=="__main__":
    unittest.main()
