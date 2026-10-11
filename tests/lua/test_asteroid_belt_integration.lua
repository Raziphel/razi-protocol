---@diagnostic disable: missing-fields, need-check-nil, undefined-field
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
local layout=require("prototypes.system.galaxy_layout")
local cx,cy=layout.anchor_position("vibrant")
check(cx and math.abs(cx-104)<.01,"Vibrant sun missing")
local src="__AsteroidBelt__/graphics/sprite/asteroid-belt.png"
local function run(outer_enabled,enabled)
  local inner={name="asteroid-belt-inner-edge",starmap_icon="__AsteroidBelt__/inner.png"}
  local outer={name="asteroid-belt-outer-edge",starmap_icon="__AsteroidBelt__/outer.png"}
  local locations={star={name="star"},[inner.name]=inner}
  if outer_enabled then locations[outer.name]=outer end
  local layers={{filename="unrelated",shift={2,4}},
    {filename=src,scale=1.1,size=2436,shift={0,0}},
    {filename="another",shift={37,11}}}
  local native={from=inner.name,to=outer.name,length=5000,
    asteroid_spawn_definitions={{asteroid="native-hazard",probability=.13}}}
  local raw={["space-location"]=locations,planet={},
    ["space-connection"]={native=native},
    ["utility-sprites"]={default={starmap_star={layers=layers}}}}
  rawset(_G,"data",{raw=raw})
  rawset(_G,"mods",enabled and {AsteroidBelt="1.2.11"} or {})
  rawset(_G,"PlanetsLib",{update=function(_,entries)
    for _,entry in ipairs(entries) do
      local proto=raw[entry.type] and raw[entry.type][entry.name]
      check(proto,"Missing native endpoint")
      check(raw[entry.orbit.parent.type][entry.orbit.parent.name],
        "Deleted sprite-only Vibrant star was used as a parent")
      proto.orbit=entry.orbit
      proto.distance=entry.orbit.distance
      proto.orientation=entry.orbit.orientation
    end
  end})
  package.loaded["prototypes.system.asteroid_belt_integration"]=nil
  local mod=require("prototypes.system.asteroid_belt_integration")
  mod.data_final_fixes()
  return mod,raw,inner,outer,layers,native
end
local mod,raw,inner,outer,layers,native=run(true,true)
local function native_xy(p)
  local a=p.orientation*2*math.pi
  return p.distance*math.sin(a),-p.distance*math.cos(a)
end
for _,entry in ipairs({inner,outer}) do
  check(entry.orbit.parent.name=="star" and entry.draw_orbit==false,
    "Sun-centered belt must use a surviving root orbit")
end
local x1,y1=native_xy(inner)
local x2,y2=native_xy(outer)
check(math.abs(x1-(cx+31*math.sin(.17*2*math.pi)))<.01 and
  math.abs(x2-(cx+39*math.sin(.17*2*math.pi)))<.01 and
  math.abs(y1-(cy-31*math.cos(.17*2*math.pi)))<.01 and
  math.abs(y2-(cy-39*math.cos(.17*2*math.pi)))<.01,
  "Source belt entry and exit not placed at Vibrant north rim")
check(layers[2].filename==src and layers[2].scale==1.12 and
  math.abs(layers[2].shift[1]-cx*32)<.01 and
  math.abs(layers[2].shift[2]-cy*32)<.01,
  "Source bitmap did not center on Vibrant sun")
check(layers[1].shift[1]==2 and layers[3].shift[1]==37,
  "Other mod art shifted with source belt")
check(raw["space-connection"].native==native and native.length==5000
  and native.asteroid_spawn_definitions[1].asteroid=="native-hazard",
  "Original AsteroidBelt hazards altered")
mod.data_final_fixes()
check(#layers==3,"Repeated loading duplicated graphics")
local _,partial,i=run(false,true)
check(i.orbit and not partial["space-location"]["asteroid-belt-outer-edge"],
  "Optional missing native endpoint breaks startup")
local _,_,missing=run(true,false)
check(not missing.orbit,"Missing AsteroidBelt should not be patched")
local f=assert(io.open("info.json","r"))
local info=f:read("*a") f:close()
check(info:find('"AsteroidBelt >= 1.2.11"',1,true),
  "AsteroidBelt ceased to be a required dependency")
print("Vibrant star native ring, 5000 km crossing and sprite-only cleanup passed")
