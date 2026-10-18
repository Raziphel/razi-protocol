"""Spoiler visibility must be reversible and never silently change source mods."""
from pathlib import Path
import unittest
from tools.journal_locale import validate

ROOT=Path(__file__).resolve().parents[1]
def file(path):
    return (ROOT/path).read_text(encoding="utf-8")

class SpoilerSettingsTests(unittest.TestCase):
    def test_single_shared_setting_defaults_to_on(self):
        source=file("settings.lua")
        self.assertIn('name="razi-hide-spoilers"',source)
        start=source.index('name="razi-hide-spoilers"')
        option=source[start:start+180]
        self.assertIn('setting_type="runtime-global"',option)
        self.assertIn("default_value=true",option)
        names=file("locale/en/settings.cfg")
        self.assertIn("razi-hide-spoilers=",names)
        self.assertIn("[mod-setting-description]",names)

    def test_tech_fog_is_reversible_and_source_tech_safe(self):
        code=file("scripts/razi_spoiler_fog.lua")
        self.assertIn('technology.name:sub(1,5)=="razi-"',code)
        self.assertIn('M.external_setting="razi-hide-other-tech-spoilers"',code)
        self.assertIn('return M.enabled() and value(M.external_setting)',code)
        self.assertIn("managed[name]={",code)
        self.assertIn("technology.visible_when_disabled=false",code)
        self.assertIn("technology.enabled=false",code)
        self.assertIn("technology.enabled=true",code)
        self.assertIn("technology.visible_when_disabled=previous.visible",code)
        self.assertIn("function M.on_research(event)",code)
        self.assertIn("function M.sync_force(force)",code)
        self.assertNotIn("on_nth_tick",code)
        self.assertNotIn("research_recursive",code)
        self.assertNotIn("technology.researched=true",code)

    def test_journal_filters_navigation_and_archive_titles(self):
        source=file("scripts/razi_journal.lua")
        for term in ('function M.journal_visible(force,quest,context,known_state)',
                     "view.states[quest.id]=revealed and state or",
                     'L("spoiler-unknown-chapter")',
                     'L("spoiler-sealed-record")',
                     'function M.refresh_open()'):
            self.assertIn(term,source)
        self.assertIn('M.journal_visible(player.force,quest)',source)
        ui=file("locale/en/razi_journal_interface.cfg")
        self.assertIn("spoiler-unknown-chapter=",ui)
        self.assertIn("spoiler-sealed-record=",ui)

    def test_future_projects_are_revealed_only_at_real_milestones(self):
        projects=file("scripts/razi_journal_projects.lua")
        self.assertIn("function M.visible(force,id)",projects)
        self.assertIn('convergence="razi-convergence-commission"',projects)
        self.assertIn('cargo="interplanetary-trade-logistics"',projects)
        self.assertIn("if not M.visible(player.force,p.project)",projects)
        self.assertIn('L("project-spoiler-locked")',projects)
        self.assertIn("for _,id in ipairs(displayed) do",projects)
        journal=file("scripts/razi_journal.lua")
        self.assertIn('projects.visible(player.force,tags.id)',journal)
        self.assertIn('projects.visible(player.force,id)',journal)

    def test_event_driven_toggle_without_auto_scans(self):
        controls=file("control.lua")
        self.assertIn("spoiler_fog.sync_all()",controls)
        self.assertIn("spoiler_fog.on_research(event)",controls)
        self.assertIn('event.setting=="razi-hide-spoilers"',controls)
        self.assertIn("razi_journal.refresh_open()",controls)
        self.assertIn("spoiler_fog.on_forces_merged(event)",controls)

    def test_translations_and_manual_check_workflow(self):
        count,issues=validate(ROOT)
        self.assertGreater(count,0)
        self.assertEqual(issues,[])
        workflow=file(".github/workflows/check.yml")
        self.assertIn("test_razi_spoiler_fog.lua",workflow)
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotIn("  push:",workflow)

if __name__=="__main__":
    unittest.main()
