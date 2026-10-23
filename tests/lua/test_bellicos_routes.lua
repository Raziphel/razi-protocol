-- Aegis source-route compatibility: the real starmap needs one readable
-- spine, no old long skip chords and no lost third-party asteroid resources.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local entry="calidus-bellicos-stargate-calidus"
local deep="calidus-bellicos-stargate-bellicos"
local outer="aegis-outer-edge"
local inner="aegis-inner-edge"
local near="near-bellicos-orbit"
local warden="point-warden"
local places={}
for _,id in ipairs({entry,deep,outer,inner,near,warden}) do
  places[id]={name=id}
end
local function route(id,a,b,km,asteroid)
  return {name=id,from=a,to=b,length=km,shape="arc",
    asteroid_spawn_definitions=asteroid and {
      {type="entity",asteroid=asteroid}
    } or {}}
end
local routes={
  ["native-outer-inner"]=route("native-outer-inner",outer,inner,5000,
    "author-original-rock"),
  ["native-near-inner"]=route("native-near-inner",near,inner,1000),
  ["native-inner-warden"]=route("native-inner-warden",inner,warden,3000),
  ["native-warden-deep"]=route("native-warden-deep",warden,deep,4000),
  ["native-direct-entry-deep"]=route("native-direct-entry-deep",
    entry,deep,800,"native-rare-asteroid"),
  ["native-direct-outer-deep"]=route("native-direct-outer-deep",
    outer,deep,500,"native-exotic-asteroid")
}
rawset(_G,"data",{raw={["space-location"]=places,planet={},
  ["space-connection"]=routes},
  extend=function(self,additions)
    for _,value in ipairs(additions) do
      check(not routes[value.name],"Duplicate route "..value.name)
      routes[value.name]=value
    end
  end})
rawset(_G,"mods",{["bellicos-and-aegis"]="0.4.1"})
local profile={
  create=function() return {} end,
  apply=function(r,p) r.test_profile=p end,
  apply_field=function(r,p) r.test_field=p end,
  preserve_custom=function(dest,from)
    dest.asteroid_spawn_definitions=dest.asteroid_spawn_definitions or {}
    local existing={}
    for _,d in ipairs(dest.asteroid_spawn_definitions) do
      existing[d.asteroid]=true
    end
    for _,d in ipairs(from.asteroid_spawn_definitions or {}) do
      if not existing[d.asteroid] then
        dest.asteroid_spawn_definitions[#dest.asteroid_spawn_definitions+1]=d
        existing[d.asteroid]=true
      end
    end
  end
}
package.loaded["prototypes.system.asteroid_profiles"]=profile
package.loaded["prototypes.system.route_icons"]={
  assign=function(r) return r end}
package.loaded["prototypes.system.bellicos"]=nil
local bellicos=require("prototypes.system.bellicos")
local added,removed=bellicos.fortify_routes()
check(added==1 and removed==2,
  "Route director should replace exactly one missing entry and two shortcuts")
local pairs={}
for name,r in pairs(routes) do
  local a,b=r.from,r.to
  local key=a<b and (a.."|"..b) or (b.."|"..a)
  check(not pairs[key],"Duplicate Aegis corridor: "..key)
  pairs[key]=r
  check(r.shape=="line" and r.origin==nil,
    "An old native Aegis arc still crosses the pulsar: "..name)
end
local function has(a,b)
  local key=a<b and a.."|"..b or b.."|"..a
  return pairs[key]
end
check(has(entry,outer) and has(outer,inner)
  and has(inner,warden) and has(warden,deep) and has(near,inner),
  "Main Aegis expedition or orbit spur disconnected")
check(not has(entry,deep) and not has(outer,deep)
  and not has(inner,deep),
  "A source shortcut bypasses the Aegis asteroid crossing")
local count=0
for _ in pairs(routes) do count=count+1 end
check(count==5,"The Aegis map should contain exactly five playable corridors")
check(routes["native-outer-inner"] and
  routes["native-outer-inner"].length>=45000,
  "Native Outer-to-Inner route name and dangerous distance were lost")
local custom={}
for _,def in ipairs(has(entry,outer).asteroid_spawn_definitions or {}) do
  custom[def.asteroid]=true
end
check(custom["native-rare-asteroid"] and custom["native-exotic-asteroid"],
  "Source-exclusive asteroid spawns vanished when removing shortcuts")
local next_added,next_removed=bellicos.fortify_routes()
check(next_added==0 and next_removed==0,
  "Repeated pass must not recreate or double the Aegis routes")
print("Aegis source route pruning, research path and exotic asteroid retention passed")
