"""Regression coverage for the Expedition Journal reading UI."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(x): return (R/x).read_text()
class JournalPolish(unittest.TestCase):
    def test_scroll(self):
        x=read("scripts/razi_journal.lua")
        for name in ("navigation","reading","chapter_reading","archive_reading","project_reader"):
            self.assertIn("razi_journal_"+name+"=true",x)
        self.assertIn("collect_scrolls(frame,saved_scrolls)",x)
        self.assertIn("restore_scrolls(frame,saved_scrolls,reveal_on_redraw)",x)
        self.assertIn("local reveal_on_redraw=p.reveal_selection==true",x)
        self.assertIn("scroll.tags={razi_scroll_context=quest.id}",x)
        self.assertIn("reading.tags={razi_scroll_context=chosen.id}",x)
        self.assertIn("scroll.tags={razi_scroll_context=p.project}",read("scripts/razi_journal_projects.lua"))
    def test_localization_and_cards(self):
        x=read("scripts/razi_journal.lua")
        self.assertNotIn('{"journal-workshop."..quest.id}',x)
        self.assertIn("preview.workshop_fallback(quest,prototypes)",x)
        self.assertIn("function M.workshop_fallback",read("scripts/razi_journal_recipe_preview.lua"))
        self.assertIn("math.min(7,math.floor(width/155))",x)
if __name__=="__main__": unittest.main()
