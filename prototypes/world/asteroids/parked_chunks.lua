-- A platform parked at a stop of our own collects nothing when the stop has no asteroids: the slipstreams of the
-- systems (sye-*) and Eneas define none, and a platform that ran out of fuel there could not make more. Such a stop
-- gets the three basic chunks at the rate of Fulgora's orbit (vanilla planet orbit), scaled like the orbit chunks of
-- More Asteroids. Hostile asteroids are not added, and a stop that already has spawns stays as it is.
local M = {}
local profiles = require("prototypes.world.asteroids.asteroid_profiles")

local chunk_rates = {metallic = .0025, carbonic = .001875, oxide = .000625}
local families = {"metallic", "carbonic", "oxide"}
local ORBIT_SPEED = 1/60

local function own_stop(kind, name)
  return (kind == "space-location" and name:find("^sye%-") ~= nil) or (kind == "planet" and name == "eneas")
end

function M.data_final_fixes()
  local chunks = data.raw["asteroid-chunk"] or {}
  local factor = profiles.asteroid_factor() * profiles.ore_factor()
  local changed = {}
  for _, kind in ipairs({"planet", "space-location"}) do
    for name, location in pairs(data.raw[kind] or {}) do
      local spawns = location.asteroid_spawn_definitions
      if own_stop(kind, name) and not (spawns and next(spawns)) then
        local definitions = {}
        for _, family in ipairs(families) do
          local chunk = family .. "-asteroid-chunk"
          if chunks[chunk] then
            definitions[#definitions + 1] = {type = "asteroid-chunk", asteroid = chunk,
              probability = chunk_rates[family] * factor, speed = ORBIT_SPEED, angle_when_stopped = 1}
          end
        end
        if #definitions > 0 then
          location.asteroid_spawn_definitions = definitions
          changed[#changed + 1] = name
        end
      end
    end
  end
  table.sort(changed)
  if #changed > 0 then
    log("[Razi Protocol/asteroids] basic chunks at the stops without asteroids: " .. table.concat(changed, ", "))
  end
  return #changed
end

return M
