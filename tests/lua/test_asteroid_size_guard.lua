-- Final asteroid roster is checked after the source integrations, not by
-- trusting the standalone More Asteroids rules. Uses the real difficulty
-- ladder; partner-mod species and shared curves are represented as prototypes.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(condition, message)
  if not condition then error(message, 2) end
end

local ladder = require("lib.difficulty.asteroids")
local guard = require("prototypes.world.asteroids.asteroid_size_guard")
local function points()
  local result = {}
  for _, t in ipairs({.08, .30, .50, .70, .92}) do
    result[#result + 1] = {distance = t, probability = .1, speed = .02}
  end
  return result
end
local function enemy(name)
  return {type = "entity", asteroid = name, spawn_points = points()}
end
local function has(definitions, name)
  for _, definition in ipairs(definitions or {}) do
    if definition.asteroid == name then return definition end
  end
end
local source = {
  {type = "asteroid-chunk", asteroid = "lithium-asteroid-chunk", probability = .05},
  enemy("small-lithium-asteroid"),
  enemy("medium-lithium-asteroid"),
  enemy("big-radioactive-asteroid"),
  enemy("huge-dense-metal-asteroid"),
  enemy("razi-quality-asteroid-huge-metallic-asteroid"),
  enemy("super-large-custom-asteroid")
}
local early = {
  from = "sye-solaris", to = "vulcanus", length = 18000,
  asteroid_spawn_definitions = source
}
local shared = {
  from = "nauvis", to = "vulcanus",
  asteroid_spawn_definitions = source
}
local hidden = {
  from = "sye-solaris", to = "vulcanus", hidden = true,
  asteroid_spawn_definitions = source
}
local early_orbit = {asteroid_spawn_definitions = source}
local early_hub = {asteroid_spawn_definitions = {enemy("huge-lithium-asteroid")}}
local tier7 = {
  from = "aquilo", to = "sye-beetlejuice",
  asteroid_spawn_definitions = {
    enemy("big-rock-asteroid"), enemy("huge-rock-asteroid"),
    enemy("medium-rock-asteroid")
  }
}
local tier9 = {
  from = "sye-umbra", to = "crucible",
  asteroid_spawn_definitions = {
    enemy("big-lithium-asteroid"), enemy("huge-lithium-asteroid")
  }
}
local deep = {
  from = "nexus", to = "solar-system-edge",
  asteroid_spawn_definitions = {
    enemy("big-lithium-asteroid"), enemy("huge-lithium-asteroid")
  }
}
local deep_orbit = {asteroid_spawn_definitions = {
  enemy("big-uranium-asteroid"), enemy("huge-uranium-asteroid")
}}
local tier9_orbit = {asteroid_spawn_definitions = {
  enemy("big-uranium-asteroid"), enemy("huge-uranium-asteroid")
}}
local solar = {asteroid_spawn_definitions = {enemy("huge-plasma-asteroid")}}
rawset(_G, "data", {raw = {
  ["space-connection"] = {
    early = early, shared = shared, hidden = hidden, tier7 = tier7,
    tier9 = tier9, deep = deep
  },
  planet = {
    vulcanus = early_orbit, crucible = tier9_orbit, nexus = deep_orbit
  },
  ["space-location"] = {
    ["sye-solaris"] = early_hub, ["slp-dyson-dummy"] = solar
  },
  technology = {["planet-discovery-sunorbit"] = {effects = {
    {type = "unlock-space-location", space_location = "slp-dyson-dummy"}
  }}}
}})
rawset(_G, "settings", {startup = {
  ["razi-difficulty-preset"] = {value = "nightmare"}
}})

check(ladder.route_level(early, .5, "balanced") < 3,
  "Solaris to Vulcanus must remain an early-tier crossing")
check(guard.data_final_fixes() > 0, "Expected to suppress early oversize asteroids")
local safe = early.asteroid_spawn_definitions
check(safe ~= source and #safe == 3,
  "Solaris-Vulcanus must have chunks, small, and non-size-labelled species only")
check(has(safe, "lithium-asteroid-chunk")
  and has(safe, "small-lithium-asteroid")
  and has(safe, "super-large-custom-asteroid"),
  "Collectible resources and unknown source species must survive")
check(#shared.asteroid_spawn_definitions == 3,
  "A source-owned shared table must be filtered independently")
check(hidden.asteroid_spawn_definitions == source and #source == 7
  and source[4].spawn_points[3].probability == .1,
  "Never modify hidden routes or shared source-owned spawn tables")
check(#early_orbit.asteroid_spawn_definitions == 3
  and #early_hub.asteroid_spawn_definitions == 0,
  "Early stationary planets and slipstreams also require size protection")
check(#tier7.asteroid_spawn_definitions == 2
  and has(tier7.asteroid_spawn_definitions, "big-rock-asteroid")
  and not has(tier7.asteroid_spawn_definitions, "huge-rock-asteroid"),
  "Tier 7 supports Big asteroids, but not Huge")
check(#tier9.asteroid_spawn_definitions == 1
  and has(tier9.asteroid_spawn_definitions, "big-lithium-asteroid")
  and not has(tier9.asteroid_spawn_definitions, "huge-lithium-asteroid"),
  "Tier 9 must not require railguns")
check(#deep.asteroid_spawn_definitions == 2
  and #deep_orbit.asteroid_spawn_definitions == 2,
  "Tier 10 keeps the fully hazardous Deep Space roster")
check(#tier9_orbit.asteroid_spawn_definitions == 1,
  "Tier 9 stationary orbits cannot retain Huge asteroids")
check(solar.asteroid_spawn_definitions[1].asteroid == "huge-plasma-asteroid",
  "Special Dyson solar-orbit hazards must remain source-owned")

local previous = early.asteroid_spawn_definitions
check(guard.data_final_fixes() == 0
  and early.asteroid_spawn_definitions == previous,
  "Second pass cannot change an already repaired source spawn list")

-- A graded crossing may introduce Medium only after leaving the early stage.
local rising = {
  from = "vulcanus", to = "aquilo",
  asteroid_spawn_definitions = {enemy("medium-lithium-asteroid")}
}
data.raw["space-connection"] = {rising = rising}
local original = rising.asteroid_spawn_definitions[1]
local source_points = original.spawn_points
check(guard.data_final_fixes() > 0,
  "Longer-route spawn curves must be graded to the actual campaign stage")
local adjusted = has(rising.asteroid_spawn_definitions, "medium-lithium-asteroid")
check(adjusted and adjusted ~= original and adjusted.spawn_points ~= source_points,
  "A partly allowed spawn curve must detach its original source table")
check(adjusted.spawn_points[1].probability == 0
  and adjusted.spawn_points[2].probability == 0
  and adjusted.spawn_points[4].probability > 0
  and source_points[1].probability == .1,
  "Medium asteroids must fade in only after their defense tier")
check(guard.data_final_fixes() == 0,
  "Repeating a partly gated final pass cannot double-edit it")

for _, mode in ipairs({"easy", "normal", "hard", "nightmare", "custom"}) do
  settings.startup["razi-difficulty-preset"].value = mode
  local candidate = {
    from = "sye-solaris", to = "vulcanus",
    asteroid_spawn_definitions = {
      enemy("big-dense-metal-asteroid"), enemy("huge-radioactive-asteroid")
    }
  }
  data.raw["space-connection"] = {candidate = candidate}
  guard.data_final_fixes()
  check(#candidate.asteroid_spawn_definitions == 0,
    mode .. " must never bypass the asteroid defense gate")
end

-- Ensure the final roster is visible to route intel and quality conversion.
local f = assert(io.open("data-final-fixes.lua", "r"))
local pipeline = f:read("*a")
f:close()
local more = assert(pipeline:find('require("prototypes.world.asteroids.more_asteroids_integration").data_final_fixes()', 1, true))
local size = assert(pipeline:find('require("prototypes.world.asteroids.asteroid_size_guard").data_final_fixes()', 1, true))
local intel = assert(pipeline:find('require("prototypes.world.routes.route_intel").data_final_fixes()', 1, true))
local quality = assert(pipeline:find('require("prototypes.world.asteroids.quality_asteroids").data_final_fixes()', 1, true))
check(more < size and size < intel and size < quality,
  "Size caps must run after source spawns and before route previews or quality")
rawset(_G, "data", nil)
rawset(_G, "settings", nil)
print("Asteroid size guard: early source routes, tier caps and progression passed")
