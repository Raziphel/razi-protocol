package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
rawset(_G,"mods",{nulla="1.0.2",PlanetAthos="1.1.3"})
local calls=0
local source={add_radio_interference_energy=function(proto,value)
  calls=calls+1
  proto.energy_source.emissions_per_minute.radio_interference=value
end}
package.loaded["lib"]=source
package.preload["__nulla__.lib"]=function() return source end
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
check(athos.repair()==1,"Only the Athos-owned cycle may be corrected")
check(#data.raw.technology["athos-particulate"].prerequisites==0,
  "Cyclic source edge not removed")
check(#data.raw.technology["other-a"].prerequisites==1 and
  #data.raw.technology["other-b"].prerequisites==1,
  "Unrelated dependency cycles must not be silently rewritten")
data.raw.technology["other-b"].prerequisites={}
check(athos.repair()==0 and athos.find_cycle(data.raw.technology)==nil,
  "Acyclic technology graphs must remain unchanged")
print("Optional world compatibility fixtures passed")
