-- Razi route hazards: vanilla spawn curves are adjusted, modded entries are not.
local M = {}
local util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
local presets = {
  starter={"nauvis_fulgora",0.82},
  first_crossing={"nauvis_fulgora",0.99},
  frontier_crosslink={"nauvis_fulgora",1.05},
  industrial={"vulcanus_castra",0.96,"nauvis_fulgora","metallic"},
  industrial_deep={"vulcanus_castra",1.08,"nauvis_fulgora","metallic"},
  biological={"nauvis_gleba",0.97,"nauvis_fulgora","carbonic"},
  biological_deep={"nauvis_gleba",1.10,"nauvis_fulgora","carbonic"},
  middle_crossing={"gleba_aquilo",1.08,"fulgora_aquilo"},
  middle_crosslink={"fulgora_aquilo",1.13},
  electrical={"fulgora_aquilo",1.08,nil,"metallic"},
  chemistry={"fulgora_aquilo",1.14,nil,"oxide"},
  chemistry_deep={"fulgora_aquilo",1.21,nil,"oxide"},
  cryogenic={"gleba_aquilo",1.15,"fulgora_aquilo","oxide"},
  cryogenic_deep={"gleba_aquilo",1.25,"fulgora_aquilo","oxide"},
  outer_crossing={"fulgora_aquilo",1.30},
  outer_crosslink={"gleba_aquilo",1.33,"fulgora_aquilo"},
  outer_ring_crosslink={"aquilo_solar_system_edge",1.42,"fulgora_aquilo"},
  outer_industry={"fulgora_aquilo",1.30,nil,"metallic"},
  outer_industry_deep={"fulgora_aquilo",1.39,nil,"metallic"},
  outer_void={"gleba_aquilo",1.34,"fulgora_aquilo","carbonic"},
  outer_void_deep={"gleba_aquilo",1.42,"fulgora_aquilo","carbonic"},
  deep_edge={"aquilo_solar_system_edge",1.40,"gleba_aquilo"},
  belt_vespera_approach={"gleba_aquilo",1.20,"fulgora_aquilo","oxide"},
  belt_vespera_crossing={"gleba_aquilo",1.48,"fulgora_aquilo","oxide"},
  belt_vespera_departure={"gleba_aquilo",1.19,"fulgora_aquilo","oxide"},
  belt_umbra_approach={"aquilo_solar_system_edge",1.42,"fulgora_aquilo","carbonic"},
  belt_umbra_crossing={"aquilo_solar_system_edge",1.72,"fulgora_aquilo","carbonic"},
  belt_umbra_departure={"aquilo_solar_system_edge",1.40,"fulgora_aquilo","carbonic"}
}
-- Sizes are tuned separately from spawn density. A route that starts with
-- big/huge asteroid probability zero stays at zero; no new species are added.
local size_tiers = {
  starter="home",
  first_crossing="first", frontier_crosslink="first",
  industrial="first", biological="first",
  industrial_deep="first_deep", biological_deep="first_deep",
  middle_crossing="middle", middle_crosslink="middle",
  electrical="middle", chemistry="middle", cryogenic="middle",
  chemistry_deep="middle_deep", cryogenic_deep="middle_deep",
  outer_crossing="outer", outer_crosslink="outer",
  outer_ring_crosslink="outer_deep",
  outer_industry="outer", outer_void="outer",
  outer_industry_deep="outer_deep", outer_void_deep="outer_deep",
  deep_edge="edge",
  belt_vespera_approach="middle_deep",
  belt_vespera_crossing="belt_middle",
  belt_vespera_departure="middle_deep",
  belt_umbra_approach="outer_deep",
  belt_umbra_crossing="belt_outer",
  belt_umbra_departure="outer_deep"
}
local size_weights = {
  -- Zero is an absolute size cap, NOT a gentle density reduction.
  home={small=1.08, medium=0, big=0, huge=0},
  first={small=1.04, medium=0.70, big=0, huge=0},
  first_deep={small=1.00, medium=1.00, big=0, huge=0},
  middle={small=0.96, medium=1.14, big=0.48, huge=0},
  middle_deep={small=0.93, medium=1.17, big=0.86, huge=0},
  belt_middle={small=0.82, medium=1.42, big=1.64, huge=0},
  outer={small=0.90, medium=1.24, big=1.24, huge=0.38},
  outer_deep={small=0.85, medium=1.31, big=1.45, huge=0.84},
  belt_outer={small=0.75, medium=1.38, big=1.90, huge=1.75},
  edge={small=0.82, medium=1.34, big=1.64, huge=1.37}
}
local vanilla = {}
local vanilla_sizes = {}
for _, family in ipairs({"metallic","carbonic","oxide","promethium"}) do
  vanilla[family.."-asteroid-chunk"] = family
  for _, size in ipairs({"small","medium","big","huge"}) do
    local name = size.."-"..family.."-asteroid"
    vanilla[name] = family
    vanilla_sizes[name] = size
  end
end
local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, element in pairs(value) do result[key] = copy(element) end
  return result
end
local function adjust(definitions, settings, profile_name)
  local weights = size_weights[size_tiers[profile_name] or "first"]
  for index, definition in ipairs(definitions) do
    local family = vanilla[definition.asteroid]
    if family then
      -- Copy only the vanilla entry so no source mod or other connection
      -- shares a spawn_points object that our balance pass modifies.
      local def = copy(definition)
      definitions[index] = def
      local family_boost = family == settings[4] and 1.10 or 1
      local size = vanilla_sizes[def.asteroid]
      local size_boost = (size == "small" and weights.small)
        or (size == "medium" and weights.medium)
        or (size == "big" and weights.big)
        or (size == "huge" and weights.huge)
        or 1
      for _, point in ipairs(def.spawn_points or {}) do
        if type(point.probability) == "number" then
          point.probability = math.max(0,
            point.probability * settings[2] * family_boost * size_boost)
        end
      end
    end
  end
end
-- Vanilla asteroid models are introduced explicitly only at the two
-- designated belt crossings, guarded by the actual installed prototypes.
local belt_escalations = {
  belt_vespera_crossing={big=0.007},
  belt_umbra_crossing={big=0.010, huge=0.0008}
}
local function add_belt_size_encounters(definitions, profile)
  local wanted = belt_escalations[profile]
  if not wanted then return end
  local asteroid_entities = data and data.raw and data.raw["asteroid"] or {}
  local found = {}
  for _, def in ipairs(definitions) do found[def.asteroid] = true end
  for _, family in ipairs({"metallic","carbonic","oxide"}) do
    for _, size in ipairs({"big","huge"}) do
      local name = size.."-"..family.."-asteroid"
      local chance = wanted[size]
      if chance and asteroid_entities[name] and not found[name] then
        definitions[#definitions+1] = {
          type="entity", asteroid=name,
          spawn_points={
            {distance=0.15, probability=chance*0.65, speed=0.015},
            {distance=0.50, probability=chance, speed=0.015},
            {distance=0.85, probability=chance*0.65, speed=0.015}
          }
        }
      end
    end
  end
end

-- Only recognized vanilla enemies are affected. Modded asteroid species and
-- resource chunks stay exactly as provided by their source mod.
function M.cap_sizes(location_or_route, maximum)
  if maximum ~= "small" then return end
  local current = location_or_route.asteroid_spawn_definitions
  if type(current) ~= "table" then return end
  local detached = {}
  for key, original in pairs(current) do detached[key] = original end
  for i, definition in ipairs(current) do
    local size = vanilla_sizes[definition.asteroid]
    if size and size ~= "small" then
      local edited = copy(definition)
      if type(edited.probability) == "number" then
        edited.probability = 0
      end
      for _, point in ipairs(edited.spawn_points or {}) do
        if type(point.probability) == "number" then point.probability = 0 end
      end
      detached[i] = edited
    end
  end
  location_or_route.asteroid_spawn_definitions = detached
end

-- Belt edges are rich in collectible ore, but a parked ship won't be smashed
-- by big/huge asteroids. Native modded resource chunks are not replaced.
function M.belt_edge_resources(intensity)
  local result = {}
  local resources = data and data.raw and data.raw["asteroid-chunk"] or {}
  for _, family in ipairs({"metallic","carbonic","oxide"}) do
    local name = family.."-asteroid-chunk"
    if resources[name] then
      result[#result+1] = {
        type="asteroid-chunk", asteroid=name,
        probability=0.06*intensity, speed=0.035,
        angle_when_stopped=0.5
      }
    end
  end
  return result
end

local done = setmetatable({}, {__mode="k"})
function M.is_vanilla(def)
  return type(def) == "table" and vanilla[def.asteroid] ~= nil
end
function M.create(profile)
  local p = presets[profile] or presets.starter
  local source = util[p[1]] or (p[3] and util[p[3]]) or util.nauvis_fulgora
  if not source then return {} end
  local defs = copy(util.spawn_definitions(source) or {})
  adjust(defs, p, profile)
  add_belt_size_encounters(defs, profile)
  return defs
end
function M.apply(route, profile)
  if done[route] then return end
  local defs = route.asteroid_spawn_definitions
  if type(defs) ~= "table" or #defs == 0 then
    route.asteroid_spawn_definitions = M.create(profile)
  else
    -- The list itself can be reused by another modded connection. Detach
    -- this route before replacing only its vanilla asteroid definitions.
    local detached = {}
    for key, value in pairs(defs) do detached[key] = value end
    route.asteroid_spawn_definitions = detached
    adjust(detached, presets[profile] or presets.starter, profile)
    add_belt_size_encounters(detached, profile)
  end
  done[route] = true
end
function M.preserve_custom(target, duplicate)
  local incoming = duplicate.asteroid_spawn_definitions or {}
  if #incoming == 0 then return end
  target.asteroid_spawn_definitions = target.asteroid_spawn_definitions or {}
  local existing = target.asteroid_spawn_definitions
  local seen = {}
  for _, def in ipairs(existing) do
    seen[(def.type or "entity").."|"..(def.asteroid or "")] = true
  end
  for _, def in ipairs(incoming) do
    local key = (def.type or "entity").."|"..(def.asteroid or "")
    if not M.is_vanilla(def) and not seen[key] then
      existing[#existing + 1] = copy(def)
      seen[key] = true
    end
  end
end
return M
