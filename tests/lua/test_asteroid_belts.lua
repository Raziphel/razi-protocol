---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
  if not ok then error(message,2) end
end
local raw = {["space-location"]={},["asteroid-chunk"]={
  ["metallic-asteroid-chunk"]={},
  ["carbonic-asteroid-chunk"]={},
  ["oxide-asteroid-chunk"]={}
}, technology={}}
rawset(_G, "data", {raw=raw,
  extend=function(self, protos)
    for _, p in ipairs(protos) do
      self.raw[p.type] = self.raw[p.type] or {}
      self.raw[p.type][p.name] = p
    end
  end
})
local util={
  nauvis_fulgora={},gleba_aquilo={},fulgora_aquilo={},
  aquilo_solar_system_edge={},
  spawn_definitions=function() return {} end
}
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]=util
package.loaded["prototypes.system.asteroid_profiles"]=nil
package.loaded["prototypes.system.asteroid_belts"]=nil
local moves={}
rawset(_G,"PlanetsLib",{extend=function(_,locations)
  for _, loc in ipairs(locations) do
    check(loc.orbit and loc.orbit.parent.type=="space-location",
      "Belt location has no system parent")
    raw["space-location"][loc.name] = loc
    moves[#moves+1] = loc.name
  end
end})
require("prototypes.system.asteroid_belts")
check(#moves == 4, "Exactly four belt rims should exist")
for _, parent in ipairs({"vespera","umbra"}) do
  for _, side in ipairs({"inner","outer"}) do
    local loc=raw["space-location"]["razi-"..parent.."-belt-"..side]
    check(loc ~= nil, "Missing belt rim")
    check(loc.orbit.parent.name == parent, "Wrong parent star")
    check(#loc.asteroid_spawn_definitions == 3,
      "Belt edges must provide metallic/carbonic/oxide ore chunks")
    check(loc.draw_orbit == false, "Extra orbit ring would clutter system")
  end
end
require("prototypes.technology.asteroid_belts")
for _, stem in ipairs({"vespera","umbra"}) do
  local tech=raw.technology["razi-"..stem.."-belt-survey"]
  check(tech and #tech.effects==2, "Belt survey tech must unlock both rims")
  check(tech.prerequisites[1]==(stem=="vespera" and
    "planet-discovery-aquilo" or "planet-discovery-crucible"),
    "Belt survey must happen before the destination's science")
  check(tech.effects[1].space_location=="razi-"..stem.."-belt-inner",
    "Wrong belt survey inner-rim unlock")
  check(tech.effects[2].space_location=="razi-"..stem.."-belt-outer",
    "Wrong belt survey outer-rim unlock")
end
print("Belt locations, stationary resources and research survey fixtures passed")
