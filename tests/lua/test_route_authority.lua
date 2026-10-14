-- Late-stage route ownership fixtures. No Factorio process needed.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message)
  if not value then error(message,2) end
end
local function key(a,b)
  if a>b then a,b=b,a end
  return a.."|"..b
end
local members={
  nauvis="calidus",muluna="calidus",["sye-calidus"]="calidus",
  ["sye-solaris"]="solaris",vulcanus="solaris",castra="solaris",
  ["sye-vespera"]="vespera",fulgora="vibrant",aquilo="vespera",
  ["asteroid-belt-inner-edge"]="mid-outer-belt",
  ["asteroid-belt-outer-edge"]="mid-outer-belt",
  ["crucible-orbit"]="umbra",crucible="umbra"
}
local approved={}
for _,two in ipairs({
  {"nauvis","sye-calidus"},{"sye-calidus","sye-solaris"},
  {"sye-solaris","vulcanus"},{"vulcanus","castra"}
}) do approved[key(two[1],two[2])]=true end
package.loaded["prototypes.system.route_reconcile"]={
  membership=members,pair_key=key,allowed_pairs=approved,
  specifications={
    {"nauvis","sye-calidus",25000,"starter"},
    {"sye-calidus","sye-solaris",60000,"first_crossing"},
    {"sye-solaris","vulcanus",18000,"industrial"},
    {"vulcanus","castra",17500,"industrial"},
    {"muluna","sye-calidus",14000,"starter"}
  },
  regional_origin=function() return nil end
}
local profiles={
  create=function(profile)
    return {{asteroid="sample-"..profile,probability=.01}}
  end,
  preserve_custom=function(keep,removed)
    keep.asteroid_spawn_definitions=keep.asteroid_spawn_definitions or {}
    for _,entry in ipairs(removed.asteroid_spawn_definitions or {}) do
      local found=false
      for _,existing in ipairs(keep.asteroid_spawn_definitions) do
        if existing.asteroid==entry.asteroid then found=true end
      end
      if not found then
        keep.asteroid_spawn_definitions[#keep.asteroid_spawn_definitions+1]=entry
      end
    end
  end
}
package.loaded["prototypes.system.asteroid_profiles"]=profiles
package.loaded["prototypes.system.route_icons"]={
  assign=function(route) return route end
}
local planets={}
for _,name in ipairs({"nauvis","muluna","vulcanus","castra",
  "fulgora","aquilo","ferrum","child-moon","remote-nexus"}) do
  planets[name]={name=name}
end
planets["child-moon"].orbit={parent={type="planet",name="nauvis"}}
local spaces={}
for _,name in ipairs({"sye-calidus","sye-solaris","sye-vespera",
  "asteroid-belt-inner-edge","asteroid-belt-outer-edge",
  "crucible-orbit","close-sun-orbit","sun-orbit"}) do
  spaces[name]={name=name}
end
local function route(name,a,b,length,asteroids)
  return {type="space-connection",name=name,from=a,to=b,length=length,
    asteroid_spawn_definitions=asteroids or {}}
end
local ore={{asteroid="rare-native-belt-chunk",probability=.4}}
local belt=route("native-belt","asteroid-belt-inner-edge",
  "asteroid-belt-outer-edge",5000,ore)
local moon=route("native-moon","nauvis","muluna",12000)
local dyson=route("dyson-lane","sye-calidus","close-sun-orbit",9000)
local internal=route("external-internal","remote-nexus","remote-nexus-inner",5000)
local roads={
  ["curated-home"]=route("curated-home","nauvis","sye-calidus",24000),
  ["curated-frontier"]=route("curated-frontier","sye-calidus","sye-solaris",60000),
  ["native-solaris"]=route("native-solaris","sye-solaris","vulcanus",17000),
  ["razi-solaris"]=route("razi-solaris","vulcanus","sye-solaris",18000,
    {{asteroid="modded-special-ore",probability=.3}}),
  ["rogue-nauvis-vulcanus"]=route("rogue-nauvis-vulcanus","nauvis","vulcanus",1000),
  ["rogue-solar-orbit-vulcanus"]=route("rogue-solar-orbit-vulcanus","sun-orbit","vulcanus",1000),
  ["rogue-close-orbit-vulcanus"]=route("rogue-close-orbit-vulcanus","close-sun-orbit","vulcanus",1000),
  ["rogue-solaris-castra"]=route("rogue-solaris-castra","sye-solaris","castra",9000),
  ["rogue-extra"]=route("rogue-extra","sye-vespera","aquilo",14000),
  ["native-belt"]=belt,
  ["native-moon"]=moon,
  ["dyson-lane"]=dyson,
  ["native-crucible"]=route("native-crucible","crucible-orbit","crucible",5000),
  ["source-moon"]=route("source-moon","nauvis","child-moon",5000),
  ["nexus-calidus"]=route("nexus-calidus","nauvis","remote-nexus",3000),
  ["ferrum-old-source"]=route("ferrum-old-source","ferrum","vulcanus",15000,
    {{asteroid="ferrum-native-crystal",probability=.26}}),
  ["nexus-solaris"]=route("nexus-solaris","sye-solaris","remote-nexus",25000),
  ["external-internal"]=internal
}
rawset(_G,"data",{raw={
  planet=planets,["space-location"]=spaces,
  ["space-connection"]=roads,
  technology={
    ["planet-discovery-sunorbit"]={effects={
      {type="unlock-space-location",space_location="close-sun-orbit"}}},
    ["slp-solar-system-sun2"]={effects={
      {type="unlock-space-location",space_location="sun-orbit"}}}
  }
},extend=function(self,prototypes)
  for _,p in ipairs(prototypes) do
    self.raw[p.type][p.name]=p
  end
end})
rawset(_G,"settings",{startup={
  ["razi-curated-space-routes"]={value=true}
}})
local manager=require("prototypes.system.route_authority")
local removed=manager.data_final_fixes()
check(removed>=5,"Unmanaged routes and duplicates were not removed")
for _,id in ipairs({"rogue-nauvis-vulcanus","rogue-solar-orbit-vulcanus",
  "rogue-close-orbit-vulcanus","rogue-solaris-castra",
  "rogue-extra","razi-solaris","nexus-calidus","ferrum-old-source"}) do
  check(roads[id]==nil,"Source shortcut survived final authority: "..id)
end
check(roads["native-solaris"]~=nil,
  "Prefer source native route ID on an approved pair")
check(roads["razi-curated-vulcanus-castra"]~=nil
  and roads["razi-curated-vulcanus-castra"].shape=="line",
  "Late catalog route missing or not centered on actual Solaris endpoints")
local has_ore=false
for _,item in ipairs(roads["native-solaris"].asteroid_spawn_definitions) do
  if item.asteroid=="modded-special-ore" then has_ore=true end
end
check(has_ore,"Deduplication lost custom asteroid resources")
check(roads["native-moon"]==moon,"Nauvis native moon route was lost")
check(roads["razi-curated-muluna-sye-calidus"]==nil,
  "Native moon already exists; must not add another Calidus hub chord")
check(roads["native-belt"]==belt and roads["native-belt"].length==5000,
  "Native belt crossing or loot was modified")
check(roads["dyson-lane"]==dyson,"Dyson station connection was lost")
check(roads["source-moon"]~=nil,"Child moon cannot be stranded")
check(roads["native-crucible"]~=nil,"Crucible access was lost")
check(roads["nexus-solaris"]~=nil,"External boss world lost its lifeline")
check(roads["external-internal"]==internal,
  "Source-only special network was destroyed")
check(roads["razi-curated-ferrum-fulgora"]~=nil,
  "Known optional Ferrum world is not linked to Razi's designated hub")
local ferrumResource=false
for _,entry in ipairs(roads["razi-curated-ferrum-fulgora"].asteroid_spawn_definitions) do
  if entry.asteroid=="ferrum-native-crystal" then ferrumResource=true end
end
check(ferrumResource,"Reassigned optional planet lost custom asteroid loot")
local count=0
for _ in pairs(roads) do count=count+1 end
check(manager.data_final_fixes()==0,
  "Running route authority twice removed more routes")
local again=0
for _ in pairs(roads) do again=again+1 end
check(count==again,"Idempotency produced duplicate routes")
settings.startup["razi-curated-space-routes"].value=false
roads["rogue-disabled"]=route("rogue-disabled","nauvis","castra",1000)
roads["rogue-stellar-disabled"]=route("rogue-stellar-disabled",
  "sun-orbit","vulcanus",1000)
check(manager.data_final_fixes()==1 and roads["rogue-disabled"]~=nil
  and roads["rogue-stellar-disabled"]==nil,
  "Disabling general authority must still remove the unwanted sun route")
print("Razi-only route authority, native lifelines and safety fixtures passed")
