"""Mission Plan: only native/source-backed goals and real prerequisite steps."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

class MissionPlanContracts(unittest.TestCase):
    def test_source_uses_real_research_and_campaign_state(self):
        src=(ROOT/"scripts/razi_journal_objectives.lua").read_text()
        for fragment in (
            "for _,id in ipairs(quest.requires or {})",
            "for _,tech in ipairs(sorted_prerequisites(technology))",
            "tech.researched",
            'kind~="goal"',
            'quest.convergence=="victory"',
            'kind=quest.boss and "boss"',
            "current.name==technology.name",
            "options.research_progress",
            "function M.visible_rows(plan,expanded,limit)",
            "row~=plan.next_step",
        ):
            self.assertIn(fragment,src)
        for risky in ("game.surfaces", "find_entities_filtered",
                      "force.technologies[", "script.on_tick", "storage.",
                      "remote.call"):
            self.assertNotIn(risky,src)

    def test_journal_dossier_uses_plan_with_safe_links(self):
        src=(ROOT/"scripts/razi_journal.lua").read_text()
        self.assertIn('require("scripts.razi_journal_objectives")',src)
        self.assertIn("objectives.snapshot(",src)
        self.assertIn("objectives.visible_rows(",src)
        self.assertIn("local goal_expanded=p.goal_expanded and p.goal_expanded_quest==quest.id",src)
        self.assertIn('tags={razi_journal_action="guidance-select",id=step.link}',src)
        self.assertIn('action=="mission-details"',src)
        self.assertIn("value.goal_expanded=value.goal_expanded==true",src)
        self.assertIn('razi_journal_action="guidance-select"',src)
        self.assertIn('restore_scrolls(reader,saved,false)',src)
        self.assertIn('section(prose,"story-heading"',src)

    def test_live_research_updates_only_named_gui_elements(self):
        journal=(ROOT/"scripts/razi_journal.lua").read_text()
        control=(ROOT/"control.lua").read_text()
        self.assertIn("function M.refresh_research_visible()",journal)
        self.assertIn('name="razi_journal_research_row"',journal)
        self.assertIn('name="razi_journal_research_progress"',journal)
        self.assertIn('name="razi_journal_research_percent"',journal)
        self.assertIn('strip.visible=active==true',journal)
        self.assertIn('if bar then bar.value=value end',journal)
        self.assertIn("razi_journal.refresh_research_visible()",control)
        updater=journal.split("function M.refresh_research_visible()",1)[1].split(
            "function M.refresh_systems_visible()",1)[0]
        self.assertNotIn("draw(player)",updater)
        self.assertNotIn("frame.clear()",updater)
        self.assertNotIn("find_entities_filtered",updater)

    def test_project_verifications_are_real_evidence_not_guide_numbers(self):
        projects=(ROOT/"scripts/razi_journal_projects.lua").read_text()
        for marker in ('facts.platform==true','facts.voyage==true',
                       'tech and tech.researched==true',
                       'project-verified-heading','project-advisory-heading'):
            self.assertIn(marker,projects)
        self.assertIn('name="razi_journal_mission_plan"',(ROOT/"scripts/razi_journal.lua").read_text())

    def test_locale(self):
        src=(ROOT/"locale/en/razi_journal_interface.cfg").read_text()
        for key in ("mission-plan","mission-finish-line","mission-step-research",
                    "mission-step-campaign","mission-step-boss",
                    "mission-step-delivery","mission-step-transmission",
                    "mission-step-discovery","mission-next","mission-complete",
                    "mission-disabled","mission-stage-count",
                    "mission-research-progress","mission-expand","mission-collapse",
                    "mission-goal-status-done","mission-goal-status-open",
                    "tracker-next","project-verified-heading",
                    "project-verified-platform-built",
                    "project-verified-voyage-crossing"):
            self.assertIn(key+"=",src)

if __name__=="__main__":
    unittest.main()
