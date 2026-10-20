"""Regression contracts for native starmap endpoint coverage."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding="utf-8")
class RouteEndpointColors(unittest.TestCase):
 def test_short_planet_links_have_colored_strokes(self):
  ribbon=read("prototypes/system/route_ribbons.lua")
  self.assertIn("MIN_VISIBLE_SPAN=0.85",ribbon)
  self.assertIn("END_CLEARANCE=0.65",ribbon)
  self.assertNotIn("if span<10 and not belt then return nil end",ribbon)
  self.assertIn("math.min(length*.10,belt and .40 or END_CLEARANCE)",ribbon)
  self.assertIn("if not sample or length<MIN_VISIBLE_SPAN then return nil end",ribbon)
 def test_long_routes_allocated_before_rendering(self):
  ribbon=read("prototypes/system/route_ribbons.lua")
  self.assertIn("M.allocate=allocate",ribbon)
  self.assertIn("allocate(routes,layer_budget,is_compact and 18.5 or MAX_CHORD)",ribbon)
  self.assertIn("if a.stellar~=b.stellar then return a.stellar end",ribbon)
  self.assertIn("local n=row.draw_pieces or 0",ribbon)
  self.assertNotIn("if row.covered/n<=",ribbon)
 def test_high_risk_sun_shows_up_in_major_route_scope(self):
  owner=read("prototypes/system/route_highlights.lua")
  self.assertIn('kind=="stellar-approach" or kind=="stellar-inner"',owner)
  self.assertIn('if scope=="all" then return true end',owner)
 def test_no_per_tick_behavior_or_bypass_geometry(self):
  ribbon=read("prototypes/system/route_ribbons.lua")
  self.assertIn("owner.route_path(route,a,b)",ribbon)
  self.assertIn("shift={(a.x+b.x)*16,(a.y+b.y)*16}",ribbon)
  self.assertIn("mode=row.difficulty_mode or mode",ribbon)
  self.assertNotIn("script.on_nth_tick",ribbon)
  self.assertNotIn("rendered_span",ribbon)
if __name__=="__main__":unittest.main()
