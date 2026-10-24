---@diagnostic disable: need-check-nil, undefined-field, assign-type-mismatch, missing-fields
-- Standalone Lua 5.2 suite for the Razi More Asteroids integration: eight
-- families on the final routes and orbits, source-owned entries preserved.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
-- The profile module loads the Space Age spawn helper for its own presets.
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]={
  spawn_definitions=function() return {} end}
-- The pass reports through log; its last line is checked against the data.
local logged={}
rawset(_G,"log",function(message) logged[#logged+1]=tostring(message) end)
-- At runtime the catalog files the Dyson sphere's orbits under Calidus; the
-- integration must still leave them alone. Everything else is the real catalog.
local real_catalog=require("scripts.galactic_catalog")
local suns={["sun-orbit"]=true,["slp-dyson-dummy"]=true,["slp-solar-system-sun"]=true}
package.loaded["scripts.galactic_catalog"]={system=function(name)
  if suns[name] then return "calidus" end
  return real_catalog.system(name)
end}
package.loaded["scripts.razi_asteroid_difficulty"]=nil
local families={"uranium","rock","scrap","organic","chemical",
  "crystalline","halide","electrostatic"}
local function prototypes()
  local chunks,enemies={},{}
  for _,family in ipairs(families) do
    chunks[family.."-asteroid-chunk"]={}
    for _,size in ipairs({"small","medium","big","huge"}) do
      enemies[size.."-"..family.."-asteroid"]={}
    end
  end
  return chunks,enemies
end
local function reload(raw,installed,startup)
  rawset(_G,"data",{raw=raw})
  rawset(_G,"mods",installed)
  rawset(_G,"settings",{startup=startup or {}})
  package.loaded["prototypes.system.more_asteroids_integration"]=nil
  return require("prototypes.system.more_asteroids_integration")
end
local function names(list)
  local out={}
  for _,def in ipairs(list or {}) do out[#out+1]=def.asteroid or "?" end
  return table.concat(out,",")
end
local function count(list,word)
  local n=0
  for _,def in ipairs(list or {}) do
    if (def.asteroid or ""):find(word,1,true) then n=n+1 end
  end
  return n
end
local function family_entries(list)
  local n=0
  for _,family in ipairs(families) do n=n+count(list,family) end
  return n
end
local function largest(list,family)
  local order={chunk=0,small=1,medium=2,big=3,huge=4}
  local best="none"
  for _,def in ipairs(list or {}) do
    local asteroid=def.asteroid or ""
    if asteroid:find(family,1,true) then
      local size=asteroid:find("%-asteroid%-chunk$") and "chunk"
        or asteroid:match("^(%a+)%-")
      if order[size] and (best=="none" or order[size]>order[best]) then best=size end
    end
  end
  return best
end
local function entry(list,name)
  for _,def in ipairs(list or {}) do
    if def.asteroid==name then return def end
  end
end

-- Without the mod nothing is touched, even when the prototypes, a catalogued
-- route and its orbits are all present; the same data with the mod is applied.
local chunks,enemies=prototypes()
local raw={["asteroid-chunk"]=chunks,asteroid=enemies,
  planet={nauvis={},vulcanus={}},
  ["space-connection"]={a={name="razi-nauvis-vulcanus",from="nauvis",
    to="vulcanus",length=20000}}}
check(reload(raw,{}).data_final_fixes()==0,"Without the mod the pass must return 0")
check(raw["space-connection"].a.asteroid_spawn_definitions==nil,
  "Without the mod no route spawn table may appear")
check(raw.planet.nauvis.asteroid_spawn_definitions==nil
  and raw.planet.vulcanus.asteroid_spawn_definitions==nil,
  "Without the mod no orbit chunks may appear")
check(reload(raw,{["razi-more-asteroids"]="1.1.1"}).data_final_fixes()==1,
  "With the mod the same data gains its one route")
check(raw["space-connection"].a.asteroid_spawn_definitions~=nil
  and raw.planet.nauvis.asteroid_spawn_definitions~=nil,
  "With the mod the route and the orbit are populated")
check(reload({},{["razi-more-asteroids"]="1.1.1"}).data_final_fixes()==0,
  "An empty data.raw must not crash the pass")

-- Malformed, hidden, teleport and solar routes stay source-owned.
chunks,enemies=prototypes()
local foreign={type="asteroid-chunk",asteroid="imersite-asteroid-chunk",
  spawn_points={{distance=.5,probability=.1}}}
local vanilla={type="entity",asteroid="medium-metallic-asteroid",
  spawn_points={{distance=.5,probability=.02}}}
local stale={type="entity",asteroid="small-uranium-asteroid",spawn_points={}}
local shared={foreign,stale,vanilla}
local routes={
  nofrom={name="nofrom",to="nauvis"},
  -- A table endpoint fails the type guard and the location lookup alike: the
  -- case guards against a crash, not one specific condition.
  tablefrom={name="tablefrom",from={name="nauvis"},to="vulcanus"},
  hidden={name="hidden",from="nauvis",to="vulcanus",hidden=true},
  -- Castra is catalogued under Solaris but declared by no prototype here, so
  -- only the location lookup keeps the route out.
  missing={name="missing",from="nauvis",to="castra"},
  gate={name="calidus-stargate-x",from="nauvis",to="vulcanus"},
  solar={name="nauvis-sun-orbit",from="nauvis",to="sun-orbit"},
  dyson={name="nauvis-dyson",from="nauvis",to="slp-dyson-dummy"},
  sun={name="slp-nauvis-sun",from="nauvis",to="slp-solar-system-sun"},
  foreign={name="foreign",from="nauvis",to="third-party-world"},
  home={name="nauvis-sye-calidus",from="nauvis",to="sye-calidus",
    length=25000,asteroid_spawn_definitions=shared},
  crossing={name="sye-calidus-sye-solaris",from="sye-calidus",to="sye-solaris",
    length=60000,asteroid_spawn_definitions={foreign}},
  moon={name="fulgora-cerys",from="fulgora",to="cerys",length=800},
  belt={name="asteroid-belt-inner-edge-asteroid-belt-outer-edge",
    from="asteroid-belt-inner-edge",to="asteroid-belt-outer-edge",length=5000},
  -- Short flat routes sit exactly on their system stage: 4-5, 5, 8 and 9.
  vib={name="razi-sye-vibrant-ribbonia",from="sye-vibrant",to="ribbonia",length=10000},
  five={name="razi-sye-vespera-muria",from="sye-vespera",to="muria",length=10000},
  eight={name="razi-sye-umbra-tenebris",from="sye-umbra",to="tenebris",length=10000},
  nine={name="crucible-crucible-orbit",from="crucible",to="crucible-orbit",length=10000},
  deep={name="solar-system-edge-nexus",from="solar-system-edge",to="nexus",
    length=300000,asteroid_spawn_definitions={foreign,vanilla}}
}
raw={
  ["asteroid-chunk"]=chunks,asteroid=enemies,
  planet={nauvis={asteroid_spawn_definitions={
      {type="asteroid-chunk",asteroid="uranium-asteroid-chunk",probability=.5},
      {type="asteroid-chunk"}}},
    vulcanus={},aquilo={},fulgora={},cerys={},ribbonia={},muria={},tenebris={},
    crucible={},["sun-orbit"]={},["third-party-world"]={}},
  ["space-location"]={["sye-calidus"]={},["sye-solaris"]={},["sye-vibrant"]={},
    ["sye-vespera"]={},["sye-umbra"]={},["crucible-orbit"]={},
    ["solar-system-edge"]={},nexus={},["slp-dyson-dummy"]={},
    ["slp-solar-system-sun"]={},["razi-deep-space-edge"]={},
    ["asteroid-belt-inner-edge"]={},["asteroid-belt-outer-edge"]={},
    ["razi-umbra-belt-inner"]={},["razi-umbra-belt-outer"]={}},
  technology={["planet-discovery-sunorbit"]={effects={
    {type="unlock-space-location",space_location="slp-dyson-dummy"},
    {type="unlock-recipe",recipe="x"}}}},
  ["space-connection"]=routes
}
local integration=reload(raw,{["razi-more-asteroids"]="1.1.1"})
local ladder=require("scripts.razi_asteroid_difficulty")
local profiles=require("prototypes.system.asteroid_profiles")
local nauvis_original=raw.planet.nauvis.asteroid_spawn_definitions
local approved={"home","crossing","moon","belt","vib","five","eight","nine","deep"}
check(integration.data_final_fixes()==#approved,"Only the nine approved routes qualify")
for _,name in ipairs({"nofrom","tablefrom","hidden","missing","gate",
    "solar","dyson","sun","foreign"}) do
  check(routes[name].asteroid_spawn_definitions==nil,name.." must stay untouched")
end
-- The log line counts the routes, their family entries and the orbit chunks.
local additions,orbit_chunks=0,-#nauvis_original
for _,name in ipairs(approved) do
  additions=additions+family_entries(routes[name].asteroid_spawn_definitions)
end
for _,kind in ipairs({"planet","space-location"}) do
  for _,location in pairs(raw[kind]) do
    orbit_chunks=orbit_chunks+#(location.asteroid_spawn_definitions or {})
  end
end
local report=logged[#logged] or ""
check(additions>0 and orbit_chunks>0 and report:find(("Rebalanced %d approved routes "
  .."(%d family entries), added %d missing orbit chunks"):format(
    #approved,additions,orbit_chunks),1,true),
  "The log line reports routes, family entries and orbit chunks: "..report)
-- Home route: the stale family hostile goes, foreign and vanilla entries stay.
local home=routes.home.asteroid_spawn_definitions
check(home~=shared and #shared==3 and shared[2]==stale,
  "A shared source list must be detached, never mutated")
check(home[1]==foreign and home[2]==vanilla,"Foreign and vanilla entries keep their order")
check(count(home,"uranium")==1 and largest(home,"uranium")=="chunk",
  "The stale uranium hostile is replaced by one fresh chunk: "..names(home))
check(count(home,"halide")==0 and count(home,"crystalline")==0,
  "The home system carries only what the first platform can crush: "..names(home))
check(largest(home,"rock")=="chunk","Home routes stay at level 1: chunks only")
-- Sizes follow the ladder: small from stage 2, medium 3, big 6, huge 9.
local crossing=routes.crossing.asteroid_spawn_definitions
check(largest(crossing,"rock")=="small" and largest(crossing,"crystalline")=="small",
  "A level 1-2 crossing adds small hostiles only: "..names(crossing))
local moon=routes.moon.asteroid_spawn_definitions
check(largest(moon,"scrap")=="medium" and largest(moon,"electrostatic")=="medium",
  "Fulgora-Cerys (level 4-5) stops at medium: "..names(moon))
local belt=routes.belt.asteroid_spawn_definitions
check(largest(belt,"rock")=="big" and count(belt,"huge")==0,
  "The Vibrant belt crossing reaches big, never huge: "..names(belt))
check(count(belt,"electrostatic")>0 and count(belt,"halide")>0,
  "The Vibrant belt carries the Fulgora and Aquilo families")
local belt_halide=entry(belt,"halide-asteroid-chunk").spawn_points
check(belt_halide[1].probability>0 and belt_halide[5].probability>0,
  "Light halide flies at both ends of the Vibrant belt")
-- Flat routes pin the thresholds: stage 4-5 and 5 stop at medium, stage 8
-- reaches big without huge, stage 9 is the first with huge; and they pin the
-- system mixes: electrostatic and chemical in Vibrant, halide in Vespera.
local vib=routes.vib.asteroid_spawn_definitions
check(largest(vib,"scrap")=="medium" and count(vib,"big")==0,
  "A flat level 4-5 route stops at medium: "..names(vib))
check(count(vib,"electrostatic")>0 and count(vib,"chemical")>0 and count(vib,"halide")==0,
  "Vibrant carries electrostatic and chemical; halide only on its belt: "..names(vib))
local five=routes.five.asteroid_spawn_definitions
check(largest(five,"chemical")=="medium" and count(five,"big")==0,
  "A flat level-5 route stops at medium: "..names(five))
check(count(five,"halide")>0 and count(five,"electrostatic")==0,
  "Vespera carries halide, not the Fulgora family: "..names(five))
local eight=routes.eight.asteroid_spawn_definitions
check(largest(eight,"rock")=="big" and count(eight,"huge")==0,
  "A flat level-8 route reaches big, never huge: "..names(eight))
local nine=routes.nine.asteroid_spawn_definitions
check(largest(nine,"rock")=="huge",
  "A flat level-9 route is the first with huge: "..names(nine))
local stage=ladder.route_level(routes.belt,.5,"balanced")
local midpoint=entry(belt,"rock-asteroid-chunk").spawn_points[3]
check(midpoint.distance==.5 and math.abs(midpoint.probability
  -.0031*(0.78+stage*.035)*1.23*1.7)<1e-12
  and midpoint.speed==.035 and midpoint.angle_when_stopped==1,
  "Belt chunks follow the chunk curve with the belt harvest factor")
-- Rock weighs 1 on both belt edges, so the midpoint weight is 1.
local hostile=entry(belt,"small-rock-asteroid").spawn_points[3]
check(math.abs(hostile.probability
  -.00082*(0.72+stage*.05)*1.23*1.2*profiles.belt_factor())<1e-12,
  "Belt hostiles follow the hostile curve with the belt threat factor")
check(math.abs(entry(moon,"scrap-asteroid-chunk").spawn_points[3].probability
  -.0031*(.925)*(0.78+ladder.route_level(routes.moon,.5,"balanced")*.035)*1.23)<1e-12,
  "Ordinary routes interpolate the endpoint weights without a belt factor")
-- Hostiles have their own curve: a steeper stage factor, slower and tumbling.
-- Rock weighs .70 on Calidus and 1 on Solaris, so .85 at the midpoint.
local small=entry(crossing,"small-rock-asteroid").spawn_points[3]
check(math.abs(small.probability-.00082*.85
  *(0.72+ladder.route_level(routes.crossing,.5,"balanced")*.05)*1.23)<1e-12
  and small.speed==.018 and small.angle_when_stopped==.6,
  "Hostile entries use the hostile stage factor, speed and stop angle")
local deep=routes.deep.asteroid_spawn_definitions
check(deep[1]==foreign and deep[2]==vanilla and count(deep,"imersite")==1,
  "Imersite and vanilla entries survive on Deep Space")
for _,family in ipairs(families) do
  check(largest(deep,family)=="huge",
    "Deep Space carries all five sizes of "..family..": "..names(deep))
end
check(#deep==2+#families*5,"Every family entry is added exactly once")
for index,def in ipairs(deep) do
  if index>2 then
    check(#def.spawn_points==5,"Five curve points per entry")
    check((def.type=="asteroid-chunk")==(def.asteroid:find("chunk",1,true)~=nil),
      "Chunk entries are asteroid-chunk, hostiles are entity")
  end
end
-- Orbits: missing chunks only; solar orbits and Razi hubs are untouched.
local nauvis=raw.planet.nauvis.asteroid_spawn_definitions
check(nauvis~=nauvis_original and #nauvis_original==2,
  "The source orbit list is copied, never mutated")
check(#nauvis==3 and nauvis[1].probability==.5 and nauvis[3].asteroid=="rock-asteroid-chunk",
  "Nauvis keeps its own uranium entry and malformed record, gains rock: "..names(nauvis))
local aquilo=raw.planet.aquilo.asteroid_spawn_definitions
check(names(aquilo)=="rock-asteroid-chunk,chemical-asteroid-chunk,"
  .."crystalline-asteroid-chunk,halide-asteroid-chunk",
  "Aquilo orbit gets its four chunk families: "..names(aquilo))
check(math.abs(entry(aquilo,"chemical-asteroid-chunk").probability-.0022)<1e-12
  and math.abs(entry(aquilo,"halide-asteroid-chunk").probability-.0022*.90)<1e-12
  and entry(aquilo,"chemical-asteroid-chunk").type=="asteroid-chunk",
  "Orbit chunks scale the base probability by the mix weight")
-- Both belts park light halide and electrostatic at both edges; the Vibrant
-- edges carry the weights the geography table promises.
for _,edge in ipairs({"asteroid-belt-inner-edge","asteroid-belt-outer-edge",
    "razi-umbra-belt-inner","razi-umbra-belt-outer"}) do
  local parked=raw["space-location"][edge].asteroid_spawn_definitions
  check(count(parked,"halide")==1 and count(parked,"electrostatic")==1,
    edge.." parks halide and electrostatic chunks: "..names(parked))
end
local inner=raw["space-location"]["asteroid-belt-inner-edge"].asteroid_spawn_definitions
local outer=raw["space-location"]["asteroid-belt-outer-edge"].asteroid_spawn_definitions
check(math.abs(entry(inner,"halide-asteroid-chunk").probability-.0022*.30)<1e-12
  and math.abs(entry(outer,"halide-asteroid-chunk").probability-.0022*.35)<1e-12,
  "The Vibrant belt edges weigh halide .30 inside and .35 outside")
check(#raw["space-location"].nexus.asteroid_spawn_definitions==#families,
  "Deep Space orbits get a chunk of every family")
check(raw.planet["sun-orbit"].asteroid_spawn_definitions==nil
  and raw["space-location"]["slp-dyson-dummy"].asteroid_spawn_definitions==nil
  and raw["space-location"]["slp-solar-system-sun"].asteroid_spawn_definitions==nil,
  "Solar orbits never get orbit chunks")
check(raw["space-location"]["sye-calidus"].asteroid_spawn_definitions==nil
  and raw["space-location"]["razi-deep-space-edge"].asteroid_spawn_definitions==nil
  and raw.planet["third-party-world"].asteroid_spawn_definitions==nil,
  "System hubs, the deep space edge and unknown worlds are skipped")
-- Idempotent: a second pass keeps every list identical in content.
local before=names(deep)..";"..names(home)..";"..names(belt)..";"..names(nauvis)
check(integration.data_final_fixes()==#approved,"A second pass sees the same routes")
deep,home,belt=routes.deep.asteroid_spawn_definitions,
  routes.home.asteroid_spawn_definitions,routes.belt.asteroid_spawn_definitions
nauvis=raw.planet.nauvis.asteroid_spawn_definitions
check(names(deep)..";"..names(home)..";"..names(belt)..";"..names(nauvis)==before,
  "A second pass must not duplicate or reorder entries")
-- The difficulty scale comes from settings.startup; missing means balanced.
integration=reload(raw,{["razi-more-asteroids"]="1.1.1"},
  {["razi-asteroid-difficulty-scale"]={value="challenging"}})
integration.data_final_fixes()
crossing,moon=routes.crossing.asteroid_spawn_definitions,routes.moon.asteroid_spawn_definitions
check(largest(crossing,"rock")=="medium",
  "Challenging lifts the crossing to medium hostiles: "..names(crossing))
check(largest(moon,"scrap")=="medium","Challenging keeps Fulgora-Cerys below big")
-- Hard selects the Challenging scale by itself.
integration=reload(raw,{["razi-more-asteroids"]="1.1.1"},
  {["razi-difficulty-preset"]={value="hard"},
   ["razi-asteroid-difficulty-scale"]={value="balanced"}})
integration.data_final_fixes()
crossing=routes.crossing.asteroid_spawn_definitions
check(largest(crossing,"rock")=="medium",
  "Hard must apply the Challenging scale: "..names(crossing))
integration=reload(raw,{["razi-more-asteroids"]="1.1.1"},
  {["razi-asteroid-difficulty-scale"]={value="relentless"}})
integration.data_final_fixes()
moon,home=routes.moon.asteroid_spawn_definitions,routes.home.asteroid_spawn_definitions
check(largest(moon,"scrap")=="big",
  "Relentless lifts Fulgora-Cerys to big hostiles: "..names(moon))
check(largest(home,"rock")=="chunk","Home links stay chunk-only on every scale")
-- Partially installed families: only existing prototypes are referenced,
-- stale entries of families that lost their prototypes are dropped, and a
-- route whose mix keeps none of the surviving families is emptied, not counted.
raw["asteroid-chunk"]={["uranium-asteroid-chunk"]={},["rock-asteroid-chunk"]={}}
raw.asteroid={["small-uranium-asteroid"]={}}
routes.deep.asteroid_spawn_definitions={foreign}
integration=reload(raw,{["razi-more-asteroids"]="1.1.1"})
check(integration.data_final_fixes()==#approved-1,
  "Partial families still apply to every route with uranium or rock")
deep,belt=routes.deep.asteroid_spawn_definitions,routes.belt.asteroid_spawn_definitions
check(names(deep)==
  "imersite-asteroid-chunk,uranium-asteroid-chunk,small-uranium-asteroid,rock-asteroid-chunk",
  "Only existing prototypes are referenced: "..names(deep))
check(count(belt,"halide")==0,
  "Entries of a family without prototypes are removed, not kept")
check(#routes.vib.asteroid_spawn_definitions==0,
  "The Vibrant flat route, with neither family, is emptied and not counted")

-- Tier rule: a family never flies below its processing gate. Every catalogued
-- world of the tier 0-1 systems is reached from its hub, and both tier-1 hubs
-- from Calidus; a route carries only what one of its ends may carry, and an
-- orbit only what its world may carry.
local gated={
  calidus={scrap=true,organic=true,chemical=true,crystalline=true,
    halide=true,electrostatic=true},
  solaris={scrap=true,chemical=true,halide=true,electrostatic=true},
  nyxaris={scrap=true,chemical=true,halide=true,electrostatic=true}}
local worlds={}
for name in pairs(ladder.explicit_levels) do
  if gated[real_catalog.system(name)] then worlds[#worlds+1]=name end
end
table.sort(worlds)
chunks,enemies=prototypes()
raw={["asteroid-chunk"]=chunks,asteroid=enemies,planet={},["space-location"]={},
  ["space-connection"]={}}
local tier_routes={}
for _,world in ipairs(worlds) do
  local system=real_catalog.system(world)
  if world=="sye-"..system then
    raw["space-location"][world]={}
  else
    raw.planet[world]={}
    tier_routes[#tier_routes+1]={name="razi-sye-"..system.."-"..world,
      from="sye-"..system,to=world,length=26500}
  end
end
for _,hub in ipairs({"sye-solaris","sye-nyxaris"}) do
  tier_routes[#tier_routes+1]={name="razi-sye-calidus-"..hub,from="sye-calidus",
    to=hub,length=60000}
end
for _,route in ipairs(tier_routes) do raw["space-connection"][route.name]=route end
integration=reload(raw,{["razi-more-asteroids"]="1.1.1"})
check(#tier_routes>=20 and integration.data_final_fixes()==#tier_routes,
  "Every tier 0-1 world is reached by one approved route")
local function below_gate(route,family)
  return gated[real_catalog.system(route.from)][family]
    and gated[real_catalog.system(route.to)][family]
end
for _,route in ipairs(tier_routes) do
  local list=route.asteroid_spawn_definitions
  check(list and #list>0,route.name.." must be populated")
  for _,family in ipairs(families) do
    if below_gate(route,family) then
      check(count(list,family)==0,
        route.name.." flies "..family.." below its gate: "..names(list))
    end
  end
end
for _,world in ipairs(worlds) do
  local list=(raw.planet[world] or {}).asteroid_spawn_definitions
  if raw.planet[world] then
    check(list and #list>0,world.." orbit must be populated")
    for _,family in ipairs(families) do
      if gated[real_catalog.system(world)][family] then
        check(count(list,family)==0,
          world.." orbit parks "..family.." below its gate: "..names(list))
      end
    end
  end
end
print("Razi More Asteroids integration passed")
