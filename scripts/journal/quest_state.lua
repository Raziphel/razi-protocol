-- What each quest is for a force: available, complete, active or locked, which
-- ones the Journal shows, the campaign view of one redraw, the next objective,
-- chapter completion times, and the search and filter tests.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local story=require("lib.story")
local trials=require("scripts.compatibility.nexus-bosses.trials")
local convergence=require("scripts.convergence.convergence")
local projects=require("scripts.journal.projects")
local guidance=require("scripts.journal.guidance")
local chapter_timing=require("scripts.journal.chapter_timing")
local journal_acts=require("scripts.journal.acts")
local search_names=require("scripts.journal.search_names")
local widgets=require("scripts.journal.widgets")
local L=widgets.L

-- The research-all cheat can fire thousands of events. We only need to
-- redraw for Codex milestones and world discovery unlocks.
local research_goals,world_goals,quests_for_technology={},{},{}
for _,quest in ipairs(defs.quests) do
  if quest.tech then
    -- Both native and replacement technology refresh this milestone.
    local names={quest.tech}
    for _,name in ipairs(quest.alternative_techs or {}) do
      names[#names+1]=name
    end
    for _,name in ipairs(names) do
      research_goals[name]=true
      local entries=quests_for_technology[name]
      if not entries then
        entries={}
        quests_for_technology[name]=entries
      end
      entries[#entries+1]=quest
    end
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
        if tech and (tech.researched or
          (tech.enabled~=false and tech.prototype
            and not tech.prototype.hidden)) then
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
      if proto and not proto.hidden
        and (tech.researched or tech.enabled~=false) then
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
-- With a player, the context carries the writer mark: a story-only quest is
-- shown to a writer even while the story is off. Calls without a player
-- (totals, chapter timing) never carry it.
function M.context(force,player)
  return {discoveries=M.discovery_index(force),nexus=trials.snapshot(force),
    writer=player~=nil and story.writer(player) or nil}
end
local function technology(force,quest,context)
  local t
  if quest.world then
    local index=context and context.discoveries or M.discovery_index(force)
    t=index[quest.world]
  else
    t=defs.resolve_technology(force,quest)
  end
  if not t then return nil end
  -- A technology's presence does not imply it can be researched.
  -- Retain completed research on old saves, but never offer disabled goals.
  if not t.researched and (t.enabled==false
    or (t.prototype and t.prototype.hidden)) then return nil end
  return t
end
function M.available(force,quest,context)
  if not technology(force,quest,context) then return false end
  if quest.story_only and not story.enabled()
    and not (context and context.writer) then return false end
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
  -- Respect native prerequisites of ALL research goals. A milestone is
  -- upcoming until its actual source research can be started.
  if not quest.boss and not quest.convergence then
    local native=technology(force,quest,context)
    for _,required in pairs(native and native.prerequisites or {}) do
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
-- One shared runtime map setting, off by default.
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

local function matches_query(quest,query,names)
  if not query or query=="" then return true end
  local corpus=search_names.corpus(quest).." "..(names and names[quest.id] or "")
  for word in search_names.fold(query):gmatch("%S+") do
    if not corpus:find(word,1,true) then return false end
  end
  return true
end
M.matches_query=matches_query

function M.quest_by_id(id)
  return defs.by_id[id]
end

return {technology=technology,completion_caption=completion_caption,
  state_matches_filter=state_matches_filter,matches_query=matches_query,
  quests_for_technology=quests_for_technology}
