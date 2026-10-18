"""Expedition Journal: supported native toolbar and GUI migration checks."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class JournalShortcutTests(unittest.TestCase):
    def test_shortcut_prototype_and_toggle_event(self):
        gui=read("prototypes/ui/razi_journal.lua")
        control=read("control.lua")
        journal=read("scripts/razi_journal.lua")
        self.assertIn('type="shortcut",name="razi-expedition-journal-shortcut"',gui)
        self.assertIn('action="lua"',gui)
        self.assertIn('associated_control_input="razi-journal-toggle"',gui)
        self.assertIn('new-blueprint-book-x56.png',gui)
        self.assertIn('new-blueprint-book-x24.png',gui)
        self.assertIn('key_sequence="CONTROL + SHIFT + J"',gui)
        self.assertIn('defines.events.on_lua_shortcut',control)
        self.assertIn('event.prototype_name~="razi-expedition-journal-shortcut"',control)
        self.assertIn('razi_journal.toggle(player)',control)
        self.assertIn('if action=="toggle" then M.toggle(player);return end',journal)
        self.assertIn('"version": "2.1.120"',read("info.json"))

    def test_unreachable_overlay_is_fully_retired(self):
        journal=read("scripts/razi_journal.lua")
        cleanup=read("scripts/razi_journal_button_cleanup.lua")
        control=read("control.lua")
        self.assertIn('local journal_button_cleanup=require(',journal)
        self.assertIn('journal_button_cleanup.remove(player,TOP)',journal)
        self.assertNotIn('journal_side_menu.ensure(',journal)
        self.assertNotIn('journal_side_menu.update_visibility(',journal)
        self.assertNotIn('razi_journal.refresh_side_menu_visibility()',control)
        for token in ('local old=top[name]', 'local frame=top["mod_gui_top_frame"]',
                      'local legacy=top["mod_gui_button_flow"]',
                      'old=screen[name]', 'old=screen[ANCHOR]'):
            self.assertIn(token,cleanup)
        self.assertIn('razi_journal.sync_all()',control)
        self.assertIn('razi_journal.sync(player)',control)
        self.assertIn('razi_journal.on_display_changed(event)',control)

if __name__=="__main__":
    unittest.main()
