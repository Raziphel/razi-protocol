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
        self.assertIn('action=="mission-details"',src)
        self.assertIn("value.goal_expanded=value.goal_expanded==true",src)
        self.assertIn('razi_journal_action="guidance-select"',src)
        self.assertIn('restore_scrolls(reader,saved,false)',src)
        self.assertIn('section(prose,"story-heading"',src)

    def test_locale(self):
        src=(ROOT/"locale/en/razi_journal_interface.cfg").read_text()
        for key in ("mission-plan","mission-step-research",
                    "mission-step-campaign","mission-step-boss",
                    "mission-step-delivery","mission-step-transmission",
                    "mission-step-discovery","mission-next","mission-complete",
                    "mission-disabled","mission-stage-count",
                    "mission-research-progress","mission-expand","mission-collapse",
                    "mission-goal-status-done","mission-goal-status-open"):
            self.assertIn(key+"=",src)

if __name__=="__main__":
    unittest.main()
