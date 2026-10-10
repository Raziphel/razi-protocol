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
for _, name in ipairs(progression) do
  local defs = profiles.create(name)
  local metal = probability(defs, "metallic-asteroid-chunk")
  ok(metal > previous, "Hazard difficulty not rising at " .. name)
  previous = metal
  ok(probability(defs, "imersite-asteroid-chunk") == 0.21,
     "Custom Imersite resource asteroid changed")
  ok(probability(defs, "super-metallic-asteroid") == 0.06,
     "Custom metallic-named species changed")
end

local native = {
  length = 20000,
  asteroid_spawn_definitions = util.spawn_definitions()
}
local custom = native.asteroid_spawn_definitions[3]
local custom_points = custom.spawn_points
profiles.apply(native, "outer_industry")
ok(native.asteroid_spawn_definitions[3] == custom,
   "Native custom asteroid definition was replaced")
ok(custom.spawn_points == custom_points and custom_points[1].probability == 0.21,
   "Native custom asteroid spawn curve was modified")
local after = probability(native.asteroid_spawn_definitions, "metallic-asteroid-chunk")
profiles.apply(native, "outer_industry")
ok(probability(native.asteroid_spawn_definitions, "metallic-asteroid-chunk") == after,
   "Repeated final-fixes doubled asteroid difficulty")

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
