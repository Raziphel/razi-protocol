"""Project HELIOS static integration and source-ownership checks."""
import json
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
class HeliosTests(unittest.TestCase):
 def test_settings_and_translations(self):
  for name in ("razi-helios-progression","razi-helios-construction",
               "razi-helios-route-danger","razi-helios-route-distance"):
   self.assertIn(f'name="{name}"',read("settings.lua"))
   for lang in ("en","ru"):
    self.assertIn(name+"=",read("locale/"+lang+"/settings.cfg"))
 def test_research_and_satellite_safety(self):
  src=read("prototypes/compat/helios_engineering.lua")
  self.assertIn("dyson.safe_link(spec.gate,spec.tech)",src)
  self.assertIn("machine_accepts(recipe,item_inputs(recipe)+1)",src)
  self.assertIn('categories={"advanced-crafting"}',src)
  self.assertIn("recipe.ingredients=ingredients",src)
  self.assertNotIn("script.on_nth_tick",src)
  self.assertNotIn("remote.call(",src)
 def test_dependency_and_registration_order(self):
  deps=json.loads(read("info.json"))["dependencies"]
  self.assertIn("slp-dyson-sphere-reworked-fork >= 1.0.5",deps)
  src=read("data-final-fixes.lua")
  self.assertLess(src.index('helios_engineering").data_final_fixes()'),
                  src.index('helios_engineering").reinforce_satellites()'))
  self.assertLess(src.index('temporary.factorio_2_1_22.loader'),
                  src.index('helios_engineering").reinforce_satellites()'))
 def test_real_component_output_is_observable(self):
  src=read("scripts/galactic_dyson.lua")
  self.assertIn("force.get_item_production_statistics(surface)",src)
  self.assertIn("stats.get_output_count(name)",src)
  self.assertNotIn("+(stats.get_input_count(name)",src)
  self.assertIn('"slp-ds-satellite"',src)
  self.assertIn('"slp-ds-planet-satellite"',src)
  self.assertIn("dyson-native-not-deployed",src)
  self.assertNotIn("script.on_nth_tick",src)
 def test_ui_is_research_based(self):
  src=read("scripts/galactic_dyson.lua")
  self.assertIn("helios_progress(parent,player.force)",src)
  self.assertIn("dyson-source-telemetry-unknown",src)
if __name__=="__main__": unittest.main()
