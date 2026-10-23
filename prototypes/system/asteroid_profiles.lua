-- Asteroid spawn profiles for Razi's routes and belt crossings.
local M = {}
local difficulty=require("scripts.razi_difficulty_presets")
local function preference(name,default)
  return difficulty.effective(name,default)
end
local function asteroid_factor()
  local name=preference("razi-asteroid-population","standard")
  return ({sparse=.65,standard=1,dense=1.3,swarm=1.6})[name] or 1
end
local function belt_factor()
  local name=preference("razi-belt-threats","standard")
  return ({relaxed=.5,standard=1,severe=1.5})[name] or 1
end
M.asteroid_factor=asteroid_factor
M.belt_factor=belt_factor
local function ore_factor()
  local name=preference("razi-belt-resource-richness","standard")
  return ({scarce=.6,standard=1,rich=1.5})[name] or 1
end
M.ore_factor=ore_factor
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
  -- Aegis is a difficult SHARED first-frontier expedition, not a Deep Space bypass.
  -- Use real high-density vanilla families so More Asteroids can enrich them.
  aegis_approach={"aquilo_solar_system_edge",1.65,"fulgora_aquilo","metallic"},
  aegis_depths={"aquilo_solar_system_edge",1.85,"gleba_aquilo","carbonic"},
  belt_vibrant_crossing={"gleba_aquilo",1.32,"fulgora_aquilo","metallic"},
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
  deep_edge="edge",aegis_approach="outer_deep",aegis_depths="edge",
  belt_vibrant_crossing="belt_middle",
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
            point.probability * settings[2] * asteroid_factor()
            * family_boost * size_boost)
        end
      end
    end
  end
end
-- Vanilla asteroid models are introduced explicitly only at the two
-- designated belt crossings, guarded by the actual installed prototypes.
local belt_escalations = {
  belt_vibrant_crossing={big=0.0035},
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
      local chance = wanted[size] and wanted[size]*belt_factor()
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

-- Razi's two belts specialize in real native Space Age resources.
-- These are data-stage weights, not a new asteroid species or runtime spawner.
-- Safe rims are strongest in their local material; the dangerous middle of
-- the crossing contains a smaller, valuable seam of the same material.
M.belt_resources={
  vibrant={metallic=1.85,carbonic=0.70,oxide=0.90},
  umbra={metallic=0.65,carbonic=1.90,oxide=1.20}
}
local belt_crossing_rates={
  vibrant={metallic=0.028,carbonic=0.011,oxide=0.014},
  umbra={metallic=0.014,carbonic=0.034,oxide=0.024}
}
local families={"metallic","carbonic","oxide"}
-- Edge harvesting uses the location spawn format rather than route points.
-- A paused space platform can collect ore without turret-heavy combat.
function M.belt_edge_resources(intensity,system)
  if preference("razi-belt-edge-harvesting",true)==false then return {} end
  local result={}
  local resources=data and data.raw and data.raw["asteroid-chunk"] or {}
  local emphasis=M.belt_resources[system] or {}
  for _,family in ipairs(families) do
    local name=family.."-asteroid-chunk"
    if resources[name] then
      result[#result+1]={
        type="asteroid-chunk",asteroid=name,
        probability=math.min(.25,.06*(intensity or 1)*
          (emphasis[family] or 1)*ore_factor()),
        speed=.035,angle_when_stopped=.5
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
-- Static asteroid fields spike in the MIDSECTION of selected routes.
-- These data-stage knots preserve source-owned custom asteroid species.
local field_done=setmetatable({}, {__mode="k"})
local function sample(points,distance)
  local ordered={}
  for _,point in ipairs(points) do
    if type(point.distance)=="number"
      and type(point.probability)=="number" then
      ordered[#ordered+1]=point
    end
  end
  table.sort(ordered,function(a,b) return a.distance<b.distance end)
  if #ordered==0 then return nil,nil end
  if distance<=ordered[1].distance then
    return ordered[1].probability,ordered[1].speed
  end
  for i=2,#ordered do
    local a,b=ordered[i-1],ordered[i]
    if distance<=b.distance then
      local span=b.distance-a.distance
      local t=span>0 and (distance-a.distance)/span or 0
      return a.probability+(b.probability-a.probability)*t,
        (a.speed or 0.015)+((b.speed or 0.015)-(a.speed or 0.015))*t
    end
  end
  return ordered[#ordered].probability,ordered[#ordered].speed
end
-- Add an earned ore-rich MIDSECTION to the *original* route prototype.
-- Native entries are copied before alteration; source-owned custom chunks
-- and enemies retain their probability tables byte-for-byte.
-- Reapplying the final pass must never multiply its first result.
local enriched=setmetatable({}, {__mode="k"})
function M.enrich_belt_crossing(route,system)
  if preference("razi-belt-midsection-salvage",true)==false then return false end
  local rates=belt_crossing_rates[system]
  if not route or not rates or enriched[route] then return false end
  local resources=data and data.raw and data.raw["asteroid-chunk"] or {}
  local definitions=route.asteroid_spawn_definitions
  if type(definitions)~="table" then definitions={} end
  local detached={}
  local by_chunk={}
  for i,def in ipairs(definitions) do
    detached[i]=def
    if def.type=="asteroid-chunk" then by_chunk[def.asteroid]=i end
  end
  local changed=false
  for _,family in ipairs(families) do
    local name=family.."-asteroid-chunk"
    local rate=rates[family]
    if resources[name] and rate then
      local index=by_chunk[name]
      local original=index and detached[index]
      local existing=original and original.spawn_points or {}
      local sampled_probability,sampled_speed
      local curve={}
      -- The high-value pocket is mostly in the most dangerous third.
      for _,mark in ipairs({
        {0.05,0.36},{0.25,0.58},{0.42,0.88},
        {0.50,1.00},{0.58,0.88},{0.75,0.58},{0.95,0.36}
      }) do
        local baseline,speed=sample(existing,mark[1])
        curve[#curve+1]={
          distance=mark[1],
          probability=math.max(baseline or 0,rate*mark[2]*ore_factor()),
          speed=speed and speed>0 and speed or .045
        }
      end
      -- Native chunks only. Unknown/modded asteroid entries are not touched.
      local entry=original and copy(original) or {
        type="asteroid-chunk",asteroid=name
      }
      entry.spawn_points=curve
      if index then detached[index]=entry
      else detached[#detached+1]=entry end
      changed=true
    end
  end
  if changed then route.asteroid_spawn_definitions=detached end
  enriched[route]=true
  return changed
end

function M.apply_field(route,multiplier)
  if not route or field_done[route] then return end
  field_done[route]=true
  if type(multiplier)~="number" or multiplier<=1 then return end
  for i,def in ipairs(route.asteroid_spawn_definitions or {}) do
    local size=vanilla_sizes[def.asteroid]
    local points=def.spawn_points or {}
    if size and #points>0 then
      local original=copy(points)
      local result={}
      for _,point in ipairs(original) do
        if type(point.distance)=="number"
          and (point.distance<0.30 or point.distance>0.70) then
          result[#result+1]=point
        end
      end
      for _,knot in ipairs({
        {0.30,1},{0.40,1+(multiplier-1)*0.6},
        {0.50,multiplier},{0.60,1+(multiplier-1)*0.6},{0.70,1}
      }) do
        local probability,speed=sample(original,knot[1])
        if probability and speed and speed>0 then
          result[#result+1]={distance=knot[1],
            probability=math.max(0,probability*knot[2]),speed=speed}
        end
      end
      if #result>0 then
        table.sort(result,function(a,b) return a.distance<b.distance end)
        local edited=copy(def)
        edited.spawn_points=result
        route.asteroid_spawn_definitions[i]=edited
      end
    end
  end
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
