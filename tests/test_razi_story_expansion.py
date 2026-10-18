"""RAZI Protocol 3.0 witness archives, Journal navigation, and welcome continuity."""
from pathlib import Path
import re
import unittest
from scripts.audit_campaign_consistency import inspect
from tools.journal_locale import validate

ROOT=Path(__file__).resolve().parents[1]
def read(file):
    return (ROOT/file).read_text(encoding="utf-8")
def section(text, name):
    match=re.search(r"^\["+re.escape(name)+r"\]\n(.*?)(?=^\[|\Z)",
                    text, re.M|re.S)
    return dict(re.findall(r"^([a-z0-9-]+)=(.*)$",
                           match.group(1),re.M)) if match else {}

NEW_WITNESSES={
    "corp-blackout-audit":"nauvis-power",
    "corp-circuit-witness":"nauvis-advanced-electronics",
    "corp-arig-reservoir":"arig",
    "corp-hyarion-crew":"hyarion",
    "corp-apia-flight":"apia",
    "corp-ribbonia-seam":"ribbonia",
    "corp-seadragon-watch":"seadragon",
    "corp-abacayba-signal":"abacayba",
    "corp-crucible-valve":"crucible",
    "corp-vesta-compass":"vesta",
    "corp-first-relay":"first-frontier-relay",
    "corp-solar-orbit-watch":"solar-orbit",
    "corp-lattice-accord":"extreme-lattice",
    "corp-frozeta-temperature":"frozeta",
    "corp-test-fire-correction":"test-fire",
    "corp-panglia-model":"panglia-sentient",
}
class WitnessContinuityTests(unittest.TestCase):
    def test_archive_milestones_and_unmodified_victory(self):
        report=inspect(ROOT)
        self.assertEqual(report["record_count"],74)
        for key in ("duplicate_record_ids","record_unlocks_without_quests",
                    "locale_errors"):
            self.assertEqual(report[key],[],key)
        records=read("scripts/razi_journal_corporate.lua")
        for name,quest in NEW_WITNESSES.items():
            self.assertIn(
                f'{{id="{name}",unlock="{quest}",series="field"}}',
                records)
        self.assertEqual(
            len(re.findall(r'series="field"',records)),34)
        self.assertLess(records.index('id="corp-test-fire-correction"'),
                        records.index('id="corp-epilogue"'))
        self.assertIn(
            '{id="corp-epilogue",unlock="convergence-victory"}',
            records)

    def test_all_new_letters_complete_and_personal(self):
        locale=read("locale/en/razi_journal_corporate.cfg")
        titles=section(locale,"journal-record-title")
        origins=section(locale,"journal-record-origin")
        bodies=section(locale,"journal-record-body")
        for key in NEW_WITNESSES:
            self.assertTrue(titles.get(key),key)
            self.assertTrue(origins.get(key),key)
            self.assertGreater(len(bodies.get(key,"")),170,key)
            self.assertNotIn("\n",bodies[key])
        joined=" ".join(bodies[key] for key in NEW_WITNESSES)
        for recurrent in ("Rhea Calder","Noor Halden","headquarters"):
            self.assertIn(recurrent,joined)
        _,errors=validate(ROOT)
        self.assertEqual(errors,[])

    def test_archive_filters_are_safe_and_persistently_validated(self):
        journal=read("scripts/razi_journal.lua")
        for word in ('value.archive_filter=','"archive-filter-"..category',
                     'p.archive_filter==category',
                     'action=="archive-filter"',
                     'p.archive_filter=tags.id',
                     'L("archive-ledger-"..category',
                     'tags={razi_journal_action="archive-source"',
                     'action=="archive-source"',
                     'M.complete(player.force,quest)'):
            self.assertIn(word,journal,word)
        self.assertIn('and (opened or not M.hide_spoilers())',journal)
        ui=section(read("locale/en/razi_journal_interface.cfg"),"journal-ui")
        for key in ("archive-ledger-legacy","archive-ledger-corporate",
                    "archive-ledger-field",
                    "archive-filter-all","archive-filter-legacy",
                    "archive-filter-corporate","archive-filter-field",
                    "archive-open-source","archive-source-tooltip"):
            self.assertIn(key,ui,key)

    def test_field_stories_and_welcome_follow_real_progress(self):
        stories=section(read("locale/en/razi_journal_stories.cfg"),
                        "journal-story")
        for name in ("nauvis-power","hyarion","apia","ribbonia",
                     "seadragon","frozeta","precision-matrix",
                     "stable-singularity","convergence-victory"):
            self.assertGreater(len(stories[name]),150)
        welcome=read("scripts/razi_welcome.lua")
        self.assertIn("function M.priority(player)",welcome)
        self.assertIn("function M.spoiler_status()",welcome)
        self.assertIn('setting.value==false',welcome)
        self.assertIn('tostring(unread_count(player.index))',welcome)
        self.assertIn('M.priority(player)',welcome)
        self.assertNotIn("script.on_nth_tick",welcome)
        rich=section(read("locale/en/razi_welcome.cfg"),"razi-welcome")
        for suffix in ("initial","local","flight","network","commission"):
            self.assertIn("priority-"+suffix,rich)
            self.assertNotIn("Shattered Planet",rich["priority-"+suffix])
        for key in ("spoilers-on","spoilers-off"):
            self.assertIn(key,rich)
        self.assertIn("https://wiki.razisrealm.com",rich["links"])
        self.assertIn("https://razisrealm.com/discord",rich["links"])

if __name__=="__main__":
    unittest.main()
