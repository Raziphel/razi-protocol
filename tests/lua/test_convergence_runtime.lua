package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local mods=require("prototypes.technology.convergence")
local m=require("scripts.razi_convergence")
rawset(_G,"storage",{})
local done=0
rawset(_G,"defines",{controllers={remote=9}})
rawset(_G,"game",{
 tick=42,finished=false,finished_but_continuing=false,
 set_win_ending_info=function(data) check(data.title~=nil,"victory title") end,
 set_game_state=function(data) check(data.player_won and data.can_continue,
   "real Factorio victory state missing") done=done+1 end,
 print=function() end
})
local function fixture(index)
 local force={index=index,name="Test Force "..index,technologies={
  [mods.commission]={researched=true},
  [mods.authorization]={researched=true}
 }}
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
   space_location={name="solar-system-edge"}}}}
 local player={force=force,character=character,name="Engineer",
  get_main_inventory=function() return inventory end}
 return force,player,inventory
end
local force,player,inventory=fixture(1)
check(not m.completed(force,"victory"),"Fresh world prewon")
check(m.current(force)==1,"Start at first delivery")
inventory.items[m.stages[1].item]=3
local message,used=m.deliver(player,"stellar")
check(message=="convergence-delivered" and used==3,
 "Cargo must be removed and partially credited")
check(m.record(force).delivered.stellar==3
 and inventory.items[m.stages[1].item]==0,
 "No free credit for unseen items")
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
check(m.completed(force,"victory") and done==1,
 "Last real shipment should win exactly once")
local before=inventory.items[m.stages[3].item]
message=m.deliver(player,"deep-space")
check(message=="convergence-wrong-stage" and done==1
 and inventory.items[m.stages[3].item]==before,
 "Double click cannot consume extra items or repeat victory")
local new_force,new_player,other=fixture(2)
check(not m.completed(new_force,"victory"),
 "Different forces must not inherit victory")
other.items[m.stages[1].item]=m.stages[1].count
m.deliver(new_player,"stellar")
m.forces_merged({source_index=2,destination_index=1})
check(not storage.razi_convergence[2] and
 m.completed(force,"stellar"),"Merging forces retains real progress")
print("Convergence: inventory, location, force isolation, victory and merge passed")
