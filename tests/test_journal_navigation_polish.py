"""Polish guardrails: compact layouts remain navigable without losing scroll."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def source(name):
    return (ROOT / name).read_text(encoding="utf-8")

class JournalNavigationPolishTests(unittest.TestCase):
    def test_project_rail_and_compact_index_scroll_independently(self):
        projects = source("scripts/razi_journal_projects.lua")
        journal = source("scripts/razi_journal.lua")
        self.assertIn('name="razi_journal_project_navigation"', projects)
        self.assertIn('local grid=selector.add{type="table",column_count=columns}', projects)
        self.assertIn('local entries=selector.add{type="flow",direction="vertical"}', projects)
        self.assertIn('size.body-selector_height-42', projects)
        self.assertIn('razi_journal_project_navigation=true', journal)
        self.assertIn('scroll.vertical_scroll_policy="auto"', projects)
        self.assertNotIn('title.style.font="heading-1"', projects)

    def test_chapter_index_has_no_redundant_meters_and_keeps_live_search(self):
        journal = source("scripts/razi_journal.lua")
        self.assertIn('name="razi_journal_chapter_status"', journal)
        self.assertNotIn('name="razi_journal_chapter_meter"', journal)
        self.assertIn('name="razi_journal_item_rule"', journal)
        self.assertIn('selection.visible=chosen', journal)
        self.assertIn('local filterbar=navigation["razi_journal_filterbar"]', journal)
        self.assertIn('lead.visible=next_quest~=nil and p.query=="" and p.filter=="all"', journal)
        self.assertIn('lead.visible=p.query=="" and p.filter=="all"', journal)
        self.assertIn('or state=="active" and theme.soft or COLOR.muted', journal)
        self.assertIn('local function update_reader(player,preserve_reader)', journal)

    def test_system_status_accents_follow_source_data(self):
        systems = source("scripts/razi_journal_systems.lua")
        self.assertIn('name=id.."_accent"', systems)
        self.assertIn('accent.style.color=ws.active and COLOR.red', systems)
        self.assertIn('or ws.warning and COLOR.amber or COLOR.teal', systems)
        self.assertIn('vertical_scroll_policy="auto"', systems)

if __name__ == "__main__":
    unittest.main()
