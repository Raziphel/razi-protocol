"""Guard the native Razi Expedition Journal against duplicate and brittle quests."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf8")
def ids(section):
    return {p.strip().split("=",1)[0] for p in section.splitlines() if "=" in p}

class ExpeditionJournalTests(unittest.TestCase):
    def test_quest_catalog_and_locale(self):
        source=read("scripts/razi_journal_data.lua")
        expanded=read("scripts/razi_journal_expansion.lua")
        quests=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",tech="([^"]+)"',source)
        extended=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",(?:tech|world)="([^"]+)"',expanded)
        industry=read("scripts/razi_journal_industry.lua")
        partnerships=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",tech="([^"]+)"',industry)
        self.assertEqual(len(partnerships),24)
        quests+=extended+partnerships
        self.assertEqual(len(quests),210)
        self.assertEqual(len({item[0] for item in quests}),210)
        chapter_sources=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',source)
        chapter_sources+=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',expanded)
        chapter_sources+=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',industry)
        self.assertEqual(len(chapter_sources),18)
        language=read("locale/en/razi_journal.cfg")
        sections={}
        for block in re.split(r'(?m)^\[([^\]]+)\]\s*',language)[1:][::2]:
            self.assertTrue(block)
        parsed=re.split(r'(?m)^\[([^\]]+)\]\s*',language)
        for i in range(1,len(parsed),2):
            sections[parsed[i]]=ids(parsed[i+1])
        for ch in chapter_sources:
            self.assertIn(ch,sections["journal-chapter"])
            self.assertIn(ch,sections["journal-chapter-story"])
        for quest,chapter,_ in quests:
            self.assertIn(chapter,chapter_sources)
            for section in ("journal-title","journal-story","journal-tip"):
                self.assertIn(quest,sections[section])
    def test_every_chapter_has_a_distinct_theme(self):
        catalog=read("scripts/razi_journal_data.lua")
        expanded=read("scripts/razi_journal_expansion.lua")
        industry=read("scripts/razi_journal_industry.lua")
        chapter_ids=set(re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',
                                   catalog+expanded+industry))
        themes=read("scripts/razi_journal_themes.lua")
        entries=re.findall(
            r'^  ([a-z0-9]+)=\{primary=\{r=([^,]+),g=([^,]+),b=([^}]+)\},'
            r'soft=\{r=([^,]+),g=([^,]+),b=([^}]+)\},',
            themes,re.M)
        self.assertEqual(chapter_ids,{entry[0] for entry in entries})
        self.assertEqual(18,len(entries))
        self.assertEqual(18,len({entry[1:4] for entry in entries}))
        primary_sprites=re.findall(
            r'^    icons=\{"([^"]+)"',themes,re.M)
        self.assertEqual(18,len(set(primary_sprites)))
        ui=read("scripts/razi_journal.lua")
        self.assertIn('themes.icon(chapter.id)',ui)
        self.assertIn('themes.icon(quest.chapter)',ui)
        self.assertIn('objective_bar.style.color=theme.primary',ui)
        self.assertIn('progress.style.color=theme.primary',ui)
        self.assertIn('chapter_intro.style.font_color=theme.primary',ui)
        self.assertIn('accent_rule(panel,theme,inner,3)',ui)
        self.assertIn('style="inside_shallow_frame"',ui)
        locale=read("locale/en/razi_journal.cfg")
        mood=locale.split("[journal-mood]",1)[1].split("\n[",1)[0]
        for chapter in chapter_ids:
            self.assertRegex(mood,rf"(?m)^{chapter}=")

    def test_archived_transmissions_are_source_research_gated(self):
        records=read("scripts/razi_journal_records.lua")
        all_records=re.findall(r'\{id="([^"]+)",unlock="([^"]+)"',records)
        self.assertEqual(len(all_records),15)
        self.assertEqual(len(set(x[0] for x in all_records)),15)
        locale=read("locale/en/razi_journal.cfg")
        sections={}
        parsed=re.split(r'(?m)^\[([^\]]+)\]\s*',locale)
        for i in range(1,len(parsed),2):
            sections[parsed[i]]=ids(parsed[i+1])
        for rec,_ in all_records:
            for section in ("journal-record-title","journal-record-origin",
                            "journal-record-body"):
                self.assertIn(rec,sections[section])
    def test_industry_prototype_origins(self):
        catalog=read("scripts/razi_journal_industry.lua")
        recipes="".join(read(path) for path in (
            "prototypes/compat/planet_production_exchanges.lua",
            "prototypes/compat/modded_planet_exchanges.lua",
            "prototypes/compat/community_industry_exchanges.lua",
            "prototypes/compat/galactic_industry_bridges.lua",
            "prototypes/compat/network_components.lua"))
        technologies=set(re.findall(r'tech="([^"]+)"',catalog))
        self.assertEqual(len(technologies),24)
        for name in technologies:
            self.assertIn(name,recipes, f"Industry quest has no registered recipe source: {name}")
        ui=read("scripts/razi_journal.lua")
        self.assertIn('effect.recipe==quest.tech',ui)
        self.assertIn('recipe_gallery(prose,quest,native,text_width,theme)',ui)

    def test_only_authoritative_research_progress(self):
        source=read("scripts/razi_journal.lua")
        self.assertIn("force.technologies[quest.tech]",source)
        self.assertIn('M.state(force,quest,context)',source)
        self.assertIn('M.discovery_index(force)',source)
        self.assertIn('effect.type=="unlock-space-location"',source)
        self.assertIn('M.unlocked_records(force,context)',source)
        self.assertIn('trials.defeated(snapshot,quest.boss)',source)
        self.assertIn('weather.for_quest(quest)',source)
        self.assertIn('razi_journal_action="nexus-codex"',source)
        self.assertIn('razi_journal_action="chapter"',source)
        self.assertIn('razi_journal_action="view"',source)
        self.assertIn('razi_journal_action="next"',source)
        self.assertIn('p.chapter==tags.id and false or tags.id',source)
        self.assertIn('function M.next_quest(force,context)',source)
        self.assertIn('function M.on_research(event)',source)
        self.assertNotIn("script.on_nth_tick",source)
        self.assertNotIn("surface.create_entity",source)
        self.assertNotIn("force.technologies[quest.tech].researched=",source)
        self.assertNotIn("player.insert(",source)
    def test_responsive_reader_without_horizontal_scrollbars(self):
        ui=read("scripts/razi_journal.lua")
        control=read("control.lua")
        loc=read("locale/en/razi_journal.cfg")
        self.assertIn('function M.layout(resolution,scale)',ui)
        self.assertIn('horizontal_scroll_policy="never"',ui)
        self.assertIn('vertical_scroll_policy="dont-show-but-allow-scrolling"',ui)
        self.assertIn('pane.style.horizontally_squashable=true',ui)
        self.assertIn('element.style.maximal_width=width',ui)
        self.assertIn('choice.style.single_line=false',ui)
        self.assertIn('name="razi_journal_chapter_picker"',ui)
        self.assertIn('function M.selection_changed(event)',ui)
        self.assertIn('razi_journal.selection_changed(event)',control)
        self.assertIn('razi_journal.text_changed(event)',control)
        self.assertIn('name="razi_journal_search"',ui)
        self.assertIn('science_gallery(native)',ui)
        self.assertIn('unlock_gallery(native)',ui)
        self.assertIn('recipe_gallery(prose,quest,native,text_width)',ui)
        self.assertIn('prototypes.recipe[quest.tech]',ui)
        self.assertIn('quest_art(player.force,quest,context)',ui)
        self.assertIn('column_count=size.reader<700 and 2 or 4',ui)
        self.assertIn('tags={razi_journal_action="select",id=quest.id}',ui)
        self.assertIn('style="inside_shallow_frame_with_padding"',ui)
        for key in ("navigator-title","archive-navigator","chapter-context",
                    "completion-heading","ready-heading","next-in-chapter",
                    "footer-hint","header-eyebrow"):
            self.assertRegex(loc,r"(?m)^"+key+r"=")
        self.assertNotIn("left.style.maximal_width=330",ui)
        self.assertNotIn("math.min(960",ui)
        self.assertNotIn('vertical_scroll_policy="always"',ui)

    def test_codex_runtime_work_is_bounded(self):
        ui=read("scripts/razi_journal.lua")
        self.assertIn('local function world_unlocks()',ui)
        self.assertIn('unlock_techs=catalog',ui)
        self.assertIn('function M.view_status(force,context)',ui)
        self.assertIn('quests_by_chapter[quest.chapter]',ui)
        self.assertIn('local state=view.states[quest.id]',ui)
        self.assertIn('done,total,ready=view.done,view.total,view.ready',ui)
        self.assertIn('render_chapters(body,player,p,context,size,view,plan)',ui)
        self.assertNotIn('for _,quest in ipairs(defs.quests) do\n      if quest.chapter==chapter.id',ui)

    def test_dynamic_expedition_priorities(self):
        ui=read("scripts/razi_journal.lua")
        planner=read("scripts/razi_journal_guidance.lua")
        fixture=read("tests/lua/test_razi_journal_guidance.lua")
        locale=read("locale/en/razi_journal.cfg")
        self.assertIn('function M.guidance(force,context,view)',ui)
        self.assertIn('local plan=view and M.guidance(player.force,context,view)',ui)
        self.assertIn('plan=plan or M.guidance(player.force,context,view)',ui)
        self.assertIn('function M.plan(states,lookup)',planner)
        self.assertIn('entry.tech_blockers=research_blockers(tech)',planner)
        self.assertIn('entry.disabled=tech.enabled==false',planner)
        self.assertIn('if not seen[entry.chapter] and #selected<3',planner)
        self.assertIn('entry.kind="campaign-blocked"',planner)
        self.assertIn('if frontier(entry.quest) then blocker=entry',planner)
        self.assertIn('local suggested=M.guidance(force,context)',ui)
        self.assertIn('if suggested.primary then return suggested.primary.quest',ui)
        self.assertIn('razi_journal_action="guidance-select"',ui)
        self.assertIn('p.reveal_selection=true',ui)
        self.assertIn('scroll.scroll_to_element(selected_element)',ui)
        self.assertNotIn('data:extend',planner)
        self.assertNotIn('script.on_tick',planner)
        self.assertIn('check(initial.ready_count==4',fixture)
        self.assertIn('check(initial.blocker',fixture)
        self.assertIn('check(not none.primary',fixture)
        for key in ("guidance-heading","guidance-main","guidance-parallel",
                    "guidance-none","guidance-blocker-heading",
                    "guidance-tech-needs","guidance-quest-needs",
                    "guidance-disabled"):
            self.assertRegex(locale,r"(?m)^"+key+r"=")

    def test_visible_during_normal_play_not_shortcut_bar(self):
        control=read("control.lua")
        ui=read("scripts/razi_journal.lua")
        self.assertIn('events:on_event("razi-journal-toggle"',control)
        self.assertIn("razi_journal.gui_click(event)",control)
        self.assertIn("razi_journal.on_research",control)
        self.assertIn("razi_journal.flush_research_refreshes()",control)
        self.assertIn("M.research_affects_journal(research)",ui)
        self.assertNotIn("if event.by_script then",ui)
        self.assertIn("function M.flush_research_refreshes()",ui)
        self.assertIn("player.gui.top.add",ui)
        self.assertIn('type="progressbar"',ui)
        self.assertIn('chapter_intro.style.font_color=',ui)
        self.assertIn('native.prerequisites or {}',ui)
        self.assertIn("player.gui.left",ui)
        self.assertIn("player.gui.screen",ui)
        self.assertNotIn('type="shortcut"',read("prototypes/ui/razi_journal.lua"))
        self.assertIn('require("prototypes.ui.razi_journal")',read("data.lua"))
    def test_industry_quests_can_open_real_cargo_chains(self):
        journal=read("scripts/razi_journal.lua")
        catalog=read("scripts/galactic_trade_catalog.lua")
        operations=read("scripts/galactic_operations.lua")
        ui=read("locale/en/razi_journal.cfg")
        self.assertIn('local cargo_catalog=require("scripts.galactic_trade_catalog")',
                      journal)
        self.assertIn('cargo_catalog.chain_for_quest(quest.id)',journal)
        self.assertIn('cargo_catalog.is_installed(player.force,cargo_id)',journal)
        self.assertIn('razi_journal_action="open-cargo"',journal)
        self.assertIn('operations.open_cargo(player,chain,target)',journal)
        self.assertIn('function M.open_quest(player,id)',journal)
        self.assertIn('p.filter="all"',journal)
        self.assertIn('p.view="quests"',journal)
        self.assertIn('function M.quest_for_technology(name)',catalog)
        self.assertIn('function M.chain_for_quest(id)',catalog)
        self.assertIn('function M.open_cargo(player,chain,target)',operations)
        for name in ("cargo-bridge-heading","cargo-bridge-description",
                     "cargo-bridge-open","cargo-bridge-tooltip"):
            self.assertRegex(ui,r"(?m)^"+name+r"=")

    def test_no_new_research_or_dependency(self):
        data=read("scripts/razi_journal_data.lua")
        self.assertNotIn('type="technology"',data)
        self.assertNotIn('data:extend',data)
        self.assertNotIn('data:extend',read("scripts/razi_journal_expansion.lua"))
        self.assertNotIn('data:extend',read("scripts/razi_journal_industry.lua"))
        self.assertNotIn('data:extend',read("scripts/razi_journal_records.lua"))
        manifest=read("info.json")
        self.assertNotIn('"quest-book"',manifest)
if __name__=="__main__":
    unittest.main()
