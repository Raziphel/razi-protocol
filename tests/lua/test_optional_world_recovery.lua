package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
rawset(_G,"mods",{nulla="1.0.2",PlanetAthos="1.1.3"})
local calls=0
local source={add_radio_interference_energy=function(proto,value)
  calls=calls+1
  proto.energy_source.emissions_per_minute.radio_interference=value
end}
package.loaded["lib"]=source
package.preload["__nulla__/lib"]=function() return source end
package.loaded["prototypes.compat.nulla_guard"]=nil
local nulla=require("prototypes.compat.nulla_guard")
check(nulla.data_updates(),"Nulla source helper was not guarded")
source.add_radio_interference_energy(nil,2)
local energy={energy_source={emissions_per_minute={}}}
source.add_radio_interference_energy(energy,3)
check(calls==1 and energy.energy_source.emissions_per_minute.radio_interference==3,
  "Missing prototype guard must not affect valid source emissions")
nulla.data_updates()
source.add_radio_interference_energy(energy,4)
check(calls==2,"Idempotent Nulla guard must not wrap twice")

rawset(_G,"data",{raw={technology={
  ["athos-particulate"]={prerequisites={"engine-building"}},
  ["engine-building"]={prerequisites={"athos-particulate"}},
  ["other-a"]={prerequisites={"other-b"}},
  ["other-b"]={prerequisites={"other-a"}}
}}})
package.loaded["prototypes.compat.athos_cycle_guard"]=nil
local athos=require("prototypes.compat.athos_cycle_guard")
check(athos.find_cycle(data.raw.technology)~=nil,"Fixture cycle not found")
check(athos.repair("before-athos-data-updates")==1,
  "The data-stage pass must repair Athos cycles before its data-updates traversal")
check(#data.raw.technology["athos-particulate"].prerequisites==0,
  "Cyclic source edge not removed")
check(#data.raw.technology["other-a"].prerequisites==1 and
  #data.raw.technology["other-b"].prerequisites==1,
  "Unrelated dependency cycles must not be silently rewritten")
data.raw.technology["other-b"].prerequisites={}
check(athos.repair("later-stage")==0
  and athos.find_cycle(data.raw.technology)==nil,
  "Acyclic technology graphs must remain unchanged")
-- Regression built from the 2.1.83 full-pack crash graph.
-- Two cycle breaks only; native planet discoveries and late research stay.
data.raw.technology={
  ["space-science-pack"]={prerequisites={"muluna-alice-propellant"}},
  ["muluna-alice-propellant"]={prerequisites={"muluna-aluminum-processing"}},
  ["muluna-aluminum-processing"]={prerequisites={"muluna-alumina-processing"}},
  ["muluna-alumina-processing"]={prerequisites={"muluna-anorthite-processing"}},
  ["muluna-anorthite-processing"]={prerequisites={"planet-discovery-muluna"}},
  ["planet-discovery-muluna"]={prerequisites={"thruster-fuel"}},
  ["thruster-fuel"]={prerequisites={"thruster-oxidizer"}},
  ["thruster-oxidizer"]={prerequisites={"space-platform-thruster"}},
  ["space-platform-thruster"]={prerequisites={"space-science-pack","space-platform"}},
  ["space-platform"]={prerequisites={}},
  ["nyxaris-discovery"]={prerequisites={"lithium-processing","planet-discovery-corrundum"}},
  ["lithium-processing"]={prerequisites={"planet-discovery-aquilo"}},
  ["planet-discovery-aquilo"]={prerequisites={"vibrant-discovery"}},
  ["vibrant-discovery"]={prerequisites={"nyxaris-discovery"}},
  ["planet-discovery-corrundum"]={prerequisites={}},
  ["unrelated-a"]={prerequisites={"unrelated-b"}},
  ["unrelated-b"]={prerequisites={"unrelated-a"}}
}
check(athos.repair("before-athos-data-updates")==2,
  "Both logged bootstrap cycles must be repaired before Athos traverses")
check(#data.raw.technology["space-platform-thruster"].prerequisites==1
  and data.raw.technology["space-platform-thruster"].prerequisites[1]=="space-platform",
  "Thruster must be researchable without post-Muluna Space Science")
check(data.raw.technology["space-science-pack"].prerequisites[1]=="muluna-alice-propellant",
  "Muluna's original space science role must remain in place")
check(data.raw.technology["nyxaris-discovery"].prerequisites[1]=="planet-discovery-corrundum",
  "Keep the original Solaris -> Nyxaris gateway intact")
check(data.raw.technology["lithium-processing"].prerequisites[1]=="planet-discovery-aquilo",
  "Late Aquilo's original lithium source research must stay untouched")
check(#data.raw.technology["unrelated-a"].prerequisites==1 and
  #data.raw.technology["unrelated-b"].prerequisites==1,
  "Never silently delete unrelated mod research")
data.raw.technology["unrelated-b"].prerequisites={}
check(athos.find_cycle(data.raw.technology)==nil
  and athos.repair("second-pass")==0,
  "Resolved game graph must remain acyclic and idempotent")
print("Required planet compatibility fixtures passed")
