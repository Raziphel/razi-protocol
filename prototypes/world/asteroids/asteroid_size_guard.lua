-- Final weapon-access gate for hostile asteroids from Razi and partner mods.
-- Run after the route spawn passes but before route intel and quality carriers,
-- so the in-game route preview shows only species that can actually spawn.
local M = {}
local ladder = require("lib.difficulty.asteroids")

-- Small asteroids remain available early; Medium appear after the initial
-- frontier. Big need rocket-era defenses, Huge are reserved for Deep Space.
-- Hard and Nightmare increase danger, not the technology needed to survive.
M.minimum_level = {medium = 3, big = 7, huge = 10}

local function size_of(name)
  if type(name) ~= "string" then return nil end
  name = name:gsub("^razi%-quality%-asteroid%-", "")
  if not name:match("%-asteroid$") then return nil end
  for _, size in ipairs({"medium", "big", "huge"}) do
    if name:sub(1, #size + 1) == size .. "-" then return size end
  end
end

local function copy(source)
  local result = {}
  for key, value in pairs(source) do result[key] = value end
  return result
end

-- Keep the mod's original curve wherever this size is eligible. Zero the
-- sample on each side of a boundary too, because Factorio interpolates
-- probabilities between spawn points.
local function limit_definition(original, threshold, allowed, whole_route)
  local points = original.spawn_points
  if type(points) ~= "table" or #points == 0 then
    -- Constant-rate definitions have no safe way to vary during travel.
    return whole_route and original or nil
  end

  local eligible = {}
  for i, point in ipairs(points) do
    eligible[i] = allowed(point.distance or 0.5, threshold)
  end
  local changed, enabled, output = false, false, nil
  for i, point in ipairs(points) do
    local safe = eligible[i]
      and (i == 1 or eligible[i - 1])
      and (i == #points or eligible[i + 1])
    local probability = type(point.probability) == "number" and point.probability or 0
    if safe and probability > 0 then enabled = true end
    if not safe and probability > 0 then
      if not output then
        output = copy(original)
        output.spawn_points = copy(points)
      end
      local adjusted = copy(point)
      adjusted.probability = 0
      output.spawn_points[i] = adjusted
      changed = true
    end
  end
  -- Remove fully suppressed species rather than leaving misleading entries
  -- with zero chance in the space-connection asteroid preview.
  if not enabled then return nil end
  if not changed then return original end
  if type(output.probability) == "number" then output.probability = 0 end
  return output
end

local function filter(target, allowed, whole_route)
  local source = target.asteroid_spawn_definitions
  if type(source) ~= "table" then return 0 end
  local removed, changed, filtered = 0, 0, {}
  for _, definition in ipairs(source) do
    local replacement = definition
    if type(definition) == "table"
      and (definition.type == "entity" or definition.type == nil) then
      local size = size_of(definition.asteroid)
      if size then
        local threshold = M.minimum_level[size]
        replacement = limit_definition(definition, threshold, allowed,
          whole_route(threshold))
      end
    end
    if replacement then
      filtered[#filtered + 1] = replacement
      if replacement ~= definition then changed = changed + 1 end
    else
      removed = removed + 1
    end
  end
  if changed > 0 or removed > 0 then
    -- Preserve non-array metadata without modifying shared source tables.
    for key, value in pairs(source) do
      if type(key) ~= "number" then filtered[key] = value end
    end
    target.asteroid_spawn_definitions = filtered
  end
  return changed + removed
end

-- Stellar plasma hazards are authored separately and are not ordinary
-- mineral routes. Their names can also come from the Dyson discovery tech.
local function solar_locations()
  local names = {["sun-orbit"] = true, ["close-sun-orbit"] = true}
  for _, id in ipairs({"planet-discovery-sunorbit", "slp-solar-system-sun2"}) do
    local tech = (data.raw.technology or {})[id]
    for _, effect in ipairs(tech and tech.effects or {}) do
      if effect.type == "unlock-space-location"
        and type(effect.space_location) == "string" then
        names[effect.space_location] = true
      end
    end
  end
  return names
end

function M.data_final_fixes()
  local routes = data.raw["space-connection"] or {}
  ladder.prepare_routes(routes)
  local solar = solar_locations()
  local function is_solar(name)
    return solar[name] or (type(name) == "string"
      and name:find("^slp%-solar%-") ~= nil)
  end

  local edited = 0
  for _, route in pairs(routes) do
    if not route.hidden and type(route.from) == "string"
      and type(route.to) == "string"
      and not is_solar(route.from) and not is_solar(route.to) then
      local from = ladder.location_level(route.from)
      local to = ladder.location_level(route.to)
      edited = edited + filter(route,
        function(t, threshold)
          return ladder.route_level(route, t, "balanced") >= threshold
        end,
        function(threshold)
          return from >= threshold and to >= threshold
        end)
    end
  end
  for _, kind in ipairs({"planet", "space-location"}) do
    for name, location in pairs(data.raw[kind] or {}) do
      if not is_solar(name) then
        local stage = ladder.location_level(name)
        edited = edited + filter(location,
          function(_, threshold) return stage >= threshold end,
          function(threshold) return stage >= threshold end)
      end
    end
  end
  if edited > 0 and type(log) == "function" then
    log(("[Razi Protocol/asteroid-size] Gated %d oversized hostile " ..
      "spawn definitions against base campaign tiers"):format(edited))
  end
  return edited
end

return M
