"""Regression: Expedition Journal visually joins the right-side minimap row.

Factorio 2.1 does NOT allow mods to add children to its native side-menu grid.
The screen overlay uses the exact native button style and known empty row slot.
"""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class RightSideJournalTests(unittest.TestCase):
    def test_journal_uses_screen_overlay_not_left_mod_gui(self):
        source=read("scripts/razi_journal.lua")
        helper=read("scripts/razi_journal_side_menu.lua")
        control=read("control.lua")
        self.assertIn('require("scripts.razi_journal_side_menu")',source)
        self.assertNotIn('require("mod-gui")',source)
        self.assertIn('journal_side_menu.ensure(player, TOP, L("button-tooltip"))',source)
        self.assertNotIn("mod_gui.get_button_flow(player)",source)
        self.assertIn("local root=player.gui.screen",helper)
        self.assertIn('style="side_menu_button"',helper)
        self.assertIn('tags={razi_journal_action="toggle"}',helper)
        self.assertIn('sprite="razi-journal-book-icon"',helper)
        self.assertIn('local old=top[name]',helper)
        self.assertIn('local frame=top["mod_gui_top_frame"]',helper)
        self.assertIn('local legacy=top["mod_gui_button_flow"]',helper)
        self.assertIn('if action=="toggle" then M.toggle(player);return end',source)
        self.assertIn('razi_journal.gui_click(event)',control)
        self.assertIn('razi_journal.sync_all()',control)
        self.assertIn('razi_journal.sync(player)',control)

    def test_right_row_position_scales_with_screen(self):
        helper=read("scripts/razi_journal_side_menu.lua")
        self.assertIn('BUTTON_EDGE=40',helper)
        self.assertIn('COLUMN_PITCH=44',helper)
        self.assertIn('COLUMNS_FROM_RIGHT=2',helper)
        self.assertIn('TOP_MARGIN=104',helper)
        self.assertIn('RIGHT_PADDING=12',helper)
        self.assertIn('player.display_resolution,player.display_scale',helper)
        self.assertIn('button.location=M.position(',helper)
        self.assertIn('settings.show_side_menu~=false',helper)
        source=read("scripts/razi_journal.lua")
        self.assertIn('function M.on_display_changed(event)',source)
        self.assertIn('journal_side_menu.ensure(player, TOP, L("button-tooltip"))',source)
        self.assertIn('on_player_display_resolution_changed',read("control.lua"))
        self.assertIn('on_player_display_scale_changed',read("control.lua"))
        self.assertIn('key_sequence="CONTROL + SHIFT + J"',
                      read("prototypes/ui/razi_journal.lua"))

if __name__=="__main__":
    unittest.main()
