"""No scripts needed for pollution, raids or colony pressure."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
class NativeDifficulty(unittest.TestCase):
 def test_preset_module_has_three_engine_levers(self):
  src=read("scripts/razi_difficulty_tuning.lua")
  for name in ("razi-pollution-pressure","razi-raid-coordination",
               "razi-colony-expansion"):
   self.assertIn(name,src)
   self.assertIn('name="'+name+'"',read("settings.lua"))
  self.assertIn("function M.pollution(target,baseline,spec)",src)
  self.assertIn("function M.unit_groups(target,baseline,spec)",src)
  self.assertNotIn("script.on_nth_tick",src)
 def test_real_mapgen_reads_native_tuning(self):
  code=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('require("scripts.razi_difficulty_tuning")',code)
  self.assertIn("tuning.profile(mode,M.profiles,difficulty)",code)
  self.assertIn("tuning.pollution(source.pollution,original.pollution,spec)",code)
  self.assertIn("tuning.unit_groups(source.unit_group,original.unit_group,spec)",code)
 def test_normal_and_nightmare_ui_choices_translated(self):
  for lang in ("en","ru"):
   src=read(f"locale/{lang}/settings.cfg")
   for key in ("razi-pollution-pressure","razi-raid-coordination",
               "razi-colony-expansion"):
    self.assertIn(key+"=",src)
  modes=read("scripts/razi_difficulty_presets.lua")
  self.assertIn('["razi-pollution-pressure"]="toxic"',modes)
  self.assertIn('["razi-raid-coordination"]="siege"',modes)
  self.assertIn('["razi-colony-expansion"]="invasive"',modes)
if __name__=="__main__":unittest.main()
