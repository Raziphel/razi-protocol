-- Locate the nearest *unlocked* real planet for Galactic Operations.
-- Factorio 2.1 has no mod-accessible native space-map camera controls.
-- This selects a read-only Atlas dossier; it never moves a player or
-- changes the camera, platform route, or research.
local M={}

local function position(p)
  if not p then return nil end
  local x,y=p.x or p[1],p.y or p[2]
  if type(x)~="number" or type(y)~="number"
    or x~=x or y~=y then return nil end
  return {x=x,y=y}
end

function M.nearest(locations,force,origin)
  origin=position(origin)
  if not origin or not force then return nil end
  local best,best_distance
  for id,loc in pairs(locations or {}) do
    if loc.type=="planet" and not loc.hidden
      and force.is_space_location_unlocked(id) then
      local p=position(loc.position)
      if p then
        local distance=(p.x-origin.x)^2+(p.y-origin.y)^2
        if not best_distance or distance<best_distance
          or (distance==best_distance and id<best) then
          best,best_distance=id,distance
        end
      end
    end
  end
  return best
end

function M.physical_origin(player)
  local surface=player and player.physical_surface
  if not surface or not surface.valid then return nil end
  local planet=surface.planet
  if planet and planet.valid then
    return planet.prototype and planet.prototype.position,planet.name
  end
  local platform=surface.platform
  if not platform or not platform.valid then return nil end
  local route=platform.space_connection
  local t=platform.distance
  if route and type(t)=="number" and t>=0 and t<=1 then
    local a=position(route.from and route.from.position)
    local b=position(route.to and route.to.position)
    if a and b then
      return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t}
    end
  end
  local location=platform.space_location
    or platform.last_visited_space_location
  return location and location.position
end

function M.for_player(player,locations)
  if not (player and player.valid and player.force) then return nil end
  locations=locations or (prototypes and prototypes.space_location)
  if not locations then return nil end
  local origin,planet=M.physical_origin(player)
  if planet and locations[planet] and not locations[planet].hidden
    and player.force.is_space_location_unlocked(planet) then
    return planet
  end
  local candidate=M.nearest(locations,player.force,origin)
  if candidate then return candidate end
  -- Nothing guessed for editor, god-view or non-planetary custom surfaces.
  return nil
end

return M
