-- Orbital Catapult machines found at the ends of the corridors: placed machines on the
-- surface of a world and built platforms in its orbit. Found machines are not working
-- machines: power and cargo are not checked. Counted when the project is drawn, nothing is
-- stored and no entity is kept.
local M={}
-- Corridors have at most eight worlds; the count is bounded by it.
local max_worlds=8
-- Launcher names come from the installed game, not from a copy of the mod's list. A launcher
-- is a placeable, non-hidden entity; hidden helper entities are not the player's machines.
function M.launcher_names()
  local names={}
  for name,prototype in pairs(prototypes.entity) do
    if (name:find("^orbital%-cannon") or name:find("^orbital%-catapult"))
      and prototype.hidden~=true then
      local items=prototype.items_to_place_this
      if items and #items>0 then names[#names+1]=name end
    end
  end
  table.sort(names)
  return names
end
local function built(platform)
  return platform.valid and not platform.hidden
    and platform.scheduled_for_deletion==0
    and platform.hub~=nil and platform.hub.valid
end
-- worlds: list of world names. Returns {[world]={launchers=N,platforms=N}}; a world
-- without a surface is not in the answer.
function M.inspect(force,worlds)
  local result={}
  local names
  for index,world in ipairs(worlds) do
    local surface=index<=max_worlds and game.surfaces[world] or nil
    if surface and surface.valid then
      names=names or M.launcher_names()
      local launchers=0
      if #names>0 then
        launchers=surface.count_entities_filtered{name=names,force=force}
      end
      local platforms=0
      for _,platform in pairs(force.get_space_platforms(world)) do
        if built(platform) then platforms=platforms+1 end
      end
      result[world]={launchers=launchers,platforms=platforms}
    end
  end
  return result
end
return M
