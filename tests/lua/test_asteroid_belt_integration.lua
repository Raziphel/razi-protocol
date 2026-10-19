---@diagnostic disable: undefined-field
-- Vibrant belt rim geometry on the star map.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local layout=require("prototypes.system.galaxy_layout")
local cx,cy=layout.anchor_position("vibrant")
check(cx and math.abs(cx-118)<.01,"Vibrant sun missing")
local inner={name="asteroid-belt-inner-edge"}
local outer={name="asteroid-belt-outer-edge"}
rawset(_G,"data",{raw={["space-location"]={
  [inner.name]=inner,[outer.name]=outer
}}})
package.loaded["prototypes.system.asteroid_belt_integration"]=nil
local belt=require("prototypes.system.asteroid_belt_integration")
belt.data_final_fixes()
local function xy(location)
  local theta=location.orientation*2*math.pi
  return location.distance*math.sin(theta),
    -location.distance*math.cos(theta)
end
for _,entry in ipairs({{inner,31,.77},{outer,39,.775}}) do
  local loc,radius=entry[1],entry[2]
  check(loc.orbit.parent.name=="star" and not loc.draw_orbit,
    "Vibrant belt must use a native root-star orbit")
  local x,y=xy(loc)
  check(x<cx,"Belt rim must stay on the western side of Vibrant")
  check(math.abs(x-(cx+radius*math.sin(entry[3]*2*math.pi)))<.01,
    "Belt rim X coordinate changed")
  check(math.abs(y-(cy-radius*math.cos(entry[3]*2*math.pi)))<.01,
    "Belt rim Y coordinate changed")
end
local first=inner.orbit.distance
belt.data_final_fixes()
check(inner.orbit.distance==first,"Repeated pass moved the rim")
data.raw["space-location"][outer.name]=nil
belt.data_final_fixes()
check(inner.orbit,"A missing rim should be handled without crashing")
local f=assert(io.open("info.json","r"))
local info=f:read("*a");f:close()
check(info:find('"! AsteroidBelt"',1,true),
  "The AsteroidBelt mod must be excluded to avoid duplicate prototypes")
check(info:find('"! kry-asteroid-belt"',1,true),
  "The kry-asteroid-belt mod must be excluded to avoid duplicate prototypes")
print("Vibrant belt rim coordinates and mod exclusions passed")
