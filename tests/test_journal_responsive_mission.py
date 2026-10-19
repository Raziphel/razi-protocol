"""Responsive mission-plan source contracts; complements Lua GUI fixture."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class ResponsiveMissionPlan(unittest.TestCase):
    def test_single_column_switch_is_available_only_on_narrow_quest_folios(self):
        journal=read("scripts/razi_journal.lua")
        loc=read("locale/en/razi_journal_interface.cfg")
        self.assertIn("local single_column=width<740",journal)
        self.assertIn('size.reader=size.width-43',journal)
        self.assertIn('compact_switch.visible=p.view=="quests" and size.single_column',journal)
        self.assertIn('navigation.visible=on_small_screen and p.compact_index_open',journal)
        self.assertIn('reader.visible=not (on_small_screen and p.compact_index_open)',journal)
        self.assertIn('p.compact_index_open=not p.compact_index_open',journal)
        self.assertIn('p.compact_index_scroll=scroller.vertical_scroll_position',journal)
        self.assertIn('scroll.vertical_scroll_position=p.compact_index_scroll',journal)
        self.assertIn('compact-index=Index',loc)
        self.assertIn('compact-read=Read dossier',loc)

    def test_actions_and_story_share_one_scroll_context(self):
        journal=read("scripts/razi_journal.lua")
        dossier=journal.split("local function render_details(",1)[1].split(
            "local function nauvis_phase(",1)[0]
        self.assertIn("local actions=prose.add{type=\"table\"",dossier)
        self.assertNotIn("local actions=panel.add{type=\"table\"",dossier)
        self.assertIn('name="razi_journal_actions"',dossier)
        self.assertIn('local content_height=size.body-(size.compact and 124 or 148)',dossier)
        self.assertLess(dossier.index('section(prose,"story-heading"'),
                        dossier.index('local actions=prose.add'))
        self.assertIn('local actions=prose and prose["razi_journal_actions"]',journal)
        self.assertIn('local pin=actions and actions["razi_journal_pin_button"]',journal)

    def test_preview_does_not_repeat_next_action_or_hide_done_history(self):
        objectives=read("scripts/razi_journal_objectives.lua")
        journal=read("scripts/razi_journal.lua")
        self.assertIn("row~=plan.next_step",objectives)
        self.assertIn("if expanded then return plan.rows end",objectives)
        self.assertIn("if plan.finished then return result end",objectives)
        self.assertIn('size.compact and 1 or 2',journal)
        self.assertIn('p.goal_expanded_quest==quest.id',journal)
        self.assertIn('if goal_expanded or #plan.rows>1 then',journal)
        self.assertIn('tags={razi_journal_action="mission-details",id=quest.id}',journal)
        self.assertIn('tags={razi_journal_action="guidance-select",id=step.link}',journal)

    def test_native_gui_fixture_covers_width_focus_and_scroll(self):
        fixture=read("tests/lua/test_razi_journal_layout.lua")
        self.assertIn('player.display_scale=1.5',fixture)
        self.assertIn('check(narrow.single_column and narrow.width<740',fixture)
        self.assertIn('reader.style.width==narrow.width-43',fixture)
        self.assertIn('scroller.vertical_scroll_position=83',fixture)
        self.assertIn('nav["razi_journal_navigation"].vertical_scroll_position==83',fixture)
        self.assertIn('razi_journal_action=="compact-index"',fixture)
        self.assertIn('journal.preferences(1).compact_index_open==false',fixture)

    def test_progress_keeps_source_data_and_no_per_tick_redraw(self):
        journal=read("scripts/razi_journal.lua")
        self.assertIn("function M.refresh_research_visible()",journal)
        code=journal.split("function M.refresh_research_visible()",1)[1].split(
            "function M.refresh_systems_visible()",1)[0]
        self.assertNotIn("draw(player)",code)
        self.assertNotIn("frame.clear()",code)
        self.assertNotIn("find_entities_filtered",code)
        self.assertIn('restore_scrolls(reader,saved,false)',journal)

if __name__=="__main__":
    unittest.main()
