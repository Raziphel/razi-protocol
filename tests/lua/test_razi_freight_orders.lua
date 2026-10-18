-- Regional freight board keeps honest, bounded manual packing plans.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
storage={}
settings={startup={
 ["razi-orbital-catapult-local-links"]={value=true},
 ["razi-orbital-catapult-regional-links"]={value=true}},
 global={["razi-hide-spoilers"]={value=true}}}
script={active_mods={["orbital-cannon"]="0.15.0"}}
local worlds={"muria","rubia","aquilo","maraxsis",
  "vulcanus","castra","gleba","moshine"}
local planet,tech={},{}
for _,name in ipairs(worlds) do
 planet[name]={}
 tech["planet-discovery-"..name]={researched=true}
end
prototypes={planet=planet,item={
 ["iron-plate"]={name="iron-plate",stack_size=100},
 ["low-density-structure"]={name="low-density-structure",stack_size=50}
}}
local orders=require("scripts.razi_freight_orders")
local a={index=2,force={technologies=tech}}
local b={index=3,force=a.force}
local route="razi-muria-rubia-catapult"
check(orders.route(a.force,route),"Researched valid outbound link required")
check(not orders.route(a.force,"razi-cheat-catapult"),
 "Forged routes must be rejected")
check(orders.select(a,route),"Should accept discovered and enabled link")
check(orders.item_changed(a,"iron-plate"),"Recognized item should be selectable")
check(orders.count_changed(a,"201"),"Positive numeric amount should parse")
check(orders.stacks("iron-plate",201)==3,
 "True inventory stack size must calculate packing effort")
check(not orders.count_changed(a,"-3")
 and not orders.count_changed(a,"1.5")
 and not orders.count_changed(a,"0")
 and not orders.count_changed(a,"1000001"),
 "Negative, fractional, zero and excessive item quantities are invalid")
check(not orders.add(a),
 "Malformed typed quantity must not reuse the previous valid amount")
check(orders.count_changed(a,"201"),"Fixing the quantity must recover draft")
check(orders.add(a),"Discovered route should accept a valid packing order")
local listed=orders.orders(a)
check(#listed==1 and listed[1].count==201 and listed[1].stacks==3,
 "Staged order must preserve exact real item count and stack estimate")
check(#orders.orders(b)==0,"Packing queue must be per player")
check(orders.update(a,listed[1].id,"packed"),"Packing checkbox must toggle")
check(orders.orders(a)[1].packed,"Manual packed state was not saved")
check(orders.update(a,listed[1].id,"packed")
 and not orders.orders(a)[1].packed,
 "Unpacking must be reversible")
check(not orders.update(a,999,"packed")
 and not orders.update(a,listed[1].id,"launch"),
 "Unknown actions must never pretend to launch source machinery")
tech["planet-discovery-rubia"].researched=false
check(not orders.add(a),"Must reject an order to an undiscovered planet")
check(#orders.orders(a)==0,
 "Do not leak inaccessible routes from saved packing lists")
tech["planet-discovery-rubia"].researched=true
check(#orders.orders(a)==1,
 "Existing orders must be visible again after research is restored")
settings.startup["razi-orbital-catapult-local-links"].value=false
check(not orders.route(a.force,route),
 "Original Vespera option OFF must disable that group's freight plans")
settings.startup["razi-orbital-catapult-local-links"].value=true
check(orders.update(a,listed[1].id,"remove"),
 "Player must be able to delete an unused order")
check(#orders.orders(a)==0,"Removed orders must disappear")
check(orders.saved_count(a)==0,"Removed plans should free queue capacity")
check(orders.select(a,route),"Re-select known route")
check(orders.add(a),"Re-create an order")
check(orders.saved_count(a)==1,"Expected one saved packing plan")
orders.clear(a)
check(orders.saved_count(a)==0,"Clearing all restores capacity")
orders.cleanup(a.index)
check(storage.razi_freight_orders[a.index]==nil,
 "Removed players must not leave serialized packing plans")
check(orders.positive_count("100") == 100
  and orders.positive_count("oops")==nil
  and orders.positive_count("2.5")==nil,
  "Count parser must enforce finite integral positive items")
print("Razi manual freight board, actual stacks and permission checks passed")
