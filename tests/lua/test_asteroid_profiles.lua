---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
package.path = "./?.lua;./?/init.lua;" .. package.path

local function ok(cond, message)
  if not cond then error(message, 2) end
end

local preset = {name = "same-source"}
local util = {
  nauvis_fulgora = preset, vulcanus_castra = preset,
  nauvis_gleba = preset, fulgora_aquilo = preset, gleba_aquilo = preset,
  aquilo_solar_system_edge = preset,
  spawn_definitions = function()
    return {
      {type="asteroid-chunk", asteroid="metallic-asteroid-chunk",
       spawn_points={{distance=0,probability=0.10,speed=1}}},
      {type="entity", asteroid="medium-oxide-asteroid",
       spawn_points={{distance=0.5,probability=0.03,speed=2}}},
      {type="entity", asteroid="small-metallic-asteroid",
       spawn_points={{distance=0.5,probability=0.03,speed=2}}},
      {type="entity", asteroid="big-metallic-asteroid",
       spawn_points={{distance=0.5,probability=0.02,speed=2}}},
      {type="entity", asteroid="huge-metallic-asteroid",
       spawn_points={{distance=0.5,probability=0.01,speed=2}}},
      {type="asteroid-chunk", asteroid="imersite-asteroid-chunk",
       spawn_points={{distance=0.4,probability=0.21,speed=2}}},
      {type="entity", asteroid="super-metallic-asteroid",
       spawn_points={{distance=0.4,probability=0.06,speed=2}}}
    }
  end
}
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"] = util
package.loaded["prototypes.system.asteroid_profiles"] = nil
local profiles = require("prototypes.system.asteroid_profiles")

local function probability(defs, name)
  for _, def in ipairs(defs) do
    if def.asteroid == name then return def.spawn_points[1].probability end
  end
end

local progression = {
  "starter", "first_crossing", "middle_crossing",
  "cryogenic", "outer_crossing", "deep_edge"
}
local previous = 0
local previous_big = 0
local previous_huge = 0
for _, name in ipairs(progression) do
  local defs = profiles.create(name)
  local metal = probability(defs, "metallic-asteroid-chunk")
  ok(metal > previous, "Hazard difficulty not rising at " .. name)
  previous = metal
  local big = probability(defs, "big-metallic-asteroid")
  local huge = probability(defs, "huge-metallic-asteroid")
  ok(big > previous_big, "Big asteroids did not escalate on " .. name)
  ok(huge > previous_huge, "Huge asteroids did not escalate on " .. name)
  previous_big, previous_huge = big, huge
  ok(probability(defs, "imersite-asteroid-chunk") == 0.21,
     "Custom Imersite resource asteroid changed")
  ok(probability(defs, "super-metallic-asteroid") == 0.06,
     "Custom metallic-named species changed")
end

local native = {
  length = 20000,
  asteroid_spawn_definitions = util.spawn_definitions()
}
local custom = native.asteroid_spawn_definitions[6]
local custom_points = custom.spawn_points
profiles.apply(native, "outer_industry")
ok(native.asteroid_spawn_definitions[6] == custom,
   "Native custom asteroid definition was replaced")
ok(custom.spawn_points == custom_points and custom_points[1].probability == 0.21,
   "Native custom asteroid spawn curve was modified")
local after = probability(native.asteroid_spawn_definitions, "metallic-asteroid-chunk")
profiles.apply(native, "outer_industry")
ok(probability(native.asteroid_spawn_definitions, "metallic-asteroid-chunk") == after,
   "Repeated final-fixes doubled asteroid difficulty")

-- Two source mod routes may share the same list and vanilla definitions.
-- Scaling one must not alter the other (or any custom entry references).
local same_list = util.spawn_definitions()
local shared = {asteroid_spawn_definitions = same_list}
local neighboring = {asteroid_spawn_definitions = same_list}
local baseline = probability(same_list, "big-metallic-asteroid")
profiles.apply(shared, "outer_void_deep")
ok(probability(neighboring.asteroid_spawn_definitions, "big-metallic-asteroid") == baseline,
   "A shared upstream asteroid table was modified in place")
ok(neighboring.asteroid_spawn_definitions[6] == same_list[6],
   "A neighboring modded asteroid was replaced")

local before = profiles.create("industrial")
local after_copy = profiles.create("industrial")
before[1].spawn_points[1].probability = 123
ok(after_copy[1].spawn_points[1].probability ~= 123,
   "Two routes unexpectedly share mutable asteroid tables")

local first = {
  asteroid_spawn_definitions = {
    {type="asteroid-chunk", asteroid="metallic-asteroid-chunk",
     spawn_points={{probability=0.3}}}
  }
}
local duplicate = {
  asteroid_spawn_definitions = {
    {type="asteroid-chunk", asteroid="imersite-asteroid-chunk",
     spawn_points={{probability=0.10, speed=3, distance=0.3}}},
    {type="asteroid-chunk", asteroid="metallic-asteroid-chunk",
     spawn_points={{probability=2}}},
    {type="entity", asteroid="extra-mod-asteroid",
     spawn_points={{probability=0.17, speed=5, distance=0.25}}}
  }
}
profiles.preserve_custom(first, duplicate)
ok(#first.asteroid_spawn_definitions == 3, "Lost a modded asteroid from duplicate route")
ok(probability(first.asteroid_spawn_definitions, "imersite-asteroid-chunk") == 0.10,
   "Changed duplicate Imersite asteroid curve")
profiles.preserve_custom(first, duplicate)
ok(#first.asteroid_spawn_definitions == 3, "Duplicated custom asteroid definitions")

print("Tiered asteroid profiles and modded spawn preservation passed")
