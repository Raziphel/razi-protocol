-- Tests of the new challenge presets. They must preserve safe defaults
-- and never let higher settings change custom asteroid species.
local calls={}
local original_settings=rawget(_G,"settings")
local function resolve(pop,belt)
  rawset(_G,"settings",{startup={
    ["razi-asteroid-population"]={value=pop},
    ["razi-belt-threats"]={value=belt}
  }})
  local helpers=require("prototypes.system.asteroid_profiles")
  return helpers.asteroid_factor(),helpers.belt_factor()
end
local a,b=resolve("standard","standard")
assert(a==1 and b==1,"Normal balance changed")
a,b=resolve("sparse","relaxed")
assert(a==.65 and b==.5,"Relaxed balance wrong")
a,b=resolve("dense","severe")
assert(a==1.3 and b==1.5,"Dense challenge balance wrong")
a,b=resolve("swarm","standard")
assert(a==1.6 and b==1,"Swarm population wrong")
rawset(_G,"settings",original_settings)
print("Gameplay options presets passed")
