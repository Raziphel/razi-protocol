-- The Cargo Network project tabs. Its selected tab is a Journal preference;
-- source-backed counts are read only while this project is open.
local style=require("scripts.journal.project_style")
local fleet=require("scripts.cargo.fleet")
local orders=require("scripts.cargo.orders")
local infrastructure=require("scripts.cargo.infrastructure")
local catapult_network=require("scripts.compatibility.orbital-cannon.catapult_network")
local desk=require("scripts.cargo.desk_view")
local L=style.L
local HUES=style.HUES
local M={}

local function add_tab(parent,key,value,active)
  local folio=parent.add{type="flow",direction="vertical"}
  folio.style.vertical_spacing=3
  local button=folio.add{type="label",style="clickable_label",
    caption=L(key),tags={razi_journal_action="cargo-tab",tab=value}}
  button.style.font=active and "default-bold" or "default"
  button.style.font_color=active and HUES.ink or HUES.quiet
  if active then
    local rule=folio.add{type="progressbar",value=1}
    rule.style.width=76
    rule.style.height=2
    rule.style.color=HUES.gold
  end
end

local function line(parent,caption,width,color,font)
  local label=parent.add{type="label",caption=caption}
  label.style.single_line=false
  label.style.maximal_width=width
  if color then label.style.font_color=color end
  if font then label.style.font=font end
  return label
end

local function heading(parent,key)
  local label=parent.add{type="label",caption=L(key)}
  label.style.font="default-bold"
  label.style.font_color=HUES.gold
end

local function world_name(world) return {"space-location-name."..world} end

local function fleet_block(parent,facts,width)
  heading(parent,"cargo-fleet-heading")
  line(parent,L("cargo-fleet-counts",tostring(facts.platforms),
    tostring(facts.unscheduled),tostring(facts.in_transit)),width)
  if facts.unscheduled>0 then
    line(parent,L("cargo-unscheduled-note"),width,HUES.quiet)
  end
end

-- Worlds of the researched corridors, once each.
local function open_worlds(network)
  local worlds,seen={},{}
  for _,entry in ipairs(network.entries) do
    if entry.state=="researched" then
      for _,world in ipairs({entry.source,entry.target}) do
        if not seen[world] then
          seen[world]=true
          worlds[#worlds+1]=world
        end
      end
    end
  end
  return worlds
end

local function end_line(parent,world,found,width)
  local caption=found and L("cargo-end",world_name(world),
    tostring(found.launchers),tostring(found.platforms))
    or L("cargo-end-no-surface",world_name(world))
  line(parent,caption,width-14,HUES.quiet)
end

local function corridors_block(parent,player,width,network)
  heading(parent,"cargo-corridors-heading")
  if not network.installed then
    line(parent,L("cargo-corridors-absent"),width)
    return
  end
  if not network.enabled then
    line(parent,L("cargo-corridors-off"),width)
    return
  end
  if #network.entries==0 then
    line(parent,L("cargo-corridors-none"),width)
    return
  end
  local found=infrastructure.inspect(player.force,open_worlds(network))
  for _,entry in ipairs(network.entries) do
    local row=parent.add{type="flow",direction="vertical"}
    row.style.vertical_spacing=2
    if entry.state=="researched" then
      local details=row.add{type="flow",direction="horizontal"}
      details.style.vertical_align="center"
      details.style.horizontal_spacing=6
      line(details,L("cargo-corridor",world_name(entry.source),
        world_name(entry.target)),math.max(120,width-130),nil,"default-bold")
      details.add{type="button",caption=L("cargo-open-freight"),
        tags={razi_journal_action="cargo-route",
          id=orders.route_id(entry,entry.source),tab="freight"}}
      end_line(row,entry.source,found[entry.source],width)
      end_line(row,entry.target,found[entry.target],width)
    else
      -- An unresearched world is not named.
      line(row,L("cargo-corridor-closed"),width,HUES.quiet)
    end
  end
end

local function overview(parent,player,width,facts,network)
  line(parent,L("project-cargo-guide"),width)
  fleet_block(parent,facts or fleet.snapshot(player.force),width)
  corridors_block(parent,player,width,network)
end

function M.render(parent,player,width,facts,preferences)
  preferences=preferences or {cargo_tab="overview"}
  local tabbar=parent.add{type="flow",name="razi_cargo_tabs",
    direction="horizontal"}
  tabbar.style.horizontal_spacing=14
  tabbar.style.vertical_align="center"
  add_tab(tabbar,"cargo-tab-overview","overview",
    preferences.cargo_tab=="overview")
  add_tab(tabbar,"cargo-tab-freight","freight",
    preferences.cargo_tab=="freight")
  local network=catapult_network.snapshot(player.force)
  if preferences.cargo_tab=="freight" then
    desk.render(parent,player,width,network)
  else
    overview(parent,player,width,facts,network)
  end
end

return M
