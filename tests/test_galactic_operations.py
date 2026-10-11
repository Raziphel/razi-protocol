"""Razi's native Space Age manager must remain opt-in and read-only."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class GalacticOperationsTests(unittest.TestCase):
    def test_gui_is_opt_in_and_event_based(self):
        control=(ROOT/"control.lua").read_text()
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        self.assertIn('on_lua_shortcut',control)
        self.assertIn('on_gui_text_changed',control)
        self.assertIn('on_gui_selection_state_changed',control)
        self.assertIn('PAGE_SIZE=22',ui)
        self.assertIn('razi_ops_role_filter',ui)
        self.assertIn('razi_ops_role_',ui)
        self.assertIn('p.roles[id]',ui)
        self.assertIn('prototypes.space_location',ui)
        self.assertIn('player.force.platforms',ui)
        self.assertNotIn('on_nth_tick',ui)
        self.assertNotIn('create_surface(',ui)
        self.assertNotIn('create_space_platform(',ui)
        self.assertNotIn('game_view_settings.show_surface_list',ui)
    def test_keyboard_shortcut_and_locale(self):
        proto=(ROOT/"prototypes/ui/galactic_operations.lua").read_text()
        loc=(ROOT/"locale/en/galactic_operations.cfg").read_text()
        self.assertIn('type="shortcut"',proto)
        self.assertIn('CONTROL + SHIFT + G',proto)
        self.assertIn('[razi-ops]',loc)
        self.assertIn('group-vibrant=',loc)
    def test_all_seven_systems(self):
        catalog=(ROOT/"scripts/galactic_catalog.lua").read_text()
        for star in ("calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"):
            self.assertIn(star,catalog)
if __name__=="__main__":
    unittest.main()
