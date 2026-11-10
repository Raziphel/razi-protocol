-- The Cargo Network overview in the Projects tab: the platform fleet and the Orbital
-- Catapult corridors with the machines found at their ends. Drawn only while the project is
-- open; one catapult snapshot per drawing.
local style=require("scripts.journal.project_style")
local fleet=require("scripts.cargo.fleet")
local infrastructure=require("scripts.cargo.infrastructure")
local catapult_network=require("scripts.compatibility.orbital-cannon.catapult_network")
local L=style.L
local HUES=style.HUES
local M={}
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
-- Worlds of the corridors that are open, once each.
local function open_worlds(network)
  local worlds,seen={}, {}
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
local function corridors_block(parent,player,width)
  heading(parent,"cargo-corridors-heading")
  local network=catapult_network.snapshot(player.force)
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
      line(row,L("cargo-corridor",world_name(entry.source),
        world_name(entry.target)),width,nil,"default-bold")
      end_line(row,entry.source,found[entry.source],width)
      end_line(row,entry.target,found[entry.target],width)
    else
      -- An unresearched world is not named.
      line(row,L("cargo-corridor-closed"),width,HUES.quiet)
    end
  end
end
-- facts: the fleet snapshot of this drawing, when the caller has one.
function M.render(parent,player,width,facts)
  line(parent,L("project-cargo-guide"),width)
  fleet_block(parent,facts or fleet.snapshot(player.force),width)
  corridors_block(parent,player,width)
end
return M
