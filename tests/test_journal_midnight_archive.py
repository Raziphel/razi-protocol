"""Midnight Archive: visual hierarchy without breaking Factorio native GUI."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class MidnightArchiveDesign(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.journal=source("scripts/razi_journal.lua")
        cls.projects=source("scripts/razi_journal_projects.lua")
        cls.systems=source("scripts/razi_journal_systems.lua")
        cls.icons=source("scripts/razi_journal_icons.lua")

    def test_masthead_is_condensed_and_uses_muted_archive_palette(self):
        ui=self.journal
        self.assertIn('ink={r=.933,g=.890,b=.808}',ui)
        self.assertIn('amber={r=.82,g=.69,b=.48}',ui)
        self.assertIn('style="tool_button"',ui)
        self.assertNotIn('wrap(frame,L("subtitle-short")',ui)
        self.assertNotIn('local foot=wrap(frame,L("footer-hint")',ui)
        self.assertIn('local masthead=panel.add{type="flow",direction="horizontal"}',ui)
        self.assertIn('local hero_title=wrap(hero_text',ui)
        self.assertIn('hero_title.style.font="heading-2"',ui)

    def test_search_filters_are_in_rail_not_a_second_global_toolbar(self):
        ui=self.journal
        navigator=ui.split('local function render_chapters(',1)[1].split(
            '-- The archive is not another quest chain.',1)[0]
        self.assertIn('local filters=frame.add{type="flow",name="razi_journal_filterbar"',navigator)
        self.assertIn('name="razi_journal_search"',navigator)
        self.assertIn('name="razi_journal_chapter_picker"',navigator)
        self.assertIn('filterbar.visible=p.view~="quests"',ui)
        self.assertIn('local filterbar=navigation["razi_journal_filterbar"]',ui)

    def test_chapters_and_selected_quests_have_one_accent_not_nested_cards(self):
        ui=self.journal
        self.assertIn('icons.sprite(head,themes.icon(chapter.id),"chapter_button"',ui)
        self.assertIn('name="razi_journal_chapter_title"',ui)
        self.assertIn('name="razi_journal_item_rule"',ui)
        self.assertIn('selection.visible=chosen',ui)
        self.assertNotIn('name="razi_journal_chapter_meter"',ui)
        self.assertIn('item.visible=state_matches_filter(state,p.filter)',ui)
        self.assertIn('row.visible=matching',ui)

    def test_story_is_first_and_chapter_context_lives_on_cover(self):
        ui=self.journal
        dossier=ui.split('local function render_details(',1)[1].split(
            'local function chapter_act(',1)[0]
        chapter=ui.split('local function render_chapter_cover(',1)[1].split(
            'local function render_chapters(',1)[0]
        self.assertLess(dossier.index('section(prose,"story-heading"'),
                        dossier.index('section(prose,"tip-heading"'))
        self.assertNotIn('section(prose,"chapter-context"',dossier)
        self.assertIn('section(body,"chapter-context"',chapter)
        self.assertIn('restore_scrolls(reader,saved,false)',ui)

    def test_projects_and_archive_use_quiet_index_rows(self):
        self.assertIn('local card=parent.add{type="flow",direction="vertical"}',
                      self.projects)
        self.assertIn('meter.visible=selected',self.projects)
        self.assertIn('local selection=row.add{type="progressbar",value=1}',
                      self.journal)
        self.assertIn('selection.visible=highlighted',self.journal)
        self.assertIn('name="razi_journal_project_navigation"',self.projects)
        self.assertIn('project_button=30',self.icons)
        self.assertIn('chapter_button=22',self.icons)

    def test_native_source_integrations_unchanged(self):
        self.assertIn('systems.render(body,player,size)',self.journal)
        self.assertIn('pcall(remote.call,"nexus-threat","get_state")',
                      self.systems)
        self.assertNotIn('script.on_tick',self.journal)
        self.assertNotIn('rendering.draw',self.journal)

if __name__=="__main__":
    unittest.main()
