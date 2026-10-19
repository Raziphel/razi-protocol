package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local mods=require("prototypes.technology.convergence")
local m=require("scripts.razi_convergence")
rawset(_G,"storage",{})
rawset(_G,"prototypes",{item={
 ["ds-energy-loader-mk1"]={place_result={name="test-dyson-receiver"}}
},entity={["test-dyson-receiver"]={}}})
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
  receiver_count=0,core_powered=false,transmissions={},technologies={
  ["razi-convergence-witness-network"]={researched=false},
  [mods.commission]={researched=true},
  [mods.authorization]={researched=true},
  [mods.ignition]={researched=false}
 }}
 function force.get_entity_count(name)
  if name=="test-dyson-receiver" then return force.receiver_count end
  if name=="razi-convergence-witness-anchor" then
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
  platform={valid=true,force=force,
   space_location={name="solar-system-edge"}},
  find_entities_filtered=function(filter)
   if filter.name=="razi-convergence-array-core" and force.core_powered then
    return {{valid=true,energy=100000000}}
   end
   return {}
  end}}
 local player={force=force,character=character,name="Engineer",
  get_main_inventory=function() return inventory end}
 return force,player,inventory
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
check(m.record(force).delivered.stellar==3
 and inventory.items[m.stages[1].item]==0,
 "No free credit for unseen items")
check(math.abs(m.assembly_fraction(force)-3/8/5)<.00001,
 "A real partial shipment must advance the visible array proportionally")
message,used=m.deliver(player,"industry")
check(message=="convergence-wrong-stage" and used==0,
 "Later stages cannot be donated early")
inventory.items[m.stages[1].item]=m.stages[1].count-3
m.deliver(player,"stellar")
check(m.completed(force,"stellar"),"Stellar stage completes")
check(m.current(force)==2,"Industrial phase next")
inventory.items[m.stages[2].item]=m.stages[2].count
m.deliver(player,"industry")
check(m.current(force)==3,"Deep phase next")
force.technologies[mods.authorization].researched=false
inventory.items[m.stages[3].item]=m.stages[3].count
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
message,used=m.deliver(player,"resonance")
check(message=="convergence-delivered" and used==m.stages[4].count
 and m.current(force)==5 and done==0,
 "Pulsar Resonance should lead to final ignition")
check(m.blackbox(force)==2,
 "Completed resonance cargo must expose the executive reclamation trap")
inventory.items[m.stages[5].item]=1
message=m.deliver(player,"ignition")
check(message=="convergence-need-ignition" and done==0,
 "Final accord cannot skip Ignition research")
force.technologies[mods.ignition].researched=true
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-witness-research" and used==0,
 "Final accord needs the separately researched Independent Witness Accord")
force.technologies["razi-convergence-witness-network"].researched=true
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
   if spec.name=="razi-convergence-witness-anchor" then
    return {{valid=true,energy=1500000}}
   end
   return {}
  end}
end
check(select(1,m.witness_status(force))==7,
 "Seven independent real planet systems must supply live anchors")
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-receiver" and used==0
 and inventory.items[m.stages[5].item]==1,
 "Missing native Dyson receivers cannot consume final cargo")
force.receiver_count=1
message,used=m.deliver(player,"ignition")
check(message=="convergence-need-core" and used==0,
 "The final physical Accord must have a powered core on this platform")
force.core_powered=true
message,used=m.deliver(player,"ignition")
check(message=="convergence-transmission-started" and used==1
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
local migration_force=fixture(4)
migration_force.technologies[mods.authorization].researched=true
migration_force.recipes={}
for _,stage in ipairs(m.stages) do
 migration_force.recipes[stage.item]={enabled=false}
end
m.repair_recipe_unlocks(migration_force)
check(migration_force.recipes[m.stages[3].item].enabled
 and migration_force.recipes[m.stages[4].item].enabled
 and not migration_force.recipes[m.stages[5].item].enabled,
 "Recipe migration must respect actual research, including final Ignition")
for _,part in ipairs(mods.assemblies) do
 migration_force.recipes[part.item]={enabled=false}
end
migration_force.technologies[mods.ignition].researched=true
m.repair_recipe_unlocks(migration_force)
for _,part in ipairs(mods.assemblies) do
 check(migration_force.recipes[part.item].enabled,
  "Existing researched save must unlock all three new assembly recipes")
end
migration_force.recipes["razi-convergence-witness-anchor"]={enabled=false}
migration_force.recipes["razi-convergence-array-core"]={enabled=false}
migration_force.technologies["razi-convergence-witness-network"].researched=true
m.repair_recipe_unlocks(migration_force)
check(migration_force.recipes["razi-convergence-witness-anchor"].enabled
 and migration_force.recipes["razi-convergence-array-core"].enabled,
 "Existing researched saves must restore new witness and core recipes")
-- Two simultaneous force transmissions merged during the finale must
-- retain the earlier accepted accord, archive its origin, and win once.
local donor=fixture(5)
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
