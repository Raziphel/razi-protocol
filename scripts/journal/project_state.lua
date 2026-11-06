-- Which projects exist, which ones a force may see, their neighbours in the list and the
-- completion of each, read from the systems that own them.
local M=require("scripts.journal.project_api")
local dyson=require("scripts.dyson.dyson")
local convergence=require("scripts.convergence.convergence")
local story=require("lib.story")
local platform_projects=require("scripts.projects.platform_projects")
local great_projects=require("scripts.projects.great_projects")
local nexus_trials=require("scripts.compatibility.nexus-bosses.trials")
local ids={"platform","voyage","skybridge","beltbreaker","dyson","array","transceiver","nexus-trials","ark","convergence"}
-- The Archive Array project only recovers story records, so it exists only
-- together with the story.
local plain_ids={}
for _,id in ipairs(ids) do
  if id~="array" then plain_ids[#plain_ids+1]=id end
end
local function project_ids()
  return story.enabled() and ids or plain_ids
end
-- The projects every player has, with or without the story.
M.plain_ids=plain_ids
local project_technologies={
  dyson="slp-dyson-sphere",
  array="razi-archive-array",
  transceiver="razi-intergalactic-transceiver-signal",
  convergence="razi-convergence-commission"
}
function M.visible(force,id)
  if not M.valid(id) then return false end
  local setting=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  if not (setting and setting.value==true) then return true end
  -- The first project must always be discoverable to new players.
  if id=="platform" then return true end
  -- The maiden voyage unlocks after a genuine built platform.
  if id=="voyage" then return platform_projects.snapshot(force).platform end
  if id=="skybridge" then
    return platform_projects.snapshot(force).voyage
      and script and script.active_mods
      and script.active_mods["orbital-cannon"]~=nil or false
  end
  if id=="beltbreaker" then
    local tech=force and force.technologies
      and force.technologies["planet-discovery-fulgora"]
    return tech and tech.researched==true or false
  end
  if id=="nexus-trials" then
    local tech=force and force.technologies
      and force.technologies["planet-discovery-nexus"]
    local completed=nexus_trials.snapshot(force)
    return (completed and completed.count>0) or
      (tech and tech.researched==true) or false
  end
  if id=="ark" then
    local tech=force and force.technologies
      and force.technologies["razi-intergalactic-transceiver-signal"]
    return tech and tech.researched==true or false
  end
  local name=project_technologies[id]
  if id=="dyson" and force and force.technologies
    and force.technologies["planet-discovery-sunorbit"] then
    name="planet-discovery-sunorbit"
  end
  local tech=force and force.technologies and force.technologies[name]
  if not tech then return false end
  if tech.researched then return true end
  if tech.enabled==false then return false end
  for _,required in pairs(tech.prerequisites or {}) do
    if not required.researched then return false end
  end
  return true
end
function M.valid(id)
  for _,value in ipairs(project_ids()) do if value==id then return true end end
  return false
end
function M.adjacent(force,id,step,known_visible)
  local visible=known_visible or {}
  if not known_visible then
    for _,project in ipairs(project_ids()) do
      if M.visible(force,project) then visible[#visible+1]=project end
    end
  end
  for index,project in ipairs(visible) do
    if project==id then return visible[index+step] end
  end
  return nil
end
function M.research_related(name)
  if name=="razi-intergalactic-transceiver-signal"
    or name=="razi-convergence-commission"
    or name=="razi-convergence-synchronization"
    or name=="razi-convergence-ignition" then return true end
  for _,stage in ipairs(dyson.stages) do
    if stage[1]==name then return true end
  end
  return false
end
M.project_ids=project_ids
-- A completion bar measures the *named* native milestone, never a guessed
-- percentage of satellites built, ships delivered or worlds conquered.
-- The third snapshot value preserves detail for action guidance.
local function status_for(force,id,ships)
  if id=="skybridge" then return great_projects.skybridge(force)
  elseif id=="beltbreaker" then return great_projects.beltbreaker(force)
  elseif id=="array" then return great_projects.array(force)
  elseif id=="nexus-trials" then
    local state=nexus_trials.snapshot(force)
    return state and state.count or 0,#nexus_trials.order,state
  elseif id=="ark" then return great_projects.ark(force)
  elseif id=="platform" or id=="voyage" then
    local facts=ships or platform_projects.snapshot(force)
    return (facts[id] and 1 or 0),1,facts
  elseif id=="dyson" then
    return dyson.status(force)
  elseif id=="convergence" then
    if not convergence.available(force) then return 0,0 end
    return convergence.progress(force)
  end
  local tech=force.technologies["razi-intergalactic-transceiver-signal"]
  if not tech then return 0,0 end
  local active=force.get_entity_count
    and force.get_entity_count("kr-activated-intergalactic-transceiver")>0
  -- Research alone does not activate the actual K2SO machine.
  return active and 1 or 0,1,tech
end
M.status_for=status_for
