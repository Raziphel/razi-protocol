-- The dossier bodies of the individual projects: the maiden platform and voyage, the great
-- projects, the Nexus trials and the transceiver.
local style=require("scripts.journal.project_style")
local marks=require("scripts.journal.marks")
local story=require("lib.story")
local great_projects=require("scripts.projects.great_projects")
local nexus_trials=require("scripts.compatibility.nexus-bosses.trials")
local L=style.L
local HUES=style.HUES
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
      local mark=row.add{type="label",caption=step.done and marks.done or marks.pending}
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
local function great_project_reader(parent,player,width,id,status) -- luacheck: ignore 212
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
    -- The recovered fragments are story text.
    for i=1,story.enabled() and math.min(3,status[1]) or 0 do
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
local function nexus_trials_reader(parent,player,width,status) -- luacheck: ignore 212
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

return {transceiver=transceiver,platform=platform_reader,great=great_project_reader,
  nexus_trials=nexus_trials_reader}
