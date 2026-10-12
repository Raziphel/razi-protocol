"""Razi's native Space Age manager must remain opt-in and read-only."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class GalacticOperationsTests(unittest.TestCase):
    def test_gui_is_opt_in_and_event_based(self):
        control=(ROOT/"control.lua").read_text()
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        self.assertIn('galactic_operations.sync_all_map_buttons',control)
        self.assertIn('on_player_controller_changed',control)
        self.assertIn('script.on_nth_tick(30, function(event)',control)
        self.assertIn('galactic_operations.sync_all_map_buttons(event)',control)
        self.assertNotIn('on_lua_shortcut',control)
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
        self.assertNotIn('type="shortcut"',proto)
        self.assertIn('type="sprite"',proto)
        self.assertIn('razi-galactic-operations-map-icon',proto)
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        self.assertIn('MAP_ANCHOR="razi_ops_map_anchor"',ui)
        self.assertIn('type="sprite-button",name=MAP_BUTTON',ui)
        self.assertIn('player.render_mode~=defines.render_mode.game',ui)
        self.assertIn('player.controller_type==defines.controllers.remote',ui)
        self.assertNotIn('set_shortcut_toggled',ui)
        self.assertIn('CONTROL + SHIFT + G',proto)
        self.assertIn('[razi-ops]',loc)
        self.assertIn('group-vibrant=',loc)
    def test_atlas_fleet_are_read_only(self):
        ui=(ROOT/"scripts/galactic_operations.lua").read_text()
        atlas=(ROOT/"scripts/galactic_atlas.lua").read_text()
        fleet=(ROOT/"scripts/galactic_fleet.lua").read_text()
        self.assertIn('atlas.render(inspector,player,id,p)',ui)
        self.assertIn('fleet.render(inspector,platform,id,p)',ui)
        self.assertIn('razi_ops_note_id',ui)
        self.assertIn('shortest_path',atlas)
        self.assertIn('unlock-space-location',atlas)
        self.assertIn('can_leave_current_location()',fleet)
        self.assertIn('defines.inventory.hub_main',fleet)
        for source in (atlas,fleet):
            self.assertNotIn('create_surface(',source)
            self.assertNotIn('on_nth_tick',source)
            self.assertNotIn('platform.schedule=',source)
    def test_map_and_atlas_performance_guards(self):
        operations=(ROOT/"scripts/galactic_operations.lua").read_text()
        atlas=(ROOT/"scripts/galactic_atlas.lua").read_text()
        self.assertIn('if not current or current.x~=x or current.y~=86 then',operations)
        self.assertIn('local search=(p.search or ""):lower()',operations)
        self.assertIn('local recent={}',operations)
        self.assertIn('row.sort_name=row.name:lower()',operations)
        self.assertIn('row.sort_group=catalog.position(row.group)',operations)
        self.assertIn('local function location_research_catalog()',atlas)
        self.assertIn('local function connection_index()',atlas)
        self.assertIn('local function accessible(name)',atlas)
        self.assertNotIn('script.on_nth_tick',atlas)

    def test_all_seven_systems(self):
        catalog=(ROOT/"scripts/galactic_catalog.lua").read_text()
        for star in ("calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"):
            self.assertIn(star,catalog)
if __name__=="__main__":
    unittest.main()
