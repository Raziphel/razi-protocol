-- Razi Protocol owns the curated galaxy; the standalone asteroid mod owns its
-- six prototypes, processing recipes, graphics, and its vanilla Space Age map.
-- Apply RP3-specific geography only after the FINAL route authority pass.
local M = {}
local catalog = require("scripts.galactic_catalog")
local ladder = require("scripts.razi_asteroid_difficulty")
local profiles = require("prototypes.system.asteroid_profiles")
local preset = require("scripts.razi_difficulty_presets")

local materials = {"uranium", "rock", "scrap", "organic", "chemical", "crystalline"}
local material_names = {}
for _, family in ipairs(materials) do
  material_names[family .. "-asteroid-chunk"] = true
  for _, size in ipairs({"small", "medium", "big", "huge"}) do
    material_names[size .. "-" .. family .. "-asteroid"] = true
  end
end

-- Resource identity travels with the destinations, not the arbitrary
-- connection name or the order Factorio happens to iterate prototypes.
local system_mix = {
  calidus      = {uranium=1, rock=.70, crystalline=.65},
  solaris      = {rock=1, uranium=.48, crystalline=.48},
  nyxaris      = {organic=1, crystalline=.52, rock=.35},
  vibrant      = {scrap=1, crystalline=.82, chemical=.45},
  vespera      = {chemical=1, organic=.47, rock=.46},
  beetlejuice  = {scrap=.84, crystalline=1, chemical=.58, uranium=.33},
  umbra        = {rock=.92, uranium=.75, crystalline=.66, organic=.42},
  ["deep-space"] = {uranium=.78, rock=.76, scrap=.62,
                    organic=.58, chemical=.83, crystalline=1}
}

-- More distinctive resources for worlds where a system-wide average would
-- feel wrong. This is only a spawn mix, NEVER a change to recipe yields.
local world_mix = {
  nauvis={uranium=.85, rock=.70, crystalline=.55},
  vulcanus={rock=1, uranium=.65, crystalline=.45},
  gleba={organic=1, crystalline=.32, rock=.22},
  fulgora={scrap=1, crystalline=.68, chemical=.28},
  aquilo={chemical=1, crystalline=.57, rock=.18},
  cerys={scrap=.85, uranium=.60, crystalline=.75},
  paracelsin={chemical=1, crystalline=.80, scrap=.25},
  maraxsis={organic=.72, rock=.65, chemical=.65},
  rubia={organic=1, chemical=.50, rock=.30},
  cubium={crystalline=1, scrap=.75, chemical=.35},
  secretas={crystalline=1, scrap=.55, uranium=.45},
  frozeta={chemical=.92, crystalline=.85, rock=.30},
  tenebris={organic=.95, crystalline=.78, rock=.45},
  vesta={rock=.90, uranium=.82, chemical=.58},
  crucible={rock=1, uranium=.85, crystalline=.52},
  obsidiax={rock=1, uranium=.75, crystalline=.43},
  ["asteroid-belt-inner-edge"]={rock=1, crystalline=.85, scrap=.45},
  ["asteroid-belt-outer-edge"]={rock=1, crystalline=.90, uranium=.55},
  ["razi-umbra-belt-inner"]={uranium=.88, rock=.72, crystalline=.74},
  ["razi-umbra-belt-outer"]={uranium=1, crystalline=.90, chemical=.55}
}

local function mix_for(name)
  return world_mix[name] or system_mix[catalog.system(name)]
end
local function valid_location(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end
local function is_belt(route)
  return ladder.is_belt(route.from, route.to)
end
local function excluded(route)
  if not route or route.hidden or type(route.from)~="string"
    or type(route.to)~="string" or not valid_location(route.from)
    or not valid_location(route.to) then return true end
  -- Dyson plasma-clot hazards and teleport-style source connections own
  -- their roster; they are not ordinary traversable mineral corridors.
  if ladder.stellar_route_tier(route) then return true end
  local label=(route.name or ""):lower()
  for _, word in ipairs({"stargate", "wormhole", "teleport", "portal"}) do
    if label:find(word, 1, true) then return true end
  end
  return false
end

local function curve(route, start_mix, end_mix, material, size, mode, belt)
  local result, max_probability = {}, 0
  local base = ({chunk=.0031, small=.00082, medium=.00054,
                 big=.00029, huge=.00013})[size]
  local minimum = ({chunk=1, small=2, medium=3, big=6, huge=9})[size]
  local crowding = profiles.asteroid_factor()
  local harvest = profiles.ore_factor()
  local belt_factor = belt and (size=="chunk" and 1.7*harvest
    or 1.2*profiles.belt_factor()) or 1
  for _, t in ipairs({.08, .30, .50, .70, .92}) do
    local stage = ladder.route_level(route, t, mode)
    local weight = (start_mix[material] or 0)*(1-t)
      + (end_mix[material] or 0)*t
    local probability = 0
    if stage >= minimum and weight > 0 then
      local stage_factor = size=="chunk" and (0.78 + stage*.035)
        or (0.72 + stage*.05)
      local middle = t==.50 and 1.23 or
        (t==.30 or t==.70) and 1.09 or .88
      probability = base*weight*stage_factor*middle*crowding*belt_factor
    end
    max_probability = math.max(max_probability, probability)
    result[#result+1] = {
      distance=t, probability=probability,
      speed=size=="chunk" and .035 or .018,
      angle_when_stopped=size=="chunk" and 1 or .6
    }
  end
  return max_probability>0 and result or nil
end

local function apply_route(route, mode)
  if excluded(route) then return 0 end
  local first, last = mix_for(route.from), mix_for(route.to)
  -- Never invent a biome for an unknown third-party subsystem.
  if not first or not last then return 0 end
  local existing = route.asteroid_spawn_definitions or {}
  local updated, removed, added = {}, 0, 0
  for _, definition in ipairs(existing) do
    if type(definition)=="table" and material_names[definition.asteroid] then
      removed=removed+1
    else
      updated[#updated+1]=definition
    end
  end
  local chunks = data.raw["asteroid-chunk"] or {}
  local enemies = data.raw.asteroid or {}
  local belt = is_belt(route)
  for _, family in ipairs(materials) do
    for _, size in ipairs({"chunk", "small", "medium", "big", "huge"}) do
      local name = size=="chunk" and (family.."-asteroid-chunk")
        or (size.."-"..family.."-asteroid")
      local kind = size=="chunk" and "asteroid-chunk" or "entity"
      if (size=="chunk" and chunks[name]) or (size~="chunk" and enemies[name]) then
        local points = curve(route,first,last,family,size,mode,belt)
        if points then
          updated[#updated+1] = {
            type=kind, asteroid=name, spawn_points=points
          }
          added=added+1
        end
      end
    end
  end
  if removed>0 or added>0 then
    route.asteroid_spawn_definitions=updated
  end
  return added
end

-- New non-vanilla destinations need something collectible while parked.
-- Leave all source-owned planet/orbit hostile lists and existing chunks intact.
local function apply_orbits()
  local added=0
  local chunks=data.raw["asteroid-chunk"] or {}
  for _, kind in ipairs({"planet", "space-location"}) do
    for name, loc in pairs(data.raw[kind] or {}) do
      local mix=mix_for(name)
      if mix and not name:find("^sye%-")
        and name~="razi-deep-space-edge" then
        local original=loc.asteroid_spawn_definitions or {}
        local present={}
        for _, def in ipairs(original) do present[def.asteroid]=true end
        local appended=nil
        for _, family in ipairs(materials) do
          local chunk=family.."-asteroid-chunk"
          local weight=mix[family] or 0
          if chunks[chunk] and weight>0 and not present[chunk] then
            if not appended then
              appended={}
              for key, def in pairs(original) do appended[key]=def end
            end
            appended[#appended+1]={
              type="asteroid-chunk",asteroid=chunk,
              probability=.0022*weight*profiles.asteroid_factor()
                *profiles.ore_factor(),
              speed=.035,angle_when_stopped=1
            }
            added=added+1
          end
        end
        if appended then loc.asteroid_spawn_definitions=appended end
      end
    end
  end
  return added
end

function M.data_final_fixes()
  if not (mods and mods["razi-more-asteroids"]) then return 0 end
  -- Unknown-world levels are resolved from surviving, not deleted, routes.
  local routes=data.raw["space-connection"] or {}
  ladder.prepare_routes(routes)
  local mode=preset.effective("razi-asteroid-difficulty-scale","balanced")
  local names={}
  for name in pairs(routes) do names[#names+1]=name end
  table.sort(names)
  local modified, additions=0,0
  for _, name in ipairs(names) do
    local n=apply_route(routes[name],mode)
    if n>0 then modified=modified+1;additions=additions+n end
  end
  local orbits=apply_orbits()
  if type(log)=="function" then
    log(("[Razi Protocol/more-asteroids] Rebalanced %d approved routes "..
      "(%d family entries), added %d missing orbit chunks; "..
      "source recipes and unrelated spawn species preserved."):format(
        modified,additions,orbits))
  end
  return modified
end
return M
