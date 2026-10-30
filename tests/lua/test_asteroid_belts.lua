---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field
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
check(#moves == 4, "Vibrant and Umbra should each have two belt rims")
for _,side in ipairs({"inner","outer"}) do
  local name="asteroid-belt-"..side.."-edge"
  local loc=raw["space-location"][name]
  check(loc and loc.orbit.parent.name=="vibrant",
    "Vibrant's rims must orbit Vibrant")
  check(math.abs(loc.orbit.orientation - (side=="inner" and .77 or .775))<.001,
    "Vibrant belt rim reverted to the wrong side of the sun")
  check(#loc.asteroid_spawn_definitions==3,
    "Vibrant rims should be resource-rich")
end
local crossing=raw["space-connection"] and
  raw["space-connection"]["asteroid-belt-inner-edge-asteroid-belt-outer-edge"]
check(crossing and crossing.length==5000
  and crossing.from=="asteroid-belt-inner-edge"
  and crossing.to=="asteroid-belt-outer-edge",
  "The physically traversable Vibrant crossing is missing")
check(crossing.shape=="line",
  "Real asteroid belt passage must be a short radial line")
check(crossing.icon and crossing.asteroid_spawn_definitions,
  "Vibrant crossing lacks its own hazard profile or route icon")
check(raw["space-location"]["razi-vespera-belt-inner"]==nil,
  "Vespera has no belt of its own")
for _, side in ipairs({"inner","outer"}) do
  local loc=raw["space-location"]["razi-umbra-belt-"..side]
  check(loc ~= nil, "Missing Umbra belt rim")
  check(loc.orbit.parent.name == "umbra", "Wrong parent star")
  check(#loc.asteroid_spawn_definitions == 3,
    "Belt edges must provide metallic/carbonic/oxide ore chunks")
  check(loc.draw_orbit == false, "Extra orbit ring would clutter system")
end
require("prototypes.technology.asteroid_belts")
local vibrant_tech=raw.technology["space-discovery-asteroid-belt"]
check(vibrant_tech and vibrant_tech.prerequisites[1]=="vibrant-discovery",
  "Vibrant belt must be discoverable before reaching Ribbonia")
check(vibrant_tech.effects[1].space_location=="asteroid-belt-inner-edge"
  and vibrant_tech.effects[2].space_location=="asteroid-belt-outer-edge",
  "Vibrant survey must unlock both rims")
local survey = {
  ["space-discovery-asteroid-belt"] = {
    prerequisite = "vibrant-discovery",
    science = {"solaris-tech-card", "nyxaris-tech-card"},
    inner = "asteroid-belt-inner-edge", outer = "asteroid-belt-outer-edge"
  },
  ["razi-umbra-belt-survey"] = {
    prerequisite = "umbra-discovery",
    science = {"vibrant-tech-card", "vespera-tech-card"},
    inner = "razi-umbra-belt-inner", outer = "razi-umbra-belt-outer"
  }
}
for name, expected in pairs(survey) do
  local tech=raw.technology[name]
  check(tech and #tech.effects==2, name .. " must unlock both rims")
  check(tech.prerequisites[1]==expected.prerequisite and #tech.prerequisites==1,
    name .. " must follow the discovery of its system")
  check(#tech.unit.ingredients == #expected.science,
    name .. " has unexpected science ingredients")
  for i, card in ipairs(expected.science) do
    local ingredient = tech.unit.ingredients[i]
    check((ingredient.name or ingredient[1]) == card,
      name .. " requires a card not guaranteed before its belt")
  end
  check(tech.effects[1].space_location==expected.inner,
    name .. " has the wrong inner-rim unlock")
  check(tech.effects[2].space_location==expected.outer,
    name .. " has the wrong outer-rim unlock")
end
print("Belt locations, stationary resources and research survey fixtures passed")
