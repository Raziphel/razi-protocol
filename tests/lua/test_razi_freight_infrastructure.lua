-- Read-only A.2 endpoint and native platform snapshots.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local mod=require("scripts.razi_freight_infrastructure")
local prototypes_snapshot={
 ["orbital-cannon-launcher"]={type="assembling-machine"},
 ["orbital-catapult-buffer"]={type="container"},
 ["orbital-cannon-projectile"]={type="projectile"},
 ["orbital-cannon-remains"]={type="corpse"},
 ["another-launcher"]={type="assembling-machine"}
}
prototypes={entity=prototypes_snapshot}
local names=mod.launcher_names()
check(#names==2 and names[1]=="orbital-cannon-launcher"
  and names[2]=="orbital-catapult-buffer",
 "Prototype discovery must exclude projectiles, remains and other mods")
local calls={}
local function surface(world,n)
 return {valid=true,count_entities_filtered=function(filter)
   calls[world]=(calls[world] or 0)+1
   check(filter.force==force,"Must scope entity checks to the player's force")
   check(#filter.name==2,"Candidate names must be passed as exact match list")
   return n
 end}
end
local worlds={
 muria={surface=surface("muria",2)},
 rubia={surface=surface("rubia",0)},
 aquilo={surface=nil}
}
game={planets=worlds}
script={active_mods={["orbital-cannon"]="0.15.0",
 ["platform-logistics-overhaul"]="2.1.2"}}
local docks={
 muria={
  {valid=true,hidden=false,scheduled_for_deletion=0,
   hub={valid=true,type="space-platform-hub",providing_to_other_platforms=true},
   schedule={records={{station="other"}}}},
  {valid=true,hidden=false,scheduled_for_deletion=0,
   hub={valid=true,type="space-platform-hub",providing_to_other_platforms=false},
   schedule=nil},
  {valid=true,hidden=true,scheduled_for_deletion=0,
   hub={valid=true,type="space-platform-hub"}},
  {valid=true,hidden=false,scheduled_for_deletion=5,
   hub={valid=true,type="space-platform-hub"}}
 },
 rubia={
  {valid=true,hidden=false,scheduled_for_deletion=0,
   hub={valid=true,type="space-platform-hub",providing_to_other_platforms=true},
   schedule={records={{station="next"}}}}
 }
}
force={
 get_space_platforms=function(world) return docks[world] or {} end
}
local network={installed=true,enabled=true,entries={
 {source="muria",target="rubia",state="researched",
  source_researched=true,target_researched=true},
 {source="muria",target="aquilo",state="unresearched",
  source_researched=true,target_researched=false}
}}
local status=mod.snapshot(force,network)
check(status.checked==2 and status.worlds.aquilo==nil,
 "Never inspect an unresearched destination, even with spoiler previews")
check(status.worlds.muria.launcher_count==2
 and status.worlds.muria.launcher_state=="candidate"
 and status.worlds.rubia.launcher_count==0
 and status.worlds.rubia.launcher_state=="none",
 "Real existing and missing candidate counts should remain distinct")
check(status.worlds.muria.platforms==2
 and status.worlds.muria.providers==1
 and status.worlds.muria.unscheduled==1,
 "Only real visible docked platforms with hubs count; provider is native")
check(status.worlds.rubia.platforms==1
 and status.worlds.rubia.providers==1
 and status.worlds.rubia.unscheduled==0,
 "Destination sharing and schedule status should be recorded accurately")
check(calls.muria==1 and calls.rubia==1 and calls.aquilo==nil,
 "Each known destination must be queried just once on explicit render")
check(status.platform_logistics==true,
 "Optional companion install should be reported separately from native data")
worlds.rubia.surface=nil
local unknown=mod.snapshot(force,network)
check(unknown.worlds.rubia.launcher_count==nil
 and unknown.worlds.rubia.launcher_state=="unknown",
 "Uncreated planet surfaces are unknown, never zero installations")
network.entries[1].state="unresearched"
network.entries[1].target_researched=false
local none=mod.snapshot(force,network)
check(none.checked==0 and next(none.worlds)==nil,
 "No unresearched routes may trigger surface probes")
network.enabled=false
check(mod.snapshot(force,network).checked==0,
 "Disabled corridors must not scan any planets")
-- No claimed transport telemetry, machine creation, or inventory mutation.
print("A.2 source-world endpoint and 2.1 docked-platform checks passed")
