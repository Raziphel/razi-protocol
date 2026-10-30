-- Routes created by bellicos.fortify_routes must carry their asteroid
-- profile once: applying it again would square the density and size weights.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local entry="calidus-bellicos-stargate-calidus"
local outer,inner,near,warden=
  "aegis-outer-edge","aegis-inner-edge","near-bellicos-orbit","point-warden"
local places={}
for _,id in ipairs({entry,outer,inner,near,warden}) do places[id]={name=id} end
local routes={}
rawset(_G,"data",{raw={["space-location"]=places,planet={},
  ["space-connection"]=routes,
  asteroid={
    ["big-metallic-asteroid"]={},["big-carbonic-asteroid"]={},
    ["big-oxide-asteroid"]={},["huge-metallic-asteroid"]={},
    ["huge-carbonic-asteroid"]={},["huge-oxide-asteroid"]={}
  },["asteroid-chunk"]={},technology={}},
  extend=function(_,additions)
    for _,value in ipairs(additions) do routes[value.name]=value end
  end})
rawset(_G,"mods",{["bellicos-and-aegis"]="0.4.1"})
local source={name="same-source"}
local util={
  aquilo_solar_system_edge=source,fulgora_aquilo=source,gleba_aquilo=source,
  spawn_definitions=function()
    return {
      {type="entity",asteroid="big-metallic-asteroid",
        spawn_points={{distance=0.1,probability=0.002,speed=1},
          {distance=0.9,probability=0.002,speed=1}}},
      {type="entity",asteroid="huge-metallic-asteroid",
        spawn_points={{distance=0.1,probability=0.001,speed=1},
          {distance=0.9,probability=0.001,speed=1}}}
    }
  end
}
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]=util
package.loaded["prototypes.system.asteroid_profiles"]=nil
package.loaded["prototypes.system.route_icons"]={assign=function(r) return r end}
package.loaded["prototypes.system.bellicos"]=nil
local profiles=require("prototypes.system.asteroid_profiles")
local bellicos=require("prototypes.system.bellicos")
local function probability(defs,name)
  for _,def in ipairs(defs) do
    if def.asteroid==name then return def.spawn_points[1].probability end
  end
end
local added=bellicos.fortify_routes()
check(added>=3,"The Aegis spine routes were not created")
local expected={
  [entry.."|"..outer]="aegis_approach",
  [outer.."|"..inner]="aegis_depths",
  [near.."|"..inner]="aegis_depths",
  [inner.."|"..warden]="aegis_depths"
}
local function centre(defs,name)
  for _,def in ipairs(defs) do
    if def.asteroid==name then
      for _,point in ipairs(def.spawn_points) do
        if math.abs(point.distance-0.5)<.001 then return point.probability end
      end
    end
  end
end
local found=0
for _,route in pairs(routes) do
  local a,b=route.from,route.to
  local profile=expected[a.."|"..b] or expected[b.."|"..a]
  if profile then
    found=found+1
    local single=profiles.create(profile)
    -- The depths carry no huge asteroids, and their mid-route field is
    -- milder than the one a wide first-frontier link used to get.
    local want_field=profile=="aegis_approach" and 1.5 or 1.6
    local base=probability(single,"big-metallic-asteroid")
    local mid=centre(route.asteroid_spawn_definitions,"big-metallic-asteroid")
    check(mid and math.abs(mid/base-want_field)<1e-9,
      route.name.." big asteroid field is not "..want_field)
    if profile=="aegis_depths" then
      check(centre(route.asteroid_spawn_definitions,"huge-metallic-asteroid")==0,
        route.name.." must carry no huge asteroids")
    end
    for _,name in ipairs({"big-metallic-asteroid","huge-metallic-asteroid"}) do
      -- The distance-0.1 point is outside the 0.3-0.7 route field.
      local want=probability(single,name)
      local have=probability(route.asteroid_spawn_definitions,name)
      check(have==want,profile.." applied twice on "..route.name..": "
        ..name.." "..tostring(have).." instead of "..tostring(want))
    end
  end
end
check(found==3 or found==4,"Expected Aegis corridors were not inspected")
print("Aegis fortified routes carry their asteroid profile once")
