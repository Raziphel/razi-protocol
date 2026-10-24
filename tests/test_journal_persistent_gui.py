"""Native GUI should remain stable under navigation, search and research."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class PersistentJournalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.journal = read("scripts/razi_journal.lua")

    def test_search_and_filters_do_not_recreate_the_window(self):
        src=self.journal
        self.assertIn("local available=data.quests",src)
        self.assertIn("item.visible=state_matches_filter(state,p.filter)",src)
        self.assertIn("row.visible=matching",src)
        self.assertIn('name="razi_journal_chapter_column"',src)
        self.assertIn('name="razi_journal_no_results"',src)
        self.assertIn('name="razi_journal_chapter_count"',src)
        self.assertIn('name="razi_journal_filter_"..filter',src)
        search=src.split("function M.text_changed(event)",1)[1].split("function M.elem_changed",1)[0]
        self.assertNotIn("draw(player",search)
        self.assertIn("update_reader(player,",search)

    def test_event_updates_are_partial_and_keep_reading_position(self):
        src=self.journal
        helper=src.split("local function update_reader(player,preserve_reader)",1)[1].split("M.draw=draw",1)[0]
        self.assertNotIn("frame.clear()",helper)
        self.assertIn("collect_scrolls(reader,saved)",helper)
        self.assertIn("restore_scrolls(reader,saved,false)",helper)
        self.assertIn('if preserve_reader then return end',helper)
        self.assertIn('if #data.quests>0 and not card then draw(player);return end',helper)
        refresh=src.split("function M.refresh_open()",1)[1].split("function M.on_removed",1)[0]
        self.assertIn('if pref(player.index).view=="quests" then update_reader(player)',refresh)
        self.assertIn('razi_journal_archive_navigation=true',src)

    def test_retired_journal_button_does_not_leave_ghost_bar(self):
        cleanup=read("scripts/razi_journal_button_cleanup.lua")
        self.assertIn('old=inner[name]',cleanup)
        self.assertIn('if old and old.valid then old.destroy() end',cleanup)
        self.assertIn('#children==1 and children[1]==inner',cleanup)
        self.assertIn('inner.valid and #inner.children==0',cleanup)
        self.assertIn('frame.destroy()',cleanup)
        self.assertIn('if #legacy.children==0 then legacy.destroy() end',cleanup)
        self.assertIn('local top=player.gui.top',cleanup)
        # Do not remove the still-used standalone Journal control.
        journal=self.journal
        self.assertIn('local top=player.gui.top[TOP]',journal)
        self.assertIn('icons.button(player.gui.top,"razi-journal-book-icon","toolbar"',journal)

    def test_saved_view_identity_and_tab_name(self):
        src=self.journal
        self.assertIn('archive=story.enabled()',src)
        loc=read("locale/en/razi_journal_interface.cfg")
        self.assertIn("view-archive=Archive",loc)
        self.assertIn("view-quests=Quests",loc)
        self.assertIn("view-projects=Projects",loc)
        systems=read("locale/en/razi_journal_systems.cfg")
        self.assertIn("view-systems=Systems",systems)

if __name__=="__main__":
    unittest.main()
