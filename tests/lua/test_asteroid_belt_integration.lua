---@diagnostic disable: missing-fields, need-check-nil, undefined-field
package.path="./?.lua;./?/init.lua;"..package.path

local function check(ok,why) if not ok then error(why,2) end end

local ring="__AsteroidBelt__/graphics/sprite/asteroid-belt.png"
local layout=require("prototypes.system.galaxy_layout")
local hx,hy=layout.anchor_position("shchierbin")
check(hx and hy,"Missing Shchierbin from canonical layout")

local function run(with_outer,with_mod)
  local inner={
    name="asteroid-belt-inner-edge",
    starmap_icon="__AsteroidBelt__/graphics/icon/inner-belt-edge-starmap.png",
    asteroid_spawn_definitions={{asteroid="metallic-asteroid-chunk",probability=.08}}
  }
  local outer={
    name="asteroid-belt-outer-edge",
    starmap_icon="__AsteroidBelt__/graphics/icon/outer-belt-edge-starmap.png",
    asteroid_spawn_definitions={{asteroid="large-metallic-asteroid",probability=.08}}
  }
  local planets={shchierbin={name="shchierbin"}}
  local locations={star={name="star"},[inner.name]=inner}
  if with_outer then locations[outer.name]=outer end
  local layers={
    {filename="__core__/graphics/icons/starmap-star.png",shift={0,0}},
    {filename=ring,size=2436,scale=1.1,shift={0,0}},
    {filename="__another-mod__/graphics/starmap/background.png",shift={37,11}}
  }
  local original_native={
    name="asteroid-belt-inner-edge-asteroid-belt-outer-edge",
    from=inner.name,to=outer.name,length=5000,
    asteroid_spawn_definitions={{asteroid="source-asteroid",probability=.13}}
  }
  local raw={
    ["space-location"]=locations,planet=planets,
    ["space-connection"]={[original_native.name]=original_native},
    ["utility-sprites"]={default={starmap_star={layers=layers}}}
  }
  rawset(_G,"data",{raw=raw})
  rawset(_G,"mods",with_mod and {AsteroidBelt="1.2.11"} or {})
  rawset(_G,"PlanetsLib",{update=function(_,entries)
    for _,entry in ipairs(entries) do
      local proto=raw[entry.type] and raw[entry.type][entry.name]
      check(proto,"Attempted to move missing source belt endpoint")
      check(raw[entry.orbit.parent.type][entry.orbit.parent.name],
        "Missing Shchierbin parent for belt waypoint")
      proto.orbit=entry.orbit
      proto.distance=entry.orbit.distance
      proto.orientation=entry.orbit.orientation
    end
  end})
  package.loaded["prototypes.system.asteroid_belt_integration"]=nil
  local integration=require("prototypes.system.asteroid_belt_integration")
  integration.data_final_fixes()
  return integration,raw,inner,outer,original_native,layers
end

local module,raw,inner,outer,native,layers=run(true,true)
check(inner.orbit.parent.name=="shchierbin" and
  outer.orbit.parent.name=="shchierbin" and
  inner.orbit.parent.type=="planet" and
  outer.orbit.parent.type=="planet",
  "Native belt waypoints should follow the midgame Shchierbin planet")
check(math.abs(inner.orbit.distance-16.124515)<.000001 and
  math.abs(outer.orbit.distance-16.124515)<.000001,
  "Gateway markers must straddle the Shchierbin-centered ring")
check(inner.orbit.orientation>.8 and inner.orbit.orientation<.9 and
  outer.orbit.orientation>.1 and outer.orbit.orientation<.2,
  "Northern Asteroid Belt waypoint bearings were inverted")
check(inner.draw_orbit==false and outer.draw_orbit==false,
  "Belt waypoints must not create giant new orbital lines")
check(#layers==3 and layers[2].filename==ring and
  layers[2].size==2436 and layers[2].scale==.55 and
  math.abs(layers[2].shift[1]-hx*32)<.01 and
  math.abs(layers[2].shift[2]-hy*32)<.01,
  "Original AsteroidBelt art was not centered on Shchierbin")
check(layers[1].shift[1]==0 and layers[1].shift[2]==0 and
  layers[3].shift[1]==37 and layers[3].shift[2]==11,
  "Changing the asteroid graphic moved another mod's artwork")
check(raw["space-connection"][native.name]==native and native.length==5000
  and native.asteroid_spawn_definitions[1].asteroid=="source-asteroid",
  "Original Asteroid Belt's source-owned 5,000 km hazards were modified")
check(inner.starmap_icon:find("__AsteroidBelt__",1,true) and
  outer.starmap_icon:find("__AsteroidBelt__",1,true),
  "Source-owned asteroid waypoint icons were replaced")
module.data_final_fixes()
check(#layers==3 and layers[2].scale==.55 and
  math.abs(layers[2].shift[1]-hx*32)<.01,
  "Repeated integration must not duplicate or drift the source ring")

local _,partial,missing_inner=run(false,true)
check(missing_inner.orbit and not partial["space-location"]["asteroid-belt-outer-edge"],
  "Missing source outer gateway caused a PlanetsLib load failure")
local _,_,no_mod_inner=run(true,false)
check(not no_mod_inner.orbit,"Missing source mod rewrote a belt prototype")

local f=assert(io.open("info.json","r"))
local info=f:read("*a")
f:close()
check(info:find('"AsteroidBelt >= 1.2.11"',1,true),
  "Upstream Asteroid Belt must remain a required dependency")
print("Shchierbin asteroid ring art, 5000 km hazards and native gateways passed")
