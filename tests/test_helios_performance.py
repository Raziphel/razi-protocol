"""Guard against new HELIOS hot loops and misleading production totals."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
class HeliosPerformance(unittest.TestCase):
 def test_grid_cache_with_fresh_final_check(self):
  grid=read("scripts/razi_helios_operations.lua")
  self.assertIn("M.grid_cache_ticks=180",grid)
  self.assertIn("not refresh and entry and entry.total==total",grid)
  self.assertIn("function M.anchor_changed(entity)",grid)
  self.assertIn("function M.ready(force,refresh)",grid)
  self.assertIn("local grid=M.grid(force,refresh)",grid)
  self.assertIn('helios_operations.ready(force,true)',
                read("scripts/razi_convergence.lua"))
 def test_gui_production_is_cached_and_uses_output_not_consumption(self):
  gui=read("scripts/galactic_dyson.lua")
  self.assertIn("M.production_cache_ticks=600",gui)
  self.assertIn("stats.get_output_count(name)",gui)
  self.assertNotIn("+(stats.get_input_count(name)",gui)
  self.assertIn("storage.razi_helios_production_cache",gui)
  self.assertIn("if not items or items[name]",gui)
 def test_non_solar_platforms_do_not_allocate_held_state(self):
  operations=read("scripts/razi_helios_operations.lua")
  begin=operations.index("function M.observe(platform)")
  end=operations.index("local surge_periods=",begin)
  section=operations[begin:end]
  self.assertLess(section.index("if not relevant then"),section.index("local all=holds()"))
  self.assertIn('M.destination("slp-solar-system-sun2")',section)
 def test_no_tick_callbacks_or_full_world_enemy_scans(self):
  for path in ("scripts/razi_helios_operations.lua",
               "scripts/galactic_dyson.lua"):
   src=read(path)
   self.assertNotIn("script.on_nth_tick(",src)
   self.assertNotIn("find_entities()",src)
  control=read("control.lua")
  self.assertIn("helios_operations.anchor_changed(entity)",control)
 def test_extreme_solar_density_has_bounded_midpoint(self):
  src=read("prototypes/compat/calidus_dyson.lua")
  self.assertIn('and (tier=="inner" and 1.22 or 1.14) or 1.08)',src)
  self.assertIn('danger=="extreme" and "belt_umbra_crossing"',src)
  self.assertIn('danger=="extreme" and "outer_ring_crosslink"',src)
  self.assertIn('profiles.apply(route,profile)',src)
if __name__=="__main__": unittest.main()
