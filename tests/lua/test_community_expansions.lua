---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(cond, why)
  if not cond then error(why,2) end
end

package.loaded["prototypes.system.asteroid_profiles"]={
  create=function(name)
    return {{asteroid="test-" .. name, probability=.001}}
  end
}

local configs={
  {"planet-ferrum","ferrum"},
  {"Velora","velora"},
  {"nulla","nulla"},
  {"alchemy-khemia","khemia"},
  {"Arcanyx","arcanyx"},
  {"biological-machines-planet-balack","bm-balack"},
  {"biological-machines-planet-wit","bm-wit"},
  {"Solar-Halo","halo-solar-orbit"},
  {"skewer_shattered_planet","shattered-planet"},
  {"rabbasca-underground","rabbasca-underground"},
  {"Hephaestus","hephaestus"}
}

local function run(options)
  options=options or {}
  local planets,locations,technologies,routes,mods_table={},{},{},{},{}
  local native={}
  for _,pair in ipairs(configs) do
    local mod,name=pair[1],pair[2]
    if mod~="Solar-Halo" and mod~="skewer_shattered_planet"
      and mod~="Hephaestus" then
      planets[name]={name=name,orbit={parent={type="planet",name="original-parent"},
        distance=4}}
    else
      locations[name]={name=name}
    end
    mods_table[mod]="1"
    if name~="rabbasca-underground" then
      technologies["unlock-"..name]={name="unlock-"..name,
        prerequisites={"source-author-research"},
        effects={{type="unlock-space-location",space_location=name},
          {type="unlock-recipe",recipe=name.."-native-science"}}}
    end
  end
  for _,name in ipairs({"calidus","solaris","nyxaris","vibrant","vespera",
    "beetlejuice","umbra","fulgora","gleba","nauvis","aquilo","tenebris",
    "paracelsin","solar-system-edge"}) do
    locations[name]=locations[name] or {name=name}
  end
  for _,name in ipairs({"solaris-discovery","nyxaris-discovery",
    "vibrant-discovery","umbra-discovery","planet-discovery-gleba",
    "planet-discovery-aquilo"}) do
    technologies[name]={name=name,prerequisites={}}
  end
  planets.fulgora={}
  planets.nauvis={}
  planets.gleba={}
  planets.aquilo={}
  planets.paracelsin={}
  planets.tenebris={}

  native.ferrum={name="fulgora-ferrum",from="fulgora",to="ferrum",
    length=10000,asteroid_spawn_definitions={{asteroid="native-ferrum"}}}
  routes[native.ferrum.name]=native.ferrum
  native.ferrum_vulcanus={name="vulcanus-ferrum",from="vulcanus",to="ferrum",
    length=10000,asteroid_spawn_definitions={{asteroid="native-metallic"}}}
  routes[native.ferrum_vulcanus.name]=native.ferrum_vulcanus
  native.wit={name="bm-nauvis-wit",from="nauvis",to="bm-wit",length=10000}
  routes[native.wit.name]=native.wit
  native.balack={name="aquilo-balack",from="aquilo",to="bm-balack",
    length=40000,asteroid_spawn_definitions={{asteroid="native-huge"}}}
  routes[native.balack.name]=native.balack
  native.halo={name="vulcanus-solar",from="vulcanus",to="halo-solar-orbit",
    length=30000,asteroid_spawn_definitions={{asteroid="halo-flare"}}}
  routes[native.halo.name]=native.halo
  native.halo_station={name="solar-station",from="halo-solar-orbit",
    to="halo-solar-station",length=1}
  routes[native.halo_station.name]=native.halo_station
  native.hidden={name="rabbasca-warp-field",from="rabbasca-underground",
    to="anomalous-depth",length=1}
  routes[native.hidden.name]=native.hidden
  native.special={name="hephaestus-relay",from="hephaestus",
    to="unknown-stargate",length=500}
  routes[native.special.name]=native.special

  if options.no_mod then mods_table[options.no_mod]=nil end
  if options.no_planet then planets[options.no_planet]=nil end
  if options.cycle then
    technologies["vibrant-discovery"].prerequisites={"unlock-khemia"}
  end
  if options.no_gate then technologies[options.no_gate]=nil end
  if options.no_native_ferrum then
    routes["fulgora-ferrum"]=nil
  end
  local raw={planet=planets,["space-location"]=locations,
    ["space-connection"]=routes,technology=technologies}
  rawset(_G,"data",{raw=raw,extend=function(self,entries)
    for _,entry in ipairs(entries) do
      local group=self.raw[entry.type]
      check(not group[entry.name],"Duplicate optional route created")
      group[entry.name]=entry
    end
  end})
  rawset(_G,"mods",mods_table)
  local moved={}
  rawset(_G,"PlanetsLib",{update=function(_,entries)
    for _,entry in ipairs(entries) do
      check(planets[entry.name],"Missing planet orbital update")
      rawset(planets[entry.name], "orbit", entry.orbit)
      moved[entry.name]=true
    end
  end})
  package.loaded["prototypes.system.community_expansions"]=nil
  local module=require("prototypes.system.community_expansions")
  module.data_final_fixes()
  return module,raw,native,moved
end

local module,raw,native,moved=run()
for _,name in ipairs({"ferrum","khemia","arcanyx","bm-balack"}) do
  check(moved[name],"A new optional world was not positioned: "..name)
end
check(raw.planet.ferrum.orbit.parent.name=="vibrant",
  "Ferrum must join electrical Vibrant while retaining source routes")
check(native.ferrum_vulcanus.length==115000,
  "Ferrum's Vulcanus cross-star distance is still a 10k shortcut")
check(native.ferrum_vulcanus.asteroid_spawn_definitions[1].asteroid
  =="native-metallic","Ferrum's native cross-star asteroids were replaced")
check(native.ferrum.length==10000,
  "Ferrum's local Fulgora route must keep its native distance")
check(raw.planet.khemia.orbit.parent.name=="vibrant",
  "Khemia did not join chemistry frontier")
check(raw.planet.arcanyx.orbit.parent.name=="umbra",
  "Arcanyx did not join the optional dark frontier")
check(raw.planet["bm-balack"].orbit.parent.name=="vespera",
  "Balack did not join Vespera's post-Aquilo region")
for _,name in ipairs({"velora","nulla","bm-wit",
  "rabbasca-underground"}) do
  check(not moved[name] and raw.planet[name].orbit.parent.name=="original-parent",
    "A moon or hidden underground world was reparented: "..name)
end
for _,key in ipairs({"ferrum","ferrum_vulcanus","wit","balack","halo",
  "halo_station","hidden","special"}) do
  check(raw["space-connection"][native[key].name]==native[key],
    "Native source route was lost: "..key)
end
check(not raw["space-connection"]["razi-expansion-ferrum-fulgora"],
  "Ferrum should use the native Fulgora route")
check(not raw["space-connection"]["razi-expansion-bm-balack-aquilo"],
  "Balack should use its native extreme route")
check(not raw["space-connection"]["razi-expansion-bm-wit-nauvis"],
  "Wit should use the existing Nauvis moon route")
check(raw["space-connection"]["razi-expansion-khemia-paracelsin"],
  "Khemia optional chemical branch is disconnected")
check(raw["space-connection"]["razi-expansion-arcanyx-tenebris"],
  "Arcanyx optional Umbra branch is disconnected")
check(raw["space-connection"]["razi-expansion-velora-gleba"],
  "Missing native moon route should be restored for Velora")
check(raw["space-connection"]["razi-expansion-nulla-aquilo"],
  "Missing native moon route should be restored for Nulla")
for _,pair in ipairs({
  {"ferrum","vibrant-discovery"},
  {"khemia","vibrant-discovery"},
  {"arcanyx","umbra-discovery"},
  {"velora","planet-discovery-gleba"},
  {"nulla","planet-discovery-aquilo"},
  {"bm-balack","planet-discovery-aquilo"},
  {"halo-solar-orbit","solaris-discovery"}
}) do
  local tech=raw.technology["unlock-"..pair[1]]
  local found=false
  for _,prerequisite in ipairs(rawget(tech,"prerequisites") or {}) do
    if prerequisite==pair[2] then found=true end
  end
  check(found,"Native discovery not chapter-gated: "..pair[1])
  local effects=rawget(tech,"effects") or {}
  local native_science=effects[2] or {}
  check(rawget(native_science,"recipe")==pair[1].."-native-science",
    "A mod's native science unlock was damaged")
end
check(#raw.technology["unlock-bm-wit"].prerequisites==1,
  "Wit science should not depend on a foreign planetary chapter")
check(#raw.technology["unlock-shattered-planet"].prerequisites==1,
  "Shattered and promethium tech must retain native research gates")
check(raw.planet["rabbasca-underground"].hidden==nil
  and not raw["space-connection"]["razi-expansion-rabbasca-underground-nauvis"],
  "Rabbasca underground cannot be accessible from a space platform")
local before=0
for _ in pairs(raw["space-connection"]) do before=before+1 end
module.data_final_fixes()
local after=0
for _ in pairs(raw["space-connection"]) do after=after+1 end
check(after==before,"Repeated data-final-fixes creates duplicate routes")

local _,off=run({no_mod="alchemy-khemia"})
check(not off["space-connection"]["razi-expansion-khemia-paracelsin"],
  "Missing optional mod still added a new route")
check(#off.technology["unlock-khemia"].prerequisites==1,
  "Absent mod incorrectly changed its own technology")

local _,cyclic=run({cycle=true})
check(#cyclic.technology["unlock-khemia"].prerequisites==1,
  "An optional discovery cycle was introduced")

local _,missing=run({no_gate="vibrant-discovery"})
check(not missing["space-connection"]["razi-expansion-khemia-paracelsin"],
  "Missing star technology must not attach a midgame route")
check(#missing.technology["unlock-khemia"].prerequisites==1,
  "Missing prerequisite technology must leave native research alone")

local _,absent=run({no_planet="arcanyx"})
check(not absent["space-connection"]["razi-expansion-arcanyx-tenebris"],
  "Prototype-absent planet still received route")

-- Verify the actual data-final-fixes entry point executes the integration
-- after the Razi route reconciler and before final orbit layout.
local f=assert(io.open("data-final-fixes.lua","r"))
local source=f:read("*a")
f:close()
local route=assert(source:find(
  'require("prototypes.system.route_reconcile").data_final_fixes()',1,true))
local expansion=assert(source:find(
  'require("prototypes.system.community_expansions").data_final_fixes()',1,true))
local layout=assert(source:find(
  'require("prototypes.system.galaxy_layout").data_final_fixes()',1,true))
check(route<expansion and expansion<layout,
  "Optional integrations must follow route reconciliation and precede layout")
print("Community expansion routes, science safeguards and special surfaces passed")
