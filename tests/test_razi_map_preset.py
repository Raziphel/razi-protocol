"""Factorio 2.1-safe Razi defaults and planet-wide map-generation tuning."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
class MapGenProfiles(unittest.TestCase):
 def test_auto_marker_is_matching_difficulty(self):
  code=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('local name="razi-protocol-"..mode',code)
  self.assertIn('group[name]={order="00[razi-default]",default=true}',code)
  self.assertIn('if autoselect and not competing and mode==selected then',code)
  self.assertIn('group["razi-protocol-custom"]=nil',code)
  self.assertIn('group["razi-protocol"]=nil',code)
  self.assertNotIn('group["razi-protocol-custom"]=explicit_preset',code)
 def test_all_registered_resources_and_enemies_not_just_vanilla_ores(self):
  code=read("prototypes/system/razi_map_preset.lua")
  self.assertIn('for id,proto in pairs((data.raw["autoplace-control"] or {}))',code)
  self.assertIn('if category=="resource" then',code)
  self.assertIn('if category=="enemy" then',code)
  self.assertIn('for name,planet in pairs(data.raw.planet or {})',code)
  self.assertIn('local value=scaled',code)
  self.assertIn('if value<=0 then return 0 end',code)
  self.assertIn('if category=="terrain" and (id=="water" or id=="trees")',code)
 def test_advanced_controls_and_performance_caps(self):
  code=read("prototypes/system/razi_map_preset.lua")
  for key in ('pollution_ageing','attack_consumption','asteroids',
    'difficulty_settings','enemy_evolution','enemy_expansion'):
   self.assertIn(key,code)
  self.assertIn('asteroids=1.12',code)
  self.assertIn('original_map_settings',code)
 def test_locale_is_short_and_guides_settings(self):
  for lang in ("en","ru"):
   content=read(f"locale/{lang}/map_preset.cfg")
   self.assertNotIn("razi-protocol-custom=",content)
   self.assertNotIn("razi-protocol=Razi Protocol",content)
   for label in ("easy","normal","hard","nightmare"):
    self.assertIn("razi-protocol-"+label+"=",content)
   if lang=="en":
    self.assertIn("Mod settings",content)
   else:
    self.assertIn("Настройки модов",content)
  english=read("locale/en/map_preset.cfg")
  self.assertIn("Before starting your new galaxy",english)
  self.assertIn("Restart Factorio",english)
 def test_tests_cover_source_planet_and_third_party_defaults(self):
  test=read("tests/lua/test_razi_map_preset.lua")
  for label in ("ionite-ore","ferric-scrap","meteorite-chunk",
   "biter-base","other-mod-default","iron-ore"):
   self.assertIn(label,test)
  self.assertIn("Custom",read("scripts/razi_difficulty_presets.lua"))
if __name__=="__main__":
 unittest.main()
