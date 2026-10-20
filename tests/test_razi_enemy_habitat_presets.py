"""RP3 difficulty-aware modded enemy habitats: static contracts."""
from pathlib import Path
import re
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
IDS=["armoured-biters","cold-biters","explosive-biters",
     "toxic-biters","arachnids","electric-enemies"]
class HabitatPresets(unittest.TestCase):
 def test_six_family_settings_support_follow_difficulty_and_manual_tiers(self):
  cfg=read("settings.lua")
  diff=read("scripts/razi_difficulty_presets.lua")
  for id in IDS:
   key="razi-habitat-"+id
   self.assertIn('name="'+key+'"',cfg)
   self.assertIn('default_value="auto"',cfg)
   self.assertIn('allowed_values={"auto","off","limited","curated","expanded","all"}',cfg)
   self.assertIn('["'+key+'"]="auto"',diff)
 def test_exact_mode_mapping(self):
  src=read("scripts/razi_difficulty_presets.lua")
  for mode,value in {"easy":"limited","normal":"curated",
                     "hard":"expanded","nightmare":"all"}.items():
   section=src.split(" "+mode+"={",1)[1].split("\n }",1)[0]
   for id in IDS:
    self.assertIn('["razi-habitat-'+id+'"]="'+value+'"',section)
 def test_ecology_is_gated_by_actual_mode(self):
  src=read("prototypes/compat/razi_enemy_ecology.lua")
  self.assertIn("local active=M.selected_planets(group)",src)
  self.assertIn("if active[planet] then",src)
  self.assertIn('if level=="off" then return {} end',src)
  self.assertIn('local preset=difficulty.presets[difficulty.selected()]',src)
  self.assertIn('if chosen~="auto" then return chosen end',src)
  self.assertIn("selected.nexus=true",src)
  self.assertIn('if existing and existing[name] then return false end',src)
  self.assertNotIn("script.on_nth_tick",src)
 def test_old_modules_no_longer_bypass_difficulty(self):
  for module in ("armoured_biters","cold_biters","explosive_biters",
                 "toxic_biters","arachnids_enemy","electric_flying_enemies"):
   content=read("prototypes/compat/"+module+".lua")
   self.assertNotIn("add_entities_to_planet(",content)
   self.assertNotIn("add_arachnids_to_planet(",content)
   self.assertNotIn("add_electric_enemies_to_planet(",content)
 def test_locales(self):
  for lang in ("en","ru"):
   text=read(f"locale/{lang}/settings.cfg")
   for id in IDS:
    for tail in ("","-auto","-off","-limited","-curated","-expanded","-all"):
     self.assertIn("razi-habitat-"+id+tail+"=",text)
 def test_nexus_and_optional_mods_remain_guarded(self):
  text=read("prototypes/compat/razi_enemy_ecology.lua")
  self.assertIn("if has_mod(group.mod) then",text)
  self.assertIn("if #tiles==0 then return false end",text)
  self.assertIn("nexus_pentapod_raft(name,map)",text)
if __name__=="__main__":unittest.main()
