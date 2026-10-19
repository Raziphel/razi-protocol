-- A.8 same-entity native pod evidence with strict force and spoiler rules.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
storage={}
local a={index=7,valid=true}
local b={index=8,valid=true}
local worlds={muria=true,rubia=true,aquilo=true}
local function mk(force,id,world,tick)
  return {tick=tick,cargo_pod={valid=true,force=force,
    unit_number=id,surface={planet=world and {name=world} or nil}}}
end
local P=require("scripts.razi_native_pod_trips")
local legs={{from="muria",to="rubia",mode="catapult"},
 {from="rubia",to="aquilo",mode="platform"}}
game={planets={muria={},rubia={},aquilo={}}}
prototypes={space_location={muria={},rubia={},aquilo={}}}
local force={index=7,is_space_location_unlocked=function(name)
 return worlds[name]==true end}
check(not P.departed(mk(a,nil,"muria",1)),
 "Pods with no unique entity ID cannot establish provenance")
check(storage.razi_native_pod_trips==nil,
 "Anonymous pods must not allocate evidence state")
check(not P.delivered(mk(a,123,"rubia",1)),
 "Delivery without observed departure must remain unattributed")
check(P.departed(mk(a,123,"muria",4)),
 "Real pod identity and planet departure may be recorded")
check(not P.departed(mk(a,123,"aquilo",5)),
 "An already tracked pod must never change its origin")
check(not P.delivered(mk(b,123,"rubia",9)),
 "Foreign force delivery must not match first force's pod")
check(P.delivered(mk(a,123,"rubia",10)),
 "Same pod and force at a new real destination correlates safely")
check(not P.delivered(mk(a,123,"rubia",10)),
 "Duplicate delivery event cannot count again")
local report=P.for_legs(force,legs)
check(report.total==1 and report.counts[1]==1
 and report.counts[2]==nil
 and report.recent[1].from=="muria",
 "Only compatible real source/destination pod evidence appears")
worlds.rubia=false
check(P.for_legs(force,legs).total==0,
 "Discovery rollback conceals historically observed endpoints")
worlds.rubia=true
check(P.for_legs(force,legs).total==1,
 "Research restoration reveals genuine prior evidence")
check(P.departed(mk(a,124,"muria",12)),
 "Can record an unrelated source event")
check(not P.delivered(mk(a,124,"muria",13)),
 "A pod landing on its source is not an interplanetary delivery")
check(P.departed(mk(a,125,"muria",18)),
 "Can record a new actual pod")
check(not P.delivered(mk(a,125,nil,21)),
 "Non-planet destination never proves an interplanetary trip")
check(P.departed(mk(a,126,"muria",50)),
 "Pending evidence may start while source is valid")
check(not P.delivered(mk(a,126,"rubia",108100)),
 "Expired evidence cannot be stitched together after 30 minutes")
for i=1,130 do
 check(P.departed(mk(a,1000+i,"muria",108110+i)),
   "Bulk in-flight pods should be accepted safely")
end
local rec=storage.razi_native_pod_trips[a.index]
local count=0
for _ in pairs(rec.pending) do count=count+1 end
check(count<=96,"Pending storage is bounded even after a busy launch")
check(not rec.pending[1001],"Oldest pending evidence must be pruned")
for i=1,32 do
 P.departed(mk(a,2000+i,"muria",109000+i))
 P.delivered(mk(a,2000+i,"rubia",109100+i))
end
check(#rec.recent==24,"Verified history remains bounded to 24 events")
P.departed(mk(a,9001,"muria",110000))
P.departed(mk(b,9002,"muria",110000))
P.delivered(mk(b,9002,"rubia",110010))
P.forces_merged({source_index=b.index,destination=a})
check(storage.razi_native_pod_trips[b.index]==nil,
 "Merged force's source observations are retired")
check(storage.razi_native_pod_trips[a.index].pending[9001]~=nil,
 "Destination force's own pending state stays intact")
check(#storage.razi_native_pod_trips[a.index].recent==24,
 "Merge cannot exceed the bounded history")
check(P.for_legs({index=9,is_space_location_unlocked=force.is_space_location_unlocked},legs).total==0,
 "Other force cannot view this force's evidence")
print("Razi A.8 native pod source/destination correlation passed")
