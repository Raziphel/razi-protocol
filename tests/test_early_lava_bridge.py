"""Static regressions for the distributable lava compatibility bridge."""
import json
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
HELP=ROOT/"companion"/"a-razi-lava-compat"
def src(path):return path.read_text(encoding="utf-8")
class LavaBridgeTests(unittest.TestCase):
 def test_helper_metadata(self):
  info=json.loads(src(HELP/"info.json"))
  self.assertEqual(info["name"],"a-razi-lava-compat")
  self.assertEqual(info["factorio_version"],"2.1")
  self.assertIn("space-age >= 2.1.20",info["dependencies"])
  razi=json.loads(src(ROOT/"info.json"))
  self.assertIn("? a-razi-lava-compat >= 0.1.0",razi["dependencies"])
  self.assertIn("planet-crucible >= 1.1.27",razi["dependencies"])
 def test_old_field_refers_to_real_image(self):
  code=src(HELP/"data.lua")
  self.assertIn('water.shader_variation=="lava"',code)
  self.assertIn('[2]=water.image_textures[1]',code)
  self.assertNotIn("filename=",code)
 def test_late_cleanup(self):
  c=src(HELP/"prototypes"/"cleanup.lua")
  self.assertIn("water.textures=nil",c)
  self.assertIn('water.shader_variation=="lava"',c)
  self.assertIn('cleaner.clean()',src(HELP/"data-final-fixes.lua"))
  self.assertEqual(src(ROOT/"data-final-fixes.lua").strip().splitlines()[-1],
    'require("prototypes.compat.legacy_lava_cleanup").data_final_fixes()')
  self.assertIn('require("__a-razi-lava-compat__/prototypes/cleanup")',
   src(ROOT/"prototypes"/"compat"/"legacy_lava_cleanup.lua"))
if __name__=="__main__":unittest.main()
