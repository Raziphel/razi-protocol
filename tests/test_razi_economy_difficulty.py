"""Difficulty economics are mapped and applied, not merely displayed."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding="utf-8")
class EconomyDifficulty(unittest.TestCase):
 def test_economy_connected_to_all_map_profiles(self):
  profile=read("prototypes/system/razi_map_preset.lua")
  self.assertEqual(profile.count(
   "economy.profile(mode,tuning.profile(mode,M.profiles,difficulty),difficulty)"),5)
  engine=read("scripts/razi_economy_difficulty.lua")
  for control in ("razi-resource-frequency","razi-resource-patch-size",
       "razi-resource-richness","razi-science-demand",
       "razi-evolution-speed","razi-rocket-launch-cost"):
   self.assertIn(control,engine)
   self.assertIn('name="'+control+'"',read("settings.lua"))
  self.assertIn('if resolver.active()~="custom" then return spec end',engine)
 def test_rocket_is_prototype_only_and_storage_guarded(self):
  src=read("prototypes/compat/razi_launch_economy.lua")
  self.assertIn("silo.rocket_parts_required=crafts",src)
  self.assertIn("rocket_parts_storage_cap=math.max(original.storage,crafts)",src)
  self.assertIn("original.storage~=0",src)
  self.assertNotIn("on_nth_tick",src)
  self.assertNotIn("recipe.ingredients",src)
  self.assertIn('razi_launch_economy").data_final_fixes()',
    read("data-final-fixes.lua"))
 def test_four_modes_are_mapped_and_custom_tracked(self):
  src=read("scripts/razi_difficulty_presets.lua")
  for key in ("razi-resource-frequency","razi-resource-patch-size",
        "razi-resource-richness","razi-science-demand",
        "razi-evolution-speed","razi-rocket-launch-cost"):
   self.assertIn('["'+key+'"]="normal"',src)
  self.assertIn('["razi-rocket-launch-cost"]="punishing"',src)
if __name__=="__main__":unittest.main()
