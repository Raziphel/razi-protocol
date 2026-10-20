-- Real expedition cargo and powered network commissioning fixtures.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
local force={index=1,technologies={
 ["razi-helios-corona-engineering"]={researched=true},
 ["razi-helios-grid-commission"]={researched=true}}}
local outer="fixture-dyson-outer"
local inner="fixture-dyson-inner"
rawset(_G,"prototypes",{technology={
 ["planet-discovery-sunorbit"]={effects={{
   type="unlock-space-location",space_location=outer}}},
 ["slp-solar-system-sun2"]={effects={{
   type="unlock-space-location",space_location=inner}}}}})
rawset(_G,"settings",{startup={
 ["razi-helios-commissioning"]={value="expedition"}}})
rawset(_G,"defines",{controllers={remote="remote"}})
rawset(_G,"storage",{})
local inventory={
 ["razi-helios-corona-shield"]=8,
 ["razi-helios-orbital-lattice"]=12}
local pack={
 get_item_count=function(id) return inventory[id] or 0 end,
 remove=function(part)
  local present=inventory[part.name] or 0
  local deducted=math.min(part.count,present)
  inventory[part.name]=present-deducted
  return deducted
 end,
 valid=true}
local platform={valid=true,index=7,force=force,
 space_location={name=outer},space_connection=nil}
local player={valid=true,force=force,controller_type="character",
 character={valid=true,surface={platform=platform}},
 get_main_inventory=function() return pack end}
local planet_a={valid=true,planet={name="vulcanus"},
 find_entities_filtered=function() return {{valid=true,energy=9000}} end}
local planet_b={valid=true,planet={name="aquilo"},
 find_entities_filtered=function() return {{valid=true,energy=18000}} end}
local space={valid=true,platform=platform,
 find_entities_filtered=function() return {{valid=true,energy=90000}} end}
force.get_entity_count=function() return 3 end
rawset(_G,"game",{tick=100,surfaces={
 ["vulcanus"]=planet_a,["aquilo"]=planet_b,["platform"]=space}})
package.loaded["scripts.razi_helios_operations"]=nil
local helios=require("scripts.razi_helios_operations")
local code=select(1,helios.deliver(player,"outer"))
check(code=="helios-need-orbit" or code=="helios-need-hold",
 "Orbital cargo must require station keeping")
check(inventory["razi-helios-corona-shield"]==8,
 "Cargo was consumed before dwell time")
game.tick=3700
local result,accepted=helios.deliver(player,"outer")
check(result=="helios-delivered" and accepted==8,
 "Outer shield delivery did not consume actual player cargo")
check(inventory["razi-helios-corona-shield"]==0,
 "Outer shield delivery removed the wrong amount")
check(helios.record(force).outer==8,
 "Outer commission did not persist for its force")
local status=helios.status(force)
check(status.grid.installed==2 and status.grid.powered==2
  and status.worlds==2,
  "Powered anchors must be on distinct actual planet surfaces")
check(not status.complete,"Grid without inner lattice is not complete")
platform.space_location={name=inner}
helios.observe(platform)
game.tick=10900
result,accepted=helios.deliver(player,"inner")
check(result=="helios-delivered" and accepted==12,
 "Inner lattice delivery ignored real cargo or orbital hold")
check(helios.ready(force),"All physically witnessed milestones should complete HELIOS")
check(inventory["razi-helios-orbital-lattice"]==0,
 "Inner lattice was not consumed exactly once")
check(select(1,helios.deliver(player,"inner"))=="helios-complete",
 "Duplicate commissioning should never consume additional items")
player.controller_type="remote"
check(select(1,helios.deliver(player,"outer"))=="helios-complete",
 "Completion lookup must not consume cargo in Remote View")
player.controller_type="character"
settings.startup["razi-helios-commissioning"].value="monumental"
check(not helios.ready(force),
 "Monumental requirements should not be bypassed by expedition progress")
settings.startup["razi-helios-commissioning"].value="off"
check(helios.ready(force),
 "Disabled commissioning must not gate a campaign")
print("HELIOS physical delivery, dwell, power grid and save state fixtures passed")
