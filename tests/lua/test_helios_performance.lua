-- Performance and correctness regression for HELIOS memoization.
-- Runs with ordinary Lua, without a Factorio instance or any timers.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
rawset(_G,"storage",{})
rawset(_G,"settings",{startup={
 ["razi-helios-commissioning"]={value="expedition"},
 ["razi-helios-coronal-surges"]={value="off"}}})
rawset(_G,"prototypes",{technology={
 ["planet-discovery-sunorbit"]={effects={{
  type="unlock-space-location",space_location="slp-outer"}}},
 ["slp-solar-system-sun2"]={effects={{
  type="unlock-space-location",space_location="slp-inner"}}}}})
local scans,stats_calls=0,0
local energy=1000
local planet={valid=true,planet={name="vulcanus"},
 find_entities_filtered=function()
   scans=scans+1
   return {{valid=true,energy=energy}}
 end}
local station={valid=true,platform={valid=true,index=99}}
local force={index=1,technologies={
 ["razi-helios-grid-commission"]={researched=true}},
 get_entity_count=function() return 1 end}
local produced=7
force.get_item_production_statistics=function(_)
 stats_calls=stats_calls+1
 return {valid=true,
  get_output_count=function(name)
   return name=="razi-helios-corona-shield" and produced or 0
  end,
  get_input_count=function()
   error("Manufacturing must not use consumption statistics")
  end}
end
rawset(_G,"game",{tick=100,surfaces={
 ["vulcanus"]=planet,["platform"]=station}})
package.loaded["scripts.razi_helios_operations"]=nil
local ops=require("scripts.razi_helios_operations")
ops.observe({valid=true,index=2,
 space_location={name="nauvis"}})
check(not storage.razi_helios_holds,
 "Non-solar platforms should not allocate hold state")
ops.observe({valid=true,index=3,
 space_location={name="slp-outer"}})
check(storage.razi_helios_holds[3]~=nil,
 "Actual solar platform must begin a hold")
ops.observe({valid=true,index=3,
 space_location={name="nauvis"}})
check(storage.razi_helios_holds[3]==nil,
 "Leaving the solar orbit must release the hold")
local a=ops.grid(force)
check(a.powered==1 and scans==1,
 "First active-grid read must inspect genuine powered anchors")
for _=1,50 do
 local value=ops.status(force)
 check(value.grid.powered==1,"Cached grid must remain accurate")
end
check(scans==1,"50 GUI refreshes should not repeat world scans")
ops.grid(force,true)
check(scans==2,"Forced final validation must ignore cached power")
ops.anchor_changed({valid=true,name="razi-helios-grid-anchor",force=force})
ops.grid(force)
check(scans==3,"Anchor construction must invalidate the grid cache")
energy=0
check(ops.grid(force).powered==1,
 "Power state should remain cached for a bounded three seconds")
game.tick=281
check(ops.grid(force).powered==0 and scans==4,
 "Power loss must be visible when the three-second cache expires")
energy=1000
check(ops.grid(force,true).powered==1 and scans==5,
 "Final-delivery proof must see restored power immediately")
package.loaded["scripts.galactic_dyson"]=nil
local display=require("scripts.galactic_dyson")
local counts=display.component_counts(force)
check(counts["razi-helios-corona-shield"]==14,
 "Manufacturing must sum actual production across both surfaces")
for _=1,50 do
 check(display.component_counts(force)["razi-helios-corona-shield"]==14,
  "Production cache changed without an actual update")
end
check(stats_calls==2,
 "50 GUI redraws must not cause repeated production-stat queries")
produced=10
game.tick=881
counts=display.component_counts(force)
check(counts["razi-helios-corona-shield"]==20 and stats_calls==4,
 "Production totals must refresh after the ten-second TTL")
ops.forces_merged({source_index=2,destination_index=1})
check(not storage.razi_helios_grid_cache[1]
 and not storage.razi_helios_production_cache[1],
 "A force merge must discard stale force-scoped snapshots")
print("HELIOS performance: 50 GUI reads used 1 grid scan and 2 statistics calls")
