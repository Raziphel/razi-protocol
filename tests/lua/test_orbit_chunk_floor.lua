-- Reproduce stationary-platform starvation through the actual final-fixes
-- prototype pass, including 3.0 slipstreams and source-owned spawn tables.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
  if not condition then error(message, 2) end
end

local chunk_names = {
  "metallic-asteroid-chunk", "carbonic-asteroid-chunk",
  "oxide-asteroid-chunk"
}
local chunks = {}
for _, name in ipairs(chunk_names) do chunks[name] = {name = name} end

local existing_metallic = {
  type = "asteroid-chunk", asteroid = chunk_names[1],
  probability = 0.015, speed = 0.05, angle_when_stopped = 0.5
}
local custom_chunk = {
  type = "asteroid-chunk", asteroid = "imersite-asteroid-chunk",
  probability = 0.2, speed = 0.06
}
local hostile = {
  type = "entity", asteroid = "big-metallic-asteroid",
  probability = 0.08, speed = 0.02
}
local native = {existing_metallic, custom_chunk, hostile}
local zero_chunk = {
  type = "asteroid-chunk", asteroid = chunk_names[2],
  probability = 0, speed = 0.04, angle_when_stopped = 0.7
}
local small_native = {
  type = "asteroid-chunk", asteroid = chunk_names[1],
  probability = 0.00001, speed = 0.03
}
local inactive = {small_native, zero_chunk}
local belt = {}
local route = {asteroid_spawn_definitions = {{type = "entity", asteroid = "native-hazard"}}}

rawset(_G, "settings", {startup = {
  ["razi-belt-edge-harvesting"] = {value = false}
}})
rawset(_G, "data", {raw = {
  ["asteroid-chunk"] = chunks,
  planet = {
    nauvis = {asteroid_spawn_definitions = native},
    ["foreign-planet"] = {}
  },
  ["space-location"] = {
    ["sye-calidus"] = {},
    ["sye-solaris"] = {asteroid_spawn_definitions = inactive},
    ["razi-deep-space-edge"] = {},
    ["slp-solar-system-sun"] = {},
    ["asteroid-belt-inner-edge"] = {asteroid_spawn_definitions = belt}
  },
  ["space-connection"] = {preserved = route}
}})
local raw = data.raw
local M = require("prototypes.world.asteroids.orbit_chunk_floor")

local function entry(location, name)
  for _, def in ipairs(location.asteroid_spawn_definitions or {}) do
    if def.asteroid == name and def.type == "asteroid-chunk" then
      return def
    end
  end
end

local function count(location, name)
  local amount = 0
  for _, def in ipairs(location.asteroid_spawn_definitions or {}) do
    if def.asteroid == name and def.type == "asteroid-chunk" then
      amount = amount + 1
    end
  end
  return amount
end

check(M.data_final_fixes() == 16,
  "All unlocked stationary locations must receive missing basic chunks")
for _, kind in ipairs({"planet", "space-location"}) do
  for name, location in pairs(raw[kind]) do
    if name ~= "asteroid-belt-inner-edge" then
      for _, chunk in ipairs(chunk_names) do
        local found = entry(location, chunk)
        check(found and found.probability > 0 and found.speed > 0,
          name .. " lacks collectible " .. chunk)
        check(count(location, chunk) == 1,
          name .. " has duplicate basic chunk definitions")
      end
    end
  end
end

local nauvis = raw.planet.nauvis
check(nauvis.asteroid_spawn_definitions ~= native and #native == 3,
  "The source spawn list must not be changed in place")
check(nauvis.asteroid_spawn_definitions[1] == existing_metallic
  and existing_metallic.probability == 0.015
  and nauvis.asteroid_spawn_definitions[2] == custom_chunk
  and nauvis.asteroid_spawn_definitions[3] == hostile,
  "Native and custom asteroid populations must stay untouched")
check(entry(nauvis, chunk_names[1]) == existing_metallic,
  "A positive native rate must not be overwritten by the fallback")

local solaris = raw["space-location"]["sye-solaris"]
check(solaris.asteroid_spawn_definitions ~= inactive
  and inactive[2] == zero_chunk and zero_chunk.probability == 0,
  "A zero-rate entry must be repaired without mutating a shared source")
check(entry(solaris, chunk_names[2]) ~= zero_chunk
  and entry(solaris, chunk_names[2]).probability == 0.0025
  and entry(solaris, chunk_names[2]).speed == 0.04
  and entry(solaris, chunk_names[2]).angle_when_stopped == 0.7,
  "The repaired source entry must retain its original speed and angle")
check(entry(solaris, chunk_names[1]) == small_native
  and small_native.probability == 0.00001,
  "A rare but functional source chunk must keep its scarcity")

check(raw["space-location"]["asteroid-belt-inner-edge"].asteroid_spawn_definitions == belt
  and #belt == 0, "Explicitly disabled belt harvesting must remain disabled")
check(route.asteroid_spawn_definitions[1].asteroid == "native-hazard",
  "A stationary location fix must not modify travel route hazards")

local refs = {}
for _, kind in ipairs({"planet", "space-location"}) do
  for name, location in pairs(raw[kind]) do
    refs[name] = location.asteroid_spawn_definitions
  end
end
check(M.data_final_fixes() == 0, "Repeated final-fixes must add nothing")
for _, kind in ipairs({"planet", "space-location"}) do
  for name, location in pairs(raw[kind]) do
    check(refs[name] == location.asteroid_spawn_definitions,
      "Repeated final-fixes must not rebuild an unchanged list")
  end
end

-- Missing asteroid prototypes must not be invented, and an explicit zero-rate
-- chunk must be repaired even if it is the sole existing resource.
rawset(_G, "settings", {startup = {}})
rawset(_G, "data", {raw = {
  ["asteroid-chunk"] = {[chunk_names[1]] = {}},
  planet = {},
  ["space-location"] = {
    ["only-metal"] = {asteroid_spawn_definitions = {{
      type = "asteroid-chunk", asteroid = chunk_names[1], probability = 0,
      speed = 0.035
    }}}
  }
}})
check(M.data_final_fixes() == 1,
  "The fallback must re-enable an existing zero-rate chunk")
check(#data.raw["space-location"]["only-metal"].asteroid_spawn_definitions == 1
  and entry(data.raw["space-location"]["only-metal"], chunk_names[1]).probability > 0,
  "An unavailable chunk type must never be introduced or duplicated")
check(M.data_final_fixes() == 0, "The single-family fallback must be stable")

print("Stationary asteroid resource floor passed")
