"""The journal should read as a field dossier, without UI-only milestones."""
from pathlib import Path
import unittest
from tools.journal_locale import load_journal_locale

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class VisualPolishTests(unittest.TestCase):
    def test_folio_navigation_and_quiet_counters(self):
        journal=read("scripts/razi_journal.lua")
        self.assertIn('for _,view in ipairs({"quests","projects","archive","systems"})',journal)
        self.assertIn('style="clickable_label"',journal)
        self.assertIn('local folio=toolbar.add{type="flow",direction="vertical"}',
                      journal)
        self.assertIn('accent_rule(folio,window_theme,76,2)',journal)
        self.assertIn('local totals=frame.add{type="flow",direction="vertical"}',
                      journal)
        self.assertNotIn('local totals=frame.add{type="frame"',journal)
        self.assertIn('body.style.width=size.width-33',journal)
        self.assertIn('hero_title.style.font_color=COLOR.ink',journal)

    def test_chapters_use_an_index_instead_of_repeating_cards(self):
        journal=read("scripts/razi_journal.lua")
        self.assertIn('type=open and "frame" or "flow"',journal)
        self.assertIn('card.style.padding=open and 8 or 3',journal)
        self.assertIn('accent_rule(card,theme,math.min(82,inner-40),2)',journal)
        self.assertIn('name="razi_journal_search"',journal)
        self.assertIn('name="razi_journal_chapter_picker"',journal)
        self.assertIn('razi_journal_action="guidance-select"',journal)
        self.assertIn('razi_journal_action="select"',journal)

    def test_editorial_quest_dossier_and_actual_readiness(self):
        journal=read("scripts/razi_journal.lua")
        loc=load_journal_locale(ROOT)
        self.assertIn('local function dossier_heading(parent,key,theme,width)',journal)
        self.assertIn('dossier_heading(readiness,"dossier-readiness",theme,text_width)',journal)
        self.assertIn('if prior and M.available(player.force,prior,context)',journal)
        self.assertIn('if M.complete(player.force,prior,context) then',journal)
        self.assertIn('value=met/required_total',journal)
        self.assertIn('tags={razi_journal_action="guidance-select",id=prior.id}',journal)
        self.assertIn('style=chosen and "inside_shallow_frame" or nil',journal)
        self.assertIn('razi_journal_action="filter-ready"',journal)
        self.assertIn('elseif action=="filter-ready" then',journal)
        self.assertNotIn('local convergence=require("scripts.razi_convergence")\n'
                         'local projects=require("scripts.razi_journal_projects")\n'
                         'local convergence=require("scripts.razi_convergence")',journal)
        for key in ("dossier-index","dossier-classification",
                    "dossier-readiness","dossier-prerequisites",
                    "open-prerequisite","filter-ready-tooltip"):
            self.assertRegex(loc,rf"(?m)^{key}=")

    def test_chapter_briefings_use_real_existing_milestones(self):
        ui=read("scripts/razi_journal.lua")
        locale=load_journal_locale(ROOT)
        self.assertIn('local function render_chapter_cover(',ui)
        self.assertIn('wheel_pane(panel,"razi_journal_chapter_reading"',ui)
        self.assertIn('journal-chapter-dispatch."..p.chapter',ui)
        self.assertIn('razi_journal_action="chapter-dossier"',ui)
        self.assertIn('razi_journal_action="chapter-continue"',ui)
        self.assertIn('chapter_cover=false',ui)
        self.assertIn('p.chapter_cover=true',ui)
        self.assertIn('if shown>=8 then break end',ui)
        self.assertIn('if view.states[quest.id]=="active"',ui)
        self.assertNotIn('rendering.draw',ui)
        self.assertNotIn('on_tick',ui)
        for key in ("chapter-cover-open","chapter-cover-eyebrow",
                    "chapter-cover-dispatch","chapter-cover-entries",
                    "chapter-cover-continue","chapter-cover-review"):
            self.assertRegex(locale,rf"(?m)^{key}=")
        chapters=read("scripts/razi_journal_themes.lua")
        for name in ("calidus","solaris","nyxaris","vibrant","vespera",
                     "beetlejuice","umbra","stellar","network","alliances",
                     "finale","foundations","fleet","outposts",
                     "sciences","defense","deepworks","echoes"):
            self.assertRegex(locale,rf"(?m)^{name}=")
        self.assertIn("[journal-chapter-dispatch]",locale)

    def test_nauvis_acts_use_existing_research(self):
        core=read("scripts/razi_journal_data.lua")
        foundation=read("scripts/razi_journal_expansion.lua")
        ui=read("scripts/razi_journal.lua")
        locale=load_journal_locale(ROOT)
        ids=("nauvis-power","nauvis-logistics","nauvis-electronics",
             "nauvis-radar","nauvis-fast-inserters","nauvis-automation-2",
             "nauvis-engines","nauvis-fluid-handling","nauvis-plastics",
             "nauvis-advanced-electronics")
        for quest in ids:
            self.assertIn('id="'+quest+'",chapter="calidus"',core)
            for section in ("journal-title","journal-story","journal-tip"):
                entries=locale.split("["+section+"]",1)[1].split("\n[",1)[0]
                self.assertIn("\n"+quest+"=",entries)
        for legacy in ("green-science","steel","railways","oil",
                       "chemical-science"):
            self.assertIn('id="'+legacy+'",chapter="calidus"',core)
            self.assertNotIn('id="'+legacy+'",chapter="foundations"',foundation)
        for phase in ("machines","growth","chemistry","departure"):
            self.assertIn('phase="'+phase+'"',core)
            self.assertIn(phase+"=",locale)
        self.assertIn('nauvis_phase(card,quest.phase,theme,inner-34)',ui)
        self.assertIn('nauvis_phase(body,quest.phase,theme,text_width)',ui)
        self.assertNotIn("data:extend(",core)

    def test_megaproject_dossiers_use_real_status(self):
        projects=read("scripts/razi_journal_projects.lua")
        icons=read("scripts/razi_journal_icons.lua")
        locale=load_journal_locale(ROOT)
        self.assertIn('local ids={"platform","voyage","skybridge","beltbreaker","dyson","array","transceiver","nexus-trials","ark","convergence"}',
                      projects)
        self.assertIn('icons.button(head,art_for(id,player.force,statuses),"project_button"',
                      projects)
        self.assertIn('project_icon=32',icons)
        self.assertIn('local meter=card.add{type="progressbar"',projects)
        self.assertIn('statuses[id]={status_for(player.force,id,ships)}',projects)
        self.assertIn('style=selected and "inside_shallow_frame" or nil',projects)
        self.assertIn('local current=statuses[p.project]',projects)
        self.assertIn('convergence.progress(force)',projects)
        self.assertIn('platform_projects.snapshot(force)',projects)
        self.assertIn('dyson.status(force)',projects)
        self.assertIn('options={embedded=true,width=width-68}',projects)
        self.assertIn('scroll.horizontal_scroll_policy="never"',projects)
        self.assertNotIn('on_tick',projects)
        self.assertNotIn('create_surface(',projects)
        for key in ("projects-heading","project-dossier","project-progress",
                    "project-caption-dyson","project-caption-platform",
                    "project-caption-voyage","project-caption-skybridge",
                    "project-caption-beltbreaker","project-caption-array",
                    "project-caption-ark","project-caption-nexus-trials",
                    "project-caption-transceiver",
                    "project-caption-convergence"):
            self.assertRegex(locale,rf"(?m)^{key}=")
if __name__=="__main__":
    unittest.main()
