"""Cross-mod factories use Factorio-native fields and bounded factors."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding="utf-8")
class IndustryDifficulty(unittest.TestCase):
 def test_factories_and_defenses_only(self):
  s=read("prototypes/compat/razi_industrial_difficulty.lua")
  for category in ('"assembling-machine"','"furnace"','"wall"','"gate"'):
   self.assertIn(category,s)
  self.assertNotIn('raw["unit"]',s)
  self.assertIn('original.crafting_speed*a',s)
  self.assertIn('original.max_health*b',s)
  self.assertNotIn('script.on_nth_tick',s)
  self.assertIn('razi_industrial_difficulty").data_final_fixes()',
                read("data-final-fixes.lua"))
 def test_master_modes_and_custom(self):
  s=read("scripts/razi_difficulty_presets.lua")
  for key in ("razi-factory-throughput","razi-fortification-durability"):
   self.assertIn('["'+key+'"]="normal"',s)
   self.assertIn('name="'+key+'"',read("settings.lua"))
  self.assertIn('["razi-factory-throughput"]="strained"',s)
  self.assertIn('["razi-fortification-durability"]="brittle"',s)
if __name__=="__main__":unittest.main()
