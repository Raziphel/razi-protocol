-- Journal Systems: compact, source-owned monitoring. No simulation/state mirroring.
-- Other mods keep their control panels and gameplay authority.
local M={}
local ROOT="razi_journal_systems_reading"
local FRAME="razi_expedition_journal"
local BODY="razi_journal_systems_body"
local COLOR={
  ink={r=.933,g=.890,b=.808},muted={r=.72,g=.73,b=.71},
  green={r=.58,g=.80,b=.66},amber={r=.82,g=.69,b=.48},
  red={r=.91,g=.46,b=.45},teal={r=.52,g=.78,b=.76}
}
local function L(key,...) return {"journal-systems."..key,...} end
local function loaded(name)
  return script and script.active_mods and script.active_mods[name]~=nil
end
local function number(value)
  local n=tonumber(value)
  if n and n==n and n>=0 and n<math.huge then return n end
  return 0
end
local function pct(value,maximum)
  if maximum<=0 then return 0 end
  return math.max(0,math.min(1,value/maximum))
end

-- Planet Express does not currently expose a read-only remote API. Its own
-- validated, force-scoped top dock is a reliable snapshot without accessing
-- private storage or synthesizing delivery state. Never invent a zero count.
function M.fleet(player)
  if not loaded("planet-express") then return {installed=false} end
  local dock=player.gui.top["planet-express-monitor-dock"]
  local button=dock and dock.valid and dock["planet-express-monitor-dock-btn"]
  local caption=button and button.valid and button.caption
  if type(caption)=="table" and
     caption[1]=="planet-express.monitor-dock-summary" then
    local working,idle,stuck=tonumber(caption[2]),tonumber(caption[3]),tonumber(caption[4])
    if working and idle and stuck and working>=0 and idle>=0 and stuck>=0 then
      return {installed=true,ready=true,working=working,idle=idle,stuck=stuck}
    end
  end
  return {installed=true,ready=false}
end

-- Mirrors Nexus's published four-slot permission algorithm. Actual built
-- counts come from Factorio's O(1) force entity counter, never a world scan.
function M.cores(force)
  if not (loaded("Nexus-Updated") or loaded("Nexus")) then
    return {installed=false}
  end
  local tech=force.technologies["zero-point-energy-engine-core"]
  if not (tech and tech.researched) then
    return {installed=true,unlocked=false}
  end
  local maximum=1
  for i=1,3 do
    local upgrade=force.technologies["zpe-core-limit-"..i]
    if not (upgrade and upgrade.researched) then break end
    maximum=maximum+1
  end
  return {installed=true,unlocked=true,
    count=force.get_entity_count("zero-point-energy-engine-core"),maximum=maximum}
end

-- Optional, read-only source interface. Never touch the stabilizer control
-- or source storage; one inexpensive snapshot when the reader is visible.
function M.storm()
  local api=remote and remote.interfaces and remote.interfaces["nexus-threat"]
  if not (api and api.get_state) then return {available=false} end
  local ok,data=pcall(remote.call,"nexus-threat","get_state")
  if not (ok and type(data)=="table") then return {available=false} end
  return {available=true,instability=number(data.instability),
    shield=number(data.shield),maximum=number(data.max_shield),
    stabilizers=number(data.stabilizers),timer=number(data.storm_timer),
    active=data.storm_active==true,warning=data.storm_warning==true}
end

local function add_label(parent,name,caption,color,width)
  local el=parent.add{type="label",name=name,caption=caption}
  el.style.single_line=false
  if width then el.style.maximal_width=width end
  if color then el.style.font_color=color end
  return el
end
local function card(root,id,title,description,width,accent)
  local panel=root.add{type="frame",name=id,direction="vertical",
    style="razi_journal_callout"}
  panel.style.width=width
  panel.style.padding=10
  local header=add_label(panel,nil,L(title),COLOR.ink,width-32)
  header.style.font="default-bold"
  header.style.font_color=accent or COLOR.ink
  local stripe=panel.add{type="progressbar",name=id.."_accent",value=1}
  stripe.style.width=math.min(74,width-34)
  stripe.style.height=2
  stripe.style.color=accent or COLOR.teal
  local sub=add_label(panel,nil,L(description),COLOR.muted,width-32)
  sub.style.font="default"
  return panel
end
local function meter(panel,name,color,width)
  local bar=panel.add{type="progressbar",name=name,value=0}
  bar.style.width=width
  bar.style.height=4
  bar.style.color=color
  return bar
end

function M.render(parent,player,size)
  local width=math.max(285,size.width-66)
  local scroll=parent.add{type="scroll-pane",name=ROOT,direction="vertical",
    horizontal_scroll_policy="never",vertical_scroll_policy="auto"}
  scroll.style.width=math.max(301,size.width-45)
  scroll.style.height=size.body
  local intro=add_label(scroll,nil,L("intro"),COLOR.muted,width)
  intro.style.font="default-bold"

  local compact=size.compact or width<800
  local tile_width=compact and width or math.floor((width-12)/2)
  local top=scroll.add{type="flow",name="razi_sys_summary_row",
    direction=compact and "vertical" or "horizontal"}
  top.style.width=width
  -- Factorio uses different runtime style classes for horizontal/vertical flows.
  -- A horizontal flow rejects vertical_spacing (and vice versa).
  if compact then
    top.style.vertical_spacing=10
  else
    top.style.horizontal_spacing=12
  end

  local fleet=card(top,"razi_sys_fleet","fleet-title","fleet-description",tile_width,COLOR.teal)
  add_label(fleet,"razi_sys_fleet_status",L("fleet-waiting"),COLOR.ink,tile_width-32)
  add_label(fleet,nil,L("fleet-tip"),COLOR.muted,tile_width-32)

  local cores=card(top,"razi_sys_cores","zpe-title","zpe-description",tile_width,COLOR.amber)
  add_label(cores,"razi_sys_cores_status",L("zpe-locked"),COLOR.ink,tile_width-32)
  meter(cores,"razi_sys_cores_bar",COLOR.teal,tile_width-35)
  add_label(cores,nil,L("zpe-tip"),COLOR.muted,tile_width-32)

  local storm=card(scroll,"razi_sys_storm","storm-title","storm-description",width,COLOR.teal)
  add_label(storm,"razi_sys_storm_status",L("storm-unavailable"),COLOR.muted,width-32)
  add_label(storm,"razi_sys_instability",L("instability","0"),COLOR.ink,width-32)
  meter(storm,"razi_sys_instability_bar",COLOR.red,width-35)
  add_label(storm,"razi_sys_shield",L("shield","0","0"),COLOR.ink,width-32)
  meter(storm,"razi_sys_shield_bar",COLOR.teal,width-35)
  add_label(storm,"razi_sys_stabilizers",L("stabilizers","0"),COLOR.muted,width-32)
  add_label(storm,nil,L("storm-tip"),COLOR.muted,width-32)

  M.refresh_root(scroll,player)
end

function M.refresh_root(root,player)
  if not (root and root.valid) then return end
  local top=root["razi_sys_summary_row"]
  local fleet=top and top["razi_sys_fleet"]
  local cores=top and top["razi_sys_cores"]
  local storm=root["razi_sys_storm"]
  if not (fleet and cores and storm) then return end

  local fs=M.fleet(player)
  local fleet_line=fleet["razi_sys_fleet_status"]
  if not fs.installed then
    fleet_line.caption=L("fleet-missing")
    fleet_line.style.font_color=COLOR.muted
  elseif not fs.ready then
    fleet_line.caption=L("fleet-waiting")
    fleet_line.style.font_color=COLOR.amber
  else
    fleet_line.caption=L("fleet-counts",fs.working,fs.idle,fs.stuck)
    fleet_line.style.font_color=fs.stuck>0 and COLOR.red or COLOR.green
  end

  local cs=M.cores(player.force)
  local core_line=cores["razi_sys_cores_status"]
  local core_bar=cores["razi_sys_cores_bar"]
  if not cs.installed then
    core_line.caption=L("zpe-missing")
    core_line.style.font_color=COLOR.muted
    core_bar.value=0
  elseif not cs.unlocked then
    core_line.caption=L("zpe-locked")
    core_line.style.font_color=COLOR.muted
    core_bar.value=0
  else
    core_line.caption=L("zpe-count",cs.count,cs.maximum)
    core_line.style.font_color=cs.count>=cs.maximum and COLOR.amber or COLOR.ink
    core_bar.value=pct(cs.count,cs.maximum)
  end

  local ws=M.storm()
  local status=storm["razi_sys_storm_status"]
  local unstable=storm["razi_sys_instability"]
  local unstable_bar=storm["razi_sys_instability_bar"]
  local shield=storm["razi_sys_shield"]
  local shield_bar=storm["razi_sys_shield_bar"]
  local stabilizers=storm["razi_sys_stabilizers"]
  local accent=storm["razi_sys_storm_accent"]
  if not ws.available then
    if accent then accent.style.color=COLOR.muted end
    status.caption=L("storm-unavailable")
    status.style.font_color=COLOR.muted
    unstable.visible=false
    unstable_bar.visible=false
    shield.visible=false
    shield_bar.visible=false
    stabilizers.visible=false
    return
  end
  unstable.visible=true
  unstable_bar.visible=true
  shield.visible=true
  shield_bar.visible=true
  stabilizers.visible=true
  if accent then
    accent.style.color=ws.active and COLOR.red
      or ws.warning and COLOR.amber or COLOR.teal
  end
  if ws.active then
    status.caption=L("storm-active",math.ceil(ws.timer))
    status.style.font_color=COLOR.red
  elseif ws.warning then
    status.caption=L("storm-warning",math.ceil(ws.timer))
    status.style.font_color=COLOR.amber
  else
    status.caption=L("storm-calm")
    status.style.font_color=COLOR.green
  end
  unstable.caption=L("instability",string.format("%.1f",ws.instability))
  unstable_bar.value=pct(ws.instability,100)
  shield.caption=L("shield",math.floor(ws.shield),math.floor(ws.maximum))
  shield_bar.value=pct(ws.shield,ws.maximum)
  stabilizers.caption=L("stabilizers",math.floor(ws.stabilizers))
end

-- The Systems folio now owns the small status readouts; hide only the
-- three verified source widgets and leave their Lua elements intact.
-- Planet Express refreshes its dock caption even while hidden, and checks
-- that clicks come from its own dock. We therefore never forge its events:
-- readers can temporarily reveal native controls for the full Monitor.
-- Nexus Threat's native slider also remains accessible on demand.
function M.sync_companion_widgets(player,show_native)
  if not (player and player.valid and player.gui and player.gui.top) then return end
  local top=player.gui.top
  local visible=show_native==true
  local function set_visible(name)
    local element=top[name]
    if element and element.valid and element.visible~=visible then
      element.visible=visible
    end
  end
  if loaded("planet-express") then
    set_visible("planet-express-monitor-dock")
  end
  if loaded("Nexus-Updated") or loaded("Nexus") then
    -- The source GUI currently contains only the ZPE core cap.
    set_visible("nexus_limit_frame")
  end
  if loaded("Nexus-Threat-Updated") or loaded("Nexus-Threat") then
    set_visible("nexus_toggle_button")
    set_visible("nexus_frame")
  end
end

function M.refresh(player)
  if not (player and player.valid) then return end
  local frame=player.gui.screen[FRAME]
  local body=frame and frame.valid and frame[BODY]
  local root=body and body.valid and body[ROOT]
  if root and root.valid then M.refresh_root(root,player) end
end
return M
