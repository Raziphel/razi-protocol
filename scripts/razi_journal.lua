-- The Protocol Codex reads research progress from each force.
-- Player storage is just UI preferences, so an older save can reopen it.
local M={}
local defs=require("scripts.razi_journal_data")
local records=require("scripts.razi_journal_records")
local trials=require("scripts.razi_nexus_trials")
local weather=require("scripts.razi_weather_guide")
local cargo_catalog=require("scripts.galactic_trade_catalog")
local operations=require("scripts.galactic_operations")
local guidance=require("scripts.razi_journal_guidance")
local FRAME="razi_expedition_journal"
local TOP="razi_expedition_journal_button"
local TRACKER="razi_expedition_objective_tracker"
local L=function(key,...) return {"journal-ui."..key,...} end
local themes=require("scripts.razi_journal_themes")
M.chapter_theme=themes.get
M.chapter_icon=themes.icon

M.FRAME=FRAME
M.TOP=TOP
M.TRACKER=TRACKER

-- The research-all cheat can fire thousands of events. We only need to
-- redraw for Codex milestones and world discovery unlocks.
local research_goals,world_goals={},{}
for _,quest in ipairs(defs.quests) do
  if quest.tech then research_goals[quest.tech]=true end
  if quest.world then world_goals[quest.world]=true end
end
function M.research_affects_journal(research)
  if not research then return false end
  if research_goals[research.name] then return true end
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
      chapter=nil,filter="all",view="quests",record=nil,query=""}
    storage.razi_expedition_journal[index]=value
  end
  value.filter=value.filter or "all"
  value.view=value.view or "quests"
  value.query=value.query or ""
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
  if proto and proto.hidden and not t.researched then return nil end
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
  if quest.boss then
    local snapshot=(context or M.context(force)).nexus
    return M.available(force,quest,context)
      and trials.defeated(snapshot,quest.boss)
  end
  local t=technology(force,quest,context)
  return t~=nil and t.researched==true
end
function M.state(force,quest,context)
  if not M.available(force,quest,context) then return "unavailable" end
  if M.complete(force,quest,context) then return "complete" end
  for _,required in ipairs(quest.requires or {}) do
    local prior=defs.by_id[required]
    -- Source content not present in this modpack is not a phantom
    -- blocker. Its own technology controls actual research prerequisites.
    if prior and M.available(force,prior,context)
      and not M.complete(force,prior,context) then return "locked" end
  end
  return "active"
end
function M.summary(force,context)
  local completed,total,active=0,0,0
  context=context or M.context(force)
  for _,q in ipairs(defs.quests) do
    local state=M.state(force,q,context)
    if state~="unavailable" then
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
  if suggested.primary then return suggested.primary.quest end
  -- A blocked objective can still be inspected, but is not called ready.
  for _,q in ipairs(defs.quests) do
    if M.state(force,q,context)=="active" then return q end
  end
  for _,q in ipairs(defs.quests) do
    if M.state(force,q,context)~="unavailable" then return q end
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
  return state_matches_filter(M.state(force,quest,context),filter)
end

-- Calculate the visible campaign once per redraw. The navigator used to
-- walk all quests for every chapter and repeat most of these state checks.
local quests_by_chapter={}
for _,chapter in ipairs(defs.chapters) do quests_by_chapter[chapter.id]={} end
for _,quest in ipairs(defs.quests) do
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
      view.states[quest.id]=state
      if state~="unavailable" then
        result.quests[#result.quests+1]=quest
        result.total=result.total+1
        view.total=view.total+1
        if state=="complete" then
          result.completed=result.completed+1
          view.done=view.done+1
        elseif state=="active" then
          view.ready=view.ready+1
        end
      end
    end
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
  local width=math.min(1370,math.max(420,screen_w-52))
  local height=math.min(930,math.max(390,screen_h-64))
  local compact=width<1020 or height<660
  local rail=math.min(compact and 335 or 425,
    math.max(235,math.floor(width*(compact and .33 or .32))))
  local reader=width-rail-43
  return {width=width,height=height,rail=rail,reader=reader,
    body=math.max(200,height-(compact and 230 or 284)),
    compact=compact}
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
  item.style.font_color=theme and theme.primary or {r=.84,g=.69,b=.46}
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
local function section(parent,key,caption,width,theme)
  local block=parent.add{type="flow",direction="vertical"}
  block.style.horizontally_stretchable=true
  block.style.vertical_spacing=5
  subtitle(block,key,width,theme)
  if theme then accent_rule(block,theme,math.min(width,152),2) end
  if caption then wrap(block,caption,width) end
  return block
end
local function wheel_pane(parent,name,width,height)
  local pane=parent.add{type="scroll-pane",name=name,
    horizontal_scroll_policy="never",
    vertical_scroll_policy="dont-show-but-allow-scrolling"}
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
  if selected and M.available(force,selected,context) then
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
    .." "..(quest.world or "").." "..(quest.site or "")):lower():gsub("[-_]"," ")
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
  local columns=math.max(1,math.min(5,math.floor(width/116)))
  local card_width=math.max(68,math.floor((width-(columns-1)*8)/columns)-3)
  local grid=block.add{type="table",column_count=columns}
  grid.style.horizontal_spacing=8
  grid.style.vertical_spacing=9
  for i=1,math.min(max_items,#entries) do
    local entry=entries[i]
    local card=grid.add{type="frame",direction="vertical",
      style="inside_shallow_frame"}
    card.style.width=card_width
    card.style.padding=4
    local picture=card.add{type="sprite",sprite=entry.sprite,
      tooltip=entry.tooltip or entry.name}
    picture.style.width=34
    picture.style.height=34
    local caption=wrap(card,entry.name,card_width-10)
    caption.style.font_color=theme and theme.soft
      or {r=.86,g=.9,b=.94}
  end
  if #entries>max_items then
    wrap(block,L("more-unlocks",tostring(#entries-max_items)),width)
  end
end
local function science_gallery(native)
  local result={}
  for _,ingredient in ipairs(native and native.research_unit_ingredients or {}) do
    local path=sprite_if_valid("item/"..ingredient.name)
    local item=prototypes and prototypes.item
      and prototypes.item[ingredient.name]
    if path then result[#result+1]={
      sprite=path,name=item and item.localised_name or ingredient.name,
      tooltip=L("science-per-unit",tostring(ingredient.amount or 1))} end
  end
  return result
end
local function unlock_gallery(native)
  local result,seen={},{}
  for _,effect in ipairs(native and native.prototype
    and native.prototype.effects or {}) do
    if effect.type=="unlock-recipe" and effect.recipe and
      not seen[effect.recipe] then
      seen[effect.recipe]=true
      local recipe=prototypes and prototypes.recipe
        and prototypes.recipe[effect.recipe]
      if recipe and not recipe.hidden then
        local output=recipe.main_product or
          (recipe.products and recipe.products[1])
        local item=output and output.type~="fluid"
          and prototypes and prototypes.item and prototypes.item[output.name]
        local building=item and item.place_result
        local sprite=building and sprite_if_valid("entity/"..building.name)
          or output and sprite_if_valid(
            (output.type=="fluid" and "fluid/" or "item/")..output.name)
          or sprite_if_valid("recipe/"..effect.recipe)
        if sprite then result[#result+1]={
          sprite=sprite,
          name=(building and building.localised_name)
            or (item and item.localised_name) or recipe.localised_name,
          tooltip=recipe.localised_name,building=building and true or false} end
      end
    end
  end
  table.sort(result,function(a,b)
    if a.building~=b.building then return a.building end
    return false
  end)
  return result
end


-- Exact recipe illustration for Razi's source-proven alternate processes.
-- Reads one recipe by ID only while its quest is viewed: no global scans.
local function recipe_gallery(parent,quest,native,width,theme)
  if not (quest.site and native and prototypes
      and prototypes.recipe) then return end
  local recipe=prototypes.recipe[quest.tech]
  if not (recipe and not recipe.hidden) then return end
  local unlocked=false
  for _,effect in ipairs(native.prototype and native.prototype.effects or {}) do
    if effect.type=="unlock-recipe" and effect.recipe==quest.tech then
      unlocked=true;break
    end
  end
  if not unlocked then return end
  local function cards(entries)
    local output={}
    for _,entry in ipairs(entries or {}) do
      local name=entry.name
      local kind=entry.type=="fluid" and "fluid" or "item"
      local proto=prototypes[kind] and prototypes[kind][name]
      local path=name and sprite_if_valid(kind.."/"..name)
      if proto and path then
        output[#output+1]={sprite=path,name=proto.localised_name,
          tooltip=proto.localised_name}
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
  wrap(panel,L("site-advisory",{"journal-workshop."..quest.id}),width-26)
  draw_gallery(panel,"factory-imports",materials,width-26,10,theme)
  draw_gallery(panel,"factory-outputs",products,width-26,5,theme)
  wrap(panel,L("factory-source-owned"),width-26)
end

local function render_tracker(player)
  local area=player.gui.left
  local old=area[TRACKER]
  if old and old.valid then old.destroy() end
  local p=pref(player.index)
  if not p.tracker then return end
  local context=M.context(player.force)
  local quest=p.pinned and defs.by_id[p.pinned]
  if not quest or not M.available(player.force,quest,context) then
    quest=M.next_quest(player.force,context)
    p.pinned=quest and quest.id or nil
  end
  if not quest then return end
  local theme=themes.get(quest.chapter)
  local frame=area.add{type="frame",name=TRACKER,direction="vertical",
    caption=L("tracker-title")}
  frame.style.maximal_width=286
  local chapter=frame.add{type="flow",direction="horizontal"}
  chapter.style.horizontal_spacing=7
  local chapter_art=chapter.add{type="sprite",sprite=themes.icon(quest.chapter)}
  chapter_art.style.width=22
  chapter_art.style.height=22
  local chapter_text=wrap(chapter,{"journal-chapter."..quest.chapter},225)
  chapter_text.style.font="default-bold"
  chapter_text.style.font_color=theme.primary
  accent_rule(frame,theme,245,3)
  local line=frame.add{type="flow",direction="horizontal"}
  line.style.horizontal_spacing=7
  local marker=line.add{type="sprite",sprite=quest_art(player.force,quest,context)}
  marker.style.width=30
  marker.style.height=30
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
  signal.style.font_color=done and {r=.51,g=.86,b=.73} or theme.soft
end
M.render_tracker=render_tracker
local function render_details(parent,player,quest,p,context,size)
  local panel=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame_with_padding"}
  panel.style.width=size.reader
  panel.style.height=size.body
  local inner=size.reader-38
  local status=M.state(player.force,quest,context)
  local theme=themes.get(quest.chapter)
  local banner=panel.add{type="flow",direction="horizontal"}
  banner.style.horizontal_spacing=10
  banner.style.vertical_align="center"
  local seal=banner.add{type="sprite",sprite=themes.icon(quest.chapter),
    tooltip={"journal-chapter."..quest.chapter}}
  seal.style.width=size.compact and 30 or 42
  seal.style.height=size.compact and 30 or 42
  local identification=banner.add{type="flow",direction="vertical"}
  identification.style.vertical_spacing=2
  local chapter_intro=label(identification,{"journal-chapter."..quest.chapter})
  chapter_intro.style.font="default-bold"
  chapter_intro.style.font_color=theme.primary
  if not size.compact then
    local atmosphere=label(identification,{"journal-mood."..quest.chapter})
    atmosphere.style.font_color=theme.soft
  end
  accent_rule(panel,theme,inner,3)
  local hero=panel.add{type="flow",direction="horizontal"}
  hero.style.horizontal_spacing=10
  local art=hero.add{type="sprite",
    sprite=quest_art(player.force,quest,context)}
  art.style.width=size.compact and 42 or 54
  art.style.height=size.compact and 42 or 54
  local hero_text=hero.add{type="flow",direction="vertical"}
  hero_text.style.vertical_spacing=2
  local hero_title=wrap(hero_text,{"journal-title."..quest.id},inner-82)
  hero_title.style.font="heading-2"
  hero_title.style.font_color=theme.primary

  local eyebrow=panel.add{type="flow",direction="horizontal"}
  eyebrow.style.horizontally_stretchable=true
  local sequence=label(eyebrow,L("entry-number",tostring(chapter_index(quest.chapter))))
  sequence.style.font="default-bold"
  tint(sequence,theme.soft)
  local status_label=label(eyebrow,L("status-"..status))
  status_label.style.font="default-bold"
  local objective_bar=panel.add{type="progressbar",
    value=status=="complete" and 1 or 0}
  objective_bar.style.width=inner
  objective_bar.style.height=8
  objective_bar.style.color=theme.primary

  local content_height=size.body-(size.compact and 253 or 292)
  local scroll=wheel_pane(panel,"razi_journal_reading",inner,content_height)
  local text_width=inner-18
  local prose=scroll.add{type="flow",direction="vertical"}
  prose.style.width=text_width
  prose.style.vertical_spacing=13
  local objective=prose.add{type="frame",direction="vertical",
    style="inside_deep_frame"}
  objective.style.width=text_width
  objective.style.padding=10
  subtitle(objective,"objective-heading",text_width-26,theme)
  accent_rule(objective,theme,math.min(text_width-26,185),3)
  local native=technology(player.force,quest,context)
  if quest.boss then
    wrap(objective,{"",L("objective-boss")," ",
      {"nexus-bosses.boss-"..quest.boss}},text_width-26)
    local record=context.nexus
    if record then
      tint(label(objective,L("nexus-victories",
        tostring(record.count),tostring(record.total))),
        {r=.55,g=.87,b=.75})
    end
  else
    wrap(objective,{"",L(quest.world and "objective-discovery"
      or "objective-research",
      native and native.localised_name or quest.world or quest.tech)},
      text_width-26)
  end
  if native and not native.researched then
    local blockers={}
    for _,prior in pairs(native.prerequisites or {}) do
      if not prior.researched then blockers[#blockers+1]=prior end
    end
    table.sort(blockers,function(a,b) return a.name<b.name end)
    for i=1,math.min(4,#blockers) do
      wrap(objective,{"",L("native-prerequisite")," ",
        blockers[i].localised_name},text_width-26)
    end
  end
  if status~="complete" then
    for _,required in ipairs(quest.requires or {}) do
      local prior=defs.by_id[required]
      if prior and M.available(player.force,prior,context)
        and not M.complete(player.force,prior,context) then
        wrap(objective,{"",L("requires-heading")," ",
          {"journal-title."..prior.id}},text_width-26)
      end
    end
  end
  -- The link is informational and never turns a researched milestone
  -- into a claim that freight actually shipped or a factory is running.
  local cargo_id=cargo_catalog.chain_for_quest(quest.id)
  if cargo_id and cargo_catalog.is_installed(player.force,cargo_id) then
    local bridge=prose.add{type="frame",direction="vertical",
      style="inside_shallow_frame_with_padding"}
    bridge.style.width=text_width
    local heading=wrap(bridge,L("cargo-bridge-heading"),text_width-26)
    heading.style.font="default-bold"
    heading.style.font_color=theme.primary
    wrap(bridge,L("cargo-bridge-description"),text_width-26)
    local link=bridge.add{type="button",caption=L("cargo-bridge-open"),
      tags={razi_journal_action="open-cargo",id=quest.id}}
    link.tooltip=L("cargo-bridge-tooltip")
  end
  if native then
    draw_gallery(prose,"science-pack-heading",
      science_gallery(native),text_width,12,theme)
    draw_gallery(prose,"recipe-unlock-heading",
      unlock_gallery(native),text_width,8,theme)
    recipe_gallery(prose,quest,native,text_width,theme)
  end
  section(prose,"tip-heading",{"journal-tip."..quest.id},text_width,theme)
  section(prose,"chapter-context",
    {"journal-chapter-story."..quest.chapter},text_width,theme)
  section(prose,"story-heading",{"journal-story."..quest.id},text_width,theme)
  local forecast=weather.for_quest(quest)
  if forecast then
    local sky=section(prose,"weather-heading",
      {"journal-weather."..forecast.world},text_width,theme)
    tint(wrap(sky,L(forecast.enabled and "weather-active"
      or "weather-inactive"),text_width),
      forecast.enabled and {r=.54,g=.85,b=.75} or {r=.72,g=.74,b=.79})
  end

  -- Never let the long Nexus and pin actions overflow narrow readers.
  local actions=panel.add{type="table",
    column_count=size.reader<700 and 2 or 4}
  actions.style.horizontal_spacing=8
  actions.style.vertical_spacing=6
  if quest.boss then
    actions.add{type="button",caption=L("nexus-open-codex"),
      tags={razi_journal_action="nexus-codex",id=quest.boss}}
  end
  local pinned=p.tracker and p.pinned==quest.id
  actions.add{type="button",caption=L(pinned
    and "tracker-hide" or "tracker-show"),
    tags={razi_journal_action="pin",id=quest.id}}
  actions.add{type="button",caption=L("previous-in-chapter"),
    tags={razi_journal_action="previous-in-chapter"}}
  actions.add{type="button",caption=L("next-in-chapter"),
    tags={razi_journal_action="next-in-chapter"}}
end

-- Wrapped, selectable labels replace the old too-wide chapter and quest
-- buttons. One chapter jump selector covers distant chapters with no bars.
local function render_chapters(parent,player,p,context,size,view,plan)
  local frame=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame_with_padding"}
  frame.style.width=size.rail
  frame.style.height=size.body
  local inner=size.rail-35
  subtitle(frame,"navigator-title",inner)
  local names={}
  for _,ch in ipairs(defs.chapters) do
    names[#names+1]={"journal-chapter."..ch.id}
  end
  local dropdown=frame.add{type="drop-down",
    name="razi_journal_chapter_picker",items=names,
    selected_index=chapter_index(p.chapter)}
  dropdown.style.width=inner
  subtitle(frame,"search-heading",inner)
  local find_row=frame.add{type="flow",direction="horizontal"}
  find_row.style.horizontal_spacing=5
  local search=find_row.add{type="textfield",name="razi_journal_search",
    text=p.query or "",tooltip=L("search-tooltip")}
  search.style.width=inner-44
  local clear=find_row.add{type="button",style="tool_button",
    caption="×",tooltip=L("clear-search"),
    tags={razi_journal_action="clear-search"}}
  clear.style.width=32
  clear.style.height=32
  local scroll=wheel_pane(frame,"razi_journal_navigation",
    inner,size.body-151)
  local column=scroll.add{type="flow",direction="vertical"}
  column.style.width=inner-13
  column.style.vertical_spacing=7
  local selected_element

  plan=plan or M.guidance(player.force,context,view)
  local priority=column.add{type="frame",direction="vertical",
    style="inside_shallow_frame"}
  priority.style.width=inner-16
  priority.style.padding=11
  -- FrameStyle has no vertical_spacing; content uses native frame spacing.
  local heading=wrap(priority,L("guidance-heading"),inner-40)
  heading.style.font="default-bold"
  heading.style.font_color={r=1,g=.84,b=.60}
  accent_rule(priority,themes.get("network"),math.min(inner-42,135),2)
  if not plan.primary then
    wrap(priority,L("guidance-none"),inner-38)
  else
    for i,entry in ipairs(plan.selected) do
      local chapter_theme=themes.get(entry.chapter)
      local row=priority.add{type="flow",direction="horizontal"}
      row.style.horizontal_spacing=6
      local image=row.add{type="sprite",
        sprite=quest_art(player.force,entry.quest,context)}
      image.style.width=22
      image.style.height=22
      local item=row.add{type="label",style="clickable_label",
        caption={"",L(i==1 and "guidance-main" or "guidance-parallel"),
          " ",{"journal-title."..entry.quest.id}},
        tags={razi_journal_action="guidance-select",id=entry.quest.id},
        tooltip={"journal-chapter."..entry.chapter}}
      item.style.single_line=false
      item.style.maximal_width=inner-79
      item.style.font_color=chapter_theme.primary
      if i==1 then item.style.font="default-bold" end
    end
  end
  if plan.blocker then
    local blocked=plan.blocker
    local warning=wrap(priority,L("guidance-blocker-heading"),inner-38)
    warning.style.font="default-bold"
    warning.style.font_color={r=1,g=.70,b=.46}
    local link=priority.add{type="label",style="clickable_label",
      caption={"journal-title."..blocked.quest.id},
      tags={razi_journal_action="guidance-select",id=blocked.quest.id}}
    link.style.single_line=false
    link.style.maximal_width=inner-38
    if blocked.disabled then
      wrap(priority,L("guidance-disabled"),inner-38)
    elseif blocked.tech_blockers and #blocked.tech_blockers>0 then
      wrap(priority,L("guidance-tech-needs",
        blocked.tech_blockers[1].localised_name),inner-38)
    elseif blocked.quest_blockers and #blocked.quest_blockers>0 then
      wrap(priority,L("guidance-quest-needs",
        {"journal-title."..blocked.quest_blockers[1]}),inner-38)
    end
  end
  local found=false

  for index,chapter in ipairs(defs.chapters) do
    local theme=themes.get(chapter.id)
    local data=view.chapters[chapter.id]
    local completed,total=data.completed,data.total
    local available={}
    for _,quest in ipairs(data.quests) do
      if state_matches_filter(view.states[quest.id],p.filter)
        and matches_query(quest,p.query) then
        available[#available+1]=quest
      end
    end
    if #available>0 then
      found=true
      local open=p.query~="" or p.chapter==chapter.id
      local card=column.add{type="frame",direction="vertical",
        style="inside_shallow_frame"}
      card.style.width=inner-16
      card.style.padding=8
      local head=card.add{type="flow",direction="horizontal"}
      head.style.horizontal_spacing=6
      local chapter_art=head.add{type="sprite-button",style="slot_button",
        sprite=themes.icon(chapter.id),
        tags={razi_journal_action="chapter",id=chapter.id},
        tooltip={"journal-chapter."..chapter.id}}
      chapter_art.style.width=34
      chapter_art.style.height=34
      local toggle=head.add{type="button",style="tool_button",
        caption=open and "▾" or "▸",
        tags={razi_journal_action="chapter",id=chapter.id},
        tooltip={"journal-chapter."..chapter.id}}
      toggle.style.width=24
      toggle.style.height=30
      toggle.style.font_color=theme.primary
      local heading=wrap(head,{"journal-chapter."..chapter.id},inner-112)
      heading.style.font="default-bold"
      heading.style.font_color=theme.primary
      heading.style.vertical_align="center"
      if open then
        accent_rule(card,theme,inner-40,3)
        local mood=wrap(card,{"journal-mood."..chapter.id},inner-40)
        mood.style.font_color=theme.soft
      end
      local counts=card.add{type="flow",direction="vertical"}
      counts.style.vertical_spacing=4
      local count=label(counts,
        L("chapter-progress-short",tostring(completed),tostring(total)))
      count.style.font_color=theme.soft
      local progress=counts.add{type="progressbar",
        value=total>0 and completed/total or 0}
      progress.style.width=math.max(95,inner-43)
      progress.style.height=9
      progress.style.color=theme.primary
      if open then
        for _,quest in ipairs(available) do
          local state=view.states[quest.id]
          local item=card.add{type="flow",direction="horizontal"}
          item.style.width=inner-34
          item.style.horizontal_spacing=7
          local icon=item.add{type="sprite",sprite=quest_art(
            player.force,quest,context)}
          icon.style.width=24
          icon.style.height=24
          local control=item.add{type="button",style="tool_button",
            caption=state=="complete" and "✓"
              or state=="active" and "●" or "○",
            tags={razi_journal_action="select",id=quest.id},
            tooltip={"journal-title."..quest.id}}
          control.style.width=27
          control.style.height=27
          local color=state=="complete" and {r=.48,g=.85,b=.67}
            or state=="active" and {r=.98,g=.79,b=.46}
            or {r=.58,g=.61,b=.68}
          control.style.font_color=color
          local choice=item.add{type="label",style="clickable_label",
            caption={"journal-title."..quest.id},
            tags={razi_journal_action="select",id=quest.id},
            tooltip=L("select-objective")}
          choice.style.single_line=false
          choice.style.maximal_width=inner-108
          choice.style.font_color=quest.id==p.selected
            and theme.primary or {r=.94,g=.94,b=.94}
          if quest.id==p.selected then
            control.style.font_color=theme.primary
            choice.style.font="default-bold"
            selected_element=choice
          end
        end
      end
    end
  end
  if not found then wrap(column,L("nothing-found"),inner-28) end
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
  local rail=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame_with_padding"}
  rail.style.width=size.rail
  rail.style.height=size.body
  subtitle(rail,"archive-navigator",size.rail-38,themes.get("echoes"))
  local left=wheel_pane(rail,"razi_journal_archive_navigation",
    size.rail-35,size.body-61)
  local collection=left.add{type="flow",direction="vertical"}
  collection.style.width=size.rail-56
  collection.style.vertical_spacing=12
  local chosen,focus
  for _,record in ipairs(records) do
    local quest=defs.by_id[record.unlock]
    local opened=quest and M.complete(player.force,quest,context)
    if opened and (not chosen or record.id==p.record) then chosen=record end
    local row=collection.add{type="flow",direction="horizontal"}
    row.style.horizontal_spacing=8
    local mark
    if opened then
      mark=row.add{type="sprite-button",style="slot_button",
        sprite=quest_art(player.force,quest,context),
        tags={razi_journal_action="record",id=record.id},
        tooltip={"journal-record-title."..record.id}}
    else
      mark=row.add{type="button",style="tool_button",
        caption="◇",enabled=false,
        tooltip={"journal-record-title."..record.id}}
      mark.style.font_color={r=.59,g=.62,b=.68}
    end
    mark.style.width=30
    mark.style.height=30
    local choice=row.add{type="label",style="clickable_label",
      caption={"journal-record-title."..record.id},
      tags={razi_journal_action="record",id=record.id}}
    choice.style.single_line=false
    choice.style.maximal_width=size.rail-105
    choice.style.font_color=opened and {r=.95,g=.95,b=.95}
      or {r=.58,g=.60,b=.65}
    if opened and record.id==p.record then
      choice.style.font="default-bold"
      focus=choice
    end
  end
  if focus then pcall(function() left.scroll_to_element(focus) end) end

  local paper=parent.add{type="frame",direction="vertical",
    style="inside_shallow_frame_with_padding"}
  paper.style.width=size.reader
  paper.style.height=size.body
  if not chosen then
    subtitle(paper,"archive-sealed-heading",size.reader-48)
    wrap(paper,L("archive-sealed"),size.reader-48)
    return
  end
  p.record=chosen.id
  local chosen_quest=defs.by_id[chosen.unlock]
  local archive_theme=themes.get(chosen_quest and chosen_quest.chapter or "echoes")
  subtitle(paper,"archive-entry-label",size.reader-48,archive_theme)
  accent_rule(paper,archive_theme,size.reader-42,3)
  local cover=paper.add{type="flow",direction="horizontal"}
  cover.style.horizontal_spacing=10
  local entry_quest=defs.by_id[chosen.unlock]
  if entry_quest then
    local cover_art=cover.add{type="sprite",
      sprite=quest_art(player.force,entry_quest,context)}
    cover_art.style.width=45
    cover_art.style.height=45
  end
  local title=wrap(cover,{"journal-record-title."..chosen.id},size.reader-112)
  title.style.font="heading-2"
  local origin=label(paper,{"journal-record-origin."..chosen.id})
  origin.style.font_color=archive_theme.primary
  paper.add{type="line",direction="horizontal"}
  local reading=wheel_pane(paper,"razi_journal_archive_reading",
    size.reader-38,size.body-179)
  local page=reading.add{type="flow",direction="vertical"}
  page.style.width=size.reader-67
  page.style.vertical_spacing=18
  wrap(page,{"journal-record-body."..chosen.id},size.reader-67)
  wrap(paper,L("archive-disclaimer"),size.reader-48)
end

function M.quest_by_id(id)
  return defs.by_id[id]
end
local function draw(player,focus_search)
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=pref(player.index)
  local size=M.layout(player.display_resolution,player.display_scale)
  local window_theme=themes.get(p.chapter or "calidus")
  frame.clear()
  frame.style.width=size.width
  frame.style.padding=12
  local head=frame.add{type="flow",direction="horizontal"}
  head.style.horizontally_stretchable=true
  head.style.vertical_align="center"
  head.style.horizontal_spacing=16
  local insignia=head.add{type="sprite",
    sprite=themes.icon(p.chapter or "calidus")}
  insignia.style.width=40
  insignia.style.height=40
  local heading=head.add{type="flow",direction="vertical"}
  heading.style.vertical_spacing=1
  local title=label(heading,L(size.compact and "window-compact" or "window"))
  title.style.font=size.compact and "heading-2" or "heading-1"
  title.style.font_color=window_theme.primary
  local kicker=tint(label(heading,L("header-eyebrow")),window_theme.soft)
  kicker.style.font="default-bold"
  local drag=head.add{type="empty-widget",style="draggable_space"}
  drag.style.horizontally_stretchable=true
  drag.style.height=35
  drag.drag_target=frame
  local refresh=head.add{type="button",caption=L("refresh"),
    tags={razi_journal_action="refresh"}}
  refresh.style.minimal_width=size.compact and 66 or 94
  local dismiss=head.add{type="button",caption=L("close"),
    tags={razi_journal_action="close"}}
  dismiss.style.minimal_width=size.compact and 66 or 94
  if not size.compact then
    local description=wrap(frame,L("subtitle-short"),size.width-42)
    description.style.font_color={r=.74,g=.77,b=.81}
  end

  local context=M.context(player.force)
  local view=p.view=="archive" and nil or M.view_status(player.force,context)
  local plan=view and M.guidance(player.force,context,view)
  local done,total,ready
  if view then
    done,total,ready=view.done,view.total,view.ready
  else
    done,total,ready=M.summary(player.force,context)
  end
  local totals=frame.add{type="frame",direction="horizontal",
    style="inside_shallow_frame_with_padding"}
  totals.style.horizontally_stretchable=true
  totals.style.vertical_align="center"
  -- FrameStyle does not expose horizontal_spacing. Use a child flow for
  -- custom column gaps instead of attempting to style the frame itself.
  totals.style.padding=10
  local metrics_row=totals.add{type="flow",direction="horizontal"}
  metrics_row.style.horizontally_stretchable=true
  metrics_row.style.vertical_align="center"
  metrics_row.style.horizontal_spacing=size.compact and 9 or 24
  local metric=metrics_row.add{type="flow",direction="vertical"}
  metric.style.vertical_spacing=4
  metric.style.minimal_width=size.compact and 96 or 165
  subtitle(metric,"completion-heading")
  local completed=label(metric,L("completion-value",
    tostring(done),tostring(total)))
  completed.style.font="heading-2"
  completed.style.font_color={r=.51,g=.86,b=.73}
  local readiness=metrics_row.add{type="flow",direction="vertical"}
  readiness.style.vertical_spacing=4
  readiness.style.minimal_width=size.compact and 92 or 156
  subtitle(readiness,"ready-heading")
  local ready_label=label(readiness,L("ready-value",tostring(ready)))
  ready_label.style.font="heading-2"
  ready_label.style.font_color={r=1,g=.78,b=.45}
  local meter=metrics_row.add{type="flow",direction="vertical"}
  meter.style.horizontally_stretchable=true
  meter.style.vertical_spacing=7
  subtitle(meter,"campaign-progress-heading")
  local overall=meter.add{type="progressbar",
    value=total>0 and done/total or 0}
  overall.style.horizontally_stretchable=true
  overall.style.height=14
  overall.style.color=themes.get(p.chapter or "calidus").primary

  local toolbar=frame.add{type="flow",direction="horizontal"}
  toolbar.style.horizontal_spacing=12
  for _,view in ipairs({"quests","archive"}) do
    local active=p.view==view
    local button=toolbar.add{type="button",
      caption=L("view-"..view),
      tags={razi_journal_action="view",id=view}}
    button.style.font=active and "default-bold" or "default"
    button.style.font_color=active and window_theme.primary
      or {r=.90,g=.90,b=.90}
  end
  if p.view~="archive" then
    toolbar.add{type="button",caption=L("next-milestone"),
      tags={razi_journal_action="next"}}
  end
  local filterbar=frame.add{type="flow",direction="horizontal"}
  filterbar.style.horizontal_spacing=9
  filterbar.style.vertical_align="center"
  if p.view=="archive" then
    local unlocked,all=M.unlocked_records(player.force,context)
    tint(label(filterbar,L("archive-progress",
      tostring(unlocked),tostring(all))),themes.get("echoes").primary)
  else
    subtitle(filterbar,"filter-heading")
    for _,filter in ipairs({"all","ready","unfinished","done"}) do
      local active=p.filter==filter
      local button=filterbar.add{type="button",
        caption=L("filter-"..filter),
        tags={razi_journal_action="filter",id=filter}}
      button.style.font=active and "default-bold" or "default"
      button.style.font_color=active and window_theme.primary
        or {r=.86,g=.86,b=.86}
    end
  end

  local body=frame.add{type="flow",direction="horizontal"}
  body.style.width=size.width-24
  body.style.height=size.body
  body.style.horizontal_spacing=12
  if p.view=="archive" then
    render_archive(body,player,p,context,size)
  else
    local selected=select_quest(player.force,p,context,plan)
    local search=render_chapters(body,player,p,context,size,view,plan)
    if focus_search then pcall(function() search.focus() end) end
    if selected then
      render_details(body,player,selected,p,context,size)
    else
      local empty=body.add{type="frame",
        style="inside_shallow_frame_with_padding"}
      empty.style.width=size.reader
      wrap(empty,L("missing-quest"),size.reader-40)
    end
  end
  local foot=wrap(frame,L("footer-hint"),size.width-38)
  foot.style.font_color={r=.63,g=.67,b=.71}
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
function M.open_quest(player,id)
  local quest=defs.by_id[id]
  if not (player and player.valid and quest
    and M.available(player.force,quest)) then return false end
  local p=pref(player.index)
  p.selected=quest.id
  p.chapter=quest.chapter
  p.filter="all"
  p.query=""
  p.view="quests"
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
  local top=player.gui.top[TOP]
  if not (top and top.valid) then
    top=player.gui.top.add{type="sprite-button",
      name=TOP,sprite="razi-journal-book-icon",
      style="slot_button",tooltip=L("button-tooltip"),
      tags={razi_journal_action="toggle"}}
    top.style.width=36
    top.style.height=36
  end
  render_tracker(player)
end
function M.sync_all()
  for _,player in pairs(game.connected_players or {}) do M.sync(player) end
end
function M.on_removed(index)
  if storage.razi_expedition_journal then
    storage.razi_expedition_journal[index]=nil
  end
end
local function refresh_force(force)
  if not force then return end
  for _,player in pairs(game.connected_players or {}) do
    if player.force==force then
      local frame=player.gui.screen[FRAME]
      if frame and frame.valid then draw(player) end
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
-- Refresh only visible boss objectives during the existing ten-second
-- maintenance tick. No global entity scans or per-tick remote calls.
function M.refresh_nexus_visible()
  if not (remote and remote.interfaces and
    remote.interfaces["nexus-bosses"]) then return end
  for _,player in pairs(game.connected_players or {}) do
    local p=storage.razi_expedition_journal
      and storage.razi_expedition_journal[player.index]
    if p then
      local frame=player.gui.screen[FRAME]
      if frame and frame.valid and (p.chapter=="deepworks"
        or (p.selected and defs.by_id[p.selected]
          and defs.by_id[p.selected].boss)) then
        draw(player)
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
  local action=tags and tags.razi_journal_action
  if not action then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if action=="toggle" then M.toggle(player);return end
  if action=="close" then close(player);return end
  if action=="nexus-codex" then
    if not trials.open_codex(player,tags.id) then
      player.print(L("nexus-codex-unavailable"))
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
    if operations.open_cargo(player,chain,target) then
      close(player)
    end
    return
  end
  if action=="tracker-open" then
    local p=pref(player.index)
    p.selected=p.pinned
    open(player)
    return
  end
  local p=pref(player.index)
  if (action=="select" or action=="guidance-select") and
    defs.by_id[tags.id] and M.available(player.force,defs.by_id[tags.id]) then
    p.selected=tags.id
    p.chapter=defs.by_id[tags.id].chapter
    p.filter="all"
    p.view="quests"
    p.query=""
    p.reveal_selection=true
  elseif action=="chapter" then
    p.chapter=p.chapter==tags.id and false or tags.id
  elseif action=="view" and (tags.id=="quests" or tags.id=="archive") then
    p.view=tags.id
  elseif action=="record" then
    local context=M.context(player.force)
    for _,record in ipairs(records) do
      if record.id==tags.id then
        local quest=defs.by_id[record.unlock]
        if quest and M.complete(player.force,quest,context) then
          p.record=record.id
          p.view="archive"
        end
        break
      end
    end
  elseif action=="filter" and ({all=true,ready=true,unfinished=true,
      done=true})[tags.id] then
    p.filter=tags.id
  elseif action=="next" then
    local next=M.next_quest(player.force)
    if next then
      p.selected=next.id
      p.chapter=next.chapter
      p.filter="all"
      p.view="quests"
      p.query=""
      p.reveal_selection=true
    end
  elseif action=="next-in-chapter" or action=="previous-in-chapter" then
    local context=M.context(player.force)
    local choices={}
    for _,quest in ipairs(defs.quests) do
      if quest.chapter==p.chapter and M.available(player.force,quest,context)
        and M.show_in_filter(player.force,quest,p.filter,context) then
        choices[#choices+1]=quest
      end
    end
    for i,quest in ipairs(choices) do
      if quest.id==p.selected then
        local offset=action=="previous-in-chapter" and -2 or 0
        p.selected=choices[(i+offset)%#choices+1].id
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
  elseif action~="refresh" then return end
  draw(player)
end
function M.text_changed(event)
  local element=event and event.element
  if not (element and element.valid
    and element.name=="razi_journal_search") then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local p=pref(player.index)
  local query=(element.text or ""):sub(1,80)
  if p.query==query then return end
  p.query=query
  -- Select the first matching visible milestone so the reader follows search.
  if query~="" then
    local context=M.context(player.force)
    for _,quest in ipairs(defs.quests) do
      if M.show_in_filter(player.force,quest,p.filter,context)
        and matches_query(quest,query) then
        p.selected=quest.id
        p.chapter=quest.chapter
        break
      end
    end
  end
  draw(player,true)
end
function M.selection_changed(event)
  local element=event and event.element
  if not (element and element.valid
    and element.name=="razi_journal_chapter_picker") then return end
  local chapter=defs.chapters[element.selected_index]
  local player=game.get_player(event.player_index)
  if not (chapter and player and player.valid) then return end
  local p=pref(player.index)
  p.chapter=chapter.id
  p.filter="all"
  p.query=""
  p.reveal_selection=true
  local context=M.context(player.force)
  for _,quest in ipairs(defs.quests) do
    if quest.chapter==chapter.id
      and M.available(player.force,quest,context) then
      p.selected=quest.id
      break
    end
  end
  draw(player)
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
  if player.gui.screen[FRAME] then
    close(player)
    open(player)
  end
end
return M
