"""Regressions: source-backed Systems folio and no duplicated gameplay state."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def load(path):
    return (ROOT/path).read_text(encoding="utf-8")

class SystemsFolio(unittest.TestCase):
    def test_tab_and_refresh_cadence(self):
        journal=load("scripts/razi_journal.lua")
        control=load("control.lua")
        self.assertIn('{"quests","projects","archive","systems"}',journal)
        self.assertIn('systems.render(body,player,size)',journal)
        self.assertIn('razi_journal_systems_reading=true',journal)
        self.assertIn('razi_journal_systems_body',journal)
        self.assertIn('function M.refresh_systems_visible()',journal)
        self.assertIn('events:on_nth_tick(120, function()\n  razi_journal.refresh_systems_visible()',control)

    def test_read_only_source_snapshots(self):
        lua=load("scripts/razi_journal_systems.lua")
        for signature in ('planet-express-monitor-dock-btn','planet-express.monitor-dock-summary',
                          'zero-point-energy-engine-core','zpe-core-limit-',
                          'pcall(remote.call,"nexus-threat","get_state")',
                          'function M.refresh_root(root,player)'):
            self.assertIn(signature,lua)
        for forbidden in ('game.surfaces','find_entities_filtered','remote.call("nexus-threat","set_storm_multiplier"',
                          'script.on_tick','force.technologies["zpe-core-limit-1"].researched=true'):
            self.assertNotIn(forbidden,lua)

    def test_responsive_telemetry_layout(self):
        lua=load("scripts/razi_journal_systems.lua")
        self.assertIn('name="razi_sys_summary_row"',lua)
        self.assertIn('local tile_width=compact and width',lua)
        self.assertIn('local top=root["razi_sys_summary_row"]',lua)
        self.assertIn('local storm=card(scroll',lua)
        self.assertIn('M.refresh_root(scroll,player)',lua)

    def test_locale(self):
        text=load("locale/en/razi_journal_systems.cfg")
        for k in ("view-systems","fleet-counts","zpe-count","storm-active",
                  "storm-warning","storm-calm","storm-unavailable"):
            self.assertIn(k+"=",text)

if __name__=="__main__":
    unittest.main()
