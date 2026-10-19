"""Midnight Archive phase-two native GUI/focus mode source contracts.

These tests protect structural promises; an actual Factorio render and
scroll playtest is still mandatory before labeling the visuals final.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class NativeMidnightArchiveFocus(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.journal=read("scripts/razi_journal.lua")
        cls.projects=read("scripts/razi_journal_projects.lua")
        cls.proto=read("prototypes/ui/razi_journal.lua")

    def test_native_styles_have_correct_prototype_types(self):
        source=self.proto
        for style, kind, parent in (
            ("razi_journal_index","frame_style","inside_deep_frame"),
            ("razi_journal_paper","frame_style","inside_shallow_frame"),
            ("razi_journal_callout","frame_style","inside_shallow_frame"),
            ("razi_journal_action_button","button_style","button"),
        ):
            self.assertIn(f"styles.{style}={{",source)
            self.assertIn(f'type="{kind}",parent="{parent}"',source)
        self.assertIn('require("prototypes.ui.razi_journal")',read("data.lua"))

    def test_focus_is_preference_only_and_retains_document_scroll(self):
        ui=self.journal
        self.assertIn('value.reader_focus=value.reader_focus==true',ui)
        self.assertIn('p.reader_focus=not p.reader_focus',ui)
        self.assertIn('if p.view~="systems" and p.reader_focus then',ui)
        self.assertIn('size.reader=size.width-43',ui)
        self.assertIn('focus.visible=p.view~="systems"',ui)
        self.assertIn('navigation.visible=not p.reader_focus',ui)
        self.assertIn('local navigation_scroll=scroll and scroll.vertical_scroll_position',ui)
        self.assertIn('scroll.vertical_scroll_position=navigation_scroll',ui)
        self.assertIn('collect_scrolls(frame,saved_scrolls)',ui)
        self.assertIn('restore_scrolls(frame,saved_scrolls,reveal_on_redraw)',ui)
        self.assertIn('restore_scrolls(reader,saved,false)',ui)
        self.assertNotIn('storage.razi_expedition_journal={}\n',ui)

    def test_project_focus_keeps_both_wide_and_narrow_paths(self):
        projects=self.projects
        self.assertIn('name="razi_journal_project_index"',projects)
        self.assertIn('rail.visible=not p.reader_focus',projects)
        self.assertIn('selector.visible=not p.reader_focus',projects)
        self.assertIn('size.body-(p.reader_focus and 35 or selector_height+42)',projects)
        self.assertIn('scroll.tags={razi_scroll_context=p.project}',projects)

    def test_archive_focus_keeps_record_state(self):
        ui=self.journal
        self.assertIn('name="razi_journal_archive_index"',ui)
        self.assertIn('rail.visible=not p.reader_focus',ui)
        self.assertIn('reading.tags={razi_scroll_context=chosen.id}',ui)
        self.assertIn('p.record=chosen.id',ui)
        self.assertIn('razi_journal_archive_navigation=true',ui)

    def test_navigation_is_themed_and_story_precedes_secondary_sections(self):
        ui=self.journal
        icons=read("scripts/razi_journal_icons.lua")
        locale=read("locale/en/razi_journal_interface.cfg")
        self.assertIn('icons.sprite(line,themes.icon(theme_id),"tab_icon")',ui)
        self.assertIn('tab_icon=16',icons)
        self.assertIn('style="razi_journal_index"',ui)
        self.assertIn('style="razi_journal_paper"',ui)
        self.assertIn('style="razi_journal_callout"',ui)
        self.assertIn('style="razi_journal_action_button"',ui)
        dossier=ui.split("local function render_details(",1)[1].split(
            "local function nauvis_phase(",1)[0]
        self.assertLess(dossier.index('section(prose,"story-heading"'),
                        dossier.index('local next_steps=guidance.followups'))
        self.assertIn('focus-read=Focus',locale)
        self.assertIn('focus-show-index=Index',locale)

    def test_native_runtime_hooks_still_own_research_and_saves(self):
        ui=self.journal
        self.assertIn('function M.on_research(event)',ui)
        self.assertIn('function M.on_display_changed(event)',ui)
        self.assertIn('M.journal_visible(player.force,quest,context)',ui)
        self.assertNotIn('script.on_tick',ui)
        self.assertNotIn('rendering.draw',ui)

if __name__=="__main__":
    unittest.main()
