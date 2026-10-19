"""Source-level contracts for the A.4 Journal logistics command.

These checks supplement, but do not replace, the Lua/Factorio GUI tests.
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class LogisticsCommandContract(unittest.TestCase):
    def test_five_sections_have_distinct_content_paths(self):
        source = read("scripts/galactic_trade.lua")
        for tab in ("overview", "routes", "supply", "freight", "industry"):
            self.assertIn(f'"{tab}"', source)
        self.assertIn("function M.render_industry(", source)
        self.assertIn("return command.routes(parent,player,width)", source)
        self.assertIn("return command.freight(parent,player,width)", source)
        self.assertIn("return supply.render(parent,player,p,width)", source)
        self.assertIn("return command.overview(parent,player,width,", source)
        self.assertNotIn("catapult_dossier(scroll,player", source)

    def test_navigation_and_scroll_are_independent(self):
        journal = read("scripts/razi_journal.lua")
        project = read("scripts/razi_journal_projects.lua")
        self.assertIn('native=="logistics-tab"', journal)
        self.assertIn('native=="logistics-route"', journal)
        self.assertIn('freight_orders.select(player,tags.value)', journal)
        self.assertIn('p.logistics_scrolls[key]=position', journal)
        self.assertIn("restore_scrolls(frame,saved_scrolls", journal)
        self.assertIn('razi_scroll_context="cargo:"..(p.logistics_tab or "overview")', project)
        self.assertIn('p.logistics_tab="industry"', journal)
        self.assertIn('p.logistics_tab="freight"', journal)
        self.assertIn('p.logistics_scrolls["razi_journal_project_reader|cargo:freight"]=0',
                      journal)

    def test_freight_reader_does_not_repeat_slow_evidence(self):
        board = read("scripts/razi_freight_dispatch_ui.lua")
        command = read("scripts/razi_logistics_command.lua")
        self.assertIn("board.render(parent,player,network,width,{clean=true})",
                      command)
        self.assertIn("if not options.clean then", board)
        self.assertIn("not options.clean and\n    infrastructure.snapshot",
                      board)
        self.assertIn("not options.clean and\n    pod_receipts.snapshot", board)
        self.assertNotIn("on_nth_tick", command)
        self.assertNotIn("remote.call", command)

    def test_new_locale_keys_are_translated(self):
        source = read("scripts/razi_logistics_command.lua")
        source += read("scripts/galactic_trade.lua")
        locale = read("locale/en/razi_freight_readiness.cfg")
        present = {
            key for key in re.findall(r"^([\w-]+)=", locale, re.MULTILINE)
        }
        keys = set(re.findall(r'L\("(logistics-[\w-]+)"', source))
        self.assertTrue(keys - {"logistics-tab-"}, "Must use localized command UI")
        missing = keys - present - {"logistics-tab-"}
        self.assertEqual(set(), missing, f"Missing A.4 locale: {sorted(missing)}")


if __name__ == "__main__":
    unittest.main()
