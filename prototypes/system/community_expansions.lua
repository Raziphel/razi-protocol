-- Optional worlds and unusual locations contributed by the October 2026
-- community expansion. Do not imitate a source planet's special progression.
-- Discovered worlds join Razi's galaxy; sealed sub-surfaces stay sealed.
local M = {}
local hazard = require("prototypes.system.asteroid_profiles")
local route_icons = require("prototypes.system.route_icons")

-- Native orbital moons and event-driven surfaces must not be reparented.
-- A side branch never contributes science to required seven-system milestones.
local candidates = {
  {mod="planet-ferrum", name="ferrum", system="beetlejuice",
    gate="beetlejuice-discovery", hub="sye-beetlejuice",
    radius=43, orientation=0.68, km=22500, profile="outer_industry",
    preserve_routes=true},
  {mod="Velora", name="velora", system="nyxaris",
    gate="planet-discovery-gleba", hub="gleba",
    moon=true, km=14000, profile="biological"},
  -- alchemy-khemia 0.3.6 localises this prototype as Khemia, but its real
  -- destination ID is alchemy-planet. Using the display name silently left
  -- the planet and its native Nauvis/Vulcanus routes in Calidus.
  {mod="alchemy-khemia", name="alchemy-planet", system="vibrant",
    gate="vibrant-discovery", hub="paracelsin",
    radius=52, orientation=0.625, km=21000, profile="chemistry"},
  {mod="Arcanyx", name="arcanyx", system="umbra",
    gate="umbra-discovery", hub="tenebris",
    radius=39.469081, orientation=0.429241, km=25000, profile="outer_void"},
  -- Source: Balack is a dangerous post-Aquilo side trip. Its prometheum
  -- research, strong asteroid routes and source bio-factory are NOT changed.
  {mod="biological-machines-planet-balack", name="bm-balack",
    system="vespera", gate="planet-discovery-aquilo", hub="aquilo",
    radius=41.637729, orientation=0.816913, km=30000, profile="cryogenic_deep",
    preserve_routes=true}
}

-- Nonstandard content is recommended for 2.1 when compatible, but must
-- keep its original routes/surface lifecycle:
-- rabbasca-underground: hidden, moving subsurface; no platform arrivals.
-- skewer_shattered_planet: plays in the existing endgame Shattered zone.
local special = {
  {mod="skewer_shattered_planet", location="shattered-planet",
    gate=nil},
  {mod="rabbasca-underground", location="rabbasca-underground",
    hidden=true}
}

local home = {
  nauvis="calidus", muluna="calidus",
  ["sye-calidus"]="calidus",
  gleba="nyxaris", vulcanus="solaris",
  fulgora="vibrant", aquilo="vespera", paracelsin="vibrant",
  tenebris="umbra", ["sye-vibrant"]="vibrant",
  ["sye-nyxaris"]="nyxaris", ["sye-vespera"]="vespera",
  ["sye-umbra"]="umbra", ["sye-beetlejuice"]="beetlejuice",
  ["solar-system-edge"]="deep-space"
}

local function location(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end

local function depends_on(current, target, seen)
  if current == target then return true end
  local tech = (data.raw.technology or {})[current]
  if not tech then return false end
  seen = seen or {}
  if seen[current] then return false end
  seen[current] = true
  for _, name in ipairs(tech.prerequisites or {}) do
    if depends_on(name,target,seen) then return true end
  end
  return false
end

local function gate_unlock(name, gate)
  if not gate then return end
  local techs = data.raw.technology or {}
  if not techs[gate] then return end
  for tech_name, tech in pairs(techs) do
    for _, effect in ipairs(tech.effects or {}) do
      if effect.type=="unlock-space-location"
        and effect.space_location==name
        and tech_name~=gate
        and not depends_on(gate,tech_name)
        and not depends_on(tech_name,gate) then
        tech.prerequisites = tech.prerequisites or {}
        tech.prerequisites[#tech.prerequisites+1] = gate
      end
    end
  end
end

local function already_connected(a, b)
  for _, route in pairs(data.raw["space-connection"] or {}) do
    if (route.from==a and route.to==b)
      or (route.from==b and route.to==a) then return true end
  end
  return false
end

local function has_local_route(destination, system)
  for _, route in pairs(data.raw["space-connection"] or {}) do
    local other
    if route.from==destination then other=route.to end
    if route.to==destination then other=route.from end
    if other and home[other]==system then return true end
  end
  return false
end

-- Dyson sphere orbital locations may have arbitrary source IDs, so the
-- Calidus designation must follow the source technology unlock effects.
local function is_calidus_stellar_orbit(name)
  for _,tech_id in ipairs({"planet-discovery-sunorbit",
    "slp-solar-system-sun2"}) do
    local tech=(data.raw.technology or {})[tech_id]
    for _,effect in ipairs(tech and tech.effects or {}) do
      if effect.type=="unlock-space-location"
        and effect.space_location==name then return true end
    end
  end
  return false
end

local function prune_known_bypass(destination, system)
  local routes=data.raw["space-connection"] or {}
  for name, route in pairs(routes) do
    local other
    if route.from==destination then other=route.to end
    if route.to==destination then other=route.from end
    -- Remove only normal other-system planet routes, never special
    -- source-owned links to unknown endgame/stargate destinations.
    if other and ((home[other] and home[other]~=system)
      or (destination=="alchemy-planet" and is_calidus_stellar_orbit(other))) then
      -- Khemia's former direct routes to Nauvis or source-owned solar
      -- stations were still drawing webs through Calidus. Only recognized
      -- cross-system links are retired; preserve native alchemy-side routes.
      routes[name]=nil
    end
  end
end

local function attach(config)
  if not location(config.hub)
    or has_local_route(config.name,config.system)
    or already_connected(config.name,config.hub) then return end
  local routes=data.raw["space-connection"] or {}
  local name="razi-expansion-" .. config.name .. "-" .. config.hub
  if routes[name] then return end
  local connection=route_icons.assign({
    type="space-connection", name=name,
    from=config.hub, to=config.name,
    length=config.km,
    asteroid_spawn_definitions=hazard.create(config.profile)
  },config.profile)
  data:extend({connection})
end

local function integrate(config)
  if not mods[config.mod] or not (data.raw.planet or {})[config.name] then
    return
  end
  -- Original discovery owners remain responsible for unlock-space-location;
  -- unknown/removed unlocks cannot be recreated by a speculative shortcut.
  if config.gate and not (data.raw.technology or {})[config.gate] then
    return
  end
  if config.radius
    and (data.raw["space-location"] or {})[config.system] then
    PlanetsLib:update({{
      type="planet", name=config.name,
      orbit={parent={type="space-location",name=config.system},
        distance=config.radius,orientation=config.orientation}
    }})
  end
  gate_unlock(config.name,config.gate)
  if not config.moon and not config.preserve_routes then
    prune_known_bypass(config.name,config.system)
  end
  attach(config)
end

function M.data_final_fixes()
  for _, config in ipairs(candidates) do integrate(config) end
  for _, config in ipairs(special) do
    if mods[config.mod] and location(config.location)
      and not config.hidden then
      -- Only gate the native space-location unlock. Keep every native
      -- route and asteroid entry on Shattered.
      gate_unlock(config.location,config.gate)
    end
  end
end

return M
