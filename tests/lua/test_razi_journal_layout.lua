-- Native Journal GUI regression without running Factorio or changing game state.
-- The mock tests column widths, wrapped captions, hidden scrollbar chrome
-- and navigation callbacks. Full visual rendering still needs a game test.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local journal=require("scripts.razi_journal")
local defs=require("scripts.razi_journal_data")
local themes=require("scripts.razi_journal_themes")
local created={}
-- The real Factorio GUI throws if a FrameStyle receives FlowStyle spacing.
-- Keep the mock strict enough to catch this regression before game startup.
local function gui_style(kind)
  local style={}
  if kind=="frame" then
    setmetatable(style,{__newindex=function(target,key,value)
      check(key~="horizontal_spacing" and key~="vertical_spacing",
        "Flow-only spacing applied to a Factorio frame: "..key)
      rawset(target,key,value)
    end})
  end
  return style
end
local function node(spec)
  local element={valid=true,type=spec.type,name=spec.name,tags=spec.tags,
    caption=spec.caption,tooltip=spec.tooltip,
    selected_index=spec.selected_index,items=spec.items,
    sprite=spec.sprite,resize_to_sprite=spec.resize_to_sprite,
    text=spec.text,
    horizontal_scroll_policy=spec.horizontal_scroll_policy,
    vertical_scroll_policy=spec.vertical_scroll_policy,
    style=gui_style(spec.type),children={}}
  created[#created+1]=element
  function element.add(child)
    local item=node(child)
    element.children[#element.children+1]=item
    if item.name then element[item.name]=item end
    return item
  end
  function element.clear()
    element.children={}
    for _,child in ipairs(created) do
      if child.name then element[child.name]=nil end
    end
  end
  function element.scroll_to_element(target)
    check(target.valid,"Cannot scroll to destroyed quest")
  end
  return element
end
local force={name="player",technologies={}}
rawset(_G,"helpers",{is_valid_sprite_path=function() return true end})
local unique_icons,unique_colors={},{}
local count=0
for _,chapter in ipairs(defs.chapters) do
  local theme=themes.get(chapter.id)
  local image=themes.icon(chapter.id)
  check(theme and theme.primary and theme.soft,
    "Missing chapter palette for "..chapter.id)
  check(image and not unique_icons[image],
    "Chapter sigil is absent or duplicated: "..chapter.id)
  unique_icons[image]=true
  local key=theme.primary.r.."/"..theme.primary.g.."/"..theme.primary.b
  check(not unique_colors[key],
    "Chapter color is duplicated: "..chapter.id)
  unique_colors[key]=true
  count=count+1
end
check(count==18,"Every campaign chapter needs unique color and artwork")
local original_sprite_check=helpers.is_valid_sprite_path
helpers.is_valid_sprite_path=function() return false end
check(themes.icon("solaris")=="razi-journal-book-icon",
  "Removed mod artwork must fall back to the Codex emblem")
helpers.is_valid_sprite_path=original_sprite_check
rawset(_G,"prototypes",{
 item={
   bioflux={localised_name="Bioflux"},
   ["kr-rare-metals"]={localised_name="Rare metals"},
   ["automation-science-pack"]={localised_name="Automation science"},
   ["assembling-machine-1"]={localised_name="Assembler",
     place_result={name="assembling-machine-1",localised_name="Assembler"}}},
 recipe={
   ["razi-bio-rare-metal-casting"]={localised_name="Imported rare metals",
     ingredients={{type="item",name="bioflux",amount=2}},
     products={{type="item",name="kr-rare-metals",amount=4}}},
   ["assembling-machine-1"]={localised_name="Assembler",
     products={{type="item",name="assembling-machine-1"}}}}
})
for _,quest in ipairs(defs.quests) do
  if quest.tech then
    force.technologies[quest.tech]={
      name=quest.tech,researched=false,enabled=true,
      localised_name=quest.tech,prerequisites={},
      prototype={hidden=false,effects={}}
    }
  end
end
force.technologies.automation.prototype.effects={
  {type="unlock-recipe",recipe="assembling-machine-1"}}
force.technologies["razi-bio-rare-metal-casting"].prototype.effects={
  {type="unlock-recipe",recipe="razi-bio-rare-metal-casting"}}
force.technologies.automation.research_unit_ingredients={
  {name="automation-science-pack",amount=1}}
local player={valid=true,index=1,force=force,
  display_resolution={width=1920,height=1080},
  display_scale=1.25,
  gui={screen={},left={},top={}}}
local root=node{type="frame",name=journal.FRAME}
player.gui.screen[journal.FRAME]=root
rawset(_G,"storage",{})
rawset(_G,"game",{
  connected_players={player},forces={player=force},
  get_player=function(id) if id==1 then return player end end
})
-- Persistent GUI updates must be inspected through the live widget tree,
-- not only the latest allocation batch. Old tests assumed frame.clear()
-- recreated every widget and therefore missed valid retained controls.
local function live_elements()
  local found={}
  local function visit(parent)
    for _,child in ipairs(parent.children) do
      found[#found+1]=child
      visit(child)
    end
  end
  visit(root)
  return found
end
local function assert_panes()
  local count=0
  for _,element in ipairs(live_elements()) do
    if element.type=="scroll-pane" then
      count=count+1
      check(element.horizontal_scroll_policy=="never",
        "One of the reader's scroll panes still has a horizontal bar")
      check(element.vertical_scroll_policy==(element.name=="razi_journal_navigation"
        and "auto" or "dont-show-but-allow-scrolling"),
        "Only the chapter index should display native scrollbar chrome")
      check(element.style.width and element.style.width>100,
        "Scroll pane missing explicit width")
    end
  end
  return count
end
journal.draw(player)
local wide=journal.layout(player.display_resolution,player.display_scale)
check(wide.width>960,"The redesigned window was not enlarged")
check(root.style.width==wide.width,"Frame width ignores resolution")
check(assert_panes()==2,"Quest view needs only navigator and reader panes")
local sprites={}
for _,entry in ipairs(live_elements()) do
  if entry.sprite then sprites[entry.sprite]=true end
end
check(sprites["technology/automation"],"Native research art is missing")
check(sprites["item/automation-science-pack"],"Native science art is missing")
check(sprites["entity/assembling-machine-1"],"Native building art is missing")
check(sprites[themes.icon("calidus")],
  "Navigator must show the chapter insignia")
local nauvis_acts={}
for _,entry in ipairs(live_elements()) do
  if type(entry.caption)=="table" and
    type(entry.caption[1])=="string" and
    entry.caption[1]:find("^journal%-nauvis%-phase%.") then
    nauvis_acts[entry.caption[1]]=true
  end
end
for _,phase in ipairs({"machines","growth","chemistry","departure"}) do
  check(nauvis_acts["journal-nauvis-phase."..phase],
    "The Nauvis chapter rail lost its act divider: "..phase)
end
-- Native sprite art can be larger than the requested GUI box. All Codex
-- widgets must ignore intrinsic dimensions, even on heavily modded packs.
local roles=require("scripts.razi_journal_icons")
local icon_count=0
for _,entry in ipairs(live_elements()) do
  if entry.sprite then
    local width=entry.style.size or entry.style.width
    local height=entry.style.size or entry.style.height
    check(type(width)=="number" and type(height)=="number"
      and width==height and width<=36,
      "Oversized or unbounded Codex sprite: "..tostring(entry.sprite))
    if entry.type=="sprite" then
      check(entry.resize_to_sprite==false,
        "Natural-size sprite expansion was not disabled")
      check(entry.style.stretch_image_to_widget_size==true,
        "Source image not fitted to the icon box")
    end
    icon_count=icon_count+1
  end
end
check(icon_count>=4 and roles.size("quest_hero")==36
  and roles.size("quest_row")==20 and roles.size("gallery")==28,
  "Codex icon sizing policy is missing")
local top_priority,parallel=0,0
for _,entry in ipairs(live_elements()) do
  if entry.tags and entry.tags.razi_journal_action=="guidance-select" then
    local q=defs.by_id[entry.tags.id]
    check(q and entry.type=="label",
      "Recommended missions must be clickable real Codex objectives")
    top_priority=top_priority+1
    if q.chapter~="calidus" then parallel=parallel+1 end
  end
end
check(top_priority>=1,
  "Navigator must show at least one genuine research-ready priority")
local selected_quest_paper,readiness_bar=0,0
for _,entry in ipairs(live_elements()) do
  if entry.type=="flow"
    and entry.name=="razi_journal_item_"..(journal.preferences(1).selected or "") then
    selected_quest_paper=selected_quest_paper+1
  end
  if entry.type=="progressbar" and entry.style.height==5 then
    readiness_bar=readiness_bar+1
  end
end
check(selected_quest_paper==1,
  "Selected objective must exist once in the persistent chapter index")
local tinted=0
for _,entry in ipairs(live_elements()) do
  if entry.type=="progressbar" and entry.style.color then
    tinted=tinted+1
  end
end
check(tinted>=2,"Chapter and progress meters should be color themed")
check(journal.matches_query(defs.by_id["first-signal"],"automation"),
  "Search must match native technology")
check(not journal.matches_query(defs.by_id["first-signal"],"maraxsis"),
  "Search must exclude unrelated technologies")
local search_field
for _,entry in ipairs(live_elements()) do
  if entry.name=="razi_journal_search" then search_field=entry end
end
check(search_field,"Live search input is missing")
search_field.text="automation"
journal.text_changed({player_index=1,element=search_field})
check(journal.preferences(1).query=="automation",
  "Typed search should persist in existing player preferences")
journal.preferences(1).query=""
created={}
journal.draw(player)
-- A real chapter briefing must open in the same reader, keep two hidden
-- wheel-scrolling panes, and let a player continue to source milestones.
local cover_link
for _,element in ipairs(live_elements()) do
  if element.tags and element.tags.razi_journal_action=="chapter-dossier"
    and element.tags.id=="calidus" then cover_link=element;break end
end
check(cover_link,"Chapter index is missing the briefing navigation")
created={}
journal.gui_click({player_index=1,element=cover_link})
check(journal.preferences(1).chapter_cover==true,
  "Opening a chapter briefing must be saved as a UI-only preference")
check(assert_panes()==2,
  "Chapter briefing should reuse one navigator and one scrollable reader")
local chapter_reading,cover_title,open_milestone
for _,element in ipairs(live_elements()) do
  if element.name=="razi_journal_chapter_reading" then
    chapter_reading=element
  elseif type(element.caption)=="table"
    and element.caption[1]=="journal-chapter.calidus" then
    cover_title=element
  end
  if element.tags and element.tags.razi_journal_action=="chapter-continue" then
    open_milestone=element
  end
end
check(chapter_reading and cover_title and open_milestone,
  "Chapter briefing needs the actual chapter, scrollable story and next entry")
created={}
journal.gui_click({player_index=1,element=open_milestone})
check(not journal.preferences(1).chapter_cover
  and journal.preferences(1).selected==open_milestone.tags.id,
  "Continue must open an actual source-backed milestone dossier")
-- The actionable ready count switches to Quests and the genuine Ready
-- filter, rather than showing an inert cosmetic number.
local ready_jump
for _,element in ipairs(live_elements()) do
  if element.tags and element.tags.razi_journal_action=="filter-ready" then
    ready_jump=element;break
  end
end
check(ready_jump~=nil,"Ready progress should be directly actionable")
journal.preferences(1).view="projects"
journal.gui_click({player_index=1,element=ready_jump})
check(journal.preferences(1).view=="quests"
  and journal.preferences(1).filter=="ready"
  and journal.preferences(1).selected
  and journal.state(force,defs.by_id[journal.preferences(1).selected])=="active",
  "Header Ready count must open a real ready quest")
journal.preferences(1).filter="all"
journal.preferences(1).selected="alliance-bio-metals"
journal.preferences(1).chapter="alliances"
created={}
journal.draw(player)
local industry_sprites={}
for _,entry in ipairs(live_elements()) do
  if entry.sprite then industry_sprites[entry.sprite]=true end
end
check(industry_sprites[themes.icon("alliances")],
  "Industrial chapter must display its own identity")
check(industry_sprites["item/bioflux"] and industry_sprites["item/kr-rare-metals"],
  "Factory research should illustrate real recipe imports and outputs")
check(journal.matches_query(defs.by_id["alliance-bio-metals"],"vulcanus"),
  "Search should find suggested production worlds")
-- Recommendation actions are visible even when an old save had a stale
-- search and completion filter selected. Jumping clears only UI filters.
journal.preferences(1).filter="done"
journal.preferences(1).query="no-such-technology"
created={}
journal.draw(player)
local recommendation
for _,entry in ipairs(live_elements()) do
  if entry.tags and entry.tags.razi_journal_action=="guidance-select" then
    recommendation=entry
    break
  end
end
check(recommendation,"Recommendations must remain visible with stale filters")
local chosen_id=recommendation.tags.id
journal.gui_click({player_index=1,element=recommendation})
check(journal.preferences(1).selected==chosen_id
  and journal.preferences(1).chapter==defs.by_id[chosen_id].chapter
  and journal.preferences(1).filter=="all"
  and journal.preferences(1).query=="",
  "Selecting a recommendation must open its genuine chapter and quest")
journal.preferences(1).selected="first-signal"
journal.preferences(1).chapter="calidus"
created={}
journal.draw(player)
local picker
local selector
for _,element in ipairs(live_elements()) do
  if element.name=="razi_journal_chapter_picker" then picker=element end
  if element.tags and element.tags.razi_journal_action=="select"
    and element.type=="button" then selector=element end
end
check(picker and picker.items and #picker.items==18 and picker.selected_index,
  "The chapter jump dropdown is absent")
check(selector and selector.tags.id,
  "Wrapped quest rows require a guaranteed clickable button")
picker.selected_index=3
created={}
journal.selection_changed({player_index=1,element=picker})
check(journal.preferences(1).chapter=="nyxaris",
  "Jumping to a chapter did not navigate the index")
check(journal.preferences(1).selected~=nil,
  "Chapter jump must select a visible objective")
created={}
-- The Archive tab belongs to the story; test it with the story on.
require("scripts.razi_story").configure(true)
journal.preferences(1).view="archive"
force.technologies.automation.researched=true
journal.draw(player)
check(assert_panes()==2,
  "Archive navigation and reading should also hide both scrollbars")
require("scripts.razi_story").configure(false)
journal.preferences(1).view="quests"
for _,size in ipairs({
  {width=1920,height=1080,scale=1},
  {width=1920,height=1080,scale=1.25},
  {width=1600,height=900,scale=1.5},
  {width=1280,height=720,scale=1},
  {width=1024,height=768,scale=1}
}) do
  local d=journal.layout(size,size.scale)
  check(d.reader+d.rail+43==d.width,
    "Columns must fit within their window at every UI scale")
  check(d.reader>=190,"Story pane too narrow for readable content")
  check(d.body<d.height,"Reader must leave space for toolbar and header")
end
-- Cross-navigation selects an existing quest without changing researched
-- technologies or rebuilding the saved campaign milestone IDs.
check(not journal.open_quest(player,"quest-does-not-exist"),
  "Unknown Codex milestones must be rejected")
created={}
check(journal.open_quest(player,"precision-matrix"),
  "Existing industrial milestones should open by exact quest ID")
check(journal.preferences(1).selected=="precision-matrix"
  and journal.preferences(1).chapter=="network"
  and journal.preferences(1).view=="quests"
  and journal.preferences(1).query=="",
  "Cargo link must select the exact milestone and clear stale filters")
local bridge
for _,entry in ipairs(live_elements()) do
  if entry.tags and entry.tags.razi_journal_action=="open-cargo" then
    bridge=entry
  end
end
check(bridge and bridge.tags.id=="precision-matrix",
  "Industry quest must offer the real cargo chain navigation")
local linked,mission,finish=0,false,false
for _,entry in ipairs(live_elements()) do
  if entry.tags and entry.tags.razi_journal_action=="guidance-select"
    and (entry.tags.id=="fulgora" or entry.tags.id=="moshine")
    and entry.tooltip and entry.tooltip[1]=="journal-ui.open-prerequisite" then
    linked=linked+1
  end
  if entry.name=="razi_journal_mission_plan" then mission=true end
  if entry.caption and type(entry.caption)=="table"
    and entry.caption[1]=="journal-ui.mission-finish-line" then
    finish=true
  end
end
check(linked>=1 and mission and finish,
  "Quest dossier needs a source-backed mission and clickable next blockers")
local original_open_project=journal.open_project
local called
journal.open_project=function(_,kind,chain,technology_name)
  called={kind,chain,technology_name}
  return false
end
journal.gui_click({player_index=1,element=bridge})
journal.open_project=original_open_project
check(called and called[1]=="cargo"
  and called[2]=="razi-network-precision-matrix"
  and called[3]=="razi-network-precision-matrix",
  "Codex must deep-link to the correct installed Cargo Network factory")

-- A narrow effective GUI must NOT show two unreadably compressed
-- columns. The Index / Read switch should retain its native scroll offset,
-- and selecting a milestone should reopen the full-width dossier.
player.display_resolution={width=1024,height=768}
player.display_scale=1.5
journal.preferences(1).view="quests"
journal.preferences(1).selected="first-signal"
journal.preferences(1).chapter="calidus"
journal.preferences(1).compact_index_open=false
journal.draw(player)
local narrow=journal.layout(player.display_resolution,player.display_scale)
check(narrow.single_column and narrow.width<740,
  "Small effective screens must use the single-column reader")
local function panels()
  local body=root["razi_journal_content"]
  check(body,"Narrow Journal must retain its live body")
  return body["razi_journal_navigation_panel"],
    body["razi_journal_reader_host"]
end
local nav,reader=panels()
check(nav.visible==false and reader.visible==true,
  "Reader should be full width by default on a narrow screen")
check(reader.style.width==narrow.width-43,
  "The narrow dossier should get the actual available width")
local switch
for _,element in ipairs(live_elements()) do
  if element.tags and element.tags.razi_journal_action=="compact-index" then
    switch=element;break
  end
end
check(switch,"Narrow screens must have a usable Index / Read switch")
journal.gui_click({player_index=1,element=switch})
nav,reader=panels()
check(nav.visible==true and reader.visible==false,
  "Index mode must hide the dossier, not squeeze it beside the rail")
local scroller=nav["razi_journal_navigation"]
check(scroller,"The same scrollable chapter index should still be available")
scroller.vertical_scroll_position=83
journal.gui_click({player_index=1,element=switch})
nav,reader=panels()
check(not nav.visible and reader.visible,
  "Leaving Index must reopen the reading page")
journal.gui_click({player_index=1,element=switch})
nav,reader=panels()
check(nav.visible and not reader.visible
  and nav["razi_journal_navigation"].vertical_scroll_position==83,
  "Returning to Index must restore its last native scroll position")
local chosen
for _,element in ipairs(live_elements()) do
  if element.tags and element.tags.razi_journal_action=="select"
    and element.tags.id=="first-signal" then chosen=element;break end
end
check(chosen,"The compact index must retain real selectable milestones")
journal.gui_click({player_index=1,element=chosen})
nav,reader=panels()
check(not nav.visible and reader.visible
  and journal.preferences(1).compact_index_open==false,
  "Selecting a milestone should immediately reopen the full-width dossier")
check(reader.children[1] and reader.children[1].style.width==narrow.width-43,
  "After an in-place selection, the full-width dossier must stay responsive")
print("Journal GUI: adaptive single-column mission reader, native index position and source-linked actions passed")
