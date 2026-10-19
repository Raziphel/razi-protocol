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
        # Clicking ordinary navigation controls may not override the saved offset.
        click=x.split("function M.gui_click(event)",1)[1].split("function M.text_changed(event)",1)[0]
        self.assertNotIn("p.reveal_selection=true",click)
        self.assertIn("p.reveal_selection=false",click)
        selection=x.split("function M.selection_changed(event)",1)[1].split("function M.gui_closed(event)",1)[0]
        self.assertNotIn("p.reveal_selection=true",selection)
        # External journal links may still intentionally reveal their target.
        self.assertIn("p.reveal_selection=true\n  open(player)",x)
        self.assertIn('cover_title.style.font="default-bold"',x)
        self.assertIn('journal-chapter-summary."..p.chapter',x)
        chapters=read("locale/en/razi_journal_chapters.cfg")
        self.assertIn("solaris=Solaris\n",chapters)
        self.assertIn("[journal-chapter-summary]",chapters)

    def test_localization_and_cards(self):
        x=read("scripts/razi_journal.lua")
        self.assertNotIn('{"journal-workshop."..quest.id}',x)
        self.assertIn("preview.workshop_fallback(quest,prototypes)",x)
        self.assertIn("function M.workshop_fallback",read("scripts/razi_journal_recipe_preview.lua"))
        self.assertIn("math.min(7,math.floor(width/155))",x)
if __name__=="__main__": unittest.main()
