---@diagnostic disable: missing-fields
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value, message)
  if not value then error(message, 2) end
end
-- A copy of Nulla 1.0.2's lib.lua:47-71 (the two helpers the guard wraps).
local function nulla_lib()
  local lib={}
  function lib.add_radio_interference(proto, value)
    proto.emissions_per_second = proto.emissions_per_second or {}
    if proto.emissions_per_second.radio_interference then
      table.insert(proto.emissions_per_second, { radio_interference = value })
    else
      proto.emissions_per_second = { radio_interference = value }
    end
  end
  function lib.add_radio_interference_energy(proto, value)
    if proto.energy_source then
      local es = proto.energy_source
      es.emissions_per_minute = es.emissions_per_minute or {}
      es.emissions_per_minute.radio_interference = value
    end
  end
  return lib
end
local function setup(nulla)
  rawset(_G,"mods",nulla and {nulla="1.0.2"} or {})
  local lib=nulla_lib()
  package.preload["__nulla__/lib"]=function() return lib end
  package.loaded["__nulla__/lib"]=nil
  package.loaded["prototypes.compat.nulla_guard"]=nil
  return lib,require("prototypes.compat.nulla_guard")
end

local lib,guard=setup(true)
check(guard.data_updates()==true,"Guard did not wrap Nulla's helpers")

-- The unguarded helper replaces the other pollutants of an entity.
local bare=nulla_lib()
local lost={emissions_per_second={pollen=0.06}}
bare.add_radio_interference(lost,0.5)
check(lost.emissions_per_second.pollen==nil,"The mock no longer shows Nulla's overwrite")

local roboport={name="tellus-roboport",emissions_per_second={pollen=0.06}}
lib.add_radio_interference(roboport,0.1)
check(roboport.emissions_per_second.pollen==0.06,
  "Radio interference dropped the pollen of a Tellus roboport")
check(roboport.emissions_per_second.radio_interference==0.1,
  "Radio interference was not added next to the pollen")

local plain={name="roboport"}
lib.add_radio_interference(plain,0.2)
check(plain.emissions_per_second.radio_interference==0.2
  and next(plain.emissions_per_second,"radio_interference")==nil,
  "An entity without emissions got more than the radio interference")
local empty={name="beacon",emissions_per_second={}}
lib.add_radio_interference(empty,0.3)
check(empty.emissions_per_second.radio_interference==0.3,
  "An entity with empty emissions got no radio interference")

-- The to-type helpers of Nulla call through the module table.
function lib.add_radio_interference_to_type(group,value)
  for _, proto in pairs(group) do lib.add_radio_interference(proto,value) end
end
local beacons={a={emissions_per_second={pollen=0.06}},b={}}
lib.add_radio_interference_to_type(beacons,0.4)
check(beacons.a.emissions_per_second.pollen==0.06
  and beacons.a.emissions_per_second.radio_interference==0.4
  and beacons.b.emissions_per_second.radio_interference==0.4,
  "The to-type helper bypassed the guard")

check(lib.add_radio_interference(nil,1)==nil,"A missing prototype raised an error")
lib.add_radio_interference_energy(nil,1)

local _,off=setup(false)
check(off.data_updates()==false,"Guard ran without Nulla installed")
print("Nulla radio interference guard passed")
