"""Static integration contracts for planet-scoped biter ecology."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(name):return (ROOT/name).read_text(encoding="utf-8")
class EnemyHabitats(unittest.TestCase):
 def test_planet_specific_families_and_valid_world_names(self):
  src=read("prototypes/compat/razi_enemy_ecology.lua")
  for planet in ("ferrum","obsidiax","panglia","tenebris","velora",
                 "alchemy-planet","bm-balack","cerys","rabbasca"):
   self.assertIn('"'+planet+'"',src)
  for mod in ("ArmouredBiters21Compat","Cold_biters","Toxic_biters",
              "Explosive_biters","Electric_flying_enemies",
              "Arachnids_enemy"):
   self.assertIn('"'+mod+'"',src)
 def test_isolated_clone_not_source_mutation(self):
  src=read("prototypes/compat/razi_enemy_ecology.lua")
  self.assertIn('local clone=table.deepcopy(source)',src)
  self.assertIn('clone.type=actual_kind',src)
  self.assertIn('tile_restriction=tiles',src)
  self.assertIn('if settings[name] then return false end',src)
  self.assertIn('if #tiles==0 then return false end',src)
  self.assertNotIn('extend_restriction',src)
  self.assertNotIn('script.on_nth_tick',src)
  self.assertIn('local available=not is_worm or index<=3 or planet=="nexus"',src)
 def test_safe_additive_legacy_routing(self):
  old=read("prototypes/compat/enemy_autoplace.lua")
  self.assertIn('function enemy_autoplace.disable_vanilla_enemies_on_planet',old)
  self.assertNotIn('entity_settings[entity_name] = {\n\t\t\t\tfrequency = 0',old)
  self.assertIn('if not map_gen_settings.autoplace_controls[control_name]',old)
 def test_full_mock_integration_present(self):
  fixture=read("tests/lua/test_razi_enemy_habitats.lua")
  for name in ("ferrum","obsidiax","panglia","gleba","alchemy-planet"):
   self.assertIn(name,fixture)
  self.assertIn('eco.data_final_fixes()',fixture)
  self.assertIn('check_planets("easy",group,#group.limited)',fixture)
  self.assertIn('check_planets("hard",group,#group.expanded)',fixture)
  self.assertIn('check(next(eco.selected_planets(group))==nil',fixture)
if __name__=="__main__":unittest.main()
