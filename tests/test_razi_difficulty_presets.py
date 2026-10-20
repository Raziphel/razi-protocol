"""Static contracts for Normal-default RP3 Difficulty Director."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
class DifficultyDirector(unittest.TestCase):
 def test_five_modes_and_normal_default(self):
  s=read("settings.lua")
  self.assertIn('setting_type="startup",default_value="normal"',s)
  self.assertIn('allowed_values={"easy","normal","hard","nightmare","custom"}',s)
 def test_difficulty_labels_are_short_but_tooltips_stay_detailed(self):
  for lang, expected in (("en",{"easy":"Easy","normal":"Normal",
                               "hard":"Hard","nightmare":"Nightmare",
                               "custom":"Custom"}),
                         ("ru",{"easy":"Лёгкая","normal":"Обычная",
                                "hard":"Сложная","nightmare":"Кошмар",
                                "custom":"Своя"})):
   body=read("locale/"+lang+"/settings.cfg")
   for name,label in expected.items():
    self.assertIn("razi-difficulty-preset-"+name+"="+label+"\n",body)
   self.assertIn("razi-difficulty-preset=",body)
 def test_manual_override_detection(self):
  d=read("scripts/razi_difficulty_presets.lua")
  self.assertIn("function M.manual_overrides()",d)
  self.assertIn("choice.value~=default",d)
  self.assertIn("for name,default in pairs(M.baseline)",d)
  self.assertIn('["razi-enable-modded-planet-exchanges"]=true',d)
  self.assertIn('if #M.manual_overrides()>0 then return "custom" end',d)
  self.assertIn('if name=="custom" then return "custom" end',d)
  self.assertIn("function M.is_overridden(name)",d)
  self.assertIn("local selected=M.selected()",d)
  self.assertIn("if M.is_overridden(name) then return item.value end",d)
  for name in ("easy","normal","hard","nightmare"):
   self.assertIn(name+"={",d)
 def test_big_monsters_api_is_supported_and_event_driven(self):
  b=read("scripts/razi_big_monsters_bridge.lua")
  self.assertIn('api(M.active() and "on" or "off")',b)
  self.assertIn('return api("add_surface",surface.name)',b)
  self.assertNotIn("script.on_nth_tick(",b)
  self.assertNotIn('settings.global["bm-event-days"]=',b)
  self.assertIn("big_monsters_bridge.sync()",read("control.lua"))
 def test_source_integrations(self):
  d=read("scripts/razi_difficulty_presets.lua")
  self.assertIn('["razi-planetary-interdependence"]="deep"',d)
  self.assertIn('razi_difficulty_presets',
    read("prototypes/compat/interdependence_mode.lua"))
  self.assertIn('["razi-big-monsters-events"]=true',d)
  for setting in ("razi-pollution-pressure","razi-raid-coordination",
                  "razi-colony-expansion"):
   self.assertIn('name="'+setting+'"',read("settings.lua"))
   self.assertIn('["'+setting+'"]',d)
 def test_translations(self):
  for lang in ("en","ru"):
   cfg=read(f"locale/{lang}/settings.cfg")
   for tail in ("-custom","-easy","-normal","-hard","-nightmare"):
    self.assertIn("razi-difficulty-preset"+tail+"=",cfg)
if __name__=="__main__":unittest.main()
