"""Static contract for the Razi gameplay preset coordinator."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")

class DifficultyPresetTests(unittest.TestCase):
 def test_master_is_opt_in_and_has_explicit_choices(self):
  text=read("settings.lua")
  self.assertIn('name="razi-difficulty-preset"',text)
  self.assertIn('setting_type="startup",default_value="custom"',text)
  self.assertIn('allowed_values={"custom","relaxed","standard","hard","extreme"}',text)
 def test_no_user_settings_overwritten(self):
  body=read("scripts/razi_difficulty_presets.lua")
  self.assertIn("function M.effective(name,fallback)",body)
  self.assertNotIn("settings.global[",body)
  self.assertNotIn("data.raw[",body)
  self.assertNotIn("script.on_nth_tick",body)
  self.assertIn('["razi-asteroid-population"]="dense"',body)
  self.assertNotIn('["razi-helios-construction"]',body)
 def test_every_scoped_consumer_reads_shared_resolver(self):
  consumers=(
    "prototypes/system/asteroid_profiles.lua",
    "prototypes/compat/calidus_dyson.lua",
    "prototypes/compat/helios_engineering.lua",
    "prototypes/compat/helios_structures.lua",
    "scripts/razi_helios_operations.lua",
    "prototypes/system/route_highlights.lua",
    "prototypes/system/route_intel.lua",
    "prototypes/system/route_ribbons.lua",
    "prototypes/system/quality_asteroids.lua",
    "scripts/razi_quality_asteroids.lua",
  )
  for path in consumers:
   with self.subTest(path=path):
    self.assertIn("razi_difficulty_presets",read(path))
 def test_localizations(self):
  for lang in ("en","ru"):
   with self.subTest(lang=lang):
    data=read("locale/"+lang+"/settings.cfg")
    for suffix in ("","-custom","-relaxed","-standard","-hard","-extreme"):
     self.assertIn("razi-difficulty-preset"+suffix+"=",data)

if __name__=="__main__": unittest.main()
