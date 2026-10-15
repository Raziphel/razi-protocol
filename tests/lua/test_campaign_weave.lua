---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
  if not ok then error(message, 2) end
end
local raw = {technology={},tool={},recipe={},lab={
  standard={inputs={"calidus-tech-card","metallurgic-science-pack",
    "battlefield-science-pack","planetaris-compression-science-pack",
    "planetaris-polishing-science-pack","agricultural-science-pack"}}
}}
local t=raw.technology
local function mk(parents)
  return {prerequisites=parents or {},unit={
    count=100,time=30,ingredients={{"calidus-tech-card",1}}}}
end
for _, name in ipairs({
  "solaris-discovery","nyxaris-discovery",
  "planet-discovery-vulcanus","planet-discovery-castra",
  "planet-discovery-arig","planet-discovery-hyarion",
  "planet-discovery-tellus","planet-discovery-corrundum",
  "planet-discovery-gleba","planet-discovery-moshine",
  "planet-discovery-apia-carnova",
  "panglia_planet_discovery_panglia",
  "panglia_tech_timewarp_data","panglia_advanced_optics_nanotech",
  "panglia_dna_manipulation","panglia_sentient_processor",
  "planet-discovery-fulgora","planet-discovery-ribbonia",
  "planet-discovery-paracelsin",
  "planet-discovery-muria","planet-discovery-aquilo",
  "planet-discovery-rubia","planet-discovery-maraxsis",
  "planet-discovery-cubium","planet-discovery-secretas",
  "planet-discovery-frozeta","planet-discovery-tenebris",
  "planet-discovery-crucible","planet-discovery-vesta"
}) do t[name]=mk() end
t["planet-discovery-castra"].prerequisites={"planet-discovery-vulcanus","native-castra"}
t["native-castra"]=mk()
for _, entry in ipairs({
  {"metallurgic-science-pack","planet-discovery-vulcanus"},
  {"battlefield-science-pack","planet-discovery-castra"},
  {"planetaris-compression-science-pack","planet-discovery-arig"},
  {"planetaris-polishing-science-pack","planet-discovery-hyarion"},
  {"agricultural-science-pack","planet-discovery-gleba"},
  {"bioluminescent-science-pack","planet-discovery-tenebris"},
  {"planet-crucible-science-pack","planet-discovery-crucible"}
}) do
  t[entry[1]]=mk({entry[2]})
  raw.tool[entry[1]]={}
  raw.recipe[entry[1]]={results={{type="item",name=entry[1],amount=1}}}
end
-- A recipe can exist but remain locked behind the discovery that is trying
-- to consume its science. The science technology milestone is still safe,
-- but the ingredient itself must not be added until its production is valid.
raw.recipe["battlefield-science-pack"].enabled=false
t["planet-discovery-arig"].effects={{
  type="unlock-recipe",recipe="battlefield-science-pack"
}}
-- Simulate a source-mod circular dependency. Do not let Frozeta require
-- a science technology which itself demands Frozeta discovery.
t["bioluminescent-science-pack"].prerequisites={"planet-discovery-frozeta"}
rawset(_G,"data",{raw=raw})
package.loaded["prototypes.technology.campaign_weave"]=nil
local M=require("prototypes.technology.campaign_weave")
-- A large unrelated recipe catalogue should not alter actual source-pack
-- eligibility: only native target-science producers may affect this weave.
for i=1,600 do
  raw.recipe["unrelated-recipe-"..i]={
    results={{type="item",name="irrelevant-product-"..i,amount=1}}
  }
end
local lab_scans=0
setmetatable(raw.lab,{__pairs=function(t)
  lab_scans=lab_scans+1
  return next,t,nil
end})
M.data_final_fixes()
check(lab_scans==1,"Campaign weave rebuilt its lab inputs for each science check")
-- The deliverability check and the later ingredient insertion must both
-- evaluate the same owner, not silently relax the provenance rule.
local source=assert(io.open("prototypes/technology/campaign_weave.lua","r"))
local body=source:read("*a")
source:close()
check(body:find("add_science(target,pack,owner)",1,true)
  and body:find("has_production_recipe_before(pack, target, owner)",1,true),
  "Research ingredient pass discarded source-world ownership")
local function has_parent(name,need)
  for _, p in ipairs(t[name].prerequisites) do if p==need then return true end end
  return false
end
local function has_pack(name,need)
  for _, p in ipairs(t[name].unit.ingredients) do
    if p[1]==need then return true end
  end
  return false
end
check(has_parent("planet-discovery-castra","metallurgic-science-pack"),
  "Castra lacks Vulcanus metallurgy research")
check(has_pack("planet-discovery-castra","metallurgic-science-pack"),
  "Castra is not using producible science accepted by one lab")
check(has_parent("planet-discovery-castra","native-castra"),
  "Native prerequisites were overwritten")
check(not has_parent("planet-discovery-arig","battlefield-science-pack"),
  "Locked source-pack recipe must not become a mandatory prerequisite")
check(not has_pack("planet-discovery-arig","battlefield-science-pack"),
  "Arig was charged science that only Arig research itself unlocks")
check(not has_parent("planet-discovery-hyarion","battlefield-science-pack")
  and not has_pack("planet-discovery-hyarion","battlefield-science-pack"),
  "Arig and Hyarion must remain independent branches after Castra")
check(has_parent("planet-discovery-tellus","planet-discovery-gleba"),
  "Tellus missing Gleba cross-system discovery")
check(has_parent("planet-discovery-tellus","planetaris-compression-science-pack"),
  "Tellus missing Arig science")
check(has_parent("planet-discovery-tellus","planetaris-polishing-science-pack"),
  "Tellus missing Hyarion science")
check(has_parent("planet-discovery-apia-carnova","planet-discovery-moshine"),
  "Apia/Carnova missing Moshine research")
check(has_parent("panglia_tech_timewarp_data","planet-discovery-moshine"),
  "Panglia timewarp research should be connected to Moshine")
check(has_parent("panglia_advanced_optics_nanotech","planet-discovery-apia-carnova"),
  "Panglia nanoscale optics should be connected to Apia/Carnova")
check(has_parent("panglia_dna_manipulation","planet-discovery-tellus"),
  "Panglia DNA research should recognize Tellus bioengineering")
check(has_parent("planet-discovery-maraxsis","planet-discovery-paracelsin"),
  "Maraxsis missing Vibrant research")
check(has_parent("planet-discovery-frozeta","planet-discovery-tenebris"),
  "Outer-frontier link missing")
check(has_parent("planet-discovery-vesta","planet-discovery-cubium"),
  "Vesta missing Beetlejuice research")
check(not has_parent("planet-discovery-frozeta","bioluminescent-science-pack"),
  "A science milestone produced a technology cycle")
check(not has_pack("planet-discovery-crucible","bioluminescent-science-pack"),
  "Science added despite no lab accepting it")
check(not has_parent("solaris-discovery","nyxaris-discovery") and
  not has_parent("nyxaris-discovery","solaris-discovery"),
  "First-system independence lost")
check(t["planet-discovery-carna"]==nil and t["planet-discovery-pelagos"]==nil,
  "An optional planet was created")

local snapshots={}
for name,v in pairs(t) do snapshots[name]={#v.prerequisites,#v.unit.ingredients} end
M.data_final_fixes()
check(lab_scans==1,"Repeated campaign weaving rescanned lab inputs")
for name,v in pairs(t) do
  check(#v.prerequisites==snapshots[name][1] and
    #v.unit.ingredients==snapshots[name][2],"Duplicate research on repeated pass: "..name)
end
local f=assert(io.open("data-final-fixes.lua","r"))
local src=f:read("*a")
f:close()
local a=assert(src:find('require("prototypes.technology.seven_system_gates").data_final_fixes()',1,true))
local b=assert(src:find('require("prototypes.technology.campaign_weave").data_final_fixes()',1,true))
check(b>a,"Weave not wired after final system research gates")
print("Cross-planet research, optional guards, lab safety and cycles passed")
