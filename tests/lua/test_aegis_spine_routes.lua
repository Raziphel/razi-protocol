---@diagnostic disable: need-check-nil, undefined-field
-- luacheck: ignore 122
-- Aegis inner corridors: both interior routes are coloured like the rim
-- crossings, and aliased or parallel corridors collapse into one connection.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local entry="calidus-bellicos-stargate-calidus"

local points={
  [entry]={distance=115,orientation=.26},
  ["aegis-outer-edge"]={distance=95,orientation=.24},
  ["aegis-inner-edge"]={distance=85,orientation=.22},
  ["bellicos-orbit"]={distance=45,orientation=.20},
  ["aegis-warden"]={distance=70,orientation=.30},
  ["aegis-inner-alias"]={distance=85,orientation=.22},
  ["aegis-near-alias"]={distance=45,orientation=.20},
  ["plain-neighbour"]={distance=85,orientation=.22},
  ["a"]={distance=10,orientation=.25},
  ["b"]={distance=68,orientation=.25}
}
local locations={}
for name,p in pairs(points) do
  locations[name]={name=name,distance=p.distance,orientation=p.orientation,
    origin={x=0,y=0}}
end
local routes={}
local function connect(name,a,b,shape)
  routes[name]={name=name,from=a,to=b,shape=shape or "line",length=12000,
    asteroid_spawn_definitions={}}
  return routes[name]
end
rawset(_G,"data",{raw={["space-location"]=locations,planet={},
  ["space-connection"]=routes,
  ["utility-sprites"]={default={starmap_star={layers={}}}}}})
rawset(_G,"mods",{["bellicos-and-aegis"]="0.4.3"})
local preset={name="same-source"}
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]={
  nauvis_fulgora=preset,vulcanus_castra=preset,nauvis_gleba=preset,
  fulgora_aquilo=preset,gleba_aquilo=preset,aquilo_solar_system_edge=preset,
  spawn_definitions=function() return {} end
}
rawset(_G,"settings",{startup={
  ["razi-route-overlay-mode"]={value="danger"},
  ["razi-route-overlay-scope"]={value="all"},
  ["razi-quality-asteroids"]={value=true}}})

-- Highlight rules
local highlights=require("prototypes.system.route_highlights")
local function spine(a,b) return highlights.is_aegis_spine({from=a,to=b}) end
check(spine("bellicos-orbit","aegis-inner-edge")
  and spine("aegis-inner-edge","bellicos-orbit"),
  "Aegis 0.4.3 near orbit -> Inner edge is not recognised")
check(spine("near-bellicos-orbit","aegis-inner-edge")
  and spine("bellicos-near-orbit","aegis-inner-edge"),
  "Older near-orbit IDs are not recognised")
check(spine("aegis-inner-edge","aegis-warden")
  and spine("aegis-inner-edge","point-warden"),
  "Inner edge -> Warden is not recognised")
check(not spine("aegis-outer-edge","aegis-warden"),
  "A route that skips the Inner edge is not part of the spine")
check(not spine("a","b") and not spine("aegis-inner-edge","a"),
  "A route without Aegis endpoints must not be coloured as the spine")
check(not spine(nil,"aegis-inner-edge"),"Malformed routes must not match")

-- Ribbons
local inner_near=connect("native-near-inner","bellicos-orbit","aegis-inner-edge")
local inner_warden=connect("native-inner-warden","aegis-inner-edge","aegis-warden")
check(highlights.is_navigation_highlight(inner_near,"major")
  and highlights.is_major(inner_near,{x=0,y=0},{x=1,y=1}),
  "Near orbit -> Inner edge is not a major highlighted route")
check(#highlights.strokes_for_connection(inner_near,"danger","major")>0,
  "Near orbit -> Inner edge received no ribbon")
check(#highlights.strokes_for_connection(inner_warden,"danger","major")>0,
  "Inner edge -> Warden received no ribbon")
routes["native-near-inner"]=nil
routes["native-inner-warden"]=nil

-- Corridor dedupe
package.loaded["prototypes.system.asteroid_profiles"]={
  preserve_custom=function() end}
package.loaded["prototypes.system.route_icons"]={assign=function(r) return r end}
package.loaded["prototypes.system.bellicos"]=nil
local bellicos=require("prototypes.system.bellicos")
local function count()
  local n=0
  for _ in pairs(routes) do n=n+1 end
  return n
end
local function between(a,b)
  local found={}
  for name,r in pairs(routes) do
    if (r.from==a and r.to==b) or (r.from==b and r.to==a) then
      found[#found+1]=name
    end
  end
  return found
end

-- 1. The original route and a generated twin of the same pair.
connect("native-near-inner","bellicos-orbit","aegis-inner-edge")
connect("razi-near-inner","aegis-inner-edge","bellicos-orbit")
check(bellicos.dedupe_internal_routes()==1,"The generated twin was not removed")
local kept=between("bellicos-orbit","aegis-inner-edge")
check(#kept==1 and kept[1]=="native-near-inner",
  "The original route must survive, got "..table.concat(kept,","))

-- 2. A route to an Aegis-named alias sitting on the same point is merged.
connect("alias-near-inner","aegis-near-alias","aegis-inner-alias")
check(bellicos.dedupe_internal_routes()==1,
  "A route between coordinate aliases was not merged")
check(routes["alias-near-inner"]==nil and routes["native-near-inner"],
  "The alias route survived or the original was removed")
locations["aegis-near-alias"]=nil
locations["aegis-inner-alias"]=nil

-- 3. An unrelated planet on the same coordinates is never merged.
connect("plain-inner","plain-neighbour","bellicos-orbit")
local before=count()
check(bellicos.dedupe_internal_routes()==0 and count()==before
  and routes["plain-inner"],
  "A planet without an Aegis-style name was merged by coordinates")
check(bellicos.dedupe_internal_routes()==0,"Dedupe must be idempotent")
print("Aegis spine highlighting and corridor dedupe passed")
