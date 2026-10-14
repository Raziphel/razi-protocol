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
check(#moves == 6, "All six original Razi belt rims should exist")
for _,side in ipairs({"inner","outer"}) do
  local name="asteroid-belt-"..side.."-edge"
  local loc=raw["space-location"][name]
  check(loc and loc.orbit.parent.name=="vibrant",
    "Vibrant's legacy rim IDs must now be Razi-owned")
  check(#loc.asteroid_spawn_definitions==3,
    "Vibrant rims should be resource-rich")
end
local crossing=raw["space-connection"] and
  raw["space-connection"]["asteroid-belt-inner-edge-asteroid-belt-outer-edge"]
check(crossing and crossing.length==5000
  and crossing.from=="asteroid-belt-inner-edge"
  and crossing.to=="asteroid-belt-outer-edge",
  "Razi's physically traversable Vibrant crossing is missing")
check(crossing.shape=="line",
  "Real asteroid belt passage must be a short radial line")
check(crossing.icon and crossing.asteroid_spawn_definitions,
  "Vibrant core lacks its own hazard profile or route icon")
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
local legacy_tech=raw.technology["space-discovery-asteroid-belt"]
check(legacy_tech and legacy_tech.prerequisites[1]=="vibrant-discovery",
  "Vibrant belt must be discoverable before reaching Ribbonia")
check(legacy_tech.effects[1].space_location=="asteroid-belt-inner-edge"
  and legacy_tech.effects[2].space_location=="asteroid-belt-outer-edge",
  "Legacy survey ID must unlock both Razi-owned rims")
local survey_science = {
  vespera = {"solaris-tech-card", "nyxaris-tech-card"},
  umbra = {"vibrant-tech-card", "vespera-tech-card"}
}
for _, stem in ipairs({"vespera","umbra"}) do
  local tech=raw.technology["razi-"..stem.."-belt-survey"]
  check(tech and #tech.effects==2, "Belt survey tech must unlock both rims")
  check(tech.prerequisites[1]==(stem=="vespera" and
    "planet-discovery-aquilo" or "planet-discovery-crucible"),
    "Belt survey must happen before the destination's science")
  local expected = survey_science[stem]
  check(#tech.unit.ingredients == #expected,
    stem .. " survey has unexpected science ingredients")
  for i, name in ipairs(expected) do
    local ingredient = tech.unit.ingredients[i]
    check((ingredient.name or ingredient[1]) == name,
      stem .. " survey requires a card not guaranteed before its belt")
  end
  check(tech.effects[1].space_location=="razi-"..stem.."-belt-inner",
    "Wrong belt survey inner-rim unlock")
  check(tech.effects[2].space_location=="razi-"..stem.."-belt-outer",
    "Wrong belt survey outer-rim unlock")
end
print("Belt locations, stationary resources and research survey fixtures passed")
