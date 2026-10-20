"""Curated Nauvis scenario preset constraints."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
class MapPresetTests(unittest.TestCase):
 def test_preset_does_not_change_default_or_native_freeplay(self):
  s=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('group["razi-protocol"]=',s)
  self.assertNotIn('group.default=',s)
  self.assertNotIn('default=true',s.split('group["razi-protocol"]=',1)[1])
  self.assertIn('["enemy-base"]={frequency=.85',s)
  self.assertIn('technology_price_multiplier=1',s)
 def test_registered_after_other_mapgen_changes(self):
  src=read("data-final-fixes.lua")
  self.assertIn('razi_map_preset").data_final_fixes()',src)
 def test_localised_english_and_russian(self):
  for lang in ("en","ru"):
   t=read(f"locale/{lang}/map_preset.cfg")
   self.assertIn("razi-protocol=",t)
if __name__=="__main__":unittest.main()
