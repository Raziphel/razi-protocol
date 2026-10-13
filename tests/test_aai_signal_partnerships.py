"""Guard native AAI logistics integration without copying its transport."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def text(path):
    return (ROOT/path).read_text(encoding="utf8")

class AAIIntegrationTests(unittest.TestCase):
    def test_real_source_not_duplicated(self):
        source=text("prototypes/compat/aai_signal_partnerships.lua")
        self.assertIn('mods["aai-signal-transmission"]',source)
        self.assertIn('mode.enabled()',source)
        self.assertIn('M.source_technology(technologies)',source)
        self.assertIn('not reaches(technologies,source,name)',source)
        self.assertIn('not reaches(technologies,name,source)',source)
        for banned in ("data:extend","remote.call","script.on_nth_tick",
                       "script.on_event","player.force.research_all"):
            self.assertNotIn(banned,source)

    def test_tech_link_after_source_research_registration(self):
        final=text("data-final-fixes.lua")
        self.assertIn('require("prototypes.compat.aai_signal_partnerships").data_final_fixes()',final)
        self.assertLess(final.index('require("prototypes.technology.research_tree_polish").data_final_fixes()'),
                        final.index('require("prototypes.compat.aai_signal_partnerships").data_final_fixes()'))
        self.assertLess(final.index('require("prototypes.compat.aai_signal_partnerships").data_final_fixes()'),
                        final.index('require("prototypes.technology.planetary_science_weave").data_final_fixes()'))

    def test_feature_is_optional_and_displayed_in_cargo(self):
        metadata=text("info.json")
        self.assertIn('? aai-signal-transmission >= 0.6.0',metadata)
        pane=text("scripts/galactic_trade.lua")
        self.assertIn('signals.source_technology(prototypes.technology)',pane)
        self.assertIn('trade-signal-guide',pane)
        self.assertNotIn("platform.schedule=",pane)
        locale=text("locale/en/galactic_operations.cfg")
        self.assertIn("trade-signal-guide=",locale)
        self.assertIn("trade-signal-heading=",locale)
        journal=text("scripts/razi_journal_data.lua")
        self.assertIn('id="signal-network"',journal)
        story=text("locale/en/razi_journal.cfg")
        for section in ("journal-title","journal-story","journal-tip"):
            block=story.split("["+section+"]",1)[1].split("\n[",1)[0]
            self.assertIn("signal-network=",block)

if __name__=="__main__":
    unittest.main()
