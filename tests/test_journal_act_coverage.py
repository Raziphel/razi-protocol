"""Every journal mission must have exactly one authored act, in every chapter."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class AllJournalActs(unittest.TestCase):
    def test_every_catalog_mission_has_exactly_one_authored_act(self):
        catalog="\n".join(read(path) for path in (
            "scripts/razi_journal_data.lua",
            "scripts/razi_journal_expansion.lua",
            "scripts/razi_journal_industry.lua",
            "scripts/razi_journal_fluxworks.lua",
            "scripts/razi_journal_frontier.lua"))
        missions=re.findall(r'\{id="([^"]+)"\s*,\s*chapter="([^"]+)"',catalog)
        source=read("scripts/razi_journal_acts.lua")
        assigned={}
        for chapter,group in re.findall(
                r'(?ms)^  \["([^"]+)"\]=\{(.*?)^  \},',source):
            for members in re.findall(r'missions=\{([^}]+)\}',group):
                for mission in re.findall(r'"([^"]+)"',members):
                    self.assertNotIn(mission,assigned,mission)
                    assigned[mission]=chapter
        self.assertEqual(dict(missions),assigned)
        self.assertEqual(19,len(set(assigned.values())))
        self.assertEqual(256,len(assigned))

    def test_every_chapter_uses_same_timing_and_section_renderer(self):
        ui=read("scripts/razi_journal.lua")
        clock=read("scripts/razi_chapter_timing.lua")
        locale=read("locale/en/razi_journal_interface.cfg")
        self.assertIn('chapter_act(entries,act,theme,inner-34,player.force)',ui)
        self.assertIn('chapter_act(body,act,theme,text_width,player.force)',ui)
        self.assertIn('matching_acts[act.key]=true',ui)
        self.assertIn('stamp.visible=caption~=nil',ui)
        self.assertIn('local act_id=act_for and act_for(quest) or quest.phase',clock)
        self.assertIn(
            'if state.required>0 then return state.done_required==state.required end',
            clock)
        self.assertIn('[journal-act-title]',locale)
        self.assertNotIn('chapter.id=="calidus" and quest.phase',ui)

if __name__=="__main__":
    unittest.main()
