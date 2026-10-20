-- The Protocol Codex reads research progress from each force.
-- Player storage is just UI preferences, so an older save can reopen it.
local M={}
local journal_button_cleanup=require("scripts.razi_journal_button_cleanup")
local defs=require("scripts.razi_journal_data")
local records=require("scripts.razi_journal_records")
local industrial_briefs=require("scripts.razi_planet_briefs")
local catapults=require("scripts.razi_catapult_network")
local freight_orders=require("scripts.razi_freight_orders")
local supply=require("scripts.razi_supply_planner")
local multihop=require("scripts.razi_supply_multihop")
local shipment_operations=require("scripts.razi_shipment_operations")
local shipment_handoff=require("scripts.razi_shipment_handoff")
local supply_routes=require("scripts.razi_supply_routes")
local trials=require("scripts.razi_nexus_trials")
local weather=require("scripts.razi_weather_guide")
local cargo_catalog=require("scripts.galactic_trade_catalog")
local convergence=require("scripts.razi_convergence")
local projects=require("scripts.razi_journal_projects")
local systems=require("scripts.razi_journal_systems")
local great_projects=require("scripts.razi_great_projects")
local guidance=require("scripts.razi_journal_guidance")
local objectives=require("scripts.razi_journal_objectives")
local chapter_timing=require("scripts.razi_chapter_timing")
local journal_acts=require("scripts.razi_journal_acts")
local preview=require("scripts.razi_journal_recipe_preview")
local FRAME="razi_expedition_journal"
local TOP="razi_expedition_journal_button"
local TRACKER="razi_expedition_objective_tracker"
local L=function(key,...) return {"journal-ui."..key,...} end
local themes=require("scripts.razi_journal_themes")
local icons=require("scripts.razi_journal_icons")
-- A field-manual palette: chapter hues are restrained accents, not the ink.
-- Midnight Archive: soft parchment, antique brass and spectral teal.
-- Chapter pigments are used as signposts, never as entire text surfaces.
local COLOR={
  ink={r=.933,g=.890,b=.808}, muted={r=.72,g=.73,b=.71},
  quiet={r=.52,g=.58,b=.58}, green={r=.58,g=.80,b=.66},
  amber={r=.82,g=.69,b=.48}, teal={r=.52,g=.78,b=.76}
}
M.chapter_theme=themes.get
M.chapter_icon=themes.icon

M.FRAME=FRAME
M.TOP=TOP
M.TRACKER=TRACKER

-- The research-all cheat can fire thousands of events. We only need to
-- redraw for Codex milestones and world discovery unlocks.
local research_goals,world_goals,quests_for_technology={},{},{}
for _,quest in ipairs(defs.quests) do
  if quest.tech then
    research_goals[quest.tech]=true
    local entries=quests_for_technology[quest.tech]
    if not entries then
      entries={}
      quests_for_technology[quest.tech]=entries
    end
    entries[#entries+1]=quest
  end
  if quest.world then world_goals[quest.world]=true end
end
function M.research_affects_journal(research)
  if not research then return false end
  if research_goals[research.name] or projects.research_related(research.name) then return true end
  local proto=research.prototype
  for _,effect in pairs(proto and proto.effects or {}) do
    if effect.type=="unlock-space-location"
      and world_goals[effect.space_location] then
      return true
    end
  end
  return false
end

local function pref(index)
  storage.razi_expedition_journal=storage.razi_expedition_journal or {}
  local value=storage.razi_expedition_journal[index]
  if not value then
    value={selected=nil,pinned=nil,tracker=false,
      chapter=nil,chapter_cover=false,filter="all",view="quests",project="platform",record=nil,query=""}
    storage.razi_expedition_journal[index]=value
  end
  value.filter=value.filter or "all"
  value.view=({quests=true,projects=true,archive=true,systems=true})[value.view] and value.view or "quests"
  value.project=(projects.valid(value.project) or value.project=="cargo")
    and value.project or "platform"
  value.query=value.query or ""
  value.logistics_tab=({overview=true,routes=true,
    supply=true,freight=true,industry=true})[value.logistics_tab]
    and value.logistics_tab or "overview"
  value.logistics_scrolls=value.logistics_scrolls or {}
  if value.supply_batches==nil then value.supply_batches=1 end
  if value.supply_path==nil then value.supply_path=1 end
  value.story_unread=value.story_unread or {}
  value.story_alerts=value.story_alerts~=false
  value.archive_filter=({all=true,legacy=true,corporate=true,
    field=true})[value.archive_filter] and value.archive_filter or "all"
  value.chapter_cover=value.chapter_cover==true
  value.goal_expanded=value.goal_expanded==true
  value.reader_focus=value.reader_focus==true
  value.compact_index_open=value.compact_index_open==true
  -- Default to one Journal toolbar. Players can reveal the source buttons
  -- temporarily when they need Planet Express or Nexus native controls.
  value.native_controls_visible=value.native_controls_visible==true
  return value
end
M.preferences=pref

-- Find actual native world-discovery research via source mod effect data.
-- One pass per journal view, rather than guessing 19 third-party tech IDs
-- or rescanning thousands of technologies for each side-world quest.
-- Prototype effects never change during a game. Keep their names in a
-- runtime-only index, then look up the current force's research as needed.
-- Test fixtures without prototypes.technology still use the original scan.
local unlock_techs
local function world_unlocks()
  if unlock_techs then return unlock_techs end
  local catalog={}
  local registered=prototypes and prototypes.technology
  if not registered then return nil end
  for name,proto in pairs(registered) do
    if not proto.hidden then
      for _,effect in pairs(proto.effects or {}) do
        if effect.type=="unlock-space-location" and effect.space_location then
          local entries=catalog[effect.space_location]
          if not entries then
            entries={}
            catalog[effect.space_location]=entries
          end
          entries[#entries+1]=name
        end
      end
    end
  end
  unlock_techs=catalog
  return catalog
end
function M.discovery_index(force)
  local indexed={}
  local technologies=force and force.technologies or {}
  local catalog=world_unlocks()
  if catalog then
    for world,names in pairs(catalog) do
      for _,name in ipairs(names) do
        local tech=technologies[name]
        if tech and tech.prototype and not tech.prototype.hidden then
          local previous=indexed[world]
          if not previous or (tech.researched and not previous.researched) then
            indexed[world]=tech
          end
        end
      end
    end
  else
    for _,tech in pairs(technologies) do
      local proto=tech.prototype
      if proto and not proto.hidden then
        for _,effect in pairs(proto.effects or {}) do
          if effect.type=="unlock-space-location" and effect.space_location then
            local previous=indexed[effect.space_location]
            if not previous or (tech.researched and not previous.researched) then
              indexed[effect.space_location]=tech
            end
          end
        end
      end
    end
  end
  return indexed
end
function M.context(force)
  return {discoveries=M.discovery_index(force),nexus=trials.snapshot(force)}
end
local function technology(force,quest,context)
  local t
  if quest.world then
    local index=context and context.discoveries or M.discovery_index(force)
    t=index[quest.world]
  else
    t=force and force.technologies and force.technologies[quest.tech]
  end
  if not t then return nil end
  local proto=t.prototype
  -- The opener is the one spoiler-safe signpost a fresh save MUST retain.
  -- Other mods can hide or delay Automation's research prototype on startup.
  -- Keep that source technology inspectable without inventing completion.
  if quest.id~="first-signal" and proto and proto.hidden
    and not t.researched then return nil end
  return t
end
function M.available(force,quest,context)
  if not technology(force,quest,context) then return false end
  if quest.boss then
    return (context or M.context(force)).nexus~=nil
  end
  return true
end
function M.complete(force,quest,context)
  -- A 2.1.57 victory must keep the new retrospective research objective
  -- complete, even though that technology did not exist when it won.
  if quest.id=="convergence-ignition-research"
    and convergence.completed(force,"victory") then return true end
  if quest.convergence then
    return convergence.completed(force,quest.convergence)
  end
  if quest.boss then
    local snapshot=(context or M.context(force)).nexus
    return M.available(force,quest,context)
      and trials.defeated(snapshot,quest.boss)
  end
  local t=technology(force,quest,context)
  return t~=nil and t.researched==true
end

-- Capture first clear without changing quest state or scanning all research
-- prototypes on every frame. Real Factorio ticks, not wall-clock timestamps.
function M.record_chapter_completions(force,historical,tick)
  if not (force and force.index and force.technologies) then return false end
  local context=M.context(force)
  return chapter_timing.observe(force,defs.quests,
    function(quest) return M.available(force,quest,context) end,
    function(quest) return M.complete(force,quest,context) end,
    historical,tick or (game and game.tick or 0),
    function(quest)
      local act=journal_acts.for_quest(quest)
      return act and act.key
    end)
end
function M.initialize_chapter_completions()
  -- Old saves cannot reveal the minute when a finished objective was earned.
  local historical=(game and game.tick or 0)>0
  for _,force in pairs(game.forces or {}) do
    if force.name~="enemy" and force.name~="neutral" then
      M.record_chapter_completions(force,historical)
    end
  end
end
function M.forces_merged(event)
  chapter_timing.forces_merged(event)
  local force=event and (event.destination or
    (game and game.forces[event.destination_index]))
  if force then M.record_chapter_completions(force,false) end
end
local function completion_caption(tick,kind)
  if tick==nil then return nil end
  if tick==false then return L(kind.."-time-earlier") end
  return L(kind.."-time-recorded",chapter_timing.format(tick))
end

function M.state(force,quest,context)
  if not M.available(force,quest,context) then return "unavailable" end
  if M.complete(force,quest,context) then return "complete" end
  if quest.id=="first-signal" then
    local native=technology(force,quest,context)
    -- Always SHOW the bootstrap mission, but don't mark it "ready"
    -- if a source mod actually disabled or prerequisite-gated its research.
    if not native or native.enabled==false
      or (native.prototype and native.prototype.hidden) then
      return "locked"
    end
    for _,required in pairs(native.prerequisites or {}) do
      if not required.researched then return "locked" end
    end
  end
  for _,required in ipairs(quest.requires or {}) do
    local prior=defs.by_id[required]
    -- Source content not present in this modpack is not a phantom
    -- blocker. Its own technology controls actual research prerequisites.
    if prior and M.available(force,prior,context)
      and not M.complete(force,prior,context) then return "locked" end
  end
  return "active"
end
-- One shared runtime map setting, on by default in the actual mod settings.
-- Tests without Factorio settings retain the legacy visibility model.
function M.hide_spoilers()
  local option=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  return option and option.value==true or false
end
function M.journal_visible(force,quest,context,known_state)
  if known_state=="unavailable" or
    not M.available(force,quest,context) then return false end
  -- The very first mission is onboarding, not a spoiler. Show it even
  -- when its native Automation research has unmet source prerequisites.
  -- Every later mission still obeys the normal spoiler rules.
  if quest.id=="first-signal" then return true end
  if not M.hide_spoilers() or M.complete(force,quest,context) then
    return true
  end
  if (known_state or M.state(force,quest,context))~="active" then
    return false
  end
  local tech=technology(force,quest,context)
  if tech then
    if tech.enabled==false then return false end
    for _,required in pairs(tech.prerequisites or {}) do
      if not required.researched then return false end
    end
  end
  return true
end
function M.summary(force,context)
  local completed,total,active=0,0,0
  context=context or M.context(force)
  for _,q in ipairs(defs.quests) do
    local state=M.state(force,q,context)
    if M.journal_visible(force,q,context,state) and not q.optional then
      total=total+1
      if state=="complete" then completed=completed+1
      elseif state=="active" then active=active+1 end
    end
  end
  return completed,total,active
end
function M.next_quest(force,context)
  context=context or M.context(force)
  local suggested=M.guidance(force,context)
  if suggested.primary and M.journal_visible(force,suggested.primary.quest,context)
    then return suggested.primary.quest end
  -- A blocked objective can still be inspected, but is not called ready.
  for _,q in ipairs(defs.quests) do
    if M.state(force,q,context)=="active"
      and M.journal_visible(force,q,context) then return q end
  end
  for _,q in ipairs(defs.quests) do
    if M.journal_visible(force,q,context) then return q end
  end
end
local function state_matches_filter(state,filter)
  if state=="unavailable" then return false end
  if filter=="ready" then return state=="active" end
  if filter=="unfinished" then return state~="complete" end
  if filter=="done" then return state=="complete" end
  return true
end
function M.show_in_filter(force,quest,filter,context)
  return M.journal_visible(force,quest,context)
    and state_matches_filter(M.state(force,quest,context),filter)
end

-- Calculate the visible campaign once per redraw. The navigator used to
-- walk all quests for every chapter and repeat most of these state checks.
local quests_by_chapter={}
local quest_order={}
for _,chapter in ipairs(defs.chapters) do quests_by_chapter[chapter.id]={} end
for index,quest in ipairs(defs.quests) do
  quest_order[quest.id]=index
  local list=quests_by_chapter[quest.chapter]
  if list then list[#list+1]=quest end
end
function M.view_status(force,context)
  context=context or M.context(force)
  local view={states={},chapters={},done=0,total=0,ready=0}
  for _,chapter in ipairs(defs.chapters) do
    local result={quests={},completed=0,total=0}
    for _,quest in ipairs(quests_by_chapter[chapter.id] or {}) do
      local state=M.state(force,quest,context)
      local revealed=M.journal_visible(force,quest,context,state)
      view.states[quest.id]=revealed and state or "unavailable"
      if revealed then
        result.quests[#result.quests+1]=quest
        result.total=result.total+1
        if not quest.optional then view.total=view.total+1 end
        if state=="complete" then
          result.completed=result.completed+1
          if not quest.optional then view.done=view.done+1 end
        elseif state=="active" and not quest.optional then
          view.ready=view.ready+1
        end
      end
    end
    -- Later source-mod catalogs should not split an act into repeated headers.
    table.sort(result.quests,function(a,b)
      local ao,bo=journal_acts.order(a),journal_acts.order(b)
      if ao~=bo then return ao<bo end
      return quest_order[a.id]<quest_order[b.id]
    end)
    view.chapters[chapter.id]=result
  end
  return view
end
-- Reuse the view already calculated for rendering. This reads live
-- ForceTechnology prerequisites without storing a second progression state.
function M.guidance(force,context,view)
  context=context or M.context(force)
  view=view or M.view_status(force,context)
  return guidance.plan(view.states,function(quest)
    return technology(force,quest,context)
  end)
end

-- Dimensions are in Factorio GUI units, after the player's UI scale.
-- Explicitly budget both columns to prevent the horizontal scroll bars
-- caused by oversized localized labels and autosizing buttons.
function M.layout(resolution,scale)
  scale=math.max(0.5,scale or 1)
  local screen_w=math.floor((resolution and resolution.width or 1600)/scale)
  local screen_h=math.floor((resolution and resolution.height or 900)/scale)
  local width=math.min(1190,math.max(420,screen_w-52))
  local height=math.min(930,math.max(390,screen_h-64))
  local compact=width<1020 or height<660
  -- Below this width, two simultaneous columns make the dossier unreadable.
  -- Present a full-size document and switch to its index on demand.
  local single_column=width<740
  local rail=math.min(compact and 282 or 302,
    math.max(228,math.floor(width*(compact and .30 or .255))))
  local reader=width-rail-43
  return {width=width,height=height,rail=rail,reader=reader,
    body=math.max(200,height-(compact and 183 or 204)),
    compact=compact,single_column=single_column}
end
local function label(parent,caption)
  return parent.add{type="label",caption=caption}
end
local function wrap(parent,caption,width)
  local element=label(parent,caption)
  element.style.single_line=false
  element.style.horizontally_stretchable=true
  if width then element.style.maximal_width=width end
  return element
end
local function tint(element,color)
  element.style.font_color=color
  return element
end
local function subtitle(parent,key,width,theme)
  local item=label(parent,L(key))
  item.style.font="default-bold"
  item.style.font_color=theme and theme.soft or COLOR.muted
  if width then item.style.maximal_width=width end
  return item
end
-- A fine, chapter-colored rule that uses Factorio's built-in progressbar
-- texture. This needs no texture atlas or custom rendering on each tick.
local function accent_rule(parent,theme,width,thickness)
  local rule=parent.add{type="progressbar",value=1}
  rule.style.width=math.max(50,width)
  rule.style.height=thickness or 3
  rule.style.color=theme.primary
  return rule
end
-- Dense but legible folio section heads: a small number of native GUI
-- strokes make the chapter distinct without new atlases or paint events.
local function dossier_heading(parent,key,theme,width)
  local heading=parent.add{type="flow",direction="horizontal"}
  heading.style.horizontal_spacing=9
  heading.style.vertical_align="center"
  local title=subtitle(heading,key,width)
  title.style.font_color=COLOR.muted
  return heading
end
local function section(parent,key,caption,width,theme)
  local block=parent.add{type="flow",direction="vertical"}
  block.style.horizontally_stretchable=true
  block.style.vertical_spacing=5
  dossier_heading(block,key,theme,width)
  if caption then
    local copy=wrap(block,caption,width)
    copy.style.font_color=COLOR.ink
  end
  return block
end
local function wheel_pane(parent,name,width,height)
  local pane=parent.add{type="scroll-pane",name=name,
    horizontal_scroll_policy="never",
    vertical_scroll_policy=name=="razi_journal_navigation"
      and "auto" or "dont-show-but-allow-scrolling"}
  pane.style.width=width
  pane.style.height=math.max(120,height)
  pane.style.horizontally_squashable=true
  pane.style.vertically_squashable=true
  return pane
end
local function chapter_index(id)
  for i,chapter in ipairs(defs.chapters) do
    if chapter.id==id then return i end
  end
  return 1
end
local function select_quest(force,p,context,plan)
  local selected=p.selected and defs.by_id[p.selected]
  if selected and M.journal_visible(force,selected,context) then
    if p.chapter==nil then p.chapter=selected.chapter end
    return selected
  end
  selected=plan and plan.primary and plan.primary.quest
    or M.next_quest(force,context)
  p.selected=selected and selected.id or nil
  p.chapter=selected and selected.chapter or false
  return selected
end

-- All icons are resolved from the installed Factorio prototypes, not guessed
-- mod-specific assets. Keep work confined to visible GUI construction.
local function sprite_if_valid(path)
  if not path then return nil end
  if helpers and helpers.is_valid_sprite_path and
    not helpers.is_valid_sprite_path(path) then return nil end
  return path
end
local function quest_art(force,quest,context)
  if quest.world then
    local image=sprite_if_valid("space-location/"..quest.world)
    if image then return image end
  end
  local tech=technology(force,quest,context)
  return tech and sprite_if_valid("technology/"..tech.name)
    or "razi-journal-book-icon"
end
local function matches_query(quest,query)
  if not query or query=="" then return true end
  local corpus=(quest.id.." "..quest.chapter.." "..(quest.tech or "")
    .." "..(quest.world or "").." "..(quest.site or "")
    .." "..(quest.recipe or "").." "..(quest.machine or "")):lower():gsub("[-_]"," ")
  for word in query:lower():gsub("[-_]"," "):gmatch("%S+") do
    if not corpus:find(word,1,true) then return false end
  end
  return true
end
M.matches_query=matches_query

local function draw_gallery(parent,key,entries,width,max_items,theme)
  if #entries==0 then return end
  local block=parent.add{type="flow",direction="vertical"}
  block.style.vertical_spacing=5
  subtitle(block,key,width,theme)
  local columns=math.max(1,math.min(4,math.floor(width/215)))
  local card_width=math.max(180,math.floor((width-(columns-1)*7)/columns)-3)
  local grid=block.add{type="table",column_count=columns}
  grid.style.horizontal_spacing=7
  grid.style.vertical_spacing=7
  for i=1,math.min(max_items,#entries) do
    local entry=entries[i]
    local card=grid.add{type="flow",direction="horizontal"}
    card.style.width=card_width
    card.style.padding=4
    card.style.horizontal_spacing=7
    icons.sprite(card,entry.sprite,"gallery",entry.tooltip or entry.name)
    local caption=wrap(card,entry.name,card_width-54)
    caption.style.font_color=theme and theme.soft
      or {r=.86,g=.9,b=.94}
  end
  if #entries>max_items then
    wrap(block,L("more-gallery-items",tostring(#entries-max_items)),width)
  end
end
-- Exact recipe illustration for Razi's source-proven alternate processes.
-- Reads one recipe by ID only while its quest is viewed: no global scans.
local function recipe_gallery(parent,quest,native,width,theme)
  if not (quest.site and native and prototypes
      and prototypes.recipe) then return end
  local recipe=preview.recipe(quest,native,prototypes.recipe)
  if not recipe then return end
  local function cards(entries)
    local output={}
    for _,entry in ipairs(entries or {}) do
      local name=entry.name
      local kind=entry.type=="fluid" and "fluid" or "item"
      local proto=prototypes[kind] and prototypes[kind][name]
      local path=name and sprite_if_valid(kind.."/"..name)
      if proto and path then
        local caption={"",proto.localised_name,preview.quantity(entry)}
        output[#output+1]={sprite=path,name=caption,
          tooltip=caption}
      end
    end
    return output
  end
  local materials=cards(recipe.ingredients)
  local products=cards(recipe.products)
  if #materials==0 or #products==0 then return end
  local panel=parent.add{type="frame",direction="vertical",
    style="inside_deep_frame"}
  panel.style.width=width
  panel.style.padding=10
  subtitle(panel,"factory-diagram",width-26,theme)
  if theme then accent_rule(panel,theme,math.min(width-26,168),3) end
  wrap(panel,L("site-advisory",preview.workshop_fallback(quest,prototypes)),width-26)
  -- Existing machines and the original planet can be inspected before
  -- researching the optional production alternative.
  if quest.machine and prototypes.item and prototypes.item[quest.machine] then
    local machine=prototypes.item[quest.machine]
    local art=sprite_if_valid("item/"..quest.machine)
    if art then
      draw_gallery(panel,"factory-equipment",{
        {sprite=art,name=machine.localised_name,tooltip=machine.localised_name}
      },width-26,1,theme)
    end
  end
  draw_gallery(panel,"factory-imports",materials,width-26,10,theme)
  draw_gallery(panel,"factory-outputs",products,width-26,5,theme)
  wrap(panel,L(quest.optional and "factory-optional-note"
    or "factory-source-owned"),width-26)
end

local function show_player_option(player,name)
  local personal=settings and settings.get_player_settings
    and settings.get_player_settings(player)
  local entry=personal and personal[name]
  return not entry or entry.value~=false
end

local function render_tracker(player)
  local area=player.gui.left
  local old=area[TRACKER]
  if old and old.valid then old.destroy() end
  local p=pref(player.index)
  if not p.tracker or not show_player_option(player,"razi-journal-show-tracker") then return end
  local context=M.context(player.force)
  local quest=p.pinned and defs.by_id[p.pinned]
  if not quest or not M.journal_visible(player.force,quest,context) then
    quest=M.next_quest(player.force,context)
    p.pinned=quest and quest.id or nil
  end
  if not quest then return end
  local theme=themes.get(quest.chapter)
  local frame=area.add{type="frame",name=TRACKER,direction="vertical",
    caption=L("tracker-title")}
  frame.style.maximal_width=286
  frame.style.padding=9
  local chapter=frame.add{type="flow",direction="horizontal"}
  chapter.style.horizontal_spacing=7
  icons.sprite(chapter,themes.icon(quest.chapter),"tracker_chapter")
  local chapter_text=wrap(chapter,{"journal-chapter."..quest.chapter},225)
  chapter_text.style.font="default-bold"
  chapter_text.style.font_color=theme.primary
  accent_rule(frame,theme,108,2)
  local line=frame.add{type="flow",direction="horizontal"}
  line.style.horizontal_spacing=7
  icons.sprite(line,quest_art(player.force,quest,context),"tracker_quest")
  local heading=line.add{type="label",style="clickable_label",
    caption={"journal-title."..quest.id},
    tags={razi_journal_action="tracker-open"}}
  heading.style.single_line=false
  heading.style.maximal_width=195
  heading.style.font="default-bold"
  local done=M.complete(player.force,quest,context)
  local signal=wrap(frame,L(quest.boss
    and (done and "tracker-boss-done" or "tracker-boss-pending")
    or (done and "tracker-done" or "tracker-pending")),245)
  signal.style.font_color=done and COLOR.green or COLOR.muted
  -- A pinned goal should say what is actually blocking it, not just
  -- "pending". Use the same source-backed checklist as the dossier.
  if not done then
    local tech=technology(player.force,quest,context)
    local live=objectives.snapshot(quest,tech,M.state(player.force,quest,context),{
      available=function(id)
        local required=defs.by_id[id]
        return required and M.available(player.force,required,context) or false
      end,
      visible=function(id)
        local required=defs.by_id[id]
        return required and M.journal_visible(player.force,required,context) or false
      end,
      complete=function(id)
        local required=defs.by_id[id]
        return required and M.complete(player.force,required,context) or false
      end,
      current_research=player.force.current_research,
      research_progress=player.force.research_progress
    })
    if live.next_step then
      local step=live.next_step
      local kind=step.kind=="goal" and live.kind or step.kind
      local next_action=wrap(frame,L("tracker-next",
        L("mission-step-"..kind,step.name)),253)
      next_action.style.font_color=theme.soft
    end
    if live.research_percent~=nil then
      local research=label(frame,L("mission-research-progress",
        tostring(live.research_percent)))
      research.style.font_color=COLOR.teal
    end
  end
end
M.render_tracker=render_tracker
local function render_details(parent,player,quest,p,context,size,view)
  local panel=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  panel.style.width=size.reader
  panel.style.height=size.body
  panel.style.padding=11
  local inner=size.reader-38
  local status=M.state(player.force,quest,context)
  local theme=themes.get(quest.chapter)
  -- One dossier masthead instead of five independent header strips.
  -- The story has one title; chapter, file ID and live state are metadata.
  local masthead=panel.add{type="flow",direction="horizontal"}
  masthead.style.vertical_align="center"
  masthead.style.horizontal_spacing=8
  icons.sprite(masthead,themes.icon(quest.chapter),"chapter_seal",
    {"journal-chapter."..quest.chapter})
  local file_meta=masthead.add{type="flow",direction="vertical"}
  file_meta.style.vertical_spacing=1
  local chapter_intro=label(file_meta,{"journal-chapter."..quest.chapter})
  chapter_intro.style.font="default-bold"
  chapter_intro.style.font_color=theme.soft
  local serial=label(file_meta,L("dossier-index",
    string.format("%02d",chapter_index(quest.chapter))))
  serial.style.font_color=COLOR.quiet
  local masthead_space=masthead.add{type="empty-widget"}
  masthead_space.style.horizontally_stretchable=true
  local status_label=label(masthead,L("status-"..status))
  status_label.style.font="default-bold"
  status_label.style.font_color=status=="complete" and COLOR.green
    or status=="active" and COLOR.amber or COLOR.muted

  local hero=panel.add{type="flow",direction="horizontal"}
  hero.style.horizontal_spacing=11
  hero.style.vertical_align="center"
  icons.sprite(hero,quest_art(player.force,quest,context),"quest_hero")
  local hero_text=hero.add{type="flow",direction="vertical"}
  hero_text.style.vertical_spacing=2
  local hero_title=wrap(hero_text,{"journal-title."..quest.id},inner-68)
  hero_title.style.font="heading-2"
  hero_title.style.font_color=COLOR.ink
  local milestone_time=completion_caption(
    chapter_timing.get(player.force,"milestones",quest.id),"milestone")
  if status=="complete" and milestone_time then
    local stamp=wrap(hero_text,milestone_time,inner-68)
    stamp.style.font_color=COLOR.green
    stamp.tooltip=L("milestone-time-explanation")
  end
  if not size.compact then
    local mood=wrap(hero_text,{"journal-mood."..quest.chapter},inner-68)
    mood.style.font_color=COLOR.muted
  end
  local folio_link=panel.add{type="label",style="clickable_label",
    caption=L("chapter-cover-open"),
    tags={razi_journal_action="chapter-dossier",id=quest.chapter},
    tooltip=L("chapter-cover-tooltip")}
  folio_link.style.font_color=theme.soft
  accent_rule(panel,theme,math.min(92,inner),2)
  -- Dossier actions now scroll with the reading sheet, instead of
  -- permanently stealing vertical space at small resolutions.
  local content_height=size.body-(size.compact and 124 or 148)
  local scroll=wheel_pane(panel,"razi_journal_reading",inner,content_height)
  scroll.tags={razi_scroll_context=quest.id}
  local text_width=inner-18
  local prose=scroll.add{type="flow",name="razi_journal_prose",direction="vertical"}
  prose.style.width=text_width
  prose.style.vertical_spacing=9
  local native=technology(player.force,quest,context)
  local force=player.force
  -- Read each milestone through the same native state as the index. No
  -- artificial crafting counters, discovered worlds or stored completion.
  local plan=objectives.snapshot(quest,native,status,{
    available=function(id)
      local required=defs.by_id[id]
      return required and M.available(force,required,context) or false
    end,
    visible=function(id)
      local required=defs.by_id[id]
      return required and M.journal_visible(force,required,context) or false
    end,
    complete=function(id)
      local required=defs.by_id[id]
      return required and M.complete(force,required,context) or false
    end,
    tech_for_quest=function(id)
      local required=defs.by_id[id]
      -- World objectives may use an alternate source technology in the
      -- installed modpack. Do not guess that technology from a world ID.
      return required and not (required.world or required.boss or
        required.convergence) and required.tech or nil
    end,
    quest_for_tech=function(name)
      for _,candidate in ipairs(quests_for_technology[name] or {}) do
        if M.journal_visible(force,candidate,context) then
          return candidate.id
        end
      end
    end,
    current_research=force.current_research,
    research_progress=force.research_progress
  })
  local mission=prose.add{type="frame",name="razi_journal_mission_plan",
    direction="vertical",style="razi_journal_callout"}
  mission.style.width=text_width
  mission.style.padding=size.compact and 8 or 10
  local mission_header=mission.add{type="flow",direction="horizontal"}
  mission_header.style.horizontal_spacing=8
  mission_header.style.vertical_align="center"
  local mission_heading=label(mission_header,L("mission-plan"))
  mission_heading.style.font="default-bold"
  mission_heading.style.font_color=theme.soft
  local mission_space=mission_header.add{type="empty-widget"}
  mission_space.style.horizontally_stretchable=true
  if plan.requirements>0 then
    local count=label(mission_header,L("mission-stage-count",
      tostring(plan.satisfied),tostring(plan.requirements)))
    count.style.font_color=COLOR.muted
  end
  -- Always display the *actual* success criterion, even if a
  -- long blocker list collapses below the first three pending steps.
  local finish=wrap(mission,L("mission-finish-line",
    L("mission-step-"..plan.kind,plan.target)),text_width-28)
  finish.style.font_color=COLOR.muted
  -- The top line is always the next verifiable action, never a made-up
  -- logistical task. For bosses and deliveries the source owns the result.
  if plan.finished then
    local done=wrap(mission,L("mission-complete"),text_width-28)
    done.style.font_color=COLOR.green
  elseif plan.next_step then
    local step=plan.next_step
    local key=step.kind=="goal" and plan.kind or step.kind
    local next_caption=L("mission-next",
      L("mission-step-"..key,step.name))
    local action
    if step.link then
      action=mission.add{type="label",style="clickable_label",
        caption=next_caption,tooltip=L("open-prerequisite"),
        tags={razi_journal_action="guidance-select",id=step.link}}
      action.style.single_line=false
      action.style.maximal_width=text_width-28
    else
      action=wrap(mission,next_caption,text_width-28)
    end
    action.style.font="default-bold"
    action.style.font_color=COLOR.ink
  end
  if plan.requirements>0 then
    local readiness=mission.add{type="progressbar",
      value=plan.satisfied/plan.requirements}
    readiness.style.width=math.min(245,text_width-34)
    readiness.style.height=3
    readiness.style.color=theme.primary
  end
  if plan.disabled and not plan.finished then
    local warning=wrap(mission,L("mission-disabled"),text_width-28)
    warning.style.font_color=COLOR.amber
  end
  -- Allocate this tiny research strip once; a 120-tick reader-only
  -- update keeps it alive without resetting the dossier scroll position.
  local research_row=mission.add{type="flow",name="razi_journal_research_row",
    direction="vertical"}
  research_row.style.vertical_spacing=3
  research_row.visible=plan.research_percent~=nil
  local running=research_row.add{type="label",
    name="razi_journal_research_percent",
    caption=L("mission-research-progress",
      tostring(plan.research_percent or 0))}
  running.style.font_color=COLOR.teal
  local research_bar=research_row.add{type="progressbar",
    name="razi_journal_research_progress",
    value=(plan.research_percent or 0)/100}
  research_bar.style.width=math.min(240,text_width-32)
  research_bar.style.height=4
  research_bar.style.color=COLOR.teal
  -- Next Action and Success Condition are already visible above these rows.
  -- An expanded checklist belongs to one dossier, not every quest the
  -- player visits afterward.
  local goal_expanded=p.goal_expanded and p.goal_expanded_quest==quest.id
  local shown=objectives.visible_rows(plan,goal_expanded,
    size.compact and 1 or 2)
  local checklist=mission.add{type="flow",direction="vertical"}
  checklist.style.vertical_spacing=4
  for _,row in ipairs(shown) do
    local item=checklist.add{type="flow",direction="horizontal"}
    item.style.horizontal_spacing=8
    item.style.vertical_align="center"
    local marker=label(item,row.done and "✓" or "○")
    marker.style.font_color=row.done and COLOR.green
      or row.kind=="goal" and theme.primary or COLOR.amber
    marker.tooltip=L(row.done and "mission-goal-status-done"
      or "mission-goal-status-open")
    local kind=row.kind=="goal" and plan.kind or row.kind
    local caption=L("mission-step-"..kind,row.name)
    if row.link then
      local link=item.add{type="label",style="clickable_label",
        caption=caption,tooltip=L("open-prerequisite"),
        tags={razi_journal_action="guidance-select",id=row.link}}
      link.style.single_line=false
      link.style.maximal_width=text_width-64
      link.style.font_color=row.done and COLOR.muted or COLOR.ink
    else
      local note=wrap(item,caption,text_width-64)
      note.style.font_color=row.done and COLOR.muted or COLOR.ink
    end
  end
  if goal_expanded or #plan.rows>1 then
    local toggle=mission.add{type="label",style="clickable_label",
      caption=L(goal_expanded and "mission-collapse" or "mission-expand",
        tostring(#plan.rows)),
      tags={razi_journal_action="mission-details",id=quest.id}}
    toggle.style.font_color=theme.soft
  end
  -- A journal is primarily a story. After the live objective and its
  -- immediate blockers, let the player read the entry before secondary
  -- route previews, industry notes or production analytics.
  section(prose,"story-heading",{"journal-story."..quest.id},text_width,theme)
  -- Direct campaign handoffs share the force snapshot with the chapter rail.
  local next_steps=guidance.followups(quest.id,view and view.states,3)
  if #next_steps>0 then
    local forecast=prose.add{type="flow",direction="vertical"}
    forecast.style.width=text_width
    forecast.style.vertical_spacing=4
    dossier_heading(forecast,"next-steps-heading",theme,text_width)
    for _,step in ipairs(next_steps) do
      local line=forecast.add{type="flow",direction="horizontal"}
      line.style.horizontal_spacing=8
      icons.sprite(line,quest_art(player.force,step.quest,context),"quest_row")
      local note=line.add{type="flow",direction="vertical"}
      note.style.vertical_spacing=1
      local link=note.add{type="label",style="clickable_label",
        caption={"journal-title."..step.quest.id},
        tags={razi_journal_action="guidance-select",id=step.quest.id}}
      link.style.single_line=false
      link.style.maximal_width=text_width-80
      if step.state~="complete" then
        tint(wrap(note,L("next-step-"..step.state),text_width-80),theme.soft)
      end
    end
  end
  -- The link is informational and never turns a researched milestone
  -- into a claim that freight actually shipped or a factory is running.
  local cargo_id=cargo_catalog.chain_for_quest(quest.id)
  if cargo_id and cargo_catalog.is_installed(player.force,cargo_id) then
    local bridge=prose.add{type="flow",direction="vertical"}
    bridge.style.width=text_width
    bridge.style.vertical_spacing=4
    subtitle(bridge,"cargo-bridge-heading",text_width-26,theme)
    wrap(bridge,L("cargo-bridge-description"),text_width-26)
    local link=bridge.add{type="button",caption=L("cargo-bridge-open"),
      tags={razi_journal_action="open-cargo",id=quest.id}}
    link.tooltip=L("cargo-bridge-tooltip")
  end
  if quest.convergence or quest.id=="convergence-commission"
    or quest.id=="convergence-synchronization" then
    local bridge=prose.add{type="flow",direction="vertical"}
    bridge.style.width=text_width
    bridge.style.vertical_spacing=4
    wrap(bridge,L("convergence-codex-description"),text_width-26)
    bridge.add{type="button",caption=L("convergence-codex-open"),
      tags={razi_journal_action="open-convergence",id=quest.id}}
  end
  -- Source-backed operational context; not an extra research requirement.
  local brief=industrial_briefs.for_quest(quest)
  if brief then
    section(prose,"industrial-brief-heading",
      {"razi-industries-brief."..brief},text_width,theme)
  end
  -- Field assignments are advisory, not research, physical exploration or
  -- shipment completion. Follow-ups must be actual, spoiler-visible Codex IDs.
  local charter=industrial_briefs.charter_for_quest(quest)
  if charter then
    local field=prose.add{type="flow",direction="vertical"}
    field.style.width=text_width
    field.style.vertical_spacing=5
    subtitle(field,"field-assignment-heading",text_width-26,theme)
    wrap(field,{"razi-planet-charter."..charter},text_width-26)
    local handoffs=industrial_briefs.visible_related(quest,defs.by_id,
      function(target)
        return M.journal_visible(force,target,context)
      end,2)
    if #handoffs>0 then
      local heading=wrap(field,L("field-assignment-followups"),
        text_width-26,true)
      heading.style.font_color=theme.soft
      for _,target in ipairs(handoffs) do
        local state=M.state(force,target,context)
        local next_link=field.add{type="label",style="clickable_label",
          caption={"",{"journal-title."..target.id},"  /  ",
            L("next-step-"..state)},
          tooltip=L("open-prerequisite"),
          tags={razi_journal_action="guidance-select",id=target.id}}
        next_link.style.single_line=false
        next_link.style.maximal_width=text_width-26
        next_link.style.font_color=state=="complete" and COLOR.green
          or theme.soft
      end
    end
    local advice=wrap(field,L("field-assignment-advisory"),text_width-26)
    advice.style.font_color=COLOR.quiet
  end
  -- Existing Vespera dossiers can discuss actually configured neighboring
  -- lanes. The shared snapshot hides undiscovered neighbors when spoiler
  -- protection is ON; no invented shipment or catapult-building state.
  if charter then
    local network=catapults.snapshot(player.force)
    if network.installed and network.enabled then
      local local_lanes=catapults.for_world(network,quest.id)
      if #local_lanes>0 then
        local lanes=prose.add{type="flow",direction="vertical"}
        lanes.style.width=text_width
        lanes.style.vertical_spacing=4
        subtitle(lanes,"catapult-local-heading",text_width-26,theme)
        for _,link in ipairs(local_lanes) do
          local neighbor=link.source==quest.id and link.target or link.source
          local world=prototypes and (
            (prototypes.space_location and prototypes.space_location[neighbor])
            or (prototypes.planet and prototypes.planet[neighbor]))
          wrap(lanes,L("catapult-local-neighbor",
            world and world.localised_name or neighbor,
            L(link.state=="researched" and "catapult-local-surveyed"
              or "catapult-local-pending")),text_width-26)
        end
        tint(wrap(lanes,L("catapult-local-note"),text_width-26),theme.soft)
      end
    end
  end
  -- The practical guidance complements the chapter's individual account;
  -- shared background still lives on the chapter briefing page.
  section(prose,"tip-heading",{"journal-tip."..quest.id},text_width,theme)
  -- The human accounts are useful where their actual milestone was
  -- completed, not just buried in the Archive's growing collection.
  -- No link or future title is shown before source quest completion.
  if M.complete(player.force,quest,context) then
    for _,record in ipairs(records) do
      if record.series=="field" and record.unlock==quest.id then
        local letter=prose.add{type="flow",direction="vertical"}
        letter.style.vertical_spacing=5
        subtitle(letter,"field-citation-heading",text_width-26,theme)
        local button=letter.add{type="button",
          caption={"journal-record-title."..record.id},
          tooltip=L("field-citation-tooltip"),
          tags={razi_journal_action="record",id=record.id}}
        button.style.minimal_width=math.min(210,text_width-26)
        break
      end
    end
  end
  -- Research costs and unlocks belong to Factorio's technology screen.
  -- The Journal keeps only the practical, source-backed workshop diagram.
  if native then
    recipe_gallery(prose,quest,native,text_width,theme)
  end
  local forecast=weather.for_quest(quest)
  if forecast then
    local sky=section(prose,"weather-heading",
      {"journal-weather."..forecast.world},text_width,theme)
    tint(wrap(sky,L(forecast.enabled and "weather-active"
      or "weather-inactive"),text_width),
      forecast.enabled and {r=.54,g=.85,b=.75} or {r=.72,g=.74,b=.79})
  end

  -- Never let the long Nexus and pin actions overflow narrow readers.
  local actions=prose.add{type="table",name="razi_journal_actions",
    column_count=text_width<350 and 1 or text_width<640 and 2 or 4}
  actions.style.horizontal_spacing=8
  actions.style.vertical_spacing=6
  if quest.boss then
    actions.add{type="button",caption=L("nexus-open-codex"),
      tags={razi_journal_action="nexus-codex",id=quest.boss}}
  end
  local pinned=p.tracker and p.pinned==quest.id
  actions.add{type="button",style="razi_journal_action_button",
    name="razi_journal_pin_button",caption=L(pinned
    and "tracker-hide" or "tracker-show"),
    tags={razi_journal_action="pin",id=quest.id}}
  actions.add{type="button",style="razi_journal_action_button",
    caption=L("previous-in-chapter"),
    tags={razi_journal_action="previous-in-chapter"}}
  actions.add{type="button",style="razi_journal_action_button",
    caption=L("next-in-chapter"),
    tags={razi_journal_action="next-in-chapter"}}
end


-- One shared section renderer for every chapter, including Calidus.
local function chapter_act(parent,act,theme,width,force)
  if not act then return end
  local divider=parent.add{type="frame",name="razi_journal_act_"..
    act.chapter.."_"..act.id,direction="vertical",
    style="razi_journal_phase_divider"}
  divider.style.width=width
  divider.style.padding=7
  accent_rule(divider,theme,math.min(76,width-22),2)
  local name=label(divider,{"",string.format("%02d",act.order),
    " / ",journal_acts.caption(act)})
  name.style.font="default-bold"
  name.style.font_color=theme.soft
  name.style.single_line=false
  name.style.maximal_width=math.max(100,width-22)
  local stamped=completion_caption(
    chapter_timing.get(force,"phases",act.key),"phase")
  local stamp=divider.add{type="label",name="razi_journal_act_stamp",
    caption=stamped or ""}
  stamp.visible=stamped~=nil
  stamp.style.font_color=COLOR.quiet
end

-- A source-backed frontispiece for each chapter. It is a *view* of the
-- existing milestones, never a separate quest or a second progress store.
-- Only the chosen page is built on demand. No tick work, custom textures,
-- temporary render objects, or research mutations.
local function render_chapter_cover(parent,player,p,context,size,view)
  local chapter=p.chapter and view.chapters[p.chapter]
  if not chapter or (M.hide_spoilers() and #chapter.quests==0) then
    return false
  end
  local theme=themes.get(p.chapter)
  local width=size.reader
  local inner=width-38
  local panel=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  panel.style.width=width
  panel.style.height=size.body
  panel.style.padding=12
  local labelline=panel.add{type="flow",direction="horizontal"}
  labelline.style.horizontal_spacing=7
  local over=label(labelline,L("chapter-cover-eyebrow",
    string.format("%02d",chapter_index(p.chapter))))
  over.style.font="default-bold"
  over.style.font_color=theme.primary
  local heading=panel.add{type="flow",direction="horizontal"}
  heading.style.horizontal_spacing=10
  heading.style.vertical_align="center"
  icons.sprite(heading,themes.icon(p.chapter),"chapter_seal")
  local cover_title=wrap(heading,{"journal-chapter."..p.chapter},inner-52)
  cover_title.style.font="heading-2"
  cover_title.style.font_color=COLOR.ink
  accent_rule(panel,theme,math.min(112,inner),2)
  local mood=wrap(panel,{"journal-mood."..p.chapter},inner)
  mood.style.font="default-bold"
  mood.style.font_color=theme.soft
  local line=panel.add{type="flow",direction="horizontal"}
  line.style.horizontal_spacing=9
  local count=label(line,L("chapter-progress-short",
    tostring(chapter.completed),tostring(chapter.total)))
  count.style.font="default-bold"
  count.style.font_color=COLOR.muted
  local stamped=completion_caption(
    chapter_timing.get(player.force,"chapters",p.chapter),"chapter")
  if stamped then
    local stamp=label(panel,stamped)
    stamp.style.font_color=COLOR.green
    stamp.tooltip=L("chapter-time-explanation")
  end
  local measure=panel.add{type="progressbar",
    value=chapter.total>0 and chapter.completed/chapter.total or 0}
  measure.style.width=math.min(inner,420)
  measure.style.height=4
  measure.style.color=theme.primary

  -- Limited-height outer folio, one scroll pane only. This lets even the
  -- largest chapter keep its narrative and real milestones scrollable.
  local scroll=wheel_pane(panel,"razi_journal_chapter_reading",
    inner,size.body-(size.compact and 248 or 265))
  local body=scroll.add{type="flow",direction="vertical"}
  local text_width=inner-18
  body.style.width=text_width
  body.style.vertical_spacing=12
  section(body,"chapter-cover-story",
    {"journal-chapter-summary."..p.chapter},text_width,theme)
  section(body,"chapter-cover-dispatch",
    {"journal-chapter-dispatch."..p.chapter},text_width,theme)
  section(body,"chapter-context",
    {"journal-chapter-story."..p.chapter},text_width,theme)
  dossier_heading(body,"chapter-cover-entries",theme,text_width)

  local next_entry
  for _,quest in ipairs(chapter.quests) do
    if view.states[quest.id]=="active" then next_entry=quest;break end
  end
  if not next_entry then
    for _,quest in ipairs(chapter.quests) do
      if view.states[quest.id]=="locked" then next_entry=quest;break end
    end
  end
  if not next_entry then
    for _,quest in ipairs(chapter.quests) do
      if view.states[quest.id]=="complete" then next_entry=quest;break end
    end
  end

  -- A real chapter navigation log; each entry jumps to its existing
  -- quest dossier, with colours derived from actual force research.
  local shown=0
  local last_act=nil
  for _,quest in ipairs(chapter.quests) do
    if shown>=8 then break end
    shown=shown+1
    local act=journal_acts.for_quest(quest)
    if act and act.key~=last_act then
      chapter_act(body,act,theme,text_width,player.force)
    end
    last_act=act and act.key
    local state=view.states[quest.id]
    local row=body.add{type="flow",direction="horizontal"}
    row.style.horizontal_spacing=9
    row.style.vertical_align="center"
    icons.sprite(row,quest_art(player.force,quest,context),"quest_row")
    local marker=label(row,state=="complete" and "✓"
      or state=="active" and "●" or "○")
    marker.style.font_color=state=="complete" and COLOR.green
      or state=="active" and COLOR.amber or COLOR.quiet
    local link=row.add{type="label",style="clickable_label",
      caption={"journal-title."..quest.id},
      tooltip=L("select-objective"),
      tags={razi_journal_action="select",id=quest.id}}
    link.style.single_line=false
    link.style.maximal_width=text_width-85
    link.style.font_color=quest==next_entry and COLOR.ink or COLOR.muted
    if quest==next_entry then link.style.font="default-bold" end
  end
  if #chapter.quests>shown then
    local extra=label(body,L("chapter-cover-more",
      tostring(#chapter.quests-shown)))
    extra.style.font_color=COLOR.quiet
  end
  if next_entry then
    -- Small screens keep the next-entry control inside the scrollable
    -- folio so it cannot force the whole reader beyond the display.
    local footer_parent=size.body<420 and body or panel
    local footer=footer_parent.add{type="flow",direction="horizontal"}
    footer.style.horizontal_spacing=8
    footer.style.vertical_align="center"
    local call=footer.add{type="button",
      caption=L(view.states[next_entry.id]=="complete"
        and "chapter-cover-review" or "chapter-cover-continue"),
      tags={razi_journal_action="chapter-continue",id=next_entry.id}}
    call.tooltip={"journal-title."..next_entry.id}
  else
    wrap(panel,L("chapter-cover-unavailable"),inner)
  end
  return true
end

-- Wrapped, selectable labels replace the old too-wide chapter and quest
-- buttons. One chapter jump selector covers distant chapters with no bars.
local function render_chapters(parent,player,p,context,size,view,plan)
  local frame=parent.add{type="frame",name="razi_journal_navigation_panel",direction="vertical",
    style="razi_journal_index"}
  frame.style.width=size.rail
  frame.style.height=size.body
  frame.style.padding=10
  local inner=size.rail-35
  local index_title=subtitle(frame,"navigator-title",inner)
  index_title.style.font_color=COLOR.amber
  local names={}
  for _,ch in ipairs(defs.chapters) do
    local chapter=view.chapters[ch.id]
    names[#names+1]=M.hide_spoilers() and chapter
      and #chapter.quests==0 and L("spoiler-unknown-chapter")
      or {"journal-chapter."..ch.id}
  end
  local dropdown=frame.add{type="drop-down",
    name="razi_journal_chapter_picker",items=names,
    selected_index=chapter_index(p.chapter)}
  dropdown.style.width=inner
  -- Search is immediately above its filters and the actual chapter list.
  local find_row=frame.add{type="flow",direction="horizontal"}
  find_row.style.horizontal_spacing=5
  local search=find_row.add{type="textfield",name="razi_journal_search",
    text=p.query or "",tooltip=L("search-tooltip")}
  search.style.width=inner-44
  local clear=find_row.add{type="button",style="tool_button",
    caption="×",tooltip=L("clear-search"),
    tags={razi_journal_action="clear-search"}}
  clear.style.width=28
  clear.style.height=28
  local filters=frame.add{type="flow",name="razi_journal_filterbar",
    direction="horizontal"}
  filters.style.horizontal_spacing=9
  for _,filter in ipairs({"all","ready","unfinished","done"}) do
    local active=p.filter==filter
    local item=filters.add{type="label",style="clickable_label",
      name="razi_journal_filter_"..filter,
      caption=L("filter-"..filter),
      tags={razi_journal_action="filter",id=filter}}
    item.style.font=active and "default-bold" or "default"
    item.style.font_color=active and COLOR.ink or COLOR.quiet
  end
  local scroll=wheel_pane(frame,"razi_journal_navigation",
    inner,size.body-164)
  local column=scroll.add{type="flow",name="razi_journal_chapter_column",direction="vertical"}
  column.style.width=inner-13
  column.style.vertical_spacing=9
  local selected_element

  plan=plan or M.guidance(player.force,context,view)
  -- A compact next-objective link rather than the old tall dashboard card.
  if plan.primary and plan.primary.quest then
    local lead=column.add{type="flow",name="razi_journal_lead",direction="vertical"}
    lead.visible=p.query=="" and p.filter=="all"
    lead.style.width=inner-16
    lead.style.vertical_spacing=2
    lead.style.bottom_padding=5
    local title=label(lead,L("guidance-heading"))
    title.style.font="default-bold"
    title.style.font_color=COLOR.amber
    local entry=lead.add{type="label",name="razi_journal_lead_link",style="clickable_label",
      caption={"journal-title."..plan.primary.quest.id},
      tags={razi_journal_action="guidance-select",id=plan.primary.quest.id}}
    entry.style.maximal_width=inner-24
    entry.style.single_line=false
    entry.style.font_color=COLOR.ink
  end
  local found=false

  for index,chapter in ipairs(defs.chapters) do
    local theme=themes.get(chapter.id)
    local data=view.chapters[chapter.id]
    local completed,total=data.completed,data.total
    -- Allocate visible quest rows once; later search/filter changes only
    -- toggle native GUI visibility, keeping the same scroll-pane instance.
    local available=data.quests
    local visible_count=0
    for _,quest in ipairs(available) do
      if state_matches_filter(view.states[quest.id],p.filter)
        and matches_query(quest,p.query) then
        visible_count=visible_count+1
      end
    end
    if #available>0 then
      found=found or visible_count>0
      local open=p.query~="" or p.chapter==chapter.id
      -- Each chapter gets its own quiet inset surface. Separation remains
      -- visible when collapsed, without adding extra scrolling containers.
      local card=column.add{type="frame",name="razi_journal_chapter_"..index,
        direction="vertical",style="razi_journal_chapter_group"}
      card.style.width=inner-16
      card.style.padding=6
      card.visible=visible_count>0
      accent_rule(card,theme,math.min(72,inner-40),2)
      local head=card.add{type="flow",name="razi_journal_chapter_head",direction="horizontal"}
      head.style.horizontal_spacing=5
      icons.sprite(head,themes.icon(chapter.id),"chapter_button",
        {"journal-chapter."..chapter.id})
      local toggle=head.add{type="button",name="razi_journal_chapter_toggle",style="tool_button",
        caption=open and "▾" or "▸",
        tags={razi_journal_action="chapter",id=chapter.id},
        tooltip={"journal-chapter."..chapter.id}}
      toggle.style.width=20
      toggle.style.height=22
      toggle.style.font_color=open and theme.primary or COLOR.quiet
      local heading=head.add{type="label",name="razi_journal_chapter_title",
        style="clickable_label",
        caption={"",string.format("%02d",index)," / ",{"journal-chapter."..chapter.id}},
        tags={razi_journal_action="chapter",id=chapter.id}}
      heading.style.single_line=false
      heading.style.maximal_width=inner-85
      heading.style.font=open and "default-bold" or "default"
      heading.style.font_color=open and COLOR.ink or COLOR.muted
      heading.style.vertical_align="center"

      local counts=card.add{type="flow",name="razi_journal_chapter_status",direction="vertical"}
      counts.style.vertical_spacing=1
      counts.style.left_padding=45
      local stamped=completion_caption(
        chapter_timing.get(player.force,"chapters",chapter.id),"chapter")
      counts.visible=open or stamped~=nil
      local count=counts.add{type="label",name="razi_journal_chapter_count",
        caption=L("chapter-progress-short",tostring(completed),tostring(total))}
      count.visible=open
      count.style.font_color=COLOR.quiet
      local stamp=counts.add{type="label",name="razi_journal_chapter_time",
        caption=stamped or ""}
      stamp.visible=stamped~=nil
      stamp.style.font_color=COLOR.green
      stamp.tooltip=L("chapter-time-explanation")
      -- The numerical count is sufficient; redundant progress bars added
      -- visual noise eighteen times in a long chapter list.
      local entries=card.add{type="flow",name="razi_journal_chapter_entries",direction="vertical"}
      entries.visible=open and visible_count>0
      entries.style.vertical_spacing=4
      do
        local open_cover=entries.add{type="label",style="clickable_label",
          caption=L(p.chapter_cover and p.chapter==chapter.id
            and "chapter-cover-current" or "chapter-cover-open"),
          tooltip=L("chapter-cover-tooltip"),
          tags={razi_journal_action="chapter-dossier",id=chapter.id}}
        open_cover.style.font_color=theme.soft
        local last_act=nil
        for _,quest in ipairs(available) do
          local act=journal_acts.for_quest(quest)
          if act and act.key~=last_act then
            chapter_act(entries,act,theme,inner-34,player.force)
          end
          last_act=act and act.key
          local state=view.states[quest.id]
          local milestone_time=completion_caption(
            chapter_timing.get(player.force,"milestones",quest.id),"milestone")
          local milestone_tooltip=milestone_time
            and {"",{"journal-title."..quest.id},"\n",milestone_time}
            or {"journal-title."..quest.id}
          -- A selected entry is a single subtly raised row, not another
          -- full-width button. The native technology image stays bounded.
          local chosen=quest.id==p.selected and not p.chapter_cover
          local item=entries.add{type="flow",name="razi_journal_item_"..quest.id,
            direction="horizontal"}
          item.style.width=inner-34
          item.visible=state_matches_filter(state,p.filter)
            and matches_query(quest,p.query)
          item.style.padding=2
          item.style.horizontal_spacing=5
          local select_rule=item.add{type="progressbar",
            name="razi_journal_item_rule",value=1}
          select_rule.style.width=3
          select_rule.style.height=18
          select_rule.style.color=theme.primary
          select_rule.visible=chosen
          icons.sprite(item,quest_art(player.force,quest,context),
            "quest_row")
          local control=item.add{type="button",name="razi_journal_item_control",style="tool_button",
            caption=state=="complete" and "✓"
              or state=="active" and "●" or "○",
            tags={razi_journal_action="select",id=quest.id},
            tooltip=milestone_tooltip}
          control.style.width=21
          control.style.height=21
          local color=state=="complete" and {r=.48,g=.85,b=.67}
            or state=="active" and {r=.98,g=.79,b=.46}
            or {r=.58,g=.61,b=.68}
          control.style.font_color=color
          local choice=item.add{type="label",name="razi_journal_item_choice",style="clickable_label",
            caption={"journal-title."..quest.id},
            tags={razi_journal_action="select",id=quest.id},
            tooltip=milestone_tooltip}
          choice.style.single_line=false
          choice.style.maximal_width=inner-108
          choice.style.font_color=chosen and COLOR.ink
            or state=="active" and theme.soft or COLOR.muted
          if chosen then
            control.style.font_color=theme.primary
            choice.style.font="default-bold"
            selected_element=choice
          end
        end
      end
    end
  end
  local missing_start=not (player.force.technologies
    and player.force.technologies["automation"])
  local empty=column.add{type="label",name="razi_journal_no_results",
    caption=(not found and missing_start and p.query=="" and p.filter=="all")
      and L("bootstrap-research-missing") or L("nothing-found")}
  empty.style.single_line=false
  empty.style.maximal_width=inner-28
  empty.visible=not found
  -- Search results should not jump while the player is still typing.
  if selected_element and p.reveal_selection and p.query=="" then
    pcall(function() scroll.scroll_to_element(selected_element) end)
  end
  p.reveal_selection=nil
  return search
end
-- The archive is not another quest chain. Each story entry opens only
-- when its source-backed research milestone is actually completed.
function M.unlocked_records(force,context)
  context=context or M.context(force)
  local unlocked=0
  for _,record in ipairs(records) do
    local q=defs.by_id[record.unlock]
    if q and M.complete(force,q,context) then unlocked=unlocked+1 end
  end
  return unlocked,#records
end
local function render_archive(parent,player,p,context,size)
  local rail=parent.add{type="frame",name="razi_journal_archive_index",
    direction="vertical",style="razi_journal_index"}
  rail.visible=not p.reader_focus
  rail.style.width=size.rail
  rail.style.height=size.body
  rail.style.padding=10
  subtitle(rail,"archive-navigator",size.rail-38,themes.get("echoes"))
  -- Recovery ledger is derived solely from completed source milestones.
  -- Sealed titles remain concealed; only aggregate counts are shown.
  local counts={legacy={0,0},corporate={0,0},field={0,0}}
  for _,record in ipairs(records) do
    local category=record.id:sub(1,5)~="corp-" and "legacy"
      or record.series=="field" and "field" or "corporate"
    local entry=counts[category]
    entry[2]=entry[2]+1
    local quest=defs.by_id[record.unlock]
    if quest and M.complete(player.force,quest,context) then
      entry[1]=entry[1]+1
    end
  end
  for _,category in ipairs({"legacy","corporate","field"}) do
    local progress=label(rail,L("archive-ledger-"..category,
      tostring(counts[category][1]),tostring(counts[category][2])))
    progress.style.font_color=COLOR.muted
  end
  local chooser=rail.add{type="table",column_count=2}
  chooser.style.horizontal_spacing=9
  chooser.style.vertical_spacing=8
  for _,category in ipairs({"all","legacy","corporate","field"}) do
    local chosen_filter=p.archive_filter==category
    local button=chooser.add{type="label",style="clickable_label",
      caption=L("archive-filter-"..category),
      tags={razi_journal_action="archive-filter",id=category}}
    button.style.font=chosen_filter and "default-bold" or "default"
    button.style.font_color=chosen_filter and COLOR.ink or COLOR.quiet
  end
  local left=wheel_pane(rail,"razi_journal_archive_navigation",
    size.rail-35,math.max(115,size.body-205))
  local collection=left.add{type="flow",direction="vertical"}
  collection.style.width=size.rail-56
  collection.style.vertical_spacing=5
  local chosen,focus
  local sealed=0
  local corporate_heading=false
  for _,record in ipairs(records) do
    local quest=defs.by_id[record.unlock]
    local opened=quest and M.complete(player.force,quest,context)
    if not opened then sealed=sealed+1 end
    -- Hide sealed pages entirely in spoiler mode. A counter replaces
    -- dozens of identical encrypted rows, without leaking future titles.
    local category=record.id:sub(1,5)~="corp-" and "legacy"
      or record.series=="field" and "field" or "corporate"
    if (p.archive_filter=="all" or p.archive_filter==category)
      and (opened or not M.hide_spoilers()) then
    if not corporate_heading and record.id:sub(1,5)=="corp-" then
      corporate_heading=true
      local heading=subtitle(collection,p.archive_filter=="field"
        and "archive-personal-heading" or "archive-corporate-heading",
        size.rail-64,themes.get("network"))
      heading.style.top_margin=10
    end
    local concealed=M.hide_spoilers() and not opened
    if opened and (not chosen or record.id==p.record) then chosen=record end
    local highlighted=opened and record.id==p.record
      or opened and not p.record and chosen==record
    local row=collection.add{type="flow",direction="horizontal"}
    row.style.padding=2
    row.style.horizontal_spacing=7
    local selection=row.add{type="progressbar",value=1}
    selection.style.width=3
    selection.style.height=20
    selection.style.color=COLOR.amber
    selection.visible=highlighted
    local mark
    if opened then
      mark=icons.button(row,quest_art(player.force,quest,context),
        "archive_button",{razi_journal_action="record",id=record.id},
        {"journal-record-title."..record.id})
    else
      mark=row.add{type="button",style="tool_button",
        caption="◇",enabled=false,
        tooltip=concealed and L("spoiler-sealed-record")
          or {"journal-record-title."..record.id}}
      mark.style.font_color={r=.59,g=.62,b=.68}
    end
    mark.style.width=icons.size("archive_button")
    mark.style.height=icons.size("archive_button")
    local choice=row.add{type="label",
      style=opened and "clickable_label" or nil,
      caption={"",opened and p.story_unread and p.story_unread[record.id]
        and "● " or "",concealed and L("spoiler-sealed-record")
        or {"journal-record-title."..record.id}},
      tags=opened and {razi_journal_action="record",id=record.id} or nil}
    choice.style.single_line=false
    choice.style.maximal_width=size.rail-105
    choice.style.font_color=opened and {r=.95,g=.95,b=.95}
      or {r=.58,g=.60,b=.65}
    if opened and record.id==p.record then
      choice.style.font="default-bold"
      focus=choice
    end
    end
  end
  -- Recovered RAZI Archive Array signals are separate from the original
  -- 59 corporate records. Their three physical unlocks never inflate the
  -- source-research archive totals or expose a future signal title.
  great_projects.array(player.force)
  local array_count=great_projects.recovered(player.force)
  if array_count>0 then
    local array_label=label(collection,L("archive-array-heading"))
    array_label.style.font="default-bold"
    array_label.style.font_color=COLOR.amber
    for i=1,array_count do
      local select_row=collection.add{type="label",style="clickable_label",
        caption=L("archive-array-title-"..i),
        tags={razi_journal_action="array-record",id=i}}
      select_row.style.single_line=false
      select_row.style.maximal_width=size.rail-65
    end
  end
  if M.hide_spoilers() and sealed>0 then
    local note=wrap(collection,L("archive-sealed-count",
      tostring(sealed)),size.rail-64)
    note.style.font_color=COLOR.quiet
  end
  if focus then pcall(function() left.scroll_to_element(focus) end) end

  local paper=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  paper.style.width=size.reader
  paper.style.height=size.body
  paper.style.padding=12
  local array_page=p.record and
    tonumber(p.record:match("^array%-(%d+)$"))
  if array_page and array_page>=1 and array_page<=array_count then
    local title=wrap(paper,L("archive-array-title-"..array_page),
      size.reader-48)
    title.style.font="heading-2"
    title.style.font_color=COLOR.ink
    local prose=wheel_pane(paper,"razi_journal_archive_reading",
      size.reader-38,size.body-140)
    prose.tags={razi_scroll_context=p.record}
    wrap(prose,L("archive-array-record-"..array_page),size.reader-67)
    return
  end
  if not chosen then
    subtitle(paper,"archive-sealed-heading",size.reader-48)
    wrap(paper,L("archive-sealed"),size.reader-48)
    return
  end
  p.record=chosen.id
  local chosen_quest=defs.by_id[chosen.unlock]
  local archive_theme=themes.get(chosen_quest and chosen_quest.chapter or "echoes")
  subtitle(paper,chosen.series=="field" and
    "archive-field-heading" or "archive-entry-label",
    size.reader-48,archive_theme)
  accent_rule(paper,archive_theme,math.min(100,size.reader-42),2)
  local cover=paper.add{type="flow",direction="horizontal"}
  cover.style.horizontal_spacing=10
  local entry_quest=defs.by_id[chosen.unlock]
  if entry_quest then
    icons.sprite(cover,quest_art(player.force,entry_quest,context),
      "archive_cover")
  end
  local title=wrap(cover,{"journal-record-title."..chosen.id},size.reader-94)
  title.style.font="heading-2"
  title.style.font_color=COLOR.ink
  local origin=label(paper,{"journal-record-origin."..chosen.id})
  origin.style.font_color=COLOR.muted
  if chosen_quest then
    local source=paper.add{type="button",
      caption=L("archive-open-source",
        {"journal-title."..chosen_quest.id}),
      tags={razi_journal_action="archive-source",id=chosen_quest.id},
      tooltip=L("archive-source-tooltip")}
    source.style.minimal_width=math.min(220,size.reader-58)
  end
  paper.add{type="line",direction="horizontal"}
  local reading=wheel_pane(paper,"razi_journal_archive_reading",
    size.reader-38,size.body-179)
  reading.tags={razi_scroll_context=chosen.id}
  local page=reading.add{type="flow",direction="vertical"}
  page.style.width=size.reader-67
  page.style.vertical_spacing=12
  wrap(page,{"journal-record-body."..chosen.id},size.reader-67)
  wrap(paper,L("archive-disclaimer"),size.reader-48)
end

function M.quest_by_id(id)
  return defs.by_id[id]
end
-- Factorio does not expose a scroll-pane's pixel offset to scripts.
-- Remember which *source-owned* boss victories the open Codex last rendered
-- so ten-second Nexus polls cannot destroy a player's scrolled reading pane.
local function nexus_revision(snapshot)
  if not snapshot then return "unavailable" end
  local bits={}
  for _,id in ipairs(trials.order) do
    bits[#bits+1]=trials.defeated(snapshot,id) and "1" or "0"
  end
  return table.concat(bits)
end
-- Preserve all independently scrollable readers when frame.clear()
-- rebuilds their GUI trees. Entry-specific tags prevent scroll bleed
-- between different milestones/projects/archive records.
local scroll_names={
  razi_journal_navigation=true,razi_journal_reading=true,
  razi_journal_chapter_reading=true,razi_journal_archive_reading=true,
  razi_journal_archive_navigation=true,
  razi_journal_project_reader=true,razi_journal_project_navigation=true,
  razi_journal_systems_reading=true
}
local function scroll_key(element)
  local tags=element.tags
  return element.name.."|"..tostring(tags and tags.razi_scroll_context or "")
end
local function collect_scrolls(element,snapshot)
  if not (element and element.valid) then return end
  if scroll_names[element.name] then
    snapshot[scroll_key(element)]=element.vertical_scroll_position
  end
  for _,child in pairs(element.children) do
    collect_scrolls(child,snapshot)
  end
end
local function restore_scrolls(element,snapshot,skip_navigation)
  if not (element and element.valid) then return end
  if scroll_names[element.name]
    and not (skip_navigation and element.name=="razi_journal_navigation") then
    local pos=snapshot[scroll_key(element)]
    if type(pos)=="number" and pos>=0 then
      pcall(function() element.vertical_scroll_position=pos end)
    end
  end
  for _,child in pairs(element.children) do
    restore_scrolls(child,snapshot,skip_navigation)
  end
end
local function draw(player,focus_search)
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=pref(player.index)
  -- Retired and uninstalled optional chapters must never leave the reader
  -- stranded on an old chapter ID when an existing save is reopened.
  if p.chapter then
    local present=false
    for _,chapter in ipairs(defs.chapters) do
      if chapter.id==p.chapter then present=true break end
    end
    if not present then
      p.chapter=false
      p.chapter_cover=false
    end
  end
  if p.selected and not defs.by_id[p.selected] then p.selected=nil end
  if p.pinned and not defs.by_id[p.pinned] then p.pinned=nil end
  local context=M.context(player.force)
  if M.hide_spoilers() then
    local quest=p.selected and defs.by_id[p.selected]
    if quest and not M.journal_visible(player.force,quest,context) then
      p.selected=nil
    end
    if p.chapter then
      local exposed=false
      for _,candidate in ipairs(defs.quests) do
        if candidate.chapter==p.chapter
          and M.journal_visible(player.force,candidate,context) then
          exposed=true;break
        end
      end
      if not exposed then
        p.chapter=false
        p.chapter_cover=false
      end
    end
  end
  local size=M.layout(player.display_resolution,player.display_scale)
  -- Focus widens only the quest reader. Hidden chapter widgets stay alive,
  -- so opening the index again does not lose its scroll position.
  if (p.view~="systems" and p.reader_focus)
    or (p.view=="quests" and size.single_column) then
    size.reader=size.width-43
  end
  local reveal_on_redraw=p.reveal_selection==true
  local chapter_theme=p.view=="systems" and "network"
    or (p.view=="projects" and "stellar" or p.chapter or "calidus")
  local window_theme=themes.get(chapter_theme)
  local saved_scrolls={}
  collect_scrolls(frame,saved_scrolls)
  -- Scroll state belongs to the logistics TAB, not the overall Projects
  -- view. Capture the old tab before frame.clear, and restore prior tabs'
  -- offsets only when their matching pane returns on a later selection.
  for key,position in pairs(saved_scrolls) do
    if key:find("^razi_journal_project_reader|cargo:") then
      p.logistics_scrolls[key]=position
    end
  end
  for key,position in pairs(p.logistics_scrolls) do
    if saved_scrolls[key]==nil then saved_scrolls[key]=position end
  end
  -- A native hidden scroll pane may report zero. Cache its last visible
  -- position before switching from Index to the mobile reading sheet.
  if p.view=="quests" and size.single_column then
    local previous=frame["razi_journal_content"]
    local nav=previous and previous["razi_journal_navigation_panel"]
    local scroller=nav and nav["razi_journal_navigation"]
    if nav and nav.visible and scroller and scroller.valid then
      p.compact_index_scroll=scroller.vertical_scroll_position
    end
  end
  frame.clear()
  frame.style.width=size.width
  frame.style.padding=10
  local head=frame.add{type="flow",direction="horizontal"}
  head.style.horizontally_stretchable=true
  head.style.vertical_align="center"
  head.style.horizontal_spacing=8
  icons.sprite(head,themes.icon(chapter_theme),"window_emblem")
  local heading=head.add{type="flow",direction="vertical"}
  heading.style.vertical_spacing=1
  local title=label(heading,L(size.compact and "window-compact" or "window"))
  title.style.font="heading-2"
  title.style.font_color=COLOR.ink
  local kicker=tint(label(heading,L("header-eyebrow")),COLOR.muted)
  kicker.style.font="default"
  kicker.visible=not size.compact
  local drag=head.add{type="empty-widget",style="draggable_space_header"}
  drag.style.horizontally_stretchable=true
  drag.style.height=19
  drag.drag_target=frame
  local focus=head.add{type="button",
    caption=L(p.reader_focus and "focus-show-index" or "focus-read"),
    tooltip=L("focus-tooltip"),
    tags={razi_journal_action="focus"}}
  focus.visible=p.view~="systems"
    and not (p.view=="projects" and p.project=="cargo")
    and not (p.view=="quests" and size.single_column)
  local compact_switch=head.add{type="button",
    caption=L(p.compact_index_open and "compact-read" or "compact-index"),
    tags={razi_journal_action="compact-index"},
    tooltip=L("compact-index-tooltip")}
  compact_switch.visible=p.view=="quests" and size.single_column
  focus.style.minimal_width=size.compact and 55 or 94
  local refresh=head.add{type="button",style="tool_button",
    caption="↻",tooltip=L("refresh"),
    tags={razi_journal_action="refresh"}}
  refresh.style.width=30
  refresh.style.height=30
  local dismiss=head.add{type="button",style="tool_button",
    caption="×",tooltip=L("close"),
    tags={razi_journal_action="close"}}
  dismiss.style.width=30
  dismiss.style.height=30
  -- The old subtitle restated the masthead and consumed a full screen row.

  p.nexus_revision=nexus_revision(context.nexus)
  local view=p.view=="quests" and M.view_status(player.force,context) or nil
  local plan=view and M.guidance(player.force,context,view)
  local done,total,ready
  if view then
    done,total,ready=view.done,view.total,view.ready
  else
    done,total,ready=M.summary(player.force,context)
  end
  -- Editorial status strip: honest progress, no generic dashboard tiles.
  local totals=frame.add{type="flow",name="razi_journal_overview",direction="vertical"}
  totals.visible=p.view~="systems"
  totals.style.horizontally_stretchable=true
  totals.style.vertical_spacing=2
  local metrics_row=totals.add{type="flow",name="razi_journal_metrics",direction="horizontal"}
  metrics_row.style.horizontally_stretchable=true
  metrics_row.style.vertical_align="center"
  metrics_row.style.horizontal_spacing=size.compact and 8 or 18
  local metric=metrics_row.add{type="flow",name="razi_journal_completion",direction="horizontal"}
  metric.style.horizontal_spacing=5
  subtitle(metric,"completion-heading")
  local completed=metric.add{type="label",name="razi_journal_completed",
    caption=L("completion-value",tostring(done),tostring(total))}
  completed.tooltip=L("progress-tooltip")
  completed.style.font="default-bold"
  completed.style.font_color=COLOR.ink
  local readiness=metrics_row.add{type="flow",name="razi_journal_readiness",direction="horizontal"}
  readiness.style.horizontal_spacing=5
  subtitle(readiness,"ready-heading")
  local ready_label=readiness.add{type="label",name="razi_journal_ready",style="clickable_label",
    caption=L("ready-value",tostring(ready)),
    tooltip=L("filter-ready-tooltip"),
    tags={razi_journal_action="filter-ready"}}
  ready_label.style.font="default-bold"
  ready_label.style.font_color=COLOR.amber
  local meter=totals.add{type="flow",name="razi_journal_meter",direction="vertical"}
  meter.style.horizontally_stretchable=true
  meter.style.vertical_spacing=2
  local overall=meter.add{type="progressbar",name="razi_journal_progress",
    value=total>0 and done/total or 0}
  overall.style.width=math.min(250,math.floor(size.width*.2))
  overall.style.height=3
  overall.style.color=window_theme.primary

  local toolbar=frame.add{type="flow",direction="horizontal"}
  toolbar.style.horizontal_spacing=size.single_column and 8
    or size.compact and 15 or 24
  toolbar.style.vertical_align="bottom"
  -- The three folios use typographic navigation and a slender active rule.
  for _,view in ipairs({"quests","projects","archive","systems"}) do
    local active=p.view==view
    local folio=toolbar.add{type="flow",direction="vertical"}
    folio.style.vertical_spacing=3
    local line=folio.add{type="flow",direction="horizontal"}
    line.style.horizontal_spacing=size.single_column and 3 or 5
    line.style.vertical_align="center"
    local theme_id=view=="quests" and (p.chapter or "calidus")
      or view=="projects" and "stellar"
      or view=="archive" and "echoes" or "network"
    icons.sprite(line,themes.icon(theme_id),"tab_icon")
    local button=line.add{type="label",style="clickable_label",
      caption=L("view-"..view),tags={razi_journal_action="view",id=view}}
    button.style.font=active and "default-bold" or "default"
    button.style.font_color=active and COLOR.ink or COLOR.muted
    if active then accent_rule(folio,window_theme,76,2) end
  end
  if p.view=="quests" and not size.single_column then
    local spacer=toolbar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable=true
    toolbar.add{type="button",caption=L("next-milestone"),
      tags={razi_journal_action="next"}}
  end
  local filterbar=frame.add{type="flow",name="razi_journal_filterbar",direction="horizontal"}
  -- Quest filters now live beside their chapter search, not in a separate
  -- window-wide toolbar that competes with the four primary folios.
  filterbar.visible=p.view~="quests"
  filterbar.style.horizontal_spacing=6
  filterbar.style.vertical_align="center"
  if p.view=="archive" then
    local unlocked,all=M.unlocked_records(player.force,context)
    tint(label(filterbar,L("archive-progress",
      tostring(unlocked),tostring(all))),themes.get("echoes").primary)
    local unread=0
    for _,record in ipairs(records) do
      local q=defs.by_id[record.unlock]
      if p.story_unread and p.story_unread[record.id]
        and q and M.complete(player.force,q,context) then
        unread=unread+1
      end
    end
    if unread>0 then
      local news=label(filterbar,L("archive-unread",tostring(unread)))
      news.style.font_color=COLOR.amber
      filterbar.add{type="button",
        caption=L("archive-read-next"),
        tags={razi_journal_action="record-next-unread"}}
    end
    local spacer=filterbar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable=true
    filterbar.add{type="label",style="clickable_label",
      caption=L(p.story_alerts and "archive-alerts-on" or "archive-alerts-off"),
      tooltip=L("archive-alerts-tooltip"),
      tags={razi_journal_action="story-alerts"}}
  elseif p.view=="projects" then
    tint(label(filterbar,L("projects-hint")),window_theme.soft)
  elseif p.view=="systems" then
    tint(label(filterbar,{"journal-systems.status-strip"}),window_theme.soft)
    local spacer=filterbar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable=true
    filterbar.add{type="button",name="razi_journal_systems_native",
      caption=L(p.native_controls_visible and "systems-native-hide" or
        "systems-native-show"),
      tooltip=L("systems-native-tooltip"),
      tags={razi_journal_action="systems-native"}}
  else
    subtitle(filterbar,"filter-heading")
    for _,filter in ipairs({"all","ready","unfinished","done"}) do
      local active=p.filter==filter
      local button=filterbar.add{type="label",name="razi_journal_filter_"..filter,
        style="clickable_label",
        caption=L("filter-"..filter),
        tags={razi_journal_action="filter",id=filter}}
      button.style.font=active and "default-bold" or "default"
      button.style.font_color=active and COLOR.ink or COLOR.quiet
    end
  end

  local body=frame.add{type="flow",
    name=p.view=="systems" and "razi_journal_systems_body" or "razi_journal_content",
    direction="horizontal"}
  body.style.width=size.width-33
  body.style.height=size.body
  body.style.horizontal_spacing=10
  if p.view=="archive" then
    render_archive(body,player,p,context,size)
  elseif p.view=="projects" then
    projects.render(body,player,p,size)
  elseif p.view=="systems" then
    systems.render(body,player,size)
  else
    local selected=select_quest(player.force,p,context,plan)
    local search=render_chapters(body,player,p,context,size,view,plan)
    local navigation=body["razi_journal_navigation_panel"]
    local on_small_screen=size.single_column
    if navigation then
      navigation.visible=on_small_screen and p.compact_index_open
        or (not on_small_screen and not p.reader_focus)
    end
    local reader=body.add{type="flow",name="razi_journal_reader_host",direction="vertical"}
    reader.visible=not (on_small_screen and p.compact_index_open)
    reader.style.width=size.reader
    -- Normal chapter expand/collapse and dossier clicks retain the user's
    -- location in the list. Explicit quest navigation may deliberately
    -- reveal its selection, so that takes precedence over this restore.
    -- Restore all scroll readers once the complete GUI tree exists.
    if focus_search then pcall(function() search.focus() end) end
    if p.chapter_cover and render_chapter_cover(
      reader,player,p,context,size,view) then
      -- A full chapter frontispiece replaces the quest reader until a
      -- real quest entry is selected.
    elseif selected then
      render_details(reader,player,selected,p,context,size,view)
    else
      local empty=reader.add{type="frame",
        style="inside_shallow_frame_with_padding"}
      empty.style.width=size.reader
      local missing_start=not (player.force.technologies
        and player.force.technologies["automation"])
      wrap(empty,missing_start and L("bootstrap-research-missing")
        or L("missing-quest"),size.reader-40)
    end
  end
  -- No decorative footer: useful space belongs to the dossiers.
  -- Restore only after the complete new GUI tree has been assembled.
  restore_scrolls(frame,saved_scrolls,reveal_on_redraw)
  if p.view=="quests" and size.single_column and p.compact_index_open
    and type(p.compact_index_scroll)=="number" then
    local navigation=body["razi_journal_navigation_panel"]
    local scroll=navigation and navigation["razi_journal_navigation"]
    if scroll then pcall(function()
      scroll.vertical_scroll_position=p.compact_index_scroll
    end) end
  end
  -- A hidden index can report zero during a Focus layout. Reapply the
  -- actual pre-Focus native offsets on the first return to the index.
  if not p.reader_focus and p.focus_navigation_scrolls then
    restore_scrolls(frame,p.focus_navigation_scrolls,false)
    p.focus_navigation_scrolls=nil
  end
end
-- A new quest updates only the document, leaving the original chapter
-- scroll pane alive. This is more reliable than restoring a rebuilt scrollbar.
-- Razi 3.0: keep the native navigator and its scrollbar alive while the
-- right-hand dossier and source-backed status are refreshed independently.
local function update_reader(player,preserve_reader)
  local frame=player.gui.screen[FRAME]
  local body=frame and frame.valid and frame["razi_journal_content"]
  local reader=body and body.valid and body["razi_journal_reader_host"]
  local navigation=body and body.valid and body["razi_journal_navigation_panel"]
  local scroll=navigation and navigation.valid
    and navigation["razi_journal_navigation"]
  -- Filtering hides/reveals children inside the same native scroll pane.
  -- Remember its actual scroll offset before the content is reflowed.
  local navigation_scroll=scroll and scroll.vertical_scroll_position
  local column=scroll and scroll.valid and scroll["razi_journal_chapter_column"]
  if not (reader and reader.valid and column and column.valid) then
    draw(player)
    return
  end
  local p=pref(player.index)
  local context=M.context(player.force)
  local size=M.layout(player.display_resolution,player.display_scale)
  if p.reader_focus or size.single_column then size.reader=size.width-43 end
  local view=M.view_status(player.force,context)
  -- A newly discovered/visible quest needs its first native GUI row built.
  -- That is the exceptional case where a full redraw is actually required.
  for index,ch in ipairs(defs.chapters) do
    local data=view.chapters[ch.id]
    local card=column["razi_journal_chapter_"..index]
    if #data.quests>0 and not card then draw(player);return end
    local entries=card and card["razi_journal_chapter_entries"]
    if entries then
      for _,quest in ipairs(data.quests) do
        if not entries["razi_journal_item_"..quest.id] then
          draw(player)
          return
        end
      end
    end
  end
  local plan=M.guidance(player.force,context,view)
  local selected=select_quest(player.force,p,context,plan)
  if size.single_column then
    if navigation.visible and type(navigation_scroll)=="number" then
      p.compact_index_scroll=navigation_scroll
    end
    navigation.visible=p.compact_index_open
    reader.visible=not p.compact_index_open
  end
  p.nexus_revision=nexus_revision(context.nexus)
  for index,ch in ipairs(defs.chapters) do
    local data=view.chapters[ch.id]
    local card=column["razi_journal_chapter_"..index]
    if card then
      local entries=card["razi_journal_chapter_entries"]
      local head=card["razi_journal_chapter_head"]
      local toggle=head and head["razi_journal_chapter_toggle"]
      local count_holder=card["razi_journal_chapter_status"]
      local count=count_holder and count_holder["razi_journal_chapter_count"]
      local heading=head and head["razi_journal_chapter_title"]
      local shown=0
      local matching_acts={}
      for _,quest in ipairs(data.quests) do
        local row=entries and entries["razi_journal_item_"..quest.id]
        if row then
          local state=view.states[quest.id]
          local matching=state_matches_filter(state,p.filter)
            and matches_query(quest,p.query)
          row.visible=matching
          if matching then
            shown=shown+1
            local act=journal_acts.for_quest(quest)
            if act then matching_acts[act.key]=true end
          end
          local choice=row["razi_journal_item_choice"]
          local marker=row["razi_journal_item_control"]
          local chosen=p.selected==quest.id and not p.chapter_cover
          local milestone_time=completion_caption(
            chapter_timing.get(player.force,"milestones",quest.id),"milestone")
          local milestone_tooltip=milestone_time
            and {"",{"journal-title."..quest.id},"\n",milestone_time}
            or {"journal-title."..quest.id}
          if choice then choice.tooltip=milestone_tooltip end
          if marker then marker.tooltip=milestone_tooltip end
          local selection=row["razi_journal_item_rule"]
          if selection then selection.visible=chosen end
          if choice then
            choice.style.font=chosen and "default-bold" or "default"
            choice.style.font_color=chosen and COLOR.ink
              or state=="active" and themes.get(ch.id).soft or COLOR.muted
          end
          if marker then
            marker.caption=state=="complete" and "✓"
              or state=="active" and "●" or "○"
            marker.style.font_color=chosen and themes.get(ch.id).primary
              or state=="complete" and COLOR.green
              or state=="active" and COLOR.amber or COLOR.quiet
          end
        end
      end
      card.visible=shown>0
      if entries then
        for _,act in ipairs(journal_acts.chapters[ch.id] or {}) do
          local divider=entries["razi_journal_act_"..ch.id.."_"..act.id]
          if divider then
            divider.visible=matching_acts[act.key]==true
            local stamp=divider["razi_journal_act_stamp"]
            if stamp then
              local caption=completion_caption(
                chapter_timing.get(player.force,"phases",act.key),"phase")
              stamp.caption=caption or ""
              stamp.visible=caption~=nil
            end
          end
        end
        local extra=entries["razi_journal_act_"..ch.id.."_additional"]
        if extra then
          extra.visible=matching_acts[ch.id..":additional"]==true
          local stamp=extra["razi_journal_act_stamp"]
          if stamp then
            local caption=completion_caption(chapter_timing.get(
              player.force,"phases",ch.id..":additional"),"phase")
            stamp.caption=caption or ""
            stamp.visible=caption~=nil
          end
        end
      end
      local expanded=shown>0 and (p.chapter==ch.id or p.query~="")
      if entries then entries.visible=expanded end
      if toggle then toggle.caption=expanded and "▾" or "▸" end
      if count then
        count.caption=L("chapter-progress-short",
          tostring(data.completed),tostring(data.total))
      end
      if count_holder then
        local stamped=completion_caption(
          chapter_timing.get(player.force,"chapters",ch.id),"chapter")
        local stamp=count_holder["razi_journal_chapter_time"]
        if stamp then
          stamp.caption=stamped or ""
          stamp.visible=stamped~=nil
        end
        if count then count.visible=expanded end
        count_holder.visible=expanded or stamped~=nil
      end
      if heading then
        heading.style.font=expanded and "default-bold" or "default"
        heading.style.font_color=expanded and COLOR.ink or COLOR.muted
      end
    end
  end
  local empty=column["razi_journal_no_results"]
  if empty then
    local any=false
    for index,_ in ipairs(defs.chapters) do
      local card=column["razi_journal_chapter_"..index]
      if card and card.visible then any=true;break end
    end
    empty.visible=not any
  end
  local lead=column["razi_journal_lead"]
  local lead_link=lead and lead["razi_journal_lead_link"]
  if lead_link then
    local next_quest=plan.primary and plan.primary.quest
    lead.visible=next_quest~=nil and p.query=="" and p.filter=="all"
    if next_quest then
      lead_link.caption={"journal-title."..next_quest.id}
      lead_link.tags={razi_journal_action="guidance-select",id=next_quest.id}
    end
  end
  local overview=frame["razi_journal_overview"]
  local metrics=overview and overview["razi_journal_metrics"]
  local completion=metrics and metrics["razi_journal_completion"]
  local completed=completion and completion["razi_journal_completed"]
  local readiness=metrics and metrics["razi_journal_readiness"]
  local ready=readiness and readiness["razi_journal_ready"]
  local meter=overview and overview["razi_journal_meter"]
  local progress=meter and meter["razi_journal_progress"]
  if completed then
    completed.caption=L("completion-value",tostring(view.done),tostring(view.total))
  end
  if ready then ready.caption=L("ready-value",tostring(view.ready)) end
  if progress then progress.value=view.total>0 and view.done/view.total or 0 end
  local filterbar=navigation["razi_journal_filterbar"]
    or frame["razi_journal_filterbar"]
  if filterbar then
    for _,filter in ipairs({"all","ready","unfinished","done"}) do
      local button=filterbar["razi_journal_filter_"..filter]
      if button then
        button.style.font=p.filter==filter and "default-bold" or "default"
        button.style.font_color=p.filter==filter and COLOR.ink or COLOR.quiet
      end
    end
  end
  local picker=navigation["razi_journal_chapter_picker"]
  if picker and picker.selected_index~=chapter_index(p.chapter) then
    picker.selected_index=chapter_index(p.chapter)
  end
  local search=navigation["razi_journal_search"]
  if search and search.text~=(p.query or "") then search.text=p.query or "" end
  if type(navigation_scroll)=="number" then
    scroll.vertical_scroll_position=navigation_scroll
  end
  -- Keep typing focus and the chapter scrollbar untouched. Readers are
  -- independently scrollable and restored when the same dossier refreshes.
  if preserve_reader then return end
  local saved={}
  collect_scrolls(reader,saved)
  reader.clear()
  if p.chapter_cover and render_chapter_cover(
    reader,player,p,context,size,view) then
  elseif selected then
    render_details(reader,player,selected,p,context,size,view)
  else
    local empty=reader.add{type="frame",
      style="inside_shallow_frame_with_padding"}
    empty.style.width=size.reader
    wrap(empty,L("missing-quest"),size.reader-40)
  end
  restore_scrolls(reader,saved,false)
end
M.draw=draw
local function open(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then draw(player);return end
  local size=M.layout(player.display_resolution,player.display_scale)
  local scale=math.max(.5,player.display_scale or 1)
  frame=player.gui.screen.add{type="frame",name=FRAME,direction="vertical"}
  frame.style.width=size.width
  frame.location={
    x=math.max(8,math.floor((player.display_resolution.width/scale-size.width)/2)),
    y=math.max(10,math.floor((player.display_resolution.height/scale-size.height)/2))
  }
  player.opened=frame
  draw(player)
end
M.open=open
function M.open_project(player,id,chain,target)
  if not (player and player.valid) then return false end
  local cargo=id=="cargo" or chain~=nil
  if cargo then
    if not projects.cargo_available(player.force) then return false end
    if chain and not projects.valid_cargo(player.force,chain,target) then
      return false
    end
  elseif id=="recovery" then
    -- The old project ID now points to its actual research milestones.
    return M.open_quest(player,"frontier-recovery-charter")
      or M.open_quest(player,"athos")
  elseif id and not projects.visible(player.force,id) then
    return false
  end
  local p=pref(player.index)
  p.view="projects"
  p.project=cargo and "cargo" or id or p.project
  if cargo then
    p.cargo_focus=chain
    p.cargo_target=target
    -- A Codex factory link opens the actual Industry reference instead
    -- of landing on the new Command dashboard.
    if chain then p.logistics_tab="industry" end
  end
  open(player)
  return true
end
function M.open_quest(player,id)
  local quest=defs.by_id[id]
  if not (player and player.valid and quest
    and M.journal_visible(player.force,quest)) then return false end
  local p=pref(player.index)
  p.selected=quest.id
  p.chapter=quest.chapter
  p.filter="all"
  p.query=""
  p.view="quests"
  p.chapter_cover=false
  p.compact_index_open=false
  p.reveal_selection=true
  open(player)
  return true
end
local function close(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then frame.destroy() end
end
M.close=close
function M.toggle(player)
  if player.gui.screen[FRAME] then close(player) else open(player) end
end
function M.sync(player)
  if not (player and player.valid) then return end
  -- Return to the original top-left gold journal button.
  -- Clean failed placements without deleting player.gui.top[TOP].
  journal_button_cleanup.remove_other_placements(player,TOP)
  systems.sync_companion_widgets(player,pref(player.index).native_controls_visible)
  local top=player.gui.top[TOP]
  if show_player_option(player,"razi-journal-show-button") then
    if not (top and top.valid) then
      top=icons.button(player.gui.top,"razi-journal-book-icon","toolbar",
        {razi_journal_action="toggle"},L("button-tooltip"),TOP)
    end
  elseif top and top.valid then
    top.destroy()
  end
  render_tracker(player)
end
function M.sync_all()
  for _,player in pairs(game.connected_players or {}) do M.sync(player) end
end
function M.refresh_open()
  for _,player in pairs(game.connected_players or {}) do
    local frame=player.gui and player.gui.screen and player.gui.screen[FRAME]
    if frame and frame.valid then
      if pref(player.index).view=="quests" then update_reader(player)
      else draw(player) end
    end
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    if p and p.tracker then render_tracker(player) end
  end
end
function M.on_removed(index)
  freight_orders.cleanup(index)
  multihop.cleanup(index)
  if storage.razi_expedition_journal then
    storage.razi_expedition_journal[index]=nil
  end
end
local function refresh_force(force)
  if not force then return end
  for _,player in pairs(game.connected_players or {}) do
    if player.force==force then
      local frame=player.gui.screen[FRAME]
      if frame and frame.valid then
        if pref(player.index).view=="quests" then update_reader(player)
        else draw(player) end
      end
      local existing=storage.razi_expedition_journal
        and storage.razi_expedition_journal[player.index]
      if existing and existing.tracker then render_tracker(player) end
    end
  end
end
-- The cheat command can finish hundreds of Codex technologies in a
-- single burst. A normal unlock redraws on the next 30-tick maintenance
-- callback, but a bulk unlock gets one redraw after the events settle.
local RESEARCH_BURST_LIMIT=12
local RESEARCH_BURST_WINDOW=120
local RESEARCH_BURST_QUIET=180
-- Staged debug research changes technology flags directly. Keep the Codex
-- parked until the final unlock settles, without relying on research events.
function M.defer_research_refresh(force)
  if not (force and force.name) then return end
  local pending=storage.razi_journal_pending_forces
  if not pending then
    pending={}
    storage.razi_journal_pending_forces=pending
  end
  local tick=game and game.tick or 0
  pending[force.name]={count=RESEARCH_BURST_LIMIT,
    first_tick=tick,last_tick=tick}
end
function M.on_research(event)
  local research=event and event.research
  local force=research and research.force
  if not (force and M.research_affects_journal(research)) then return end
  local tick=game and game.tick or 0
  M.record_chapter_completions(force,false,tick)
  local pending=storage.razi_journal_pending_forces
  if not pending then
    pending={}
    storage.razi_journal_pending_forces=pending
  end
  local state=pending[force.name]
  if type(state)~="table" then
    state={count=0,first_tick=tick}
    pending[force.name]=state
  elseif tick-(state.first_tick or tick)>RESEARCH_BURST_WINDOW then
    state.count=0
    state.first_tick=tick
  end
  state.count=math.min(RESEARCH_BURST_LIMIT,(state.count or 0)+1)
  state.last_tick=tick
end
function M.flush_research_refreshes()
  local pending=storage.razi_journal_pending_forces
  if not pending then return end
  local tick=game and game.tick or 0
  for force_name,state in pairs(pending) do
    -- A boolean may still exist in an old save's deferred work table.
    local burst=type(state)=="table" and
      (state.count or 0)>=RESEARCH_BURST_LIMIT
    if not burst or tick-(state.last_tick or 0)>=RESEARCH_BURST_QUIET then
      pending[force_name]=nil
      refresh_force(game.forces[force_name])
    end
  end
  if not next(pending) then storage.razi_journal_pending_forces=nil end
end
function M.refresh_chapter_completions()
  for _,force in pairs(game.forces or {}) do
    if force.name~="enemy" and force.name~="neutral"
      and M.record_chapter_completions(force,false) then
      refresh_force(force)
    end
  end
end
-- Refresh only visible boss objectives during the existing ten-second
-- maintenance tick. No global entity scans or per-tick remote calls.
function M.refresh_convergence(force)
  if not force then return end
  for _,player in pairs(force.connected_players or {}) do
    local p=storage.razi_expedition_journal and storage.razi_expedition_journal[player.index]
    local frame=player.gui.screen[FRAME]
    if p and p.view=="projects" and p.project=="convergence"
      and frame and frame.valid then draw(player) end
  end
end
-- The progress indicator is a sampled ForceTechnology percentage, not
-- a separate quest state. This never rebuilds the reader or moves scroll.
function M.refresh_research_visible()
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal and
      storage.razi_expedition_journal[player.index]
    if p and p.view=="quests" and p.selected and not p.chapter_cover then
      local frame=player.gui.screen[FRAME]
      local body=frame and frame.valid and frame["razi_journal_content"]
      local host=body and body["razi_journal_reader_host"]
      local panel=host and host.children[1]
      local scroll=panel and panel["razi_journal_reading"]
      local prose=scroll and scroll["razi_journal_prose"]
      local mission=prose and prose["razi_journal_mission_plan"]
      local strip=mission and mission["razi_journal_research_row"]
      if strip and strip.valid then
        local quest=defs.by_id[p.selected]
        local current=player.force.current_research
        local active=current and quest and not quest.boss
          and not quest.convergence and quest.tech==current.name
        if current and quest and quest.world and not active then
          for _,effect in pairs(current.prototype and
              current.prototype.effects or {}) do
            if effect.type=="unlock-space-location"
              and effect.space_location==quest.world then
              active=true
              break
            end
          end
        end
        active=active and current.researched~=true
        strip.visible=active==true
        if active then
          local value=player.force.research_progress
          value=type(value)=="number" and value or 0
          value=math.max(0,math.min(1,value))
          local percent=math.floor(value*100+.5)
          local text=strip["razi_journal_research_percent"]
          local bar=strip["razi_journal_research_progress"]
          if text then text.caption=L("mission-research-progress",
            tostring(percent)) end
          if bar then bar.value=value end
        end
      end
    end
  end
end

function M.refresh_systems_visible()
  -- A small reconciliation also catches companion GUIs rebuilt by their own
  -- join/research/configuration handlers; it never scans the world.
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    systems.sync_companion_widgets(player,p and p.native_controls_visible)
    if p and p.view=="systems" then systems.refresh(player) end
  end
end
function M.refresh_nexus_visible()
  if not (remote and remote.interfaces and
    remote.interfaces["nexus-bosses"]) then return end
  -- One source snapshot per force, not one remote call per open reader.
  local revisions={}
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    if p then
      local frame=player.gui.screen[FRAME]
      local relevant=(p.view=="quests" and
        (p.chapter=="deepworks"
          or (p.selected and defs.by_id[p.selected]
            and defs.by_id[p.selected].boss)))
        or (p.view=="projects"
          and (p.project=="nexus-trials" or p.project=="convergence"))
      if relevant and frame and frame.valid then
        local force=player.force
        local revision=revisions[force.index]
        if not revision then
          revision=nexus_revision(trials.snapshot(force))
          revisions[force.index]=revision
        end
        -- Preserve both scroll panes and search focus on ordinary polls.
        -- Only a real boss-victory change warrants a full redraw.
        if p.nexus_revision~=revision then
          if p.view=="quests" then update_reader(player)
          else draw(player) end
        end
      end
      if p.tracker and p.pinned and defs.by_id[p.pinned]
        and defs.by_id[p.pinned].boss then
        render_tracker(player)
      end
    end
  end
end
function M.gui_click(event)
  local element=event and event.element
  if not (element and element.valid) then return end
  local tags=element.tags
  if not tags then return end
  local action=tags.razi_journal_action
  local native=tags.razi_ops_action
  if not action and not native then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if native then
    local p=pref(player.index)
    if not (player.gui.screen[FRAME] and p.view=="projects") then return end
    if native=="convergence-deliver" and p.project=="convergence" then
      local known=false
      for _,stage in ipairs(convergence.stages) do
        if stage.id==tags.value then known=true;break end
      end
      if not known or not convergence.available(player.force) then return end
      local message,amount=convergence.deliver(player,tags.value)
      player.print({"razi-ops."..message,tostring(amount)})
    elseif p.project=="cargo" and native=="logistics-tab" then
      if not ({overview=true,routes=true,supply=true,
        freight=true,industry=true})[tags.value] then return end
      p.logistics_tab=tags.value
    elseif p.project=="cargo" and native=="logistics-route" then
      if not freight_orders.select(player,tags.value) then return end
      p.logistics_tab="freight"
      -- The player deliberately selected a new route. Reveal its editor
      -- at the top; ordinary tab switches and packing clicks keep scroll.
      p.logistics_scrolls["razi_journal_project_reader|cargo:freight"]=0
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-route" then
      local candidate=supply.recipe(player.force,p.supply_recipe)
      if not candidate then return end
      local allowed=false
      for _,route in ipairs(supply.inbound(player.force,candidate.site)) do
        if route.id==tags.value then allowed=true;break end
      end
      if not allowed then return end
      p.supply_route=tags.value
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-recalculate" then
      -- Batch quantity was recorded by the native text-change event.
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-plan" then
      if not supply.plan(player,p.supply_recipe,p.supply_route,
        tags.value,p.supply_batches) then
        player.print({"razi-ops.supply-plan-invalid"})
        return
      end
      player.print({"razi-ops.supply-plan-added"})
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-plan-all" then
      if not supply.plan_all(player,p.supply_recipe,p.supply_route,
        p.supply_batches) then
        player.print({"razi-ops.supply-plan-invalid"})
        return
      end
      player.print({"razi-ops.supply-all-added"})
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-path" then
      local recipe=supply.recipe(player.force,p.supply_recipe)
      if not recipe then return end
      local graph=supply_routes.graph(player.force)
      local options=supply_routes.paths(graph,p.supply_origin,recipe.site)
      local index=tags.value
      if not (type(index)=="number" and index==math.floor(index)
        and index>=1 and index<=#options) then return end
      p.supply_path=index
      p.supply_path_key=options[index].key
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-itinerary-save-all" then
      if not multihop.save(player,p,nil) then
        player.print({"razi-ops.supply-itinerary-invalid"})
        return
      end
      player.print({"razi-ops.supply-itinerary-saved"})
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-itinerary-toggle" then
      if not multihop.toggle_details(player,p,tags.value) then return end
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-itinerary-remove" then
      if not multihop.remove(player,tags.value) then return end
      if p.supply_expanded==tags.value then p.supply_expanded=nil end
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and (native=="supply-operation-depart"
        or native=="supply-operation-arrive"
        or native=="supply-operation-undo") then
      local operation=native:match("^supply%-operation%-(%a+)$")
      if not shipment_operations.change(player,tags.value,operation) then
        player.print({"razi-ops.supply-operation-rejected"})
        return
      end
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-handoff-review" then
      if not shipment_handoff.review(player,p,tags.value) then
        player.print({"razi-ops.handoff-failed"})
        return
      end
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-handoff-confirm" then
      if not shipment_handoff.confirm(player,p,tags.value) then
        player.print({"razi-ops.handoff-failed"})
        return
      end
      player.print({"razi-ops.handoff-staged"})
    elseif p.project=="cargo" and p.logistics_tab=="supply"
      and native=="supply-freight" then
      p.logistics_tab="freight"
    elseif p.project=="cargo" and native=="freight-select" then
      if not freight_orders.select(player,tags.value) then return end
    elseif p.project=="cargo" and native=="freight-add" then
      if not freight_orders.add(player) then
        player.print({"razi-ops.freight-board-invalid"})
        return
      end
    elseif p.project=="cargo" and native=="freight-packed" then
      if not freight_orders.update(player,tags.value,"packed") then return end
    elseif p.project=="cargo" and native=="freight-remove" then
      if not freight_orders.update(player,tags.value,"remove") then return end
    elseif p.project=="cargo" and native=="freight-up" then
      if not freight_orders.update(player,tags.value,"up") then return end
    elseif p.project=="cargo" and native=="freight-down" then
      if not freight_orders.update(player,tags.value,"down") then return end
    elseif p.project=="cargo" and native=="freight-clear" then
      freight_orders.clear(player)
    elseif native=="cargo-focus" and p.project=="cargo" then
      if not projects.valid_cargo(player.force,tags.value) then return end
      p.cargo_focus=p.cargo_focus==tags.value and nil or tags.value
      p.cargo_target=nil
    elseif native=="cargo-codex" and p.project=="cargo" then
      local chain=cargo_catalog.chain_for_technology(tags.value)
      local quest_id=cargo_catalog.quest_for_technology(tags.value)
      if not (quest_id and projects.valid_cargo(player.force,chain,tags.value)) then return end
      M.open_quest(player,quest_id)
      return
    else return end
    draw(player)
    return
  end
  if action=="toggle" then M.toggle(player);return end
  if action=="close" then close(player);return end
  if action=="systems-native" then
    local p=pref(player.index)
    local frame=player.gui.screen[FRAME]
    if not (frame and frame.valid and p.view=="systems") then return end
    -- Never redraw the folio for this control: preserve scroll position.
    p.native_controls_visible=not p.native_controls_visible
    systems.sync_companion_widgets(player,p.native_controls_visible)
    local bar=frame["razi_journal_filterbar"]
    local button=bar and bar["razi_journal_systems_native"]
    if button and button.valid then
      button.caption=L(p.native_controls_visible and "systems-native-hide"
        or "systems-native-show")
    end
    return
  end
  if action=="nexus-codex" then
    if not trials.open_codex(player,tags.id) then
      player.print(L("nexus-codex-unavailable"))
    end
    return
  end
  if action=="open-convergence" then
    local quest=defs.by_id[tags.id]
    if quest and M.available(player.force,quest)
      and convergence.available(player.force) then
      M.open_project(player,"convergence")
    end
    return
  end
  if action=="open-cargo" then
    local quest=defs.by_id[tags.id]
    if not (quest and M.available(player.force,quest)) then return end
    local chain,target=cargo_catalog.chain_for_quest(quest.id)
    if not (chain and cargo_catalog.is_installed(player.force,chain)) then
      return
    end
    M.open_project(player,"cargo",chain,target)
    return
  end
  if action=="tracker-open" then
    local p=pref(player.index)
    p.selected=p.pinned
    open(player)
    return
  end
  local p=pref(player.index)
  local old_view=p.view
  if (action=="select" or action=="guidance-select") and
    defs.by_id[tags.id] and M.journal_visible(player.force,defs.by_id[tags.id]) then
    p.selected=tags.id
    p.chapter=defs.by_id[tags.id].chapter
    -- Keep a clicked search/filter result in its original list.
    -- Guidance links may jump outside the filter, so only they clear it.
    if action=="guidance-select" then
      p.filter="all"
      p.query=""
    end
    p.view="quests"
    p.chapter_cover=false
    p.compact_index_open=false
    p.reveal_selection=false
  elseif action=="mission-details" and p.view=="quests"
    and p.selected==tags.id then
    p.goal_expanded=p.goal_expanded_quest~=tags.id
      or not p.goal_expanded
    p.goal_expanded_quest=tags.id
  elseif action=="compact-index" and p.view=="quests"
    and M.layout(player.display_resolution,player.display_scale).single_column then
    p.reader_focus=false
    p.compact_index_open=not p.compact_index_open
  elseif action=="focus" and p.view~="systems"
    and not (p.view=="projects" and p.project=="cargo") then
    if not p.reader_focus then
      local frame=player.gui.screen[FRAME]
      local saved={}
      collect_scrolls(frame,saved)
      p.focus_navigation_scrolls={}
      for _,name in ipairs({"razi_journal_navigation",
          "razi_journal_project_navigation",
          "razi_journal_archive_navigation"}) do
        local key=name.."|"
        if type(saved[key])=="number" then
          p.focus_navigation_scrolls[key]=saved[key]
        end
      end
    end
    p.reader_focus=not p.reader_focus
  elseif action=="chapter-dossier" then
    local known=false
    for _,ch in ipairs(defs.chapters) do
      if ch.id==tags.id then known=true;break end
    end
    if not known then return end
    if M.hide_spoilers() then
      local exposed=false
      for _,candidate in ipairs(defs.quests) do
        if candidate.chapter==tags.id
          and M.journal_visible(player.force,candidate) then
          exposed=true;break
        end
      end
      if not exposed then return end
    end
    p.chapter=tags.id
    p.chapter_cover=true
    p.view="quests"
    p.compact_index_open=false
    p.filter="all"
    p.query=""
  elseif action=="chapter-continue" then
    local target=defs.by_id[tags.id]
    if not (target and M.journal_visible(player.force,target)) then return end
    p.selected=target.id
    p.chapter=target.chapter
    p.chapter_cover=false
    p.compact_index_open=false
    p.filter="all"
    p.query=""
    p.reveal_selection=false
  elseif action=="chapter" then
    if M.hide_spoilers() then
      local exposed=false
      for _,candidate in ipairs(defs.quests) do
        if candidate.chapter==tags.id
          and M.journal_visible(player.force,candidate) then
          exposed=true;break
        end
      end
      if not exposed then return end
    end
    p.chapter=p.chapter==tags.id and false or tags.id
  elseif action=="view" and ({quests=true,projects=true,archive=true,systems=true})[tags.id] then
    p.view=tags.id
  elseif action=="project" and projects.visible(player.force,tags.id) then
    p.project=tags.id
  elseif action=="skybridge-sign" and p.view=="projects"
    and p.project=="skybridge" then
    if not great_projects.sign(player,tags.a,tags.b) then return end
  elseif action=="skybridge-deliver" and p.view=="projects"
    and p.project=="skybridge" then
    if not great_projects.deliver(player) then return end
  elseif action=="project-back" and p.view=="projects"
    and p.project=="cargo" then
    p.project="platform"
    p.cargo_focus=nil
    p.cargo_target=nil
  elseif action=="project-cycle" and p.view=="projects"
    and projects.visible(player.force,tags.id)
    and (projects.adjacent(player.force,p.project,-1)==tags.id
      or projects.adjacent(player.force,p.project,1)==tags.id) then
    p.project=tags.id
  elseif action=="project-next" and p.view=="projects" then
    local quest_id=projects.next_quest(player.force,p.project)
    if not quest_id or not M.open_quest(player,quest_id) then return end
    return
  elseif action=="array-record" and p.view=="archive" then
    local index=tonumber(tags.id)
    if not index or index<1 or index>great_projects.recovered(player.force)
      then return end
    p.record="array-"..index
    p.archive_filter="all"
  elseif action=="story-alerts" and p.view=="archive" then
    p.story_alerts=not p.story_alerts
  elseif action=="record-next-unread" and p.view=="archive" then
    local context=M.context(player.force)
    local found=false
    for _,record in ipairs(records) do
      local quest=defs.by_id[record.unlock]
      if p.story_unread and p.story_unread[record.id]
        and quest and M.complete(player.force,quest,context) then
        p.record=record.id
        p.archive_filter="all"
        p.story_unread[record.id]=nil
        found=true
        break
      end
    end
    if not found then return end
  elseif action=="archive-filter" then
    if not ({all=true,legacy=true,corporate=true,field=true})[tags.id]
      then return end
    p.archive_filter=tags.id
    p.record=nil
  elseif action=="archive-source" then
    local quest=defs.by_id[tags.id]
    if not (quest and M.complete(player.force,quest)) then return end
    p.selected=quest.id
    p.chapter=quest.chapter
    p.chapter_cover=false
    p.view="quests"
    p.compact_index_open=false
    p.filter="all"
    p.query=""
    p.reveal_selection=false
  elseif action=="record" then
    local context=M.context(player.force)
    for _,record in ipairs(records) do
      if record.id==tags.id then
        local quest=defs.by_id[record.unlock]
        if quest and M.complete(player.force,quest,context) then
          p.record=record.id
          p.archive_filter="all"
          p.view="archive"
          if p.story_unread then p.story_unread[record.id]=nil end
        end
        break
      end
    end
  elseif action=="filter-ready" then
    p.view="quests"
    p.filter="ready"
    p.query=""
    -- The counter is an actual navigation shortcut: open a ready entry
    -- rather than keeping a stale selection from another chapter.
    local context=M.context(player.force)
    local target=M.next_quest(player.force,context)
    if not (target and M.state(player.force,target,context)=="active") then
      target=nil
      for _,candidate in ipairs(defs.quests) do
        if M.state(player.force,candidate,context)=="active" then
          target=candidate
          break
        end
      end
    end
    if target then
      p.selected=target.id
      p.chapter=target.chapter
      p.compact_index_open=false
      p.reveal_selection=false
    end
  elseif action=="filter" and ({all=true,ready=true,unfinished=true,
      done=true})[tags.id] then
    p.filter=tags.id
  elseif action=="next" then
    local next=M.next_quest(player.force)
    if next then
      p.compact_index_open=false
      p.selected=next.id
      p.chapter=next.chapter
      p.filter="all"
      p.view="quests"
      p.query=""
      p.reveal_selection=false
      p.chapter_cover=false
    end
  elseif action=="next-in-chapter" or action=="previous-in-chapter" then
    local context=M.context(player.force)
    local choices={}
    for _,quest in ipairs(defs.quests) do
      if quest.chapter==p.chapter and M.journal_visible(player.force,quest,context)
        and M.show_in_filter(player.force,quest,p.filter,context) then
        choices[#choices+1]=quest
      end
    end
    for i,quest in ipairs(choices) do
      if quest.id==p.selected then
        local offset=action=="previous-in-chapter" and -2 or 0
        p.selected=choices[(i+offset)%#choices+1].id
        p.chapter_cover=false
        break
      end
    end
  elseif action=="clear-search" then
    p.query=""
  elseif action=="pin" and defs.by_id[tags.id] then
    if p.tracker and p.pinned==tags.id then
      p.tracker=false
    else
      p.pinned=tags.id;p.tracker=true
    end
    render_tracker(player)
  elseif action=="refresh" and p.view=="projects" then
    projects.refresh(player.force)
  elseif action=="refresh" and p.view=="systems" then
    systems.refresh(player)
  elseif action~="refresh" then return end
  -- Keep the navigation GUI (and its native scrollbar) on ordinary clicks.
  if old_view=="quests" and p.view=="quests" then
    if action=="select" or action=="guidance-select" or action=="chapter"
      or action=="next" or action=="chapter-dossier" or action=="chapter-continue"
      or action=="next-in-chapter" or action=="previous-in-chapter"
      or action=="filter" or action=="filter-ready" or action=="clear-search"
      or action=="mission-details" then
      update_reader(player,action=="chapter" or action=="filter")
      return
    elseif action=="pin" then
      local frame=player.gui.screen[FRAME]
      local body=frame and frame["razi_journal_content"]
      local reader=body and body["razi_journal_reader_host"]
      local panel=reader and reader.children[1]
      local scroll=panel and panel["razi_journal_reading"]
      local prose=scroll and scroll["razi_journal_prose"]
      local actions=prose and prose["razi_journal_actions"]
      local pin=actions and actions["razi_journal_pin_button"]
      if pin then
        pin.caption=L(p.tracker and p.pinned==tags.id
          and "tracker-hide" or "tracker-show")
      end
      return
    end
  end
  draw(player)
end
function M.text_changed(event)
  local element=event and event.element
  if not (element and element.valid) then return end
  local tags=element.tags
  if tags and tags.razi_ops_action=="supply-batches" then
    local player=game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local p=pref(player.index)
    if player.gui.screen[FRAME] and p.view=="projects"
      and p.project=="cargo" and p.logistics_tab=="supply" then
      p.supply_batches=supply.batches(element.text or "") or false
    end
    return
  end
  if tags and tags.razi_ops_action=="freight-count" then
    local player=game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local p=pref(player.index)
    if player.gui.screen[FRAME] and p.view=="projects"
      and p.project=="cargo" then
      freight_orders.count_changed(player,element.text or "")
    end
    return
  end
  if element.name~="razi_journal_search" then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local p=pref(player.index)
  local query=(element.text or ""):sub(1,80)
  if p.query==query then return end
  local prior=p.selected
  local prior_cover=p.chapter_cover
  p.query=query
  -- Select the first matching visible milestone so the reader follows search.
  if query~="" then
    local context=M.context(player.force)
    for _,quest in ipairs(defs.quests) do
      if M.show_in_filter(player.force,quest,p.filter,context)
        and matches_query(quest,query) then
        p.selected=quest.id
        p.chapter=quest.chapter
        p.chapter_cover=false
        break
      end
    end
  end
  update_reader(player,p.selected==prior and p.chapter_cover==prior_cover)
end
function M.elem_changed(event)
  local element=event and event.element
  if not (element and element.valid and element.tags
    and element.tags.razi_ops_action=="freight-item") then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local p=pref(player.index)
  if not (player.gui.screen[FRAME] and p.view=="projects"
    and p.project=="cargo") then return end
  if freight_orders.item_changed(player,element.elem_value) then
    draw(player)
  end
end
function M.selection_changed(event)
  local element=event and event.element
  if not (element and element.valid) then return end
  if element.tags and element.tags.razi_ops_action=="supply-recipe" then
    local player=game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local p=pref(player.index)
    if not (player.gui.screen[FRAME] and p.view=="projects"
      and p.project=="cargo" and p.logistics_tab=="supply") then return end
    local options=supply.catalog(player.force)
    local row=options[element.selected_index]
    if not row then return end
    p.supply_recipe=row.quest.tech
    p.supply_route=nil
    p.supply_origin=nil
    p.supply_path=1
    p.supply_path_key=nil
    draw(player)
    return
  end
  if element.tags and element.tags.razi_ops_action=="supply-origin" then
    local player=game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local p=pref(player.index)
    if not (player.gui.screen[FRAME] and p.view=="projects"
      and p.project=="cargo" and p.logistics_tab=="supply") then return end
    local recipe=supply.recipe(player.force,p.supply_recipe)
    if not recipe then return end
    local graph=supply_routes.graph(player.force)
    local origins=supply_routes.origins(graph,recipe.site)
    local world=origins[element.selected_index]
    if not world then return end
    p.supply_origin=world
    p.supply_path=1
    p.supply_path_key=nil
    draw(player)
    return
  end
  if element.name~="razi_journal_chapter_picker" then return end
  local chapter=defs.chapters[element.selected_index]
  local player=game.get_player(event.player_index)
  if not (chapter and player and player.valid) then return end
  local p=pref(player.index)
  local preserve=p.view=="quests" and p.query=="" and p.filter=="all"
  p.chapter=chapter.id
  p.filter="all"
  p.query=""
  p.reveal_selection=false
  p.chapter_cover=true
  local context=M.context(player.force)
  for _,quest in ipairs(defs.quests) do
    if quest.chapter==chapter.id
      and M.journal_visible(player.force,quest,context) then
      p.selected=quest.id
      break
    end
  end
  if preserve then update_reader(player) else draw(player) end
end
function M.gui_closed(event)
  if event.element and event.element.valid and event.element.name==FRAME then
    local player=game.get_player(event.player_index)
    if player then close(player) end
  end
end
function M.on_display_changed(event)
  local player=game.get_player(event.player_index)
  if not player then return end
  M.sync(player)
  if player.gui.screen[FRAME] then
    close(player)
    open(player)
  end
end
return M
