"""Regression contracts for Project HELIOS orbital commissioning."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def src(path): return (ROOT/path).read_text(encoding="utf-8")
class HeliosCommissionTests(unittest.TestCase):
 def test_coronal_surge_is_event_checked_not_entity_spam(self):
  srcfile=src("scripts/razi_helios_operations.lua")
  self.assertIn("function M.coronal_surge(tick)",srcfile)
  self.assertIn('if surge then return "helios-need-surge"',srcfile)
  self.assertNotIn("script.on_nth_tick",srcfile)
  self.assertNotIn("surface.create_entity",srcfile)
 def test_structures_require_real_energy(self):
  proto=src("prototypes/compat/helios_structures.lua")
  self.assertIn('radar.energy_usage="15MW"',proto)
  self.assertIn('categories={"advanced-crafting"}',proto)
  self.assertIn('dyson.safe_link("ds-energy-loader-mk3",tech.name)',proto)
 def test_orbital_deliveries_are_physical_and_team_bound(self):
  engine=src("scripts/razi_helios_operations.lua")
  for marker in ("player.character.valid","platform.force==player.force",
    "platform.space_location","not platform.space_connection",
    "player.controller_type==defines.controllers.remote",
    "inv.remove{name=spec.item,count=offered}"):
   self.assertIn(marker,engine)
  self.assertNotIn("script.on_nth_tick",engine)
  self.assertNotIn("remote.call(",engine)
 def test_grid_requires_distinct_powered_planets(self):
  engine=src("scripts/razi_helios_operations.lua")
  for marker in ("surface.planet and not surface.platform",
    "entity.energy>0","if world.powered>0 then distinct=distinct+1"):
   self.assertIn(marker,engine)
 def test_journal_click_rechecks_hold(self):
  self.assertIn('helios_operations.deliver(player,tags.value)',
    src("scripts/razi_journal.lua"))
  self.assertIn("deliver.enabled=carrying>0",
    src("scripts/galactic_dyson.lua"))
 def test_optional_finale(self):
  control=src("scripts/razi_convergence.lua")
  self.assertIn('and not helios_operations.ready(force,true)',control)
  self.assertIn('technologies["razi-helios-grid-commission"]',
    src("scripts/razi_helios_operations.lua"))
  self.assertIn('name="razi-helios-convergence-proof"',src("settings.lua"))
 def test_locales_have_unique_sections(self):
  for file in ("locale/en/helios.cfg","locale/ru/helios.cfg"):
   sections=set()
   for line in src(file).splitlines():
    if line.startswith("["):
     self.assertNotIn(line,sections)
     sections.add(line)
if __name__=="__main__": unittest.main()
