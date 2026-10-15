-- Contract test for optional Abacayba 0.0.42+ without a Factorio client.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
package.loaded["prototypes.system.abacayba_integration"]=nil
local adapter=require("prototypes.system.abacayba_integration")
rawset(_G,"mods",{})
rawset(_G,"data",{raw={planet={vesta={name="vesta"}},
  technology={["planet-discovery-vesta"]={prerequisites={}}}}})
check(adapter.data_updates()==nil and not adapter.gate(),
  "Absent optional mod must remain inert")

local original={name="abacayba",orbit={
    parent={type="planet",name="aquilo"},
    distance=4,orientation=.1,sprite={filename="source-orbit.png"}
  },map_gen_settings={property_expression_names={cliffiness=1}},
  surface_properties={gravity=40}}
local original_map=original.map_gen_settings
local original_sprite=original.orbit.sprite
local unlock={prerequisites={"planet-discovery-aquilo","military-4"},
  effects={{type="unlock-space-location",space_location="abacayba"},
    {type="unlock-recipe",recipe="ominous-science-pack"}},
  unit={count=740,ingredients={{"production-science-pack",1}},time=30}}
local original_unit=unlock.unit
local original_effects=unlock.effects
rawset(_G,"mods",{Abacayba_Moon_of_Nauvis="0.0.42"})
rawset(_G,"data",{raw={planet={
    vesta={name="vesta"},aquilo={name="aquilo"},abacayba=original},
  technology={
    ["planet-discovery-vesta"]={prerequisites={"planet-discovery-crucible"}},
    ["planet-discovery-aquilo"]={prerequisites={}},
    ["military-4"]={prerequisites={}},
    ["abacayba-native-discovery"]=unlock
  }}})
check(adapter.data_updates()=="abacayba","Abacayba source planet not detected")
check(original.orbit.parent.type=="planet" and original.orbit.parent.name=="vesta",
  "Abacayba must be a real moon of Vesta, not a root star planet")
check(original.orbit.distance==9.5 and original.orbit.orientation==.85,
  "Vesta moon orientation or separation changed")
check(original.orbit.sprite==original_sprite and original.map_gen_settings==original_map,
  "Rehoming must not replace source artwork or terrain generation")
check(adapter.data_final_fixes()=="abacayba","Final reparenting did not run")
local requirements=unlock.prerequisites
check(#requirements==2
  and requirements[1]=="military-4"
  and requirements[2]=="planet-discovery-vesta",
  "Old Aquilo discovery must be exchanged for Vesta without losing other tech")
check(unlock.unit==original_unit and unlock.effects==original_effects,
  "Native science cost and original unlock effects must not be overwritten")
check(adapter.gate() and #unlock.prerequisites==2,
  "Repeated late research repair must be idempotent")
local count=0
for _ in pairs(data.raw.planet) do count=count+1 end
check(count==3,"A second Abacayba planet was accidentally registered")

-- A source-owned Vesta->Abacayba tech cycle is never introduced.
unlock.prerequisites={"planet-discovery-aquilo"}
data.raw.technology["planet-discovery-vesta"].prerequisites=
  {"abacayba-native-discovery"}
check(adapter.gate()==false
  and #unlock.prerequisites==1
  and unlock.prerequisites[1]=="planet-discovery-aquilo",
  "Cycle guard must preserve source research on a conflicting modpack")

-- Alternate source IDs are supported only if they identify a single
-- unambiguous planet; arbitrary worlds must never be silently reparented.
data.raw.planet.abacayba=nil
data.raw.planet["planet-abacayba"]=original
check(adapter.planet_name()=="planet-abacayba",
  "A unique alternate native Abacayba ID should resolve")
data.raw.planet["moon-abacayba"]=original
check(adapter.planet_name()==nil,
  "Multiple Abacayba matches must not result in a guessed planet")
print("Abacayba moon integration: absent, reparenting, discovery, cycle, variants PASS")
