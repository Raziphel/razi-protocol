-- What a project asks of the player next, and the quest that explains it.
local M=require("scripts.journal.project_api")
require("scripts.journal.project_state")
local style=require("scripts.journal.project_style")
local convergence=require("scripts.convergence.convergence")
local nexus_trials=require("scripts.compatibility.nexus-bosses.trials")
-- Factorio prohibits require() inside GUI events; resolve this at control load.
local objectives=require("scripts.journal.data")
local L=style.L
local status_for=M.status_for
local quest_by_technology={}
for _,quest in ipairs(objectives.quests or {}) do
  if quest.tech and not quest.convergence and
    not quest_by_technology[quest.tech] then
    quest_by_technology[quest.tech]=quest.id
  end
end
local function unmet(tech)
  local missing={}
  for _,required in pairs(tech and tech.prerequisites or {}) do
    if not required.researched then missing[#missing+1]=required end
  end
  table.sort(missing,function(a,b)return a.name<b.name end)
  return missing
end

-- Read-only next step from real source research, discoveries and deliveries.
-- Return a localized caption and optional quest ID for a safe Journal link.
local function next_action(force,id,status)
  local done,total,detail=status[1],status[2],status[3]
  if id=="cargo" then
    local research=detail and detail.research
    if research and not research.researched then
      return L("project-next-research",research.localised_name),
        quest_by_technology[research.name]
    end
    if total==0 then return L("project-next-cargo-platform") end
    if done<total then
      return L("project-next-cargo-unscheduled",tostring(total-done))
    end
    return L("project-next-cargo-done")
  end
  if total==0 then return L("project-next-unavailable") end
  if id=="platform" then
    if done==1 then return L("project-next-platform-done") end
    local research=force.technologies and force.technologies["space-platform"]
    if research and not research.researched then
      local missing=unmet(research)
      if #missing>0 then
        return L("project-next-prerequisite",missing[1].localised_name),
          quest_by_technology[missing[1].name]
      end
      return L("project-next-research",research.localised_name),
        quest_by_technology[research.name]
    end
    return L("project-next-platform-launch")
  elseif id=="voyage" then
    if done==1 then return L("project-next-voyage-done") end
    if not detail.platform then
      return L("project-next-voyage-platform")
    end
    return L("project-next-voyage-launch")
  elseif id=="skybridge" then
    if done==3 then return L("project-next-skybridge-done") end
    if detail and detail.missing then
      return L("project-next-skybridge-missing")
    end
    if not detail or not detail.options or #detail.options==0 then
      return L("project-next-skybridge-build")
    end
    if not detail.chosen or not detail.chosen.from then
      return L("project-next-skybridge-sign")
    end
    return L("project-next-skybridge-deliver")
  elseif id=="beltbreaker" then
    if done==2 then return L("project-next-beltbreaker-done") end
    return L(detail and detail.vibrant
      and "project-next-beltbreaker-umbra"
      or "project-next-beltbreaker-vibrant")
  elseif id=="array" then
    if done>=total then return L("project-next-array-done") end
    local tech=force.technologies and force.technologies["razi-archive-array"]
    if tech and not tech.researched then
      return L("project-next-research",tech.localised_name)
    end
    return L("project-next-array-build")
  elseif id=="nexus-trials" then
    if not detail then return L("project-next-nexus-unavailable") end
    if done==total then return L("project-next-nexus-done") end
    for _,boss in ipairs(nexus_trials.order) do
      if not nexus_trials.defeated(detail,boss) then
        return L("project-next-nexus-boss",
          {"nexus-bosses.boss-"..boss})
      end
    end
    return L("project-next-nexus-unavailable")
  elseif id=="ark" then
    if done==1 then return L("project-next-ark-done") end
    return L("project-next-ark-build")
  elseif id=="dyson" then
    for _,stage in ipairs(detail or {}) do
      if not stage.tech.researched then
        local missing=unmet(stage.tech)
        if #missing>0 then
          return L("project-next-prerequisite",missing[1].localised_name),
            quest_by_technology[missing[1].name]
        end
        if stage.tech.enabled==false then return L("project-next-disabled") end
        return L("project-next-research",stage.tech.localised_name),
          quest_by_technology[stage.tech.name]
      end
    end
    return L("project-next-dyson-build")
  elseif id=="transceiver" then
    if done==1 then return L("project-next-transceiver-done") end
    if detail and detail.researched then
      return L("project-next-transceiver-activate"),
        quest_by_technology["kr-intergalactic-transceiver"]
    end
    local missing=unmet(detail)
    if #missing>0 then
      return L("project-next-prerequisite",missing[1].localised_name),
        quest_by_technology[missing[1].name]
    end
    if detail and detail.enabled==false then
      return L("project-next-disabled")
    end
    return L("project-next-transceiver-research"),
      quest_by_technology["razi-intergalactic-transceiver-signal"]
  end
  if detail==true then return L("project-next-convergence-done") end
  local current=convergence.current(force)
  if current>#convergence.stages then
    return L("project-next-convergence-transmission")
  end
  local commission=force.technologies["razi-convergence-commission"]
  if commission and not commission.researched then
    return L("project-next-research",commission.localised_name),
      "convergence-commission"
  end
  -- Match the actual delivery gates in razi_convergence.stage_ready:
  -- later mandates cannot be submitted before synchronization/ignition.
  if current>=3 then
    local sync=force.technologies["razi-convergence-synchronization"]
    if sync and not sync.researched then
      return L("project-next-research",sync.localised_name),
        "convergence-synchronization"
    end
  end
  if current>=5 then
    local ignition=force.technologies["razi-convergence-ignition"]
    if ignition and not ignition.researched then
      return L("project-next-research",ignition.localised_name),
        "convergence-ignition-research"
    end
    local boss_status=nexus_trials.snapshot(force)
    if not boss_status then
      return L("project-next-nexus-unavailable")
    end
    if boss_status.count<boss_status.total then
      return L("project-next-convergence-nexus")
    end
    local witness=force.technologies["razi-convergence-witness-network"]
    if witness and not witness.researched then
      return L("project-next-research",witness.localised_name)
    end
    if select(1,convergence.witness_status(force))<7 then
      return L("project-next-convergence-witness")
    end
    local arrived,required,_,chart_ready=convergence.expedition_status(force)
    if not chart_ready or required==0 then
      return L("project-next-convergence-chart")
    end
    if arrived<required then
      return L("project-next-convergence-deep-tour",
        tostring(arrived),tostring(required))
    end
    local receivers_ready=convergence.dyson_readiness(force)
    if not receivers_ready then
      return L("project-next-convergence-receiver")
    end
  end
  local stage=convergence.stages[current]
  if not stage then return L("project-next-unavailable") end
  return L("project-next-convergence-deliver",
    {"razi-ops.convergence-stage-"..stage.id}),
    "convergence-"..stage.id
end

M.next_action=next_action
-- Only link to entries already present and visible under the active
-- spoiler setting; never reveal a future milestone through this shortcut.
function M.next_quest(force,id,known_status)
  if not known_status and not M.visible(force,id) then return nil end
  local status=known_status or {status_for(force,id)}
  local _,quest_id=next_action(force,id,status)
  local quest=quest_id and objectives.by_id[quest_id]
  if not quest then return nil end
  local spoiler=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  if spoiler and spoiler.value==true then
    if quest.tech then
      local tech=force.technologies and force.technologies[quest.tech]
      if not tech or (not tech.researched and tech.enabled==false) then
        return nil
      end
    elseif quest.world then
      -- World discovery links should not reveal locked native locations.
      local seen=false
      for _,tech in pairs(force.technologies or {}) do
        for _,effect in pairs(tech.prototype and tech.prototype.effects or {}) do
          if effect.type=="unlock-space-location"
            and effect.space_location==quest.world
            and (tech.researched or tech.enabled) then
            seen=true
            break
          end
        end
        if seen then break end
      end
      if not seen then return nil end
    end
  end
  return quest.id
end
