"""Enemy world-generation and Nexus coexistence contracts."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
class EcologyTests(unittest.TestCase):
 def test_nexus_does_not_suppress_native_biters(self):
  old=read("prototypes/compat/enemy_autoplace.lua")
  self.assertIn('function enemy_autoplace.disable_vanilla_enemies_on_planet',old)
  self.assertIn('return false',old)
  src=read("prototypes/compat/razi_enemy_ecology.lua")
  self.assertIn('map.autoplace_controls["enemy-base"]=',src)
  self.assertIn('"biter-spawner","spitter-spawner"',src)
  self.assertIn('put("nexus",id,kind',src)
 def test_native_gleba_and_vulcanus_are_prototype_guarded(self):
  s=read("prototypes/compat/razi_enemy_ecology.lua")
  self.assertIn('name=="gleba-spawner" or name=="gleba-spawner-small"',s)
  self.assertIn("local nest=table.deepcopy(base)",s)
  self.assertIn('"enemy_autoplace_base(0, 25) * 0.15"',s)
  self.assertIn('nest.name=id',s)
  self.assertIn('nest.type="unit-spawner"',s)
  self.assertIn('data:extend({nest})',s)
  self.assertIn('map.territory_settings=table.deepcopy(native_territory)',s)
  self.assertIn("map.territory_settings=table.deepcopy(native_territory)",s)
  self.assertIn('data.raw["segmented-unit"]',s)
  self.assertIn("source_entity(name)",s)
  self.assertIn('clone.name=id',s)
  self.assertIn('if existing and existing[name] then return false end',s)
  self.assertNotIn("script.on_nth_tick",s)
 def test_more_planet_species_and_last_pass(self):
  for p in ("castra","athos","shchierbin","corrundum","rabbasca","foliax"):
   self.assertIn('"'+p+'"',read("prototypes/compat/razi_enemy_ecology.lua"))
  final=read("data-final-fixes.lua")
  self.assertGreater(final.index('razi_enemy_ecology").data_final_fixes()'),
   final.index('enemy_autoplace").repair_optional_enemy_autoplace()'))
if __name__=="__main__":unittest.main()
