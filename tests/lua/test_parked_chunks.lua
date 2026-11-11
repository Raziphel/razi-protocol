---@diagnostic disable: need-check-nil, missing-fields, undefined-field
-- The stops of our own without asteroids (slipstreams, Eneas) get the basic chunks, on a mocked data.raw.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]={
  spawn_definitions=function() return {} end}
local logged={}
rawset(_G,"log",function(message) logged[#logged+1]=tostring(message) end)
local function run(raw,startup)
  rawset(_G,"data",{raw=raw})
  rawset(_G,"settings",{startup=startup or {}})
  package.loaded["prototypes.world.asteroids.asteroid_profiles"]=nil
  package.loaded["prototypes.world.asteroids.parked_chunks"]=nil
  return require("prototypes.world.asteroids.parked_chunks").data_final_fixes()
end
local own={type="asteroid-chunk",asteroid="metallic-asteroid-chunk",probability=.5}
local raw={
  ["asteroid-chunk"]={["metallic-asteroid-chunk"]={},["carbonic-asteroid-chunk"]={},["oxide-asteroid-chunk"]={}},
  planet={eneas={},nauvis={},vulcanus={asteroid_spawn_definitions={own}}},
  ["space-location"]={["sye-calidus"]={},["sye-umbra"]={asteroid_spawn_definitions={}},
    ["sye-vibrant"]={asteroid_spawn_definitions={own}},["solar-system-edge"]={}},
}
check(run(raw)==3,"Two slipstreams without asteroids and Eneas get chunks")
local calidus=raw["space-location"]["sye-calidus"].asteroid_spawn_definitions
check(#calidus==3 and calidus[1].asteroid=="metallic-asteroid-chunk" and calidus[1].type=="asteroid-chunk",
  "The three basic chunks, metallic first")
check(math.abs(calidus[1].probability-.0025)<1e-12 and math.abs(calidus[3].probability-.000625)<1e-12,
  "At the rate of Fulgora's orbit with standard settings")
check(#raw["space-location"]["sye-umbra"].asteroid_spawn_definitions==3,"An empty list counts as no asteroids")
check(#raw.planet.eneas.asteroid_spawn_definitions==3,"Eneas gets them too")
check(raw["space-location"]["sye-vibrant"].asteroid_spawn_definitions[1]==own
  and #raw["space-location"]["sye-vibrant"].asteroid_spawn_definitions==1,"A stop with asteroids stays as it is")
check(raw.planet.nauvis.asteroid_spawn_definitions==nil
  and raw["space-location"]["solar-system-edge"].asteroid_spawn_definitions==nil,
  "Locations of other mods are not touched")
check(#logged==1 and logged[1]:find("eneas, sye%-calidus, sye%-umbra"),"One log line names the stops")
check(run(raw)==0,"A second pass finds nothing to do")
-- The population and richness settings scale the rate.
local dense={["asteroid-chunk"]={["metallic-asteroid-chunk"]={}},planet={},["space-location"]={["sye-calidus"]={}}}
run(dense,{["razi-asteroid-population"]={value="dense"},["razi-belt-resource-richness"]={value="standard"}})
check(math.abs(dense["space-location"]["sye-calidus"].asteroid_spawn_definitions[1].probability-.0025*1.3)<1e-12,
  "Dense population scales the chunks like the orbit chunks of More Asteroids")
print("test_parked_chunks: ok")
