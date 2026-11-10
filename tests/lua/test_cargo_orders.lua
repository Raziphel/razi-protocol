---@diagnostic disable: need-check-nil
-- The Freight Desk stores manual plans and reads one supplied corridor snapshot.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message)
  if not ok then error(message,2) end
end

local snapshot_calls=0
package.loaded["scripts.compatibility.orbital-cannon.catapult_network"]={
  snapshot=function()
    snapshot_calls=snapshot_calls+1
    error("orders must use the supplied snapshot")
  end,
  researched=function(force,world)
    return force.technologies[world]==true
  end
}
prototypes={item={
  ["iron-plate"]={stack_size=100},
  ["copper-plate"]={stack_size=50}
}}
storage={}
local orders=require("scripts.cargo.orders")
local force={technologies={nauvis=true,vulcanus=true,gleba=true}}
local inventory={}
local player={
  index=1,force=force,
  physical_surface={planet={name="nauvis"}},
  get_item_count=function(name) return inventory[name] or 0 end
}
local open={installed=true,enabled=true,entries={
  {id="nauvis-vulcanus",source="nauvis",target="vulcanus",state="researched"},
  {id="nauvis-gleba",source="nauvis",target="gleba",state="researched"}
}}
local one_route={installed=true,enabled=true,entries={open.entries[1]}}
local closed={installed=true,enabled=true,entries={
  {id="nauvis-vulcanus",source="nauvis",target="vulcanus",state="unresearched"}
}}

local directions=orders.routes(open,force)
check(#directions==4,"each open corridor has two directions")
check(directions[1].id=="nauvis>vulcanus"
  and directions[2].id=="vulcanus>nauvis","direction IDs retain source order")
check(snapshot_calls==0,"route listing does not build a network snapshot")

local saved=orders.store(player.index)
check(saved.draft.count==100 and #saved.orders==0,"first access creates a draft and list")
check(orders.select(player,open,"nauvis>vulcanus"),"select an open direction")
check(not orders.select(player,closed,"nauvis>vulcanus"),"reject a closed corridor")
check(orders.item_changed(player,"iron-plate"),"select a prototype item")
check(not orders.item_changed(player,"missing-item"),"reject a non-item prototype")
check(saved.draft.item=="iron-plate","a rejected item leaves the prior selection intact")

for _,invalid in ipairs({0,-1,1.5,"abc",1000001}) do
  check(not orders.count_changed(player,invalid),"reject invalid quantity "..tostring(invalid))
  check(saved.draft.count==nil,"invalid quantity clears the draft")
  check(orders.count_changed(player,100),"restore a valid quantity")
end

local added,reason=orders.add(player,closed)
check(not added and reason=="route" and #saved.orders==0,
  "add rejects a corridor that is no longer open")

local function add_one(route,item,count)
  check(orders.select(player,open,route),"select route "..route)
  check(orders.item_changed(player,item),"select item "..item)
  check(orders.count_changed(player,count),"select count "..tostring(count))
  return orders.add(player,open)
end

check(add_one("nauvis>vulcanus","iron-plate",100),"add first row")
check(add_one("nauvis>vulcanus","iron-plate",100),"add second row")
check(add_one("nauvis>gleba","copper-plate",75),"add third row")
local first_id=saved.orders[1].id
local second_id=saved.orders[2].id
local third_id=saved.orders[3].id
check(not orders.update(player,first_id,"up"),"the first row cannot move up")
check(not orders.update(player,third_id,"down"),"the last row cannot move down")
check(orders.update(player,first_id,"packed") and saved.orders[1].packed,
  "packed is a manual toggle")
check(orders.update(player,second_id,"up") and saved.orders[1].id==second_id,
  "a row can move up")
check(orders.update(player,second_id,"down") and saved.orders[2].id==second_id,
  "a row can move down")
check(orders.stacks("iron-plate",101)==2,"stack count uses the item prototype")

orders.clear(player)
for index=1,20 do
  local ok=add_one("nauvis>vulcanus","iron-plate",index)
  check(ok,"row "..index.." fits the list")
end
check(orders.saved_count(player)==20,"the list has exactly twenty rows")
orders.count_changed(player,321)
local before={route=saved.draft.route,item=saved.draft.item,count=saved.draft.count}
added,reason=orders.add(player,open)
check(not added and reason=="full","the 21st row is rejected")
check(orders.saved_count(player)==20 and saved.draft.route==before.route
  and saved.draft.item==before.item and saved.draft.count==before.count,
  "a full list does not change the draft")

orders.clear(player)
check(add_one("nauvis>vulcanus","iron-plate",100),"add readiness row one")
check(add_one("nauvis>vulcanus","iron-plate",100),"add readiness row two")
inventory["iron-plate"]=150
local listed=orders.orders(player,open)
local readiness=orders.readiness(player,listed)
check(listed[1].load_state=="ready" and listed[2].load_state=="short"
  and listed[2].shortfall==50,"one stock is divided between rows in order")
check(readiness.ready==1 and readiness.short==1,"readiness totals match the rows")
player.physical_surface={planet={name="vulcanus"}}
orders.readiness(player,listed)
check(listed[1].load_state=="remote" and listed[2].load_state=="remote",
  "rows are not ready on a different planet")
player.physical_surface={planet={name="nauvis"}}

orders.clear(player)
check(add_one("nauvis>vulcanus","iron-plate",10),"add visible row")
check(add_one("nauvis>gleba","copper-plate",20),"add second corridor row")
local hidden=orders.unavailable(player,one_route)
check(#hidden==1 and hidden[1]==saved.orders[2].id
  and type(hidden[1])=="number","unavailable rows expose only their IDs")
check(#orders.orders(player,one_route)==1,"unavailable details are not listed")
check(orders.drop_unavailable(player,one_route)==1
  and #saved.orders==1 and saved.orders[1].route=="nauvis>vulcanus",
  "removing unavailable rows keeps open plans")

orders.store(2)
orders.cleanup(player.index)
check(storage.razi_cargo_orders[1]==nil and storage.razi_cargo_orders[2]~=nil,
  "cleanup removes only the selected player's list")
check(snapshot_calls==0,"orders never build their own catapult snapshot")

print("test_cargo_orders: ok")
