"""Cinematic should have a distinct, safe static visual language."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding="utf-8")
class CinematicContrast(unittest.TestCase):
 def test_extra_layers_distinguish_cinematic_from_subtle(self):
  mod=read("prototypes/system/starmap_background.lua")
  self.assertIn("local cinematic_clusters={",mod)
  self.assertIn("local cinematic_nebulae={",mod)
  self.assertIn("local function cinematic_composition(layers,halos,details)",mod)
  self.assertIn('if cinematic and option("razi-starmap-cinematic-extras",true)',mod)
  self.assertIn('if system.name~="deep-space" then',mod)
 def test_system_pockets_are_finite(self):
  mod=read("prototypes/system/starmap_background.lua")
  cluster=mod.split("local cinematic_clusters={",1)[1].split("\n}",1)[0]
  dust=mod.split("local cinematic_nebulae={",1)[1].split("\n}",1)[0]
  self.assertEqual(sum(1 for line in cluster.splitlines() if line.strip().startswith('{"')),8)
  self.assertEqual(sum(1 for line in dust.splitlines() if line.strip().startswith('{"')),6)
  self.assertLess(mod.count('cinematic_composition(layers,halos,details)'),3)
 def test_only_existing_assets_are_used(self):
  mod=read("prototypes/system/starmap_background.lua")
  self.assertIn('filename=ASSET.."atlas-starfield-"..spec[4]..".png"',mod)
  self.assertIn('insert_asset(layers,"atlas-dust-"..cloud[4]..".png"',mod)
  self.assertNotIn("create_entity(",mod)
  self.assertNotIn("script.on_nth_tick",mod)
 def test_toggle_and_localisations(self):
  self.assertIn('startup_toggle("razi-starmap-cinematic-extras"',read("settings.lua"))
  for lang in ("en","ru"):
   cfg=read(f"locale/{lang}/settings.cfg")
   sections=cfg.split("[mod-setting-description]",1)
   self.assertEqual(len(sections),2)
   self.assertIn("razi-starmap-cinematic-extras=",sections[0])
   self.assertIn("razi-starmap-cinematic-extras=",sections[1])
 def test_lua_fixture_covers_real_layer_counts(self):
  test=read("tests/lua/test_starmap_background.lua")
  self.assertIn("#cine==#parts+28",test)
  self.assertIn("cinematic_counts.corona==14",test)
  self.assertIn('==#parts+1,"Duplicate background layer registration"',test)
if __name__=="__main__":unittest.main()
