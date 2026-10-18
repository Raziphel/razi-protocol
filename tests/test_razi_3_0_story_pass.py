"""RAZI 3.0 story/ending consistency and notification integration contracts."""
import re
import unittest
from pathlib import Path
from scripts.audit_campaign_consistency import inspect
from tools.journal_locale import validate

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def section(text,title):
    match=re.search(r"^\["+re.escape(title)+r"\]\n(.*?)(?=^\[|\Z)",
                    text,re.M|re.S)
    if not match: return {}
    return dict(re.findall(r"^([a-z0-9-]+)=(.*)$",match.group(1),re.M))

class NarrativePassTests(unittest.TestCase):
    def test_quest_gating_preserves_all_existing_ids(self):
        analysis=inspect(ROOT)
        self.assertEqual(analysis["record_count"],40)
        self.assertEqual(analysis["duplicate_record_ids"],[])
        self.assertEqual(analysis["record_unlocks_without_quests"],[])
        self.assertEqual(analysis["locale_errors"],[])
        records=read("scripts/razi_journal_corporate.lua")
        names=re.findall(r'\{id="(corp-[a-z0-9-]+)",unlock="([a-z0-9-]+)"',records)
        self.assertEqual(len(names),25)
        self.assertEqual(len(set(a for a,b in names)),25)

    def test_five_physical_shipments_plus_true_victory_epilogue(self):
        content=read("scripts/razi_journal_corporate.lua")
        for record,quest in (
            ("corp-shipment-stellar","convergence-stellar"),
            ("corp-shipment-industry","convergence-industry"),
            ("corp-shipment-deep","convergence-deep-space"),
            ("corp-shipment-resonance","convergence-resonance"),
            ("corp-shipment-ignition","convergence-ignition"),
            ("corp-epilogue","convergence-victory"),
        ):
            self.assertIn(f'id="{record}",unlock="{quest}"',content)
        finish=read("scripts/razi_convergence.lua")
        self.assertIn('story_dispatch.shipment(force,"victory")',finish)
        self.assertIn('saved.victory=true',finish)
        self.assertIn('game.set_game_state{game_finished=true,player_won=true,',finish)
        self.assertIn('can_continue=true',finish)
        self.assertIn('story_dispatch.shipment(force,id)',finish)

    def test_corporate_locale_has_every_record_in_three_sections(self):
        src=read("locale/en/razi_journal_corporate.cfg")
        ids=re.findall(r'\{id="(corp-[a-z0-9-]+)",unlock=',read(
            "scripts/razi_journal_corporate.lua"))
        for title in ("journal-record-title","journal-record-origin",
                      "journal-record-body"):
            keys=section(src,title)
            self.assertTrue(all(record in keys for record in ids))
            self.assertEqual(len([k for k in keys if k.startswith("corp-")]),25)
            self.assertTrue(all(keys[k].strip() for k in ids))
        count,issues=validate(ROOT)
        self.assertGreater(count,0)
        self.assertEqual(issues,[])

    def test_archive_notifications_are_per_player_and_throttled(self):
        dispatch=read("scripts/razi_story_dispatch.lua")
        journal=read("scripts/razi_journal.lua")
        control=read("control.lua")
        for phrase in ("state.last_tick",">=120","story_alerts~=false",
                       "p.story_unread[id]=true","function M.forces_merged"):
            self.assertIn(phrase,dispatch)
        self.assertIn("razi_story_pending",dispatch)
        self.assertIn('tags={razi_journal_action="story-alerts"}',journal)
        self.assertIn('p.story_unread[record.id]=nil',journal)
        self.assertIn('story_dispatch.on_research(event)',control)
        self.assertIn('story_dispatch.flush()',control)
        self.assertIn('story_dispatch.forces_merged(event)',control)
        self.assertNotIn('script.on_nth_tick',dispatch)

    def test_finale_words_are_consistent_with_physical_proof(self):
        operations=section(read("locale/en/galactic_operations.cfg"),"razi-ops")
        self.assertIn("Continuity Engine",operations["convergence-victory-message"])
        self.assertIn("keep",operations["convergence-victory-final"].lower())
        self.assertIn("cargo",read("locale/en/razi_journal_stories.cfg").lower())
        self.assertIn("actual victory",read("docs/STORY_BIBLE.md").lower())

if __name__=="__main__":
    unittest.main()
