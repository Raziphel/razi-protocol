"""Expedition Journal minimap-side placement regression checks."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class JournalMinimapTests(unittest.TestCase):
    def test_native_styled_right_hand_overlay(self):
        side=read("scripts/razi_journal_side_menu.lua")
        journal=read("scripts/razi_journal.lua")
        controls=read("control.lua")
        for token in ('style="invisible_frame"', 'anchor.location=M.position(',
                      'style="side_menu_button"', 'anchor.bring_to_front()',
                      'old=player.gui.screen[name]', 'local old=top[name]',
                      'local legacy=top["mod_gui_button_flow"]',
                      'tags={razi_journal_action="toggle"}'):
            self.assertIn(token,side)
        self.assertIn('journal_side_menu.ensure(player, TOP, L("button-tooltip"))',
                      journal)
        self.assertIn('journal_side_menu.update_visibility(player,TOP)',journal)
        self.assertNotIn('mod_gui.get_button_flow(player)',journal)
        self.assertIn('razi_journal.gui_click(event)',controls)
        self.assertIn('razi_journal.sync_all()',controls)
        self.assertIn('razi_journal.sync(player)',controls)

    def test_geometry_book_sprite_and_migration_version(self):
        side=read("scripts/razi_journal_side_menu.lua")
        self.assertIn('BUTTON_SIZE=40',side)
        self.assertIn('COLUMN_PITCH=44',side)
        self.assertIn('RIGHT_PADDING=3',side)
        self.assertIn('TOP_MARGIN=94',side)
        self.assertIn('player.display_resolution,player.display_scale',side)
        gui=read("prototypes/ui/razi_journal.lua")
        self.assertIn('size=64,y=640,scale=0.5',gui)
        self.assertIn('key_sequence="CONTROL + SHIFT + J"',gui)
        self.assertIn('"version": "2.1.119"',read("info.json"))
        control=read("control.lua")
        self.assertIn('razi_journal.refresh_side_menu_visibility()',control)
        self.assertIn('razi_journal.on_display_changed(event)',control)

if __name__=="__main__":
    unittest.main()
