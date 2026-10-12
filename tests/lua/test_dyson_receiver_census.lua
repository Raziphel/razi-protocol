-- Stated physical data must remain explicitly unknown without a
-- documented source-mod satellite and energy telemetry API.
local runtime=require("scripts.galactic_dyson_runtime")
local function ok(v,message) if not v then error(message,2) end end
local items={
 ["ds-energy-loader-mk1"]={place_result={name="source-energy-relay"}},
 ["ds-energy-loader-mk2"]={place_result={name="source-energy-relay-2"}},
 ["ds-energy-loader-mk3"]={place_result={name="source-energy-relay-3"}}
}
local registry={item=items,entity={
 ["source-energy-relay"]={},
 ["source-energy-relay-2"]={},
 ["source-energy-relay-3"]={}
}}
local names=runtime.resolve_receiver_names(registry)
ok(#names==3 and names[1]=="source-energy-relay",
  "Receiver identity should use source item place_result")
local queries=0
local force={index=8,name="player",
 get_entity_count=function(name)
   if name=="source-energy-relay" then return 2 end
   if name=="source-energy-relay-2" then return 1 end
   return 0
 end}
local surfaces={
 nauvis={
   valid=true,name="nauvis",
   count_entities_filtered=function(args)
     queries=queries+1
     ok(args.force==force and #args.name==3,"Receiver filter lost force")
     return 2
   end
 },
 vulcanus={
   valid=true,name="vulcanus",
   count_entities_filtered=function(args)
     queries=queries+1
     return 1
   end
 },
 empty={
   valid=true,name="empty",
   count_entities_filtered=function(args)
     queries=queries+1
     return 0
   end
 }
}
local sample=runtime.inspect(force,surfaces,registry)
ok(sample.receivers==3 and #sample.sites==2 and queries==3,
  "Real placed receivers not counted by world")
ok(sample.satellite_count==nil and sample.allocated_mw==nil,
  "Private SLP counts must never be guessed")
rawset(_G,"storage",{})
rawset(_G,"game",{tick=1000,surfaces=surfaces})
rawset(_G,"prototypes",registry)
queries=0
local first=runtime.snapshot(force)
ok(queries==3 and first.receivers==3,"First UI scan missing")
local second=runtime.snapshot(force)
ok(queries==3 and second==first,"Cache did not prevent duplicate scans")
game.tick=1600
runtime.snapshot(force)
ok(queries==6,"Cache did not refresh at ten seconds")
runtime.invalidate(force)
runtime.snapshot(force)
ok(queries==9,"Explicit Stellar Works refresh failed")
local unsupported=runtime.inspect(force,surfaces,{item={},entity={}})
ok(not unsupported.physical_available and unsupported.receivers==nil,
 "No source receiver prototypes must mean unavailable, not zero")
print("Dyson receiver provenance and cached read-only census passed")
