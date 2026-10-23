-- Razi Protocol owns the curated galaxy; the standalone asteroid mod owns its
-- eight families, processing recipes, graphics, and its vanilla Space Age map.
-- Apply RP3-specific geography only after the FINAL route authority pass.
local M = {}
local catalog = require("scripts.galactic_catalog")
local ladder = require("scripts.razi_asteroid_difficulty")
local profiles = require("prototypes.system.asteroid_profiles")

local materials = {"uranium", "rock", "scrap", "organic", "chemical", "crystalline",
                   "halide", "electrostatic"}
local material_names = {}
for _, family in ipairs(materials) do
  material_names[family .. "-asteroid-chunk"] = true
  for _, size in ipairs({"small", "medium", "big", "huge"}) do
    material_names[size .. "-" .. family .. "-asteroid"] = true
  end
end

-- The difficulty scale is read like the other route passes read it: an
-- unset or undeclared setting means balanced.
local function settings_value(name, default)
  local s = settings and settings.startup and settings.startup[name]
  if s == nil or s.value == nil then return default end
  return s.value
end

-- Resource identity travels with the destinations, not the arbitrary
-- connection name or the order Factorio happens to iterate prototypes.
-- Processing gates (razi-more-asteroids data-updates.lua): uranium, rock at
-- space-platform (tier 0); crystalline = Vulcanus, organic = Gleba (tier 1);
-- scrap, electrostatic = Fulgora, chemical, halide = Aquilo (tier 2). A tier
-- is a system group of the campaign (Vibrant and Vespera share tier 2), and
-- no family is placed below its tier. Within a tier the gate may sit on a
-- parallel branch: crystalline also flies in Nyxaris; chemical flies across
-- Vibrant (Paracelsin lead, Fulgora light) and halide reaches the Vibrant
-- belt, one system before their Aquilo gate.
--
-- RP3 region     Families (lead first)
-- Calidus        uranium, rock
-- Solaris        rock, uranium, crystalline (tungsten; Vulcanus is here)
-- Nyxaris        organic, crystalline, rock
-- Vibrant        scrap, crystalline, electrostatic (holmium; Fulgora), chemical
-- Vespera        chemical, halide (fluorine, brine; Aquilo), organic, rock
-- Beetlejuice    crystalline, scrap, chemical, halide, electrostatic, uranium
-- Umbra          rock, uranium, crystalline, electrostatic, organic, halide
-- Deep Space     all eight; crystalline and chemical emphasis
-- Vibrant belt   rock, crystalline, electrostatic, scrap (inner) or uranium
--                (outer), light halide
-- Umbra belt     uranium, crystalline, rock (inner) or chemical (outer),
--                electrostatic, halide
local system_mix = {
  calidus      = {uranium=1, rock=.70},
  solaris      = {rock=1, uranium=.48, crystalline=.48},
  nyxaris      = {organic=1, crystalline=.52, rock=.35},
  vibrant      = {scrap=1, crystalline=.82, electrostatic=.55, chemical=.45},
  vespera      = {chemical=1, halide=.70, organic=.47, rock=.46},
  beetlejuice  = {crystalline=1, scrap=.84, chemical=.58, halide=.45,
                  electrostatic=.40, uranium=.33},
  umbra        = {rock=.92, uranium=.75, crystalline=.66, electrostatic=.50,
                  organic=.42, halide=.35},
  ["deep-space"] = {crystalline=1, chemical=.83, uranium=.78, rock=.76,
                    electrostatic=.75, scrap=.62, halide=.60, organic=.58}
}

-- More distinctive resources for worlds where a system-wide average would
-- feel wrong. This is only a spawn mix, NEVER a change to recipe yields.
local world_mix = {
  nauvis={uranium=.85, rock=.70},
  vulcanus={rock=1, uranium=.65, crystalline=.45},
  gleba={organic=1, crystalline=.32, rock=.22},
  fulgora={scrap=1, electrostatic=.75, crystalline=.68, chemical=.28},
  aquilo={chemical=1, halide=.90, crystalline=.57, rock=.18},
  cerys={scrap=.85, crystalline=.75, electrostatic=.65, uranium=.60},
  paracelsin={chemical=1, crystalline=.80, scrap=.25},
  maraxsis={organic=.72, rock=.65, chemical=.65, halide=.65},
  rubia={organic=1, chemical=.50, halide=.30, rock=.30},
  cubium={crystalline=1, scrap=.75, electrostatic=.35, chemical=.35},
  secretas={crystalline=1, scrap=.55, uranium=.45, halide=.35},
  frozeta={chemical=.92, halide=.90, crystalline=.85, rock=.30},
  tenebris={organic=.95, crystalline=.78, rock=.45, electrostatic=.35},
  vesta={rock=.90, uranium=.82, chemical=.58, electrostatic=.40},
  crucible={rock=1, uranium=.85, crystalline=.52, electrostatic=.40},
  obsidiax={rock=1, uranium=.75, crystalline=.43},
  ["asteroid-belt-inner-edge"]={rock=1, crystalline=.85, electrostatic=.50,
                                scrap=.45, halide=.30},
  ["asteroid-belt-outer-edge"]={rock=1, crystalline=.90, uranium=.55,
                                electrostatic=.55, halide=.35},
  ["razi-umbra-belt-inner"]={uranium=.88, rock=.72, crystalline=.74,
                             electrostatic=.60, halide=.40},
  ["razi-umbra-belt-outer"]={uranium=1, crystalline=.90, electrostatic=.70,
                             chemical=.55, halide=.50}
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

-- The Dyson sphere's solar orbits are plasma hazards with their own roster.
-- The catalog resolves their identifiers from the live technologies only at
-- runtime, so read the same two technologies from data.raw here, the way
-- route_authority.lua and community_expansions.lua do; when the port renames
-- them, all four lists change together. "sun-orbit" and "close-sun-orbit" are
-- the upstream SLP identifiers: the reworked port does not define them, so
-- the fallback only matters for another port.
local solar_technologies = {"planet-discovery-sunorbit", "slp-solar-system-sun2"}
local function solar_locations()
  local result = {["sun-orbit"]=true, ["close-sun-orbit"]=true}
  local technologies = data.raw.technology or {}
  for _, id in ipairs(solar_technologies) do
    local tech = technologies[id]
    for _, effect in ipairs(tech and tech.effects or {}) do
      if type(effect)=="table" and effect.type=="unlock-space-location"
        and type(effect.space_location)=="string" then
        result[effect.space_location] = true
      end
    end
  end
  return result
end
local function is_solar(name, solar)
  return solar[name] or name:find("^slp%-solar%-")~=nil
end

local function excluded(route, solar)
  if not route or route.hidden or type(route.from)~="string"
    or type(route.to)~="string" or not valid_location(route.from)
    or not valid_location(route.to) then return true end
  -- Dyson plasma-clot hazards and teleport-style source connections own
  -- their roster; they are not ordinary traversable mineral corridors.
  if is_solar(route.from, solar) or is_solar(route.to, solar) then return true end
  local label=(route.name or ""):lower()
  for _, word in ipairs({"stargate", "wormhole", "teleport", "portal"}) do
    if label:find(word, 1, true) then return true end
  end
  return false
end

local function curve(route, start_mix, end_mix, material, size, mode, belt)
  local result, max_probability = {}, 0.0
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
    local probability = 0.0
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

local function apply_route(route, mode, solar)
  if excluded(route, solar) then return 0 end
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
local function apply_orbits(solar)
  local added=0
  local chunks=data.raw["asteroid-chunk"] or {}
  for _, kind in ipairs({"planet", "space-location"}) do
    for name, loc in pairs(data.raw[kind] or {}) do
      local mix=mix_for(name)
      if mix and not is_solar(name, solar) and not name:find("^sye%-")
        and name~="razi-deep-space-edge" then
        local original=loc.asteroid_spawn_definitions or {}
        local present={}
        for _, def in ipairs(original) do
          if type(def)=="table" and def.asteroid then present[def.asteroid]=true end
        end
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
  local mode=settings_value("razi-asteroid-difficulty-scale","balanced")
  local solar=solar_locations()
  local names={}
  for name in pairs(routes) do names[#names+1]=name end
  table.sort(names)
  local modified, additions=0,0
  for _, name in ipairs(names) do
    local n=apply_route(routes[name],mode,solar)
    if n>0 then modified=modified+1;additions=additions+n end
  end
  local orbits=apply_orbits(solar)
  if type(log)=="function" then
    log(("[Razi Protocol/more-asteroids] Rebalanced %d approved routes "..
      "(%d family entries), added %d missing orbit chunks; "..
      "source recipes and unrelated spawn species preserved."):format(
        modified,additions,orbits))
  end
  return modified
end
return M
