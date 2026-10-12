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
  {"starter", false, false, false},
  {"first_crossing", true, false, false},
  {"industrial_deep", true, false, false},
  {"middle_crossing", true, true, false},
  {"belt_vibrant_crossing", true, true, false},
  {"belt_vespera_crossing", true, true, false},
  {"outer_crossing", true, true, true},
  {"belt_umbra_crossing", true, true, true},
  {"deep_edge", true, true, true}
}
for _, entry in ipairs(progression) do
  local name, medium_allowed, big_allowed, huge_allowed =
    entry[1], entry[2], entry[3], entry[4]
  local defs = profiles.create(name)
  local metallic = probability(defs, "metallic-asteroid-chunk")
  ok(metallic > 0, "Resource chunks were removed on " .. name)
  local medium = probability(defs, "medium-oxide-asteroid")
  local big = probability(defs, "big-metallic-asteroid")
  local huge = probability(defs, "huge-metallic-asteroid")
  ok((medium > 0) == medium_allowed, "Medium asteroid size tier failed on " .. name)
  ok((big > 0) == big_allowed, "Big asteroid size tier failed on " .. name)
  ok((huge > 0) == huge_allowed, "Huge asteroid size tier failed on " .. name)
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
ok(custom_points == native.asteroid_spawn_definitions[6].spawn_points and
   custom_points[1].probability == 0.21,
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

-- Route asteroid fields must be a localized MIDPOINT spike, not a
-- permanent boost that accidentally changes modded resource profiles.
local field_route={asteroid_spawn_definitions=util.spawn_definitions()}
local original_modded=field_route.asteroid_spawn_definitions[6]
local original_points=original_modded.spawn_points
profiles.apply(field_route,"middle_crossing")
profiles.apply_field(field_route,1.8)
local medium_points
for _,def in ipairs(field_route.asteroid_spawn_definitions) do
  if def.asteroid=="medium-oxide-asteroid" then medium_points=def.spawn_points end
end
ok(medium_points and #medium_points>=5,
  "Field should create a smooth midpoint hazard window")
local centre,edge
for _,point in ipairs(medium_points) do
  if math.abs(point.distance-0.5)<.001 then centre=point.probability end
  if math.abs(point.distance-0.3)<.001 then edge=point.probability end
end
ok(centre and edge and centre>edge,
  "Field must be more dangerous in the middle of the journey")
ok(field_route.asteroid_spawn_definitions[6]==original_modded and
  original_modded.spawn_points==original_points,
  "Custom asteroid species were modified by route fields")
local before_points=medium_points
profiles.apply_field(field_route,1.8)
for _,def in ipairs(field_route.asteroid_spawn_definitions) do
  if def.asteroid=="medium-oxide-asteroid" then
    ok(def.spawn_points==before_points,"Field multiplier stacked twice")
  end
end

-- Stationary Calidus platforms must be small-only, not merely
-- a lower probability of getting hit by a medium or huge asteroid.
local shared_home = util.spawn_definitions()
local home_orbit = {asteroid_spawn_definitions = shared_home}
local another_orbit = {asteroid_spawn_definitions = shared_home}
profiles.cap_sizes(home_orbit, "small")
ok(probability(home_orbit.asteroid_spawn_definitions, "medium-oxide-asteroid") == 0,
   "Calidus platform still spawns medium asteroids")
ok(probability(home_orbit.asteroid_spawn_definitions, "big-metallic-asteroid") == 0,
   "Calidus platform still spawns big asteroids")
ok(probability(home_orbit.asteroid_spawn_definitions, "huge-metallic-asteroid") == 0,
   "Calidus platform still spawns huge asteroids")
ok(probability(another_orbit.asteroid_spawn_definitions, "medium-oxide-asteroid") > 0,
   "Size clamp contaminated a shared modded asteroid list")
ok(probability(home_orbit.asteroid_spawn_definitions, "imersite-asteroid-chunk") == 0.21,
   "Calidus size cap removed custom asteroid resources")

-- A belt can introduce an actual big/huge encounter when the native vanilla
-- preset omitted that size, but ONLY if Factorio defines that entity.
rawset(_G, "data", {raw={asteroid={
  ["big-metallic-asteroid"]={},
  ["huge-metallic-asteroid"]={}
}}})
local old_spawn = util.spawn_definitions
util.spawn_definitions = function()
  return {{type="asteroid-chunk",asteroid="metallic-asteroid-chunk",
    spawn_points={{distance=0.5,probability=0.1,speed=1}}}}
end
local v_belt = profiles.create("belt_vespera_crossing")
local u_belt = profiles.create("belt_umbra_crossing")
ok(probability(v_belt, "big-metallic-asteroid") > 0,
   "Vespera belt lacks an intentional big asteroid challenge")
ok(probability(v_belt, "huge-metallic-asteroid") == nil,
   "Vespera belt introduced huge asteroids too soon")
ok(probability(u_belt, "huge-metallic-asteroid") > 0,
   "Umbra belt lacks an intentional huge asteroid challenge")
ok(probability(u_belt, "imersite-asteroid-chunk") == nil,
   "Belt generated a non-native modded asteroid without source data")
util.spawn_definitions = old_spawn

print("Tiered asteroid profiles and modded spawn preservation passed")
