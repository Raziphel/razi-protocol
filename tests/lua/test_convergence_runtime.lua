---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local mods=require("prototypes.technology.convergence")
local m=require("scripts.razi_convergence")
rawset(_G,"storage",{})
rawset(_G,"prototypes",{item={
 ["ds-energy-loader-mk1"]={place_result={name="test-dyson-receiver"}}
},entity={["test-dyson-receiver"]={}},
space_location={
 ["solar-system-edge"]={localised_name="Solar System Edge"},
 ["nexus"]={localised_name="Nexus"},
 ["shattered-planet"]={localised_name="Shattered Planet"},
 ["oort-cloud"]={localised_name="Oort Cloud"},
 ["sol"]={localised_name="Sol"}
},space_connection={
 edge_nexus={from="solar-system-edge",to="nexus"},
 edge_shattered={from="solar-system-edge",to="shattered-planet"},
 nexus_oort={from="nexus",to="oort-cloud"},
 oort_sol={from="oort-cloud",to="sol"}
}})
local done=0
rawset(_G,"defines",{controllers={remote=9}})
rawset(_G,"game",{
 tick=42,finished=false,finished_but_continuing=false,
 forces={},surfaces={},
 set_win_ending_info=function(data) check(data.title~=nil,"victory title") end,
 set_game_state=function(data) check(data.player_won and data.can_continue,
   "real Factorio victory state missing") done=done+1 end,
 print=function() end
})
local function fixture(index)
 local force={index=index,name="Test Force "..index,
  receiver_count=0,transmissions={},technologies={
  ["razi-convergence-witness-network"]={researched=false},
  [mods.commission]={researched=true},
  [mods.authorization]={researched=true},
  [mods.ignition]={researched=false}
 }}
 function force.get_entity_count(name)
  if name=="test-dyson-receiver" then return force.receiver_count end
  if name=="radar" then
   return #(game.surfaces or {})
  end
  return 0
 end
 function force.print(message)
  force.transmissions[#force.transmissions+1]=message
 end
 game.forces[index]=force
 local inventory={valid=true,items={}}
 function inventory.get_item_count(name)
  return inventory.items[name] or 0
 end
 function inventory.remove(spec)
  local current=inventory.items[spec.name] or 0
  local removed=math.min(current,spec.count)
  inventory.items[spec.name]=current-removed
  return removed
 end
 local character={valid=true,surface={
  platform={valid=true,force=force,hub={valid=true},
   completed_trips=2,space_location={name="solar-system-edge"}},
  find_entities_filtered=function() return {} end}}
 local player={force=force,character=character,name="Engineer",
  valid=true,controller_type=1,
  get_main_inventory=function() return inventory end}
 return force,player,inventory
end
local function stock_supplies(inventory,rule)
 for _,part in ipairs(rule.supplies or {}) do
  inventory.items[part[1]]=part[2]
 end
end
local force,player,inventory=fixture(1)
-- An absent or incompatible receiver prototype must not create
-- an unfinishable endgame in a reduced modpack.
local source_registry=prototypes
rawset(_G,"prototypes",{item={},entity={}})
local allowed,unknown_count=m.dyson_readiness(force)
check(allowed and unknown_count==nil,
 "Missing source receiver should gracefully use research-only fallback")
rawset(_G,"prototypes",source_registry)
check(not m.completed(force,"victory"),"Fresh world prewon")
check(m.current(force)==1,"Start at first delivery")
check(m.blackbox(force)==0,"Do not reveal the Board's hidden order before real shipments")
inventory.items[m.stages[1].item]=3
local message,used=m.deliver(player,"stellar")
check(message=="convergence-delivered" and used==3,
 "Cargo must be removed and partially credited")
check(m.record(force).delivered.stellar==nil
 and m.record(force).materials.stellar[m.stages[1].item]==3
 and inventory.items[m.stages[1].item]==0,
 "Partial freight must credit only the items actually carried")
check(math.abs(m.assembly_fraction(force)-3/24/7/5)<.00001,
 "A real partial shipment must advance the visible array proportionally")
message,used=m.deliver(player,"industry")
check(message=="convergence-wrong-stage" and used==0,
 "Later stages cannot be donated early")
inventory.items[m.stages[1].item]=m.stages[1].count-3
stock_supplies(inventory,m.stages[1])
m.deliver(player,"stellar")
check(m.completed(force,"stellar"),"Stellar stage completes")
check(m.current(force)==2,"Industrial phase next")
inventory.items[m.stages[2].item]=m.stages[2].count
stock_supplies(inventory,m.stages[2])
m.deliver(player,"industry")
check(m.current(force)==3,"Deep phase next")
force.technologies[mods.authorization].researched=false
inventory.items[m.stages[3].item]=m.stages[3].count
stock_supplies(inventory,m.stages[3])
message=m.deliver(player,"deep-space")
check(message=="convergence-need-synchronization",
 "No victory before deep-space authorization")
force.technologies[mods.authorization].researched=true
player.character.surface.platform.space_location.name="nauvis"
message=m.deliver(player,"deep-space")
check(message=="convergence-need-platform",
 "Deliveries must happen in REAL deep space, not at home")
player.character.surface.platform.space_location.name="solar-system-edge"
player.controller_type=9
message=m.deliver(player,"deep-space")
check(message=="convergence-need-platform",
 "Remote View must never submit from the physical platform")
player.controller_type=1
m.deliver(player,"deep-space")
check(m.current(force)==4 and done==0,
 "Deep Space should lead to Pulsar Resonance, not an early win")
check(m.blackbox(force)==1,
 "Completed Deep-Space freight must reveal the signed BLACKOUT-SEVEN order")
inventory.items[m.stages[4].item]=m.stages[4].count
stock_supplies(inventory,m.stages[4])
message,used=m.deliver(player,"resonance")
check(message=="convergence-delivered" and used>0
 and m.current(force)==5 and done==0,
 "Pulsar Resonance should lead to final ignition")
check(m.blackbox(force)==2,
 "Completed resonance cargo must expose the executive reclamation trap")
inventory.items[m.stages[5].item]=m.stages[5].count
stock_supplies(inventory,m.stages[5])
message=m.deliver(player,"ignition")
check(message=="convergence-need-ignition" and done==0,
 "Final accord cannot skip Ignition research")
force.technologies[mods.ignition].researched=true
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-witness-research" and used==0,
 "Final accord needs the separately researched Independent Witness Accord")
force.technologies["razi-convergence-witness-network"].researched=true
local boss_defeats={}
rawset(_G,"remote",{
 interfaces={["nexus-bosses"]={get_state=true}},
 call=function(interface,method)
  check(interface=="nexus-bosses" and method=="get_state",
    "Razi must only read source boss victories")
  return {defeated={[force.name]=boss_defeats}}
 end
})
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-nexus-trials" and used==0,
 "Nexus Silence research or warp keys cannot substitute for nine boss victories")
local boss_bridge=require("scripts.razi_nexus_trials")
for _,boss in ipairs(boss_bridge.order) do boss_defeats[boss]=true end
check(boss_bridge.snapshot(force).count==9,
 "All nine authentic source boss defeat flags satisfy the victory requirement")
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-witnesses" and used==0,
 "Seven true, powered systems must physically countersign the Accord")
local worlds={
 {"nauvis","calidus"},{"vulcanus","solaris"},{"gleba","nyxaris"},
 {"fulgora","vibrant"},{"aquilo","vespera"},{"cubium","beetlejuice"},
 {"tenebris","umbra"}
}
for _,world in ipairs(worlds) do
 game.surfaces[#game.surfaces+1]={
  planet={name=world[1]},
  find_entities_filtered=function(spec)
   if spec.name=="radar" then
    return {{valid=true,energy=1500000}}
   end
   return {}
  end}
end
check(select(1,m.witness_status(force))==7,
 "Seven independent real planet systems must supply live anchors")
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-deep-expedition" and used==0,
 "The final Mandate cannot be submitted without in-person travel to every reachable deep-space stop")
local expedition=require("scripts.razi_deep_space_expedition")
local _,required,stops,chart_ready=expedition.status(force)
check(chart_ready and required==5,
 "Connected mandatory destinations include distant Oort and Sol routes")
for _,stop in ipairs(stops) do
 player.character.surface.platform.space_location.name=stop.id
 check(expedition.observe(player),
   "A real crew member physically arriving must register each required stop")
end
player.character.surface.platform.space_location.name="solar-system-edge"
check(select(1,expedition.status(force))==5,
 "All five physical expedition arrivals must persist")
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-receiver" and used==0
 and inventory.items[m.stages[5].item]==m.stages[5].count,
 "Missing native Dyson receivers cannot consume final cargo")
force.receiver_count=1
message,used=m.deliver(player,"ignition")
check(message=="convergence-transmission-started" and used>0
 and not m.completed(force,"victory") and done==0,
 "Final physical accord must begin a saved transmission, not instant victory")
local before=inventory.items[m.stages[5].item]
message=m.deliver(player,"ignition")
check(message=="convergence-wrong-stage" and done==0
 and inventory.items[m.stages[5].item]==before,
 "Double click during transmission cannot consume extra freight")
check(m.record(force).transmission.beat==1,"First beat must be recorded")
storage.razi_convergence_pending=nil
m.restore_pending()
check(storage.razi_convergence_pending[1],
 "A reload must rediscover the active transmission")
game.tick=1842
m.advance(game.tick)
check(m.record(force).transmission.beat==2 and done==0,
 "Dyson sequence should advance after thirty seconds")
game.tick=3642
m.advance(game.tick)
game.tick=5442
m.advance(game.tick)
check(m.record(force).transmission.beat==4 and #force.transmissions==4
 and done==0,"All four announcements must precede victory")
game.tick=7242
m.advance(game.tick)
check(m.completed(force,"victory") and done==1
 and not storage.razi_convergence_pending[1]
 and m.record(force).completed_site=="solar-system-edge",
 "Native victory must fire once and archive the original transmission site")
check(m.blackbox(force)==3,"The final refusal is revealed only after real victory")
m.advance(game.tick+60)
check(done==1,"Completed transmissions must not replay the win")
local new_force,new_player,other=fixture(2)
check(not m.completed(new_force,"victory"),
 "Different forces must not inherit victory")
other.items[m.stages[1].item]=m.stages[1].count
stock_supplies(other,m.stages[1])
m.deliver(new_player,"stellar")
m.forces_merged({source_index=2,destination_index=1})
check(not storage.razi_convergence[2] and
 m.completed(force,"stellar"),"Merging forces retains real progress")
local legacy_force=fixture(3)
storage.razi_convergence[3]={
 delivered={stellar=8,industry=10,["deep-space"]=6},victory=true,
 victory_tick=10,completed_by="Legacy Engineer"
}
check(m.current(legacy_force)==#m.stages+1
 and m.completed(legacy_force,"resonance")
 and m.completed(legacy_force,"ignition"),
 "2.1.57 winner must remain fully credited after adding two phases")
local progress,total,won=m.progress(legacy_force)
check(won and progress==5 and total==5 and done==1
 and m.assembly_fraction(legacy_force)==1,
 "Loading an old victory must preserve a fully assembled array")
-- Two simultaneous force transmissions merged during the finale must
-- retain the earlier accepted accord, archive its origin, and win once.
local donor=fixture(5) -- luacheck: ignore 211
local recipient=fixture(6)
storage.razi_convergence[5]={
 delivered={stellar=24,industry=30,["deep-space"]=18,
  resonance=12,ignition=1},victory=false,
 transmission={started=1000,beat=1,
  operator="Earlier Engineer",site="nexus"}
}
storage.razi_convergence[6]={
 delivered={stellar=24,industry=30,["deep-space"]=18,
  resonance=12,ignition=1},victory=false,
 transmission={started=1050,beat=1,
  operator="Later Engineer",site="shattered-planet"}
}
storage.razi_convergence_pending[5]=true
storage.razi_convergence_pending[6]=true
m.forces_merged({source_index=5,destination_index=6})
check(storage.razi_convergence[5]==nil
 and storage.razi_convergence[6].transmission.started==1000
 and storage.razi_convergence_pending[5]==nil
 and storage.razi_convergence_pending[6],
 "Merged forces must preserve exactly one earliest transmission")
game.tick=8200
m.advance(game.tick)
check(m.completed(recipient,"victory") and done==2
 and m.record(recipient).completed_by=="Earlier Engineer"
 and m.record(recipient).completed_site=="nexus"
 and not storage.razi_convergence_pending[6],
 "Merged force must win once with the actual earlier contributor")
m.advance(game.tick+60)
check(done==2,"Merged transmission must not replay another victory")
print("Convergence: partial freight, receiver gates, restored signals, force merges and legacy wins passed")
