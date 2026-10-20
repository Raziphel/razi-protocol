"""Regression guards against a return of Level 1 solar paths."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
class HeliosRiskTests(unittest.TestCase):
 def test_native_source_route_ids_registered(self):
  engine=read("scripts/razi_asteroid_difficulty.lua")
  self.assertIn('"sun-orbit"',engine)
  self.assertIn('"close-sun-orbit"',engine)
  self.assertIn("function M.register_stellar_locations(outer,inner)",engine)
  self.assertIn("function M.stellar_route_tier(route)",engine)
  source=read("prototypes/compat/calidus_dyson.lua")
  self.assertIn(".register_stellar_locations(outer,inner)",source)
 def test_solar_routes_are_not_local_shuttles(self):
  classifier=read("prototypes/system/route_hazards.lua")
  self.assertIn('return "stellar-approach"',classifier)
  self.assertIn('return "stellar-inner"',classifier)
  engine=read("scripts/razi_asteroid_difficulty.lua")
  self.assertIn("local initial=tier==",engine)
  for lang in ("en","ru"):
   locale=read(f"locale/{lang}/routes.cfg")
   self.assertIn("kind-stellar-approach=",locale)
   self.assertIn("kind-stellar-inner=",locale)
 def test_long_real_routes_keep_native_plasma(self):
  source=read("prototypes/compat/calidus_dyson.lua")
  self.assertIn("extended={outer=125000,inner=65000}",source)
  self.assertIn("marathon={outer=175000,inner=100000}",source)
  self.assertIn("profiles.apply(route,profile)",source)
  self.assertIn("if minimum and (not route.length or route.length<minimum)",source)
 def test_original_dyson_plasma_never_gets_quality_proxy(self):
  converter=read("prototypes/system/quality_asteroids.lua")
  self.assertIn("function M.preserve_stellar_source_enemy(target,name)",converter)
  self.assertIn("and not M.preserve_stellar_source_enemy(target,entry.asteroid)",converter)
 def test_shared_quality_grade_drives_both_display_and_actual_spawns(self):
  difficulty=read("scripts/razi_asteroid_difficulty.lua")
  self.assertIn("return clamp(initial+.65*midpoint,1,10)",difficulty)
  self.assertIn("stellar_route_tier(route)",difficulty)
  for path in ("prototypes/system/route_highlights.lua",
               "prototypes/system/quality_asteroids.lua",
               "prototypes/system/route_intel.lua"):
   self.assertIn("route_range(",read(path))
if __name__=="__main__": unittest.main()
