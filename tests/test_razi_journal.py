"""Guard the native Razi Expedition Journal against duplicate and brittle quests."""
from pathlib import Path
import re
import unittest
from tools.journal_locale import load_journal_locale

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf8")
def ids(section):
    return {p.strip().split("=",1)[0] for p in section.splitlines() if "=" in p}

class ExpeditionJournalTests(unittest.TestCase):
    def test_quest_catalog_and_locale(self):
        source=read("scripts/razi_journal_data.lua")
        expanded=read("scripts/razi_journal_expansion.lua")
        frontier=read("scripts/razi_journal_frontier.lua")
        quests=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",tech="([^"]+)"',source)
        extended=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",(?:tech|world)="([^"]+)"',expanded)
        industry=read("scripts/razi_journal_industry.lua")
        partnerships=re.findall(r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",tech="([^"]+)"',industry)
        self.assertEqual(len(partnerships),31)
        primary_worlds=re.findall(
            r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)",world="([^"]+)"',source)
        frontier_quests=[
            (id,chapter,"source-owned") for id,chapter in re.findall(
            r'\{id="([a-z0-9-]+)",chapter="([a-z0-9-]+)"',
            frontier,re.S)]
        quests+=extended+partnerships+primary_worlds+frontier_quests
        self.assertEqual(len(quests),233)
        self.assertEqual(len({item[0] for item in quests}),233)
        chapter_sources=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',source)
        chapter_sources+=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',expanded)
        chapter_sources+=re.findall(r'\{id="([a-z0-9-]+)",title="journal-chapter',industry)
        self.assertEqual(len(chapter_sources),18)
        language=load_journal_locale(ROOT)
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
        self.assertNotIn('objective_bar=panel.add',ui)
        self.assertIn('local content_height=size.body-(size.compact and 170 or 186)',ui)
        self.assertIn('select_rule.style.color=theme.primary',ui)
        self.assertIn('chapter_intro.style.font_color=theme.soft',ui)
        self.assertIn('accent_rule(panel,theme,math.min(92,inner),2)',ui)
        self.assertIn('style="inside_shallow_frame"',ui)
        locale=load_journal_locale(ROOT)
        mood=locale.split("[journal-mood]",1)[1].split("\n[",1)[0]
        for chapter in chapter_ids:
            self.assertRegex(mood,rf"(?m)^{chapter}=")

    def test_archived_transmissions_are_source_research_gated(self):
        records=read("scripts/razi_journal_records.lua")
        all_records=re.findall(r'\{id="([^"]+)",unlock="([^"]+)"',records)
        self.assertEqual(len(all_records),15)
        self.assertEqual(len(set(x[0] for x in all_records)),15)
        locale=load_journal_locale(ROOT)
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
            "prototypes/compat/first_frontier_industry.lua",
            "prototypes/compat/network_components.lua"))
        technologies=set(re.findall(r'tech="([^"]+)"',catalog))
        self.assertEqual(len(technologies),31)
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
    def test_codex_icon_sizes_are_fixed_and_keep_story_navigation(self):
        ui=read("scripts/razi_journal.lua")
        size=read("scripts/razi_journal_icons.lua")
        locale=load_journal_locale(ROOT)
        self.assertIn('resize_to_sprite=false',size)
        self.assertIn('element.style.stretch_image_to_widget_size=true',size)
        self.assertIn('element.style.size=edge',size)
        self.assertIn('quest_hero=36',size)
        self.assertIn('quest_row=20',size)
        self.assertIn('gallery=28',size)
        self.assertIn('icons.sprite(card,entry.sprite,"gallery"',ui)
        self.assertIn('icons.sprite(head,themes.icon(chapter.id)',ui)
        self.assertIn('icons.sprite(hero,quest_art(player.force,quest,context),"quest_hero")',ui)
        self.assertIn('for _,view in ipairs({"quests","projects","archive","systems"}) do',ui)
        self.assertIn("view-quests=Quests",locale)
        self.assertIn("view-archive=Archive",locale)
        self.assertNotIn('local insignia=head.add{type="sprite"',ui)

    def test_responsive_reader_without_horizontal_scrollbars(self):
        ui=read("scripts/razi_journal.lua")
        control=read("control.lua")
        loc=load_journal_locale(ROOT)
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
        self.assertNotIn('science_gallery(native)',ui)
        self.assertNotIn('unlock_gallery(native)',ui)
        self.assertIn('recipe_gallery(prose,quest,native,text_width,theme)',ui)
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
        locale=load_journal_locale(ROOT)
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
        self.assertIn('icons.button(player.gui.top,"razi-journal-book-icon","toolbar"',ui)
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
        ui=load_journal_locale(ROOT)
        self.assertIn('local cargo_catalog=require("scripts.galactic_trade_catalog")',
                      journal)
        self.assertIn('cargo_catalog.chain_for_quest(quest.id)',journal)
        self.assertIn('cargo_catalog.is_installed(player.force,cargo_id)',journal)
        self.assertIn('razi_journal_action="open-cargo"',journal)
        self.assertIn('M.open_project(player,\"cargo\",chain,target)',journal)
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
    def test_no_runtime_require_on_cargo_codex_gui_click(self):
        catalog=read("scripts/galactic_trade_catalog.lua")
        journal=read("scripts/razi_journal.lua")
        operations=read("scripts/galactic_operations.lua")
        control=read("control.lua")
        self.assertIn('local journal_definitions=require("scripts.razi_journal_data")', catalog)
        self.assertIn('local quest=journal_definitions.by_id[id]', catalog)
        self.assertNotIn('  local definitions=require("scripts.razi_journal_data")', catalog)
        self.assertNotIn('    local operations=require("scripts.galactic_operations")', journal)
        self.assertNotIn('    local journal=require("scripts.razi_journal")', operations)
        self.assertIn('razi_journal.open_project(player)', control)
        self.assertIn('journal_module.open_quest(player,quest_id)', operations)

    def test_cargo_project_cards_use_fixed_icons_and_contained_milestones(self):
        trade=read("scripts/galactic_trade.lua")
        projects=read("scripts/razi_journal_projects.lua")
        icons=read("scripts/razi_journal_icons.lua")
        locale=read("locale/en/galactic_operations.cfg")
        self.assertIn('local icons=require("scripts.razi_journal_icons")',trade)
        self.assertIn('icons.sprite(parent,path,role)',trade)
        self.assertNotIn('add{type="sprite",sprite=',trade)
        self.assertIn('resize_to_sprite=false',icons)
        for role in ("cargo_header","cargo_chain","cargo_research",
                     "cargo_world","cargo_material","cargo_science",
                     "project_button","project_hero"):
            self.assertIn(role+"=",icons)
        self.assertIn('type=inline and "label" or "button"',trade)
        self.assertIn('codex_link(metadata,consumer.name',trade)
        self.assertIn('if index<#row.upgrades then',trade)
        self.assertIn('render_chain(grid,row,p,size.card,index)',trade)
        self.assertIn('icons.button(head,art_for(id,player.force)',projects)
        self.assertIn('icons.sprite(header,art_for(p.project,player.force)',projects)
        self.assertIn("trade-chain-folio=PRODUCTION CHAIN __1__",locale)

    def test_codex_layout_polish_keeps_native_scroll_controls(self):
        source=read("scripts/razi_journal.lua")
        self.assertIn('metrics_row.style.horizontal_spacing=size.compact and 8 or 18',source)
        self.assertIn('overall.style.height=9',source)
        self.assertIn('priority.style.padding=8',source)
        self.assertIn('progress.style.height=6',source)
        self.assertIn('horizontal_scroll_policy="never"',source)
        self.assertIn('local function wheel_pane(',source)

    def test_journal_editorial_and_reading_order(self):
        source=read("scripts/razi_journal.lua")
        locale=load_journal_locale(ROOT)
        ui=locale.split("[journal-ui]",1)[1].split("\n[",1)[0]
        self.assertIn("window=RAZI PROTOCOL",ui)
        self.assertIn("header-eyebrow=EXPEDITION JOURNAL",ui)
        self.assertIn("next-steps-heading=RELATED MILESTONES",ui)
        self.assertNotIn("real research",ui.lower())
        self.assertNotIn("confirmed victory",ui.lower())
        self.assertNotIn('wrap(forecast,L("next-steps-note")',source)
        self.assertIn('if step.state~="complete" then',source)
        self.assertNotIn('objective_bar=panel.add',source)
        self.assertLess(source.index('section(prose,"tip-heading"'),
                        source.index('recipe_gallery(prose,quest,native,text_width,theme)'))
        self.assertIn('forecast.style.vertical_spacing=4',source)
        self.assertIn('bridge.style.vertical_spacing=4',source)

    def test_frame_styles_do_not_use_flow_spacing(self):
        source=read("scripts/razi_journal.lua")
        self.assertNotIn("totals.style.horizontal_spacing=",source)
        self.assertNotIn("priority.style.vertical_spacing=",source)
        self.assertIn('metrics_row.style.horizontal_spacing=',source)
        self.assertIn('local metric=metrics_row.add',source)
        self.assertIn('local readiness=metrics_row.add',source)
        self.assertIn('local meter=metrics_row.add',source)
        fixture=read("tests/lua/test_razi_journal_layout.lua")
        self.assertIn('Flow-only spacing applied to a Factorio frame:',fixture)

if __name__=="__main__":
    unittest.main()
