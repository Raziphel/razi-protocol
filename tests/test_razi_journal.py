"""Guard the native Razi Expedition Journal against duplicate and brittle quests."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf8")
def ids(section):
    return {p.strip().split("=",1)[0] for p in section.splitlines() if "=" in p}

class ExpeditionJournalTests(unittest.TestCase):
    def test_quest_catalog_and_locale(self):
        source=read("scripts/razi_journal_data.lua")
        expanded=read("scripts/razi_journal_expansion.lua")
        quests=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",tech="([^"]+)"',source)
        extended=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",(?:tech|world)="([^"]+)"',expanded)
        quests+=extended
        self.assertEqual(len(quests),157)
        self.assertEqual(len({item[0] for item in quests}),157)
        chapter_sources=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',source)
        chapter_sources+=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',expanded)
        self.assertEqual(len(chapter_sources),17)
        language=read("locale/en/razi_journal.cfg")
        sections={}
        for block in re.split(r'(?m)^\[([^\]]+)\]\s*',language)[1:][::2]:
            self.assertTrue(block)
        parsed=re.split(r'(?m)^\[([^\]]+)\]\s*',language)
        for i in range(1,len(parsed),2):
            sections[parsed[i]]=ids(parsed[i+1])
        for ch in chapter_sources:
            self.assertIn(ch,sections["journal-chapter"])
            self.assertIn(ch,sections["journal-chapter-story"])
        for quest,chapter,_ in quests:
            self.assertIn(chapter,chapter_sources)
            for section in ("journal-title","journal-story","journal-tip"):
                self.assertIn(quest,sections[section])
    def test_archived_transmissions_are_source_research_gated(self):
        records=read("scripts/razi_journal_records.lua")
        all_records=re.findall(r'\{id="([^"]+)",unlock="([^"]+)"',records)
        self.assertEqual(len(all_records),12)
        self.assertEqual(len(set(x[0] for x in all_records)),12)
        locale=read("locale/en/razi_journal.cfg")
        sections={}
        parsed=re.split(r'(?m)^\[([^\]]+)\]\s*',locale)
        for i in range(1,len(parsed),2):
            sections[parsed[i]]=ids(parsed[i+1])
        for rec,_ in all_records:
            for section in ("journal-record-title","journal-record-origin",
                            "journal-record-body"):
                self.assertIn(rec,sections[section])
    def test_only_authoritative_research_progress(self):
        source=read("scripts/razi_journal.lua")
        self.assertIn("force.technologies[quest.tech]",source)
        self.assertIn('M.state(force,quest,context)',source)
        self.assertIn('M.discovery_index(force)',source)
        self.assertIn('effect.type=="unlock-space-location"',source)
        self.assertIn('M.unlocked_records(force,context)',source)
        self.assertIn('razi_journal_action="chapter"',source)
        self.assertIn('razi_journal_action="view"',source)
        self.assertIn('razi_journal_action="next"',source)
        self.assertIn('p.chapter==tags.id and false or tags.id',source)
        self.assertIn('function M.next_quest(force)',source)
        self.assertIn('function M.on_research(event)',source)
        self.assertNotIn("script.on_nth_tick",source)
        self.assertNotIn("surface.create_entity",source)
        self.assertNotIn("force.technologies[quest.tech].researched=",source)
        self.assertNotIn("player.insert(",source)
    def test_visible_during_normal_play_not_shortcut_bar(self):
        control=read("control.lua")
        ui=read("scripts/razi_journal.lua")
        self.assertIn('script.on_event("razi-journal-toggle"',control)
        self.assertIn("razi_journal.gui_click(event)",control)
        self.assertIn("razi_journal.on_research",control)
        self.assertIn("player.gui.top.add",ui)
        self.assertIn('type="progressbar"',ui)
        self.assertIn('chapter_intro.style.font_color=',ui)
        self.assertIn('native.prerequisites or {}',ui)
        self.assertIn("player.gui.left",ui)
        self.assertIn("player.gui.screen",ui)
        self.assertNotIn('type="shortcut"',read("prototypes/ui/razi_journal.lua"))
        self.assertIn('require("prototypes.ui.razi_journal")',read("data.lua"))
    def test_no_new_research_or_dependency(self):
        data=read("scripts/razi_journal_data.lua")
        self.assertNotIn('type="technology"',data)
        self.assertNotIn('data:extend',data)
        self.assertNotIn('data:extend',read("scripts/razi_journal_expansion.lua"))
        self.assertNotIn('data:extend',read("scripts/razi_journal_records.lua"))
        manifest=read("info.json")
        self.assertNotIn('"quest-book"',manifest)
if __name__=="__main__":
    unittest.main()
