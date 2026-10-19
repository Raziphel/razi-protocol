-- A.3 delivery receipts: engine-confirmed event, not shipment attribution.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
storage={}
local receipts=require("scripts.razi_freight_receipts")
local a={index=1,valid=true}
local b={index=2,valid=true}
local function event(force,world,tick)
 return {tick=tick,cargo_pod={valid=true,force=force,
   surface={planet=world and {name=world}}}}
end
local net={installed=true,enabled=true,entries={
 {source="muria",target="rubia",state="researched",
 source_researched=true,target_researched=true},
 {source="rubia",target="aquilo",state="unresearched",
 source_researched=true,target_researched=false}
}}
check(not receipts.on_delivered({tick=1}),"Missing pod must not count")
check(not receipts.on_delivered(event(a,nil,2)),
 "Space platforms and non-planet surfaces must not count")
check(not receipts.on_delivered(event(a,"nauvis",3)),
 "Worlds outside explicit Razi regional endpoints must not count")
check(not receipts.on_delivered(event({index=3,valid=false},"muria",4)),
 "Invalid forces must not create records")
check(storage.razi_pod_receipts==nil,
 "Irrelevant events must not even allocate ledger storage")
check(receipts.on_delivered(event(a,"muria",10)),"Valid delivery must count")
check(receipts.on_delivered(event(a,"aquilo",11)),
 "Unlocked state is not needed to record a real future destination")
check(receipts.on_delivered(event(a,"rubia",12)),"Arrival at destination counts")
check(receipts.on_delivered(event(b,"rubia",13)),
 "Independent force must record its own deliveries")
local r=receipts.snapshot(a,net)
check(r.total==2 and r.worlds.muria==1 and r.worlds.rubia==1
 and r.worlds.aquilo==nil,"Future worlds must never leak through GUI")
check(#r.recent==2 and r.recent[1].world=="rubia",
 "Only discovered destinations belong in recent history")
local rb=receipts.snapshot(b,net)
check(rb.total==1,"Force ledgers must not contaminate each other")
net.entries[1].state="unresearched"
net.entries[1].target_researched=false
check(receipts.snapshot(a,net).total==0,
 "Spoiler-off previews still must not reveal unresearched activity")
net.entries[1].state="researched"
net.entries[1].target_researched=true
net.entries[2].state="researched"
net.entries[2].target_researched=true
check(receipts.snapshot(a,net).total==3,
 "Previously recorded destinations become visible after research")
for tick=20,53 do
 check(receipts.on_delivered(event(a,"rubia",tick)),
  "The bounded delivery ring must still count repeated engine events")
end
local all=storage.razi_pod_receipts[a.index]
check(all.worlds.rubia==35 and #all.recent==24,
 "World aggregate must persist while history stays bounded to 24")
check(all.recent[1].tick==53 and all.recent[#all.recent].tick==30,
 "Recent ring must retain newest actual delivery ticks")
receipts.forces_merged({source_index=b.index,destination=a})
check(storage.razi_pod_receipts[b.index]==nil,
 "Merged source force storage must be removed")
check(storage.razi_pod_receipts[a.index].worlds.rubia==36,
 "Native force mergers must preserve delivery aggregates")
check(#storage.razi_pod_receipts[a.index].recent==24,
 "Merged recent histories must still obey their size cap")
net.enabled=false
check(receipts.snapshot(a,net).total==0,
 "A disabled Razi corridor may not leak historic activity")
print("Razi A.3 engine-confirmed pod event evidence and force merge passed")
