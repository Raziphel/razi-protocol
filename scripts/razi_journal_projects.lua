-- Project dashboards share the Expedition Journal window.
-- Research, receivers, shipments and victory remain owned by source systems.
local M={}
local dyson=require("scripts.galactic_dyson")
local trade=require("scripts.galactic_trade")
local convergence=require("scripts.razi_convergence")
local catalog=require("scripts.galactic_trade_catalog")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
local icons=require("scripts.razi_journal_icons")
-- Factorio prohibits require() inside GUI events; resolve this at control load.
local objectives=require("scripts.razi_journal_data")
local platform_projects=require("scripts.razi_platform_projects")
local great_projects=require("scripts.razi_great_projects")
local nexus_trials=require("scripts.razi_nexus_trials")
local quest_by_technology={}
for _,quest in ipairs(objectives.quests or {}) do
  if quest.tech and not quest.convergence and
    not quest_by_technology[quest.tech] then
    quest_by_technology[quest.tech]=quest.id
  end
end
local L=function(k,...) return {"journal-ui."..k,...} end
local ids={"platform","voyage","skybridge","beltbreaker","dyson","array","transceiver","nexus-trials","ark","convergence"}
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
  for _,value in ipairs(ids) do if value==id then return true end end
  return false
end
function M.adjacent(force,id,step,known_visible)
  local visible=known_visible or {}
  if not known_visible then
    for _,project in ipairs(ids) do
      if M.visible(force,project) then visible[#visible+1]=project end
    end
  end
  for index,project in ipairs(visible) do
    if project==id then return visible[index+step] end
  end
  return nil
end
function M.cargo_available(force)
  local tech=force and force.technologies
    and force.technologies["interplanetary-trade-logistics"]
  local setting=settings and settings.global
    and settings.global["razi-hide-spoilers"]
  if setting and setting.value==true then
    if not tech then return false end
    if not tech.researched and tech.enabled==false then return false end
    if not tech.researched then
      for _,required in pairs(tech.prerequisites or {}) do
        if not required.researched then return false end
      end
    end
  end
  return catalog.snapshot(force).available>0
end
function M.valid_cargo(force,chain,target)
  if not chain or not catalog.is_installed(force,chain) then return false end
  for _,entry in ipairs(catalog.chains) do
    if entry.id==chain then
      return not target or catalog.chain_for_technology(target)==chain
    end
  end
  return false
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
local function transceiver(parent,player,width)
  local tech=player.force.technologies["razi-intergalactic-transceiver-signal"]
  local active=player.force.get_entity_count("kr-activated-intergalactic-transceiver")>0
  local title=parent.add{type="label",caption=L("project-transceiver")}
  title.style.font="heading-2"
  local status=parent.add{type="label",caption=L(not tech
    and "project-transceiver-missing" or active
    and "project-transceiver-active" or tech.researched
    and "project-transceiver-researched" or "project-transceiver-waiting")}
  status.style.single_line=false
  status.style.maximal_width=width
  if tech and not tech.researched then
    for _,required in pairs(tech.prerequisites or {}) do
      if not required.researched then
        local note=parent.add{type="label",caption={
          "",L("project-transceiver-needs")," ",required.localised_name}}
        note.style.single_line=false
        note.style.maximal_width=width
      end
    end
  end
  local note=parent.add{type="label",caption=L("project-transceiver-desc")}
  note.style.single_line=false
  note.style.maximal_width=width
end
-- Five build-and-expedition project dossiers. All completion values come from the
-- original mods: there is no fabricated megaproject percentage.
local HUES={
  ink={r=.933,g=.890,b=.808},
  quiet={r=.60,g=.66,b=.65},
  gold={r=.82,g=.69,b=.48},
  green={r=.58,g=.80,b=.66},
  unused={r=.39,g=.46,b=.51}
}
local PROJECT_ART={
  platform="item/space-platform-starter-pack",
  voyage="entity/thruster",
  skybridge="item/processing-unit",
  beltbreaker="technology/rocket-turret",
  array="item/razi-archive-relay",
  ark="item/space-platform-foundation",
  dyson="razi-dyson-works-stage-",
  transceiver="technology/razi-intergalactic-transceiver-signal",
  ["nexus-trials"]="technology/nexus-convergence",
  convergence="technology/razi-convergence-commission"
}
local function art_for(id,force,statuses)
  if id=="dyson" then
    local recorded=statuses and statuses.dyson
    local finished=recorded and recorded[1] or select(1,dyson.status(force))
    return PROJECT_ART.dyson..math.min(6,finished)
  end
  local path=PROJECT_ART[id]
  if helpers and helpers.is_valid_sprite_path
    and not helpers.is_valid_sprite_path(path) then
    return "razi-journal-book-icon"
  end
  return path
end
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

local function platform_reader(parent,player,width,id,status)
  local facts=status[3] or {}
  -- The native platform/voyage tracker only verifies two conditions here.
  -- Keep instructional flight notes distinct from actual source evidence.
  local title=parent.add{type="label",caption=L("project-verified-heading")}
  title.style.font="default-bold"
  title.style.font_color=HUES.gold
  local tech=player.force.technologies
    and player.force.technologies["space-platform"]
  local checks
  if id=="platform" then
    checks={
      {key="project-verified-platform-research",
        done=tech and tech.researched==true,available=tech~=nil},
      {key="project-verified-platform-built",
        done=facts.platform==true,available=true}
    }
  else
    checks={
      {key="project-verified-voyage-platform",
        done=facts.platform==true,available=true},
      {key="project-verified-voyage-crossing",
        done=facts.voyage==true,available=true}
    }
  end
  for _,step in ipairs(checks) do
    if step.available then
      local row=parent.add{type="flow",direction="horizontal"}
      row.style.horizontal_spacing=8
      local mark=row.add{type="label",caption=step.done and "✓" or "○"}
      mark.style.font_color=step.done and HUES.green or HUES.gold
      local text=row.add{type="label",caption=L(step.key)}
      text.style.single_line=false
      text.style.maximal_width=math.max(125,width-45)
    end
  end
  local flight=parent.add{type="label",caption=L("project-advisory-heading")}
  flight.style.font="default-bold"
  flight.style.font_color=HUES.quiet
  local started=parent.add{type="label",
    caption=L(id=="platform" and "project-platform-guide"
      or "project-voyage-guide")}
  started.style.single_line=false
  started.style.maximal_width=width
  local steps=id=="platform"
    and {"project-platform-step-research","project-platform-step-launch",
      "project-platform-step-hub"}
    or {"project-voyage-step-thrusters","project-voyage-step-route",
      "project-voyage-step-arrival"}
  for i,key in ipairs(steps) do
    local row=parent.add{type="flow",direction="horizontal"}
    row.style.horizontal_spacing=9
    local num=row.add{type="label",caption=string.format("%02d",i)}
    num.style.font_color=HUES.gold
    local label=row.add{type="label",caption=L(key)}
    label.style.single_line=false
    label.style.maximal_width=math.max(130,width-56)
  end
  if status[1]>0 then
    local key=id=="platform" and "project-platform-success"
      or "project-voyage-success"
    local name=id=="platform" and facts.first_name
      or facts.voyage_name
    local message=parent.add{type="label",
      caption=L(key,name or L("project-unnamed-platform"))}
    message.style.font="default-bold"
    message.style.single_line=false
    message.style.maximal_width=width
    message.style.font_color={r=.49,g=.83,b=.67}
  end
end
local function great_project_reader(parent,player,width,id,status)
  local detail=status[3]
  local desc=parent.add{type="label",caption=L("project-"..id.."-guide")}
  desc.style.single_line=false
  desc.style.maximal_width=width
  if id=="skybridge" then
    if detail.missing then
      local warning=parent.add{type="label",
        caption=L("project-skybridge-native-unavailable")}
      warning.style.single_line=false
      warning.style.maximal_width=width
    end
    for _,lane in ipairs(detail.options or {}) do
      local row=parent.add{type="flow",direction="horizontal"}
      row.style.vertical_align="center"
      row.style.horizontal_spacing=6
      local label=row.add{type="label",caption=L("project-skybridge-link",
        {"space-location-name."..lane.source},
        {"space-location-name."..lane.target})}
      label.style.single_line=false
      label.style.maximal_width=math.max(110,width-115)
      if not (detail.chosen and detail.chosen.from) then
        row.add{type="button",caption=L("project-skybridge-sign"),
          tags={razi_journal_action="skybridge-sign",
            a=lane.source,b=lane.target}}
      end
    end
    if detail.chosen and detail.chosen.from then
      local claim=parent.add{type="label",
        caption=L("project-skybridge-pending",
          {"space-location-name."..detail.chosen.from},
          {"space-location-name."..detail.chosen.to})}
      claim.style.single_line=false
      claim.style.maximal_width=width
      if not detail.chosen.delivered then
        parent.add{type="button",caption=L("project-skybridge-deliver"),
          tags={razi_journal_action="skybridge-deliver"}}
      end
    end
    local honesty=parent.add{type="label",
      caption=L("project-skybridge-evidence")}
    honesty.style.single_line=false
    honesty.style.maximal_width=width
  elseif id=="beltbreaker" then
    for _,belt in ipairs({"vibrant","umbra"}) do
      local row=parent.add{type="label",caption=L(
        detail and detail[belt] and "project-beltbreaker-crossed"
          or "project-beltbreaker-uncrossed",
        L("project-beltbreaker-"..belt))}
      row.style.single_line=false
      row.style.maximal_width=width
    end
  elseif id=="array" then
    for _,site in ipairs(detail or {}) do
      local row=parent.add{type="label",caption=L(
        "project-array-site",{"razi-route-intel.system-"..site.system},
        {"space-location-name."..site.world})}
      row.style.single_line=false
      row.style.maximal_width=width
    end
    for i=1,math.min(3,status[1]) do
      local evidence=parent.add{type="label",caption=L("project-array-record-"..i)}
      evidence.style.single_line=false
      evidence.style.maximal_width=width
    end
  else
    local candidate=parent.add{type="label",
      caption=L("project-ark-requirements",
        tostring(great_projects.ark_weight))}
    candidate.style.single_line=false
    candidate.style.maximal_width=width
    if detail then
      local ship=parent.add{type="label",
        caption=L("project-ark-candidate",detail)}
      ship.style.single_line=false
      ship.style.maximal_width=width
    end
  end
end

-- Each circle comes from the Nexus Bosses API's real per-force defeats.
-- Source boss fights, trophy drops, warp key and music remain untouched.
local function nexus_trials_reader(parent,player,width,status)
  local state=status[3]
  local intro=parent.add{type="label",
    caption=L("project-nexus-guide")}
  intro.style.single_line=false
  intro.style.maximal_width=width
  if not state then
    local unavailable=parent.add{type="label",
      caption=L("project-next-nexus-unavailable")}
    unavailable.style.single_line=false
    unavailable.style.maximal_width=width
    return
  end
  for index,stage in ipairs(nexus_trials.circles) do
    local stage_count=0
    for _,boss in ipairs(stage.bosses) do
      if nexus_trials.defeated(state,boss) then stage_count=stage_count+1 end
    end
    local card=parent.add{type="frame",
      style="inside_shallow_frame",direction="vertical"}
    card.style.horizontally_stretchable=true
    card.style.padding=8
    local heading=card.add{type="label",
      caption=L("project-nexus-circle",tostring(index),
        L("project-nexus-stage-"..stage.id),
        tostring(stage_count),tostring(#stage.bosses))}
    heading.style.font="default-bold"
    for _,boss in ipairs(stage.bosses) do
      local complete=nexus_trials.defeated(state,boss)
      local row=card.add{type="flow",direction="horizontal"}
      row.style.horizontal_spacing=8
      row.style.vertical_align="center"
      local mark=row.add{type="label",caption=complete
        and L("project-nexus-defeated") or L("project-nexus-unbeaten")}
      mark.style.font_color=complete
        and {r=.48,g=.88,b=.67} or {r=.86,g=.68,b=.47}
      local name=row.add{type="label",
        caption={"nexus-bosses.boss-"..boss}}
      name.style.single_line=false
      name.style.maximal_width=math.max(110,width-174)
      local spacer=row.add{type="empty-widget"}
      spacer.style.horizontally_stretchable=true
      row.add{type="button",style="tool_button",
        caption=L("project-nexus-open-codex"),
        tags={razi_journal_action="nexus-codex",id=boss}}
    end
  end
  local signal=parent.add{type="label",
    caption=L("project-nexus-silence")}
  signal.style.single_line=false
  signal.style.maximal_width=width
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
    return L("project-next-convergence-core")
  end
  local stage=convergence.stages[current]
  if not stage then return L("project-next-unavailable") end
  return L("project-next-convergence-deliver",
    {"razi-ops.convergence-stage-"..stage.id}),
    "convergence-"..stage.id
end

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

local function project_progress(id,done,total)
  if total==0 then return L("project-unavailable") end
  return L("project-progress-"..id,tostring(done),tostring(total))
end

local function project_entry(parent,player,p,id,width,index,statuses)
  local selected=p.project==id
  -- Treat the left column as a project index, not ten stacked cards.
  -- Selection is expressed through type weight and a single small bar.
  local card=parent.add{type="flow",direction="vertical"}
  card.style.width=width
  card.style.padding=3
  card.style.vertical_spacing=4
  local head=card.add{type="flow",direction="horizontal"}
  head.style.horizontal_spacing=8
  head.style.vertical_align="center"
  -- The emblem itself is the navigation target, not a separate grey arrow.
  icons.button(head,art_for(id,player.force,statuses),"project_button",
    {razi_journal_action="project",id=id},L("project-caption-"..id))
  local copy=head.add{type="flow",direction="vertical"}
  copy.style.vertical_spacing=2
  local over=copy.add{type="label",caption=L("project-number",index)}
  over.style.font_color=selected and HUES.gold or HUES.quiet
  local name=copy.add{type="label",style="clickable_label",
    caption=L("project-"..id),tooltip=L("project-caption-"..id),
    tags={razi_journal_action="project",id=id}}
  name.style.font=selected and "default-bold" or "default"
  name.style.font_color=selected and HUES.ink or {r=.73,g=.78,b=.81}
  name.style.single_line=false
  name.style.maximal_width=math.max(100,width-73)
  local snapshot=statuses[id]
  local complete,total=snapshot[1],snapshot[2]
  local count=card.add{type="label",
    caption=project_progress(id,complete,total)}
  count.style.font_color=HUES.quiet
  local meter=card.add{type="progressbar",
    value=total>0 and complete/total or 0}
  meter.style.width=math.max(95,width-(selected and 32 or 18))
  meter.style.height=3
  meter.style.color=HUES.gold
  meter.visible=selected
end
local function project_reader(parent,player,p,size,width,compact,statuses,displayed,reader_override)
  local reader=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  reader.style.width=width
  local reader_height=reader_override or (compact
    and math.max(175,size.body-175) or size.body)
  reader.style.height=reader_height
  reader.style.padding=11
  local controls=reader.add{type="flow",direction="horizontal"}
  controls.style.horizontally_stretchable=true
  controls.style.horizontal_spacing=7
  controls.style.vertical_align="center"
  local folio=controls.add{type="label",caption=L("project-dossier")}
  folio.style.font="default-bold"
  folio.style.font_color=HUES.gold
  local spacer=controls.add{type="empty-widget"}
  spacer.style.horizontally_stretchable=true
  for _,step in ipairs({-1,1}) do
    local target=M.adjacent(player.force,p.project,step,displayed)
    if target then
      controls.add{type="button",style="tool_button",
        caption=L(step<0 and "project-previous" or "project-next"),
        tooltip=L("project-"..target),
        tags={razi_journal_action="project-cycle",id=target}}
    end
  end
  local header=reader.add{type="flow",direction="horizontal"}
  header.style.horizontal_spacing=12
  header.style.vertical_align="center"
  icons.sprite(header,art_for(p.project,player.force,statuses),"project_hero")
  local copy=header.add{type="flow",direction="vertical"}
  copy.style.vertical_spacing=4
  local title=copy.add{type="label",caption=L("project-"..p.project)}
  title.style.font="heading-2"
  title.style.font_color=HUES.ink
  title.style.single_line=false
  title.style.maximal_width=math.max(125,width-112)
  local description=copy.add{type="label",
    caption=L("project-caption-"..p.project)}
  description.style.single_line=false
  description.style.maximal_width=math.max(125,width-112)
  description.style.font_color=HUES.quiet
  local accent=reader.add{type="progressbar",value=1}
  accent.style.width=math.min(104,width-38)
  accent.style.height=3
  accent.style.color=HUES.gold
  -- Real stage totals provide a compact project cover summary; the
  -- substantial source-owned construction detail remains in the reader.
  local current=statuses[p.project]
  local done,total=current[1],current[2]
  local digest=reader.add{type="flow",direction="horizontal"}
  digest.style.vertical_align="center"
  digest.style.horizontal_spacing=9
  local count=digest.add{type="label",
    caption=project_progress(p.project,done,total)}
  count.style.font="default-bold"
  count.style.font_color=total>0 and done==total
    and HUES.gold or HUES.quiet
  local gauge=reader.add{type="progressbar",
    value=total>0 and done/total or 0}
  gauge.style.width=math.min(240,width-38)
  gauge.style.height=4
  gauge.style.color=HUES.gold
  local scroll=reader.add{type="scroll-pane",direction="vertical",
    name="razi_journal_project_reader"}
  scroll.style.width=width-32
  scroll.style.height=math.max(80,reader_height-(compact and 185 or 202))
  scroll.tags={razi_scroll_context=p.project}
  scroll.horizontal_scroll_policy="never"
  scroll.vertical_scroll_policy="auto"
  scroll.style.horizontally_squashable=true
  local content=scroll.add{type="flow",direction="vertical"}
  content.style.width=width-54
  content.style.vertical_spacing=10
  -- Project advice belongs at the top of the dossier's own scroll area,
  -- leaving the narrow-screen reader free to show its real details.
  local next=content.add{type="frame",direction="vertical",
    style="razi_journal_callout"}
  next.style.width=math.max(120,width-72)
  next.style.padding=10
  -- FrameStyle has no vertical_spacing: spacing belongs to a nested Flow.
  local next_body=next.add{type="flow",direction="vertical"}
  next_body.style.horizontally_stretchable=true
  next_body.style.vertical_spacing=4
  local eyebrow=next_body.add{type="label",caption=L("project-next-heading")}
  eyebrow.style.font="default-bold"
  eyebrow.style.font_color=HUES.gold
  local advice,quest_id=next_action(player.force,p.project,current)
  local guidance=next_body.add{type="label",caption=advice}
  guidance.style.single_line=false
  guidance.style.maximal_width=math.max(100,width-98)
  if quest_id and M.next_quest(player.force,p.project,current)==quest_id then
    next_body.add{type="button",caption=L("project-open-next"),
      tags={razi_journal_action="project-next"}}
  end
  local perspective=next_body.add{type="label",
    caption=L("project-measures-"..p.project)}
  perspective.style.single_line=false
  perspective.style.maximal_width=math.max(100,width-98)
  perspective.style.font_color=HUES.quiet
  local context=content.add{type="label",
    caption=L("project-context-"..p.project)}
  context.style.single_line=false
  context.style.maximal_width=math.max(115,width-72)
  context.style.font_color=HUES.quiet
  local options={embedded=true,width=width-68}
  if p.project=="platform" or p.project=="voyage" then
    platform_reader(content,player,width-68,p.project,current)
  elseif p.project=="skybridge" then
    great_project_reader(content,player,width-68,"skybridge",current)
  elseif p.project=="beltbreaker" then
    great_project_reader(content,player,width-68,"beltbreaker",current)
  elseif p.project=="array" then
    great_project_reader(content,player,width-68,"array",current)
  elseif p.project=="nexus-trials" then
    nexus_trials_reader(content,player,width-68,current)
  elseif p.project=="ark" then
    great_project_reader(content,player,width-68,"ark",current)
  elseif p.project=="dyson" then
    dyson.render(content,player,options)
  elseif p.project=="convergence" then
    convergence.render(content,player,options)
  else
    transceiver(content,player,width-68)
  end
end
local function cargo_reference(parent,player,p,size)
  -- Keep the real industrial reference and freight board, not a project tile.
  local pane=parent.add{type="flow",direction="vertical"}
  pane.style.width=size.width-36
  pane.style.height=size.body
  pane.style.vertical_spacing=7
  local bar=pane.add{type="flow",direction="horizontal"}
  bar.style.vertical_align="center"
  local title=bar.add{type="label",caption=L("project-industry-reference")}
  title.style.font="heading-2"
  title.style.font_color=HUES.gold
  local spacer=bar.add{type="empty-widget"}
  spacer.style.horizontally_stretchable=true
  bar.add{type="button",caption=L("project-back-to-projects"),
    tags={razi_journal_action="project-back"}}
  local scroll=pane.add{type="scroll-pane",direction="vertical",
    name="razi_journal_project_reader"}
  scroll.style.width=size.width-43
  scroll.style.height=math.max(150,size.body-55)
  scroll.tags={razi_scroll_context="cargo:"..(p.logistics_tab or "overview")}
  scroll.horizontal_scroll_policy="never"
  scroll.vertical_scroll_policy="dont-show-but-allow-scrolling"
  local content=scroll.add{type="flow",direction="vertical"}
  content.style.width=size.width-72
  content.style.vertical_spacing=12
  trade.render(content,player,p,{embedded=true,width=size.width-83})
end
function M.render(parent,player,p,size)
  if p.project=="cargo" then
    if M.cargo_available(player.force) then
      cargo_reference(parent,player,p,size)
      return
    end
    -- Existing saves with a locked Cargo reference return to Projects.
    p.project="platform"
    p.cargo_focus=nil
    p.cargo_target=nil
  end
  local displayed={}
  for _,id in ipairs(ids) do
    if M.visible(player.force,id) then displayed[#displayed+1]=id end
  end
  if #displayed==0 then
    local empty=parent.add{type="label",caption=L("project-spoiler-locked")}
    empty.style.font_color=HUES.quiet
    return
  end
  local known=false
  for _,id in ipairs(displayed) do
    if id==p.project then known=true break end
  end
  if not known then p.project=displayed[1] end
  -- Each expensive source-owned project snapshot is evaluated once per
  -- redraw, even though the chosen project is drawn in two separate panes.
  local statuses={}
  local ships=platform_projects.snapshot(player.force)
  for _,id in ipairs(displayed) do
    statuses[id]={status_for(player.force,id,ships)}
  end
  local compact=size.width<900
  if compact then
    local stack=parent.add{type="flow",direction="vertical"}
    stack.style.width=size.width-37
    stack.style.vertical_spacing=8
    local title=stack.add{type="label",caption=L("projects-heading")}
    title.visible=not p.reader_focus
    title.style.font="default-bold"
    title.style.font_color=HUES.gold
    local columns=size.width<620 and 1 or 2
    -- Ten project cards must not push the active dossier off a compact screen.
    local selector_height=math.max(88,math.min(148,math.floor(size.body*.28)))
    local selector=stack.add{type="scroll-pane",
      name="razi_journal_project_navigation",direction="vertical",
      horizontal_scroll_policy="never",vertical_scroll_policy="auto"}
    selector.style.width=size.width-43
    selector.style.height=selector_height
    selector.visible=not p.reader_focus
    local grid=selector.add{type="table",column_count=columns}
    grid.style.horizontal_spacing=9
    grid.style.vertical_spacing=9
    local cell=math.max(170,math.floor((size.width-55-(columns-1)*9)/columns))
    for index,id in ipairs(displayed) do
      project_entry(grid,player,p,id,cell,
        string.format("%02d",index),statuses)
    end
    project_reader(stack,player,p,size,size.width-43,true,statuses,displayed,
      math.max(170,size.body-(p.reader_focus and 35 or selector_height+42)))
  else
    local rail=parent.add{type="frame",name="razi_journal_project_index",
      direction="vertical",style="razi_journal_index"}
    rail.visible=not p.reader_focus
    rail.style.width=size.rail
    rail.style.height=size.body
    rail.style.padding=10
    local section=rail.add{type="label",caption=L("projects-heading")}
    section.style.font="default-bold"
    section.style.font_color=HUES.gold
    local selector=rail.add{type="scroll-pane",
      name="razi_journal_project_navigation",direction="vertical",
      horizontal_scroll_policy="never",vertical_scroll_policy="auto"}
    selector.style.width=size.rail-27
    selector.style.height=math.max(120,size.body-78)
    local entries=selector.add{type="flow",direction="vertical"}
    entries.style.width=size.rail-44
    entries.style.vertical_spacing=3
    for index,id in ipairs(displayed) do
      project_entry(entries,player,p,id,size.rail-45,
        string.format("%02d",index),statuses)
    end
    project_reader(parent,player,p,size,size.reader,false,statuses,displayed)
  end
end
function M.refresh(force) dyson_runtime.invalidate(force) end
return M
