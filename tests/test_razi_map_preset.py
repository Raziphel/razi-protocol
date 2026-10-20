"""Factorio 2.1-safe RP3 default selection and world-generation profiles."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding="utf-8")
class MapPresets(unittest.TestCase):
 def test_default_preset_has_no_custom_settings(self):
  source=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('group["razi-protocol"]={default=true,order=',source)
  self.assertIn("group.default.default=nil",source)
  self.assertIn("M.set_world_defaults(M.active_mode())",source)
  self.assertIn("if not competing then",source)
  self.assertIn('and preset.default==true',source)
  self.assertIn('local settings_map=(raw["map-settings"] or {})["map-settings"]',source)
  self.assertNotIn('group.default={',source)
 def test_selectable_profiles_cover_each_difficulty(self):
  s=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('{"easy","normal","hard","nightmare"}',s)
  self.assertIn('group["razi-protocol-custom"]=explicit_preset',s)
  self.assertIn("starting_area=2.55",s)
  self.assertIn("starting_area=1.65",s)
  self.assertIn("starting_area=1.15",s)
  self.assertIn("starting_area=.90",s)
  self.assertIn("technology_price_multiplier=spec.research",s)
 def test_default_can_be_disabled(self):
  settings=read("settings.lua")
  self.assertIn('name="razi-default-new-game-map"',settings)
  self.assertIn('setting_type="startup",default_value=true',settings)
  s=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('autoselect.value~=false',s)
 def test_localizations_and_docs(self):
  for lang in ("en","ru"):
   text=read(f"locale/{lang}/map_preset.cfg")
   for name in ("razi-protocol","razi-protocol-easy",
     "razi-protocol-normal","razi-protocol-hard",
     "razi-protocol-nightmare","razi-protocol-custom"):
    self.assertIn(name+"=",text)
   self.assertIn("razi-default-new-game-map=",read(
     f"locale/{lang}/settings.cfg"))
  self.assertIn('razi_map_preset").data_final_fixes()',
    read("data-final-fixes.lua"))
if __name__=="__main__":unittest.main()
