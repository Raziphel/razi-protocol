package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
local function node(prereqs)
 return {prerequisites=prereqs or {},unit={count=8000,time=60,
  ingredients={{"promethium-science-pack",2},{"kr-singularity-tech-card",1}}}}
end
local function setup(late)
 local techs={
  ["razi-outer-frontier-mastery"]=node(),
  ["razi-singularity-theory"]=node({
    "kr-intergalactic-transceiver","razi-outer-frontier-mastery"}),
  ["razi-singularity-test-fire"]=node({"razi-singularity-theory"}),
  ["razi-stable-intergalactic-singularity"]=node({
    "razi-singularity-test-fire"}),
  ["razi-intergalactic-transceiver-signal"]=node({
    "razi-stable-intergalactic-singularity"}),
  ["stellar-discovery-solar-system-edge"]=node({
    "razi-outer-frontier-mastery"}),
  ["kr-intergalactic-transceiver"]=node(
    late and {"stellar-discovery-solar-system-edge"} or {})
 }
 if late then
  techs["razi-stable-intergalactic-singularity"].prerequisites={
   "razi-singularity-test-fire","stellar-discovery-solar-system-edge"}
 end
 local tools={}
 for _,name in ipairs({"calidus-tech-card","solaris-tech-card",
  "nyxaris-tech-card","vibrant-tech-card","vespera-tech-card",
  "beetlejuice-tech-card","umbra-tech-card"}) do tools[name]={} end
 rawset(_G,"data",{raw={technology=techs,tool=tools}})
 package.loaded["prototypes.technology.deep_space_arrival"]=nil
 return techs,require("prototypes.technology.deep_space_arrival")
end
local function has(tech,name)
 for _,item in ipairs(tech.prerequisites or {}) do
  if item==name then return true end
 end
 return false
end
local techs,m=setup()
m.data_final_fixes()
check(has(techs["stellar-discovery-solar-system-edge"],
  "razi-intergalactic-transceiver-signal"),
  "Activated source transceiver must open Deep Space")
check(not has(techs["razi-singularity-theory"],
  "kr-intergalactic-transceiver"),
  "Source K2SO late research must not block construction")
for _,id in ipairs({"razi-singularity-theory",
 "razi-singularity-test-fire",
 "razi-stable-intergalactic-singularity"}) do
 local t=techs[id]
 check(t.unit.count<=2100 and #t.unit.ingredients==7,
  "The opening transceiver research needs only the earlier seven stars")
 for _,part in ipairs(t.unit.ingredients) do
  check(part[1]~="promethium-science-pack",
   "Post-edge Promethium cannot unlock the edge")
 end
end
local prior=#techs["stellar-discovery-solar-system-edge"].prerequisites
m.data_final_fixes()
check(#techs["stellar-discovery-solar-system-edge"].prerequisites==prior,
 "Repeated data stages duplicated the signal gate")
local blocked,b=setup(true)
b.data_final_fixes()
check(not has(blocked["stellar-discovery-solar-system-edge"],
  "razi-intergalactic-transceiver-signal"),
  "Future-locked transceiver must not create a research loop")
print("Transceiver arrival: research, physical activation, cycles passed")
