-- The Convergence panel: the progress, the five shipment cards and the checks the
-- finale asks for, drawn into the Journal. Adds M.render to the public table of
-- scripts/convergence/convergence.lua.
local M=require("scripts.convergence.api")
local defs=require("prototypes.technology.endgame.convergence")
local nexus_trials=require("scripts.compatibility.nexus-bosses.trials")
local story=require("lib.story")
local function L(key,...)
 return {"razi-ops."..key,...}
end
local function line(parent,key,width,...)
 local label=parent.add{type="label",caption=L(key,...)}
 label.style.single_line=false
 label.style.maximal_width=width
 return label
end
function M.render(parent,player,options)
 options=options or {}
 local layout_width=options.width or math.max(320,math.min(850,
  (player.display_resolution.width or 1280)/
   math.max(player.display_scale or 1,.5)-100))
 local width=math.max(250,math.floor(layout_width)-28)
 if not options.embedded then
  local heading=line(parent,"convergence-heading",width)
  heading.style.font="heading-1"
  heading.style.font_color={r=.88,g=.73,b=1}
 end
 line(parent,"convergence-overview",width)
 local scroll=options.embedded and parent
   or parent.add{type="scroll-pane",direction="vertical"}
 if not options.embedded then
   scroll.style.horizontally_stretchable=true
   scroll.horizontal_scroll_policy="never"
   scroll.style.height=math.min(560,math.max(230,
     math.floor(player.display_resolution.height/
       math.max(player.display_scale or 1,.5)*.59)))
 end
 if not M.available(player.force) then
  line(scroll,"convergence-unavailable",width)
  return
 end
 local force=player.force
 local progress,total,won=M.progress(force)
 local saved=M.record(force)
 local stat=line(scroll,"convergence-progress",width,
  tostring(progress),tostring(total))
 stat.style.font="default-bold"
 local fraction=M.assembly_fraction(force)
 local overall=scroll.add{type="progressbar",value=fraction}
 overall.style.horizontally_stretchable=true
 overall.style.height=16
 overall.style.color={r=.73,g=.58,b=.97}
 local percent=line(scroll,"convergence-assembly-percent",width,
  tostring(math.floor(fraction*100+.5)))
 percent.style.font="default-bold"
 local assembly=line(scroll,"convergence-assembly-heading",width)
 assembly.style.font="heading-2"
 line(scroll,"convergence-assembly-subtitle",width)
 -- Budget each card's real width, including padding and spacing,
 -- rather than squeezing five 135px labels into a narrow panel.
 local columns=width>=780 and 5 or (width>=480 and 3 or 2)
 local cell_width=math.floor((width-24-(columns-1)*6)/columns)
 local tiles=scroll.add{type="table",column_count=columns}
 tiles.style.horizontally_stretchable=true
 tiles.style.horizontal_spacing=6
 tiles.style.vertical_spacing=6
 for _,rule in ipairs(M.stages) do
  local donated=won and rule.count or
   ---@diagnostic disable-next-line: param-type-mismatch
   math.max(0,math.min(rule.count,saved.delivered[rule.id] or 0))
  local completed=donated==rule.count
  local shade=M.module_colors[rule.id]
  local tile=tiles.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
  tile.style.padding=6
  local image=tile.add{type="sprite",sprite="item/"..rule.item}
  image.style.width=32
  image.style.height=32
  local caption=tile.add{type="label",caption=
   {"razi-ops.convergence-stage-"..rule.id}}
  caption.style.single_line=false
  caption.style.maximal_width=math.max(72,cell_width-20)
  caption.style.font="default-bold"
  caption.style.font_color=shade
  local fill=tile.add{type="progressbar",value=donated/rule.count}
  fill.style.width=math.max(58,cell_width-24)
  fill.style.height=7
  fill.style.color=shade
  local marker=tile.add{type="label",caption={
   "razi-ops."..(completed and "convergence-tile-complete"
    or "convergence-tile-pending")}}
  marker.style.font_color=completed and {r=.48,g=.9,b=.72}
    or {r=.92,g=.74,b=.50}
 end
 if won then
  local win
  if story.visible(player) then
   win=scroll.add{type="label",caption=story.text(player,"finale","won",
    {"razi-ops.convergence-won"}),
    tooltip=story.key_tooltip(player,"finale","won")}
  else
   win=scroll.add{type="label",caption={"razi-story-off.convergence-won"}}
  end
  win.style.single_line=false
  win.style.maximal_width=width
  win.style.font_color={r=.48,g=.9,b=.72}
  local archive=scroll.add{type="frame",
   style="inside_shallow_frame",direction="vertical"}
  archive.style.horizontally_stretchable=true
  local title=line(archive,"convergence-archive-title",width)
  title.style.font="heading-2"
  if story.visible(player) then
   local message=archive.add{type="label",
    caption=story.text(player,"finale","archive-message",
     {"razi-ops.convergence-archive-message"}),
    tooltip=story.key_tooltip(player,"finale","archive-message")}
   message.style.single_line=false
   message.style.maximal_width=width
  else
   local note=archive.add{type="label",
    caption={"razi-story-off.convergence-archive-message"}}
   note.style.single_line=false
   note.style.maximal_width=width
  end
  if saved.completed_by then
   line(archive,"convergence-archive-operator",width,saved.completed_by)
  end
  if saved.completed_site then
   local site=saved.completed_site:gsub("-"," ")
   line(archive,"convergence-archive-site",width,site)
  end
  if saved.victory_tick then
   local seconds=math.floor(saved.victory_tick/60)
   local hours=math.floor(seconds/3600)
   local minutes=math.floor(seconds%3600/60)
   local secs=seconds%60
   line(archive,"convergence-archive-time",width,
    string.format("%d:%02d:%02d",hours,minutes,secs))
  end
 end
 -- Nexus trials are independently earned through real source-owned fights.
 -- The nine boss flags are authoritative; this panel does not spawn bosses.
 local trials_panel=scroll.add{type="frame",
  style="inside_shallow_frame",direction="vertical"}
 trials_panel.style.horizontally_stretchable=true
 local nexus=M.nexus_status(force)
 local count=nexus and nexus.count or 0
 local total=#nexus_trials.order -- luacheck: ignore 411
 local trials_title=line(trials_panel,"convergence-nexus-heading",width)
 trials_title.style.font="heading-2"
 line(trials_panel,nexus and "convergence-nexus-count"
  or "convergence-nexus-unavailable",width,
  tostring(count),tostring(total))
 if nexus and count<total then
  for _,boss in ipairs(nexus_trials.order) do
   if not nexus_trials.defeated(nexus,boss) then
    line(trials_panel,"convergence-nexus-missing",width,
      {"nexus-bosses.boss-"..boss})
   end
  end
 end
 -- Seven powered, independently built systems are the new physical
 -- countersignature. Never count technologies as functioning transmitters.
 local network=scroll.add{type="frame",
  style="inside_shallow_frame",direction="vertical"}
 network.style.horizontally_stretchable=true
 local wdone,wtotal,sites=M.witness_status(force)
 local witness_title=line(network,"convergence-witness-heading",width)
 witness_title.style.font="heading-2"
 line(network,"convergence-witness-count",width,
   tostring(wdone),tostring(wtotal))
 local network_research=force.technologies["razi-convergence-witness-network"]
 if network_research and not network_research.researched then
  line(network,"convergence-witness-research",width)
 end
 for _,site in ipairs(sites) do
  line(network,site.planet and "convergence-witness-online"
   or "convergence-witness-offline",width,
   {"razi-ops.convergence-system-"..site.system})
  if site.planet and story.visible(player) then
   local testimony=network.add{type="label",
    caption=story.text(player,"finale-testimony",site.system,
     {"razi-ops.convergence-witness-testimony-"..site.system}),
    tooltip=story.key_tooltip(player,"finale-testimony",site.system)}
   testimony.style.single_line=false
   testimony.style.maximal_width=width
   testimony.style.font_color={r=.73,g=.77,b=.82}
  end
 end
 -- Black-box recovery is shipment-gated; the reveal has tangible evidence.
 local blackbox=M.blackbox(force)
 if blackbox>0 and story.visible(player) then
  local archive=scroll.add{type="frame",
    style="inside_shallow_frame",direction="vertical"}
  archive.style.horizontally_stretchable=true
  local label=archive.add{type="label",
    caption=story.text(player,"finale","blackbox-heading",
     {"razi-ops.convergence-blackbox-heading"}),
    tooltip=story.key_tooltip(player,"finale","blackbox-heading")}
  label.style.single_line=false
  label.style.maximal_width=width
  label.style.font="heading-2"
  for i=1,blackbox do
    local note=archive.add{type="label",
     caption=story.text(player,"finale-blackbox",tostring(i),
      {"razi-ops.convergence-blackbox-"..i}),
     tooltip=story.key_tooltip(player,"finale-blackbox",tostring(i))}
    note.style.single_line=false
    note.style.maximal_width=width
  end
 end
 -- Complete personal landings, not technology research or an empty
 -- autopilot tour. Multiple real crew members may sign for one force.
 local expedition=scroll.add{type="frame",
   style="inside_shallow_frame",direction="vertical"}
 expedition.style.horizontally_stretchable=true
 local landed,required,stops,chart_ready=M.expedition_status(force)
 local expedition_title=line(expedition,"convergence-deep-tour-heading",width)
 expedition_title.style.font="heading-2"
 line(expedition,chart_ready and "convergence-deep-tour-count"
   or "convergence-deep-tour-unavailable",width,
   tostring(landed),tostring(required))
 for _,stop in ipairs(stops) do
   local item=line(expedition,stop.visited
     and "convergence-deep-tour-arrived"
     or "convergence-deep-tour-missing",width,stop.caption)
   item.style.font_color=stop.visited
     and {r=.48,g=.9,b=.72} or {r=.94,g=.72,b=.49}
 end
 line(expedition,"convergence-deep-tour-proof",width)
 -- A built, force-owned receiver is tangible evidence of the Dyson grid.
 -- The source mod remains authoritative for real satellite count and MW.
 local receiver_ready,receivers=M.dyson_readiness(force)
 local dyson=scroll.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
 dyson.style.horizontally_stretchable=true
 local heading=line(dyson,"convergence-dyson-title",width)
 heading.style.font="heading-2"
 line(dyson,receivers==nil and "convergence-dyson-unknown"
  or (receiver_ready and "convergence-dyson-ready"
  or "convergence-dyson-missing"),width,tostring(receivers or 0))
 for _,id in ipairs({"slp-dyson-sphere",
    "slp-dyson-sphere-grounded","ds-energy-loader-mk2"}) do
  local tech=force.technologies[id]
  if tech then
   line(dyson,tech.researched and "convergence-dyson-tech-done"
    or "convergence-dyson-tech-pending",width,tech.localised_name)
  end
 end
 local sequence=saved.transmission
 if sequence and not won then
  local panel=scroll.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
  panel.style.horizontally_stretchable=true
  local title=line(panel,"convergence-transmission-heading",width)
  title.style.font="heading-2"
  ---@diagnostic disable-next-line: assign-type-mismatch
  local elapsed=math.max(0,game.tick-sequence.started)
  local meter=panel.add{type="progressbar",
   value=math.min(1,elapsed/M.transmission_duration)}
  meter.style.horizontally_stretchable=true
  line(panel,"convergence-transmission-duration",width,
   tostring(math.max(0,math.ceil(
    (M.transmission_duration-elapsed)/60))))
  for i,beat in ipairs(M.transmission_beats) do -- luacheck: ignore 213
   local label=line(panel,
    i<=(sequence.beat or 1) and "convergence-transmission-beat-done"
     or "convergence-transmission-beat-pending",width,
    M.beat_text(i,player))
   if i==sequence.beat then label.style.font="default-bold" end
  end
 end
 local where=M.location(player)
 line(scroll,where and "convergence-at-site"
  or "convergence-travel",width)
 local commission=force.technologies[defs.commission]
 local sync=force.technologies[defs.authorization]
 local ignition=force.technologies[defs.ignition]
 line(scroll,commission.researched and "convergence-commission-complete"
  or "convergence-commission-pending",width)
 line(scroll,sync.researched and "convergence-sync-complete"
  or "convergence-sync-pending",width)
 line(scroll,ignition.researched and "convergence-ignition-complete"
  or "convergence-ignition-pending",width)
 if won and (saved.delivered.resonance or 0)<M.stages[4].count then
  line(scroll,"convergence-legacy-victory",width)
 end
 local next_index=M.current(force)
 if not won and not saved.transmission then
  local next_rule=M.stages[next_index]
  if next_rule then
   local advice=scroll.add{type="frame",
     style="inside_shallow_frame",direction="vertical"}
   advice.style.horizontally_stretchable=true
   local title=line(advice,"convergence-next-action-title",width)
   title.style.font="heading-2"
   line(advice,"convergence-next-action-stage",width,
    {"razi-ops.convergence-stage-"..next_rule.id})
   local researched=commission.researched
    and (next_index<3 or sync.researched)
    and (next_index<5 or ignition.researched)
   -- Not `required`: that name already holds the Deep Space stop count.
   local pending=not researched and (not commission.researched
     and commission or (not sync.researched and sync or ignition))
   if pending then
    line(advice,"convergence-next-action-research",width,
     pending.localised_name)
    local shown=0
    for _,prior in pairs(pending.prerequisites or {}) do
     if not prior.researched and shown<3 then
      line(advice,"convergence-next-action-prereq",width,
       prior.localised_name)
      shown=shown+1
     end
    end
   elseif next_index==5 and not nexus then
    line(advice,"convergence-next-action-nexus-source",width)
   elseif next_index==5 and count<total then
    line(advice,"convergence-next-action-nexus",width,
      tostring(count),tostring(total))
   elseif next_index==5 and wdone<wtotal then
    line(advice,"convergence-next-action-witnesses",width)
   elseif next_index==5 and (not chart_ready or landed<required) then
    line(advice,"convergence-next-action-deep-tour",width)
   elseif next_index==5 and not receiver_ready then
    line(advice,"convergence-next-action-receiver",width)
   elseif not (force.recipes and force.recipes[next_rule.item]
    and force.recipes[next_rule.item].enabled) then
    line(advice,"convergence-next-action-recipe",width)
   else
    line(advice,"convergence-next-action-freight",width)
   end
  end
 end
 -- Read one player's carried freight when the panel opens or redraws.
 -- No background inventory scans, and a remote camera cannot deliver it.
 local inventory=player.get_main_inventory()
 for i,rule in ipairs(M.stages) do
  local card=scroll.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
  card.style.horizontally_stretchable=true
  card.style.padding=9
  local title=card.add{type="flow",direction="horizontal"}
  local sprite=title.add{type="sprite",sprite="item/"..rule.item}
  sprite.style.width=35
  sprite.style.height=35
  local display=title.add{type="label",caption=L(
    "convergence-stage-"..rule.id)}
  display.style.font="heading-2"
  local donated=won and rule.count
   ---@diagnostic disable-next-line: param-type-mismatch
   or math.min(rule.count,saved.delivered[rule.id] or 0)
  local amount=line(card,"convergence-stage-progress",width,
   tostring(donated),tostring(rule.count))
  amount.style.font_color=donated>=rule.count
   and {r=.49,g=.87,b=.71} or {r=.98,g=.74,b=.49}
  local meter=card.add{type="progressbar",
   value=math.min(1,donated/rule.count)}
  meter.style.horizontally_stretchable=true
  meter.style.height=12
  local status=i<next_index and "finished"
   or (i>next_index and "pending")
   or (i>=5 and not ignition.researched and "ignition")
   or (i>=3 and not sync.researched and "synchronization")
   or "active"
  local state=line(card,"convergence-status-"..status,width)
  state.style.font="default-bold"
  local carried=inventory and inventory.valid
   and inventory.get_item_count(rule.item) or 0
  local cargo_available=false
  local amounts=saved.materials and saved.materials[rule.id] or {}
  local requirements={{rule.item,rule.count}}
  for _,part in ipairs(rule.supplies or {}) do requirements[#requirements+1]=part end
  for _,part in ipairs(requirements) do
   local credited=amounts[part[1]] or 0
   if part[1]==rule.item then
    credited=math.max(credited,saved.delivered[rule.id] or 0)
   end
   local owned=inventory and inventory.valid
    and inventory.get_item_count(part[1]) or 0
   if owned>0 and credited<part[2] then cargo_available=true end
   local row=card.add{type="label",caption={
    "", "[item="..part[1].."] ",tostring(credited),"/",tostring(part[2]),
    "  (",tostring(owned)," carried)"
   }}
   row.style.single_line=false
   row.style.maximal_width=width
  end
  line(card,"convergence-carried",width,tostring(carried))
  local recipe=force.recipes and force.recipes[rule.item]
  local recipe_state=not recipe and "convergence-recipe-unavailable"
   or (recipe.enabled and "convergence-recipe-ready"
   or "convergence-recipe-locked")
  line(card,recipe_state,width)
  line(card,"convergence-stage-description-"..rule.id,width)
  local build=card.add{type="label",caption=L(
    "convergence-build-"..rule.id)}
  build.style.single_line=false
  build.style.maximal_width=width
  local button=card.add{type="button",
   caption=L("convergence-submit"),
   tags={razi_ops_action="convergence-deliver",value=rule.id}}
  button.enabled=i==next_index and cargo_available and where~=nil
   and (i<3 or sync.researched)
   and (i<5 or (ignition.researched and receiver_ready))
   and commission.researched
 end
 line(scroll,"convergence-continued-play",width)
end
return M
