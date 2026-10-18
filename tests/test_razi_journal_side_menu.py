"""Regression: the original gold Expedition Journal button is restored."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding="utf-8")

class JournalToolbarTests(unittest.TestCase):
    def test_gold_top_left_button_and_hotkey(self):
        journal=read("scripts/razi_journal.lua")
        proto=read("prototypes/ui/razi_journal.lua")
        control=read("control.lua")
        self.assertIn('local top=player.gui.top[TOP]',journal)
        self.assertIn('top=icons.button(player.gui.top,"razi-journal-book-icon","toolbar",',journal)
        self.assertIn('{razi_journal_action="toggle"},L("button-tooltip"),TOP)',journal)
        self.assertIn('if action=="toggle" then M.toggle(player);return end',journal)
        self.assertIn('graphics/icons/routes/interstellar-route.png',proto)
        self.assertIn('key_sequence="CONTROL + SHIFT + J"',proto)
        self.assertNotIn('type="shortcut"',proto)
        self.assertNotIn('defines.events.on_lua_shortcut',control)
        self.assertIn('razi_journal.gui_click(event)',control)
        self.assertIn('"version": "2.1.121"',read("info.json"))

    def test_legacy_placements_removed_without_touching_top_button(self):
        journal=read("scripts/razi_journal.lua")
        cleanup=read("scripts/razi_journal_button_cleanup.lua")
        control=read("control.lua")
        self.assertIn('journal_button_cleanup.remove_other_placements(player,TOP)',journal)
        self.assertIn('function M.remove_other_placements(player,name)',cleanup)
        self.assertNotIn('local old=top[name]',cleanup)
        self.assertIn('local frame=top["mod_gui_top_frame"]',cleanup)
        self.assertIn('local legacy=top["mod_gui_button_flow"]',cleanup)
        self.assertIn('old=screen[name]',cleanup)
        self.assertIn('old=screen[ANCHOR]',cleanup)
        self.assertIn('razi_journal.sync_all()',control)
        self.assertIn('razi_journal.sync(player)',control)
        self.assertIn('razi_journal.on_display_changed(event)',control)
        self.assertIn('M.sync(player)',journal)

if __name__=="__main__":
    unittest.main()
