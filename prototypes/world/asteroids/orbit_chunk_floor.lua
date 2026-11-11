-- Every place where a platform can wait needs a modest source of the three
-- basic Space Age chunks. Routes use different spawn definitions and are not
-- changed here. Run after all other asteroid integrations in data-final-fixes.
local M = {}

local basic_chunks = {
  "metallic-asteroid-chunk",
  "carbonic-asteroid-chunk",
  "oxide-asteroid-chunk"
}
local minimum_probability = 0.0025
local chunk_speed = 0.035

local belt_locations = {
  ["asteroid-belt-inner-edge"] = true,
  ["asteroid-belt-outer-edge"] = true,
  ["razi-umbra-belt-inner"] = true,
  ["razi-umbra-belt-outer"] = true
}

local function harvesting_disabled(name)
  if not belt_locations[name] then return false end
  local startup = settings and settings.startup
  local option = startup and startup["razi-belt-edge-harvesting"]
  -- An explicit choice to turn off belt harvesting must still be respected.
  return option and option.value == false
end

local function shallow_copy(source)
  local target = {}
  for key, value in pairs(source) do target[key] = value end
  return target
end

local function supply(location, chunks)
  local source = location.asteroid_spawn_definitions or {}
  local first, active = {}, {}
  for index, def in ipairs(source) do
    if type(def) == "table" and def.type == "asteroid-chunk"
      and chunks[def.asteroid] then
      first[def.asteroid] = first[def.asteroid] or index
      if type(def.probability) == "number" and def.probability > 0 then
        active[def.asteroid] = true
      end
    end
  end

  local updated, added = nil, 0
  for _, name in ipairs(basic_chunks) do
    if chunks[name] and not active[name] then
      updated = updated or shallow_copy(source)
      if first[name] then
        -- Re-enable an existing zero-rate chunk without duplicating its ID.
        -- Detach the definition before editing a table shared by other mods.
        local repaired = shallow_copy(source[first[name]])
        repaired.probability = minimum_probability
        if type(repaired.speed) ~= "number" or repaired.speed <= 0 then
          repaired.speed = chunk_speed
        end
        updated[first[name]] = repaired
      else
        updated[#updated + 1] = {
          type = "asteroid-chunk", asteroid = name,
          probability = minimum_probability, speed = chunk_speed,
          angle_when_stopped = 1
        }
      end
      added = added + 1
    end
  end

  if updated then location.asteroid_spawn_definitions = updated end
  return added
end

function M.data_final_fixes()
  local raw = data.raw
  local chunks = raw["asteroid-chunk"] or {}
  local locations, additions = 0, 0
  for _, kind in ipairs({"planet", "space-location"}) do
    for name, location in pairs(raw[kind] or {}) do
      if not harvesting_disabled(name) then
        local count = supply(location, chunks)
        if count > 0 then
          locations = locations + 1
          additions = additions + count
        end
      end
    end
  end
  if type(log) == "function" then
    log(("[Razi Protocol/orbit-chunks] Supplied %d missing basic chunk " ..
      "definitions at %d locations"):format(additions, locations))
  end
  return additions
end

return M
