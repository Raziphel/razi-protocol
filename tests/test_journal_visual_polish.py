"""The journal should read as a field dossier, without UI-only milestones."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class VisualPolishTests(unittest.TestCase):
    def test_folio_navigation_and_quiet_counters(self):
        journal=read("scripts/razi_journal.lua")
        self.assertIn('for _,view in ipairs({"quests","projects","archive"})',journal)
        self.assertIn('style="clickable_label"',journal)
        self.assertIn('local folio=toolbar.add{type="flow",direction="vertical"}',
                      journal)
        self.assertIn('accent_rule(folio,window_theme,76,2)',journal)
        self.assertIn('local totals=frame.add{type="flow",direction="vertical"}',
                      journal)
        self.assertNotIn('local totals=frame.add{type="frame"',journal)
        self.assertIn('body.style.width=size.width-33',journal)
        self.assertIn('hero_title.style.font_color=COLOR.ink',journal)

    def test_chapters_use_an_index_instead_of_repeating_cards(self):
        journal=read("scripts/razi_journal.lua")
        self.assertIn('type=open and "frame" or "flow"',journal)
        self.assertIn('card.style.padding=open and 8 or 3',journal)
        self.assertIn('accent_rule(card,theme,math.min(82,inner-40),2)',journal)
        self.assertIn('name="razi_journal_search"',journal)
        self.assertIn('name="razi_journal_chapter_picker"',journal)
        self.assertIn('razi_journal_action="guidance-select"',journal)
        self.assertIn('razi_journal_action="select"',journal)

    def test_megaproject_dossiers_use_real_status(self):
        projects=read("scripts/razi_journal_projects.lua")
        icons=read("scripts/razi_journal_icons.lua")
        locale=read("locale/en/razi_journal.cfg")
        self.assertIn('local ids={"dyson","cargo","recovery","transceiver","convergence"}',
                      projects)
        self.assertIn('icons.button(head,art_for(id,player.force),"project_button"',
                      projects)
        self.assertIn('project_icon=32',icons)
        self.assertIn('local meter=card.add{type="progressbar"',projects)
        self.assertIn('convergence.progress(force)',projects)
        self.assertIn('catalog.snapshot(force)',projects)
        self.assertIn('dyson.status(force)',projects)
        self.assertIn('options={embedded=true,width=width-68}',projects)
        self.assertIn('scroll.horizontal_scroll_policy="never"',projects)
        self.assertNotIn('on_tick',projects)
        self.assertNotIn('create_surface(',projects)
        for key in ("projects-heading","project-dossier","project-progress",
                    "project-caption-dyson","project-caption-cargo",
                    "project-caption-recovery","project-caption-transceiver",
                    "project-caption-convergence"):
            self.assertRegex(locale,rf"(?m)^{key}=")
if __name__=="__main__":
    unittest.main()
