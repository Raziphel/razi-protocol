---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, why)
  if not ok then error(why, 2) end
end

local planets = {}
local places = {star={name="star"}}
for _,name in ipairs({
  "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra",
  "solar-system-edge","sye-calidus",
  "sye-solaris","sye-nyxaris","sye-vibrant","sye-vespera",
  "sye-beetlejuice","sye-umbra","apia-carnova-orbit",
  "crucible-orbit","secretas",
  "razi-vespera-belt-inner","razi-vespera-belt-outer",
  "razi-umbra-belt-inner","razi-umbra-belt-outer"
}) do places[name]={name=name} end
for _,name in ipairs({
  "vulcanus","castra","arig","hyarion","tellus","corrundum",
  "gleba","moshine","panglia","fulgora","ribbonia","paracelsin",
  "shchierbin","muria","aquilo","rubia","maraxsis",
  "cubium","linox-planet_linox","tenebris","vesta",
  "cerys","rabbasca","athos"
}) do planets[name]={name=name} end

local moon={parent={type="planet",name="gleba"},distance=4}
planets.rabbasca.orbit=moon
planets.rabbasca.draw_orbit=false
local native_moon_sprite={type="sprite",filename="custom-dashed-moon-orbit.png"}
moon.sprite=native_moon_sprite
local optional_orbit={parent={type="space-location",name="solaris"},
  distance=40,orientation=.1,sprite={filename="custom-optional-orbit.png"}}
planets.athos.orbit=optional_orbit
planets.athos.draw_orbit=false
planets.castra.draw_orbit=false
places["sye-solaris"].draw_orbit=false
rawset(_G,"data",{raw={planet=planets,["space-location"]=places}})
rawset(_G,"PlanetsLib",{update=function(_,values)
  for _,item in ipairs(values) do
    local dest=data.raw[item.type] and data.raw[item.type][item.name]
    check(dest~=nil,"Unknown layout destination "..item.name)
    dest.orbit=item.orbit
  end
end})

package.loaded["prototypes.system.galaxy_layout"]=nil
local layout=require("prototypes.system.galaxy_layout")
layout.data_final_fixes()

local function position(name)
  if name=="star" then return 0,0 end
  local location=places[name] or planets[name]
  local orbit=location and location.orbit
  check(orbit~=nil,"Missing orbit for "..name)
  local parent=orbit.parent
  local x,y=position(parent.name)
  local angle=orbit.orientation*2*math.pi
  return x+math.sin(angle)*orbit.distance,
    y-math.cos(angle)*orbit.distance
end

-- Factorio/PlanetsLib use clockwise turns from north:
-- 0=N, .25=E, .5=S, .75=W; x=r*sin(tau*turn), y=-r*cos(tau*turn).
local function cartesian(radius,orientation)
  local angle=orientation*2*math.pi
  return radius*math.sin(angle),-radius*math.cos(angle)
end
for _,direction in ipairs({
  {0,0,-10}, {.25,10,0}, {.5,0,10}, {.75,-10,0}
}) do
  local x,y=cartesian(10,direction[1])
  check(math.abs(x-direction[2])<.001 and math.abs(y-direction[3])<.001,
    "Factorio compass bearings are no longer interpreted correctly")
end

local bearings={
  solaris=5/12,nyxaris=7/12,
  vibrant=1/4,vespera=3/4,
  beetlejuice=1/12,umbra=11/12
}
for name,bearing in pairs(bearings) do
  local star=places[name]
  local radius=star.orbit.distance
  check(math.abs(radius-124)<.001,
    "Stars are not positioned on the same circular radius: "..name)
  check(math.abs(star.orbit.orientation-bearing)<.000002,
    "Wrong clockwise compass bearing for "..name)
  local x,y=position(name)
  local ex,ey=cartesian(124,bearing)
  check(math.abs(x-ex)<.01 and math.abs(y-ey)<.01,
    "Star position does not match Factorio polar orientation: "..name)
  local hx,hy=position("sye-"..name)
  check(math.sqrt((hx-x)^2+(hy-y)^2)>25,
    "Slipstream overlaps its parent star: "..name)
  check(star.draw_orbit==false,"Giant orbital ring survived")
end
local dx,dy=position("solar-system-edge")
check(math.abs(dx)<1 and dy < -235 and dy > -260,
  "Deep Space must be a northern outer frontier")
local hx,hy=position("sye-calidus")
check(math.abs(hx)<1 and hy>20 and hy<30,
  "Calidus departure must remain near the central star")

-- All planets directly orbiting a Razi star get Factorio 2.1 native
-- rings, not only the old handpicked six signature planets.
for _,name in ipairs({"vulcanus","castra","arig","hyarion","tellus",
  "corrundum","gleba","moshine","panglia","fulgora","ribbonia",
  "paracelsin","shchierbin","muria","aquilo","rubia","maraxsis",
  "cubium","linox-planet_linox","tenebris","vesta","athos"}) do
  check(planets[name].draw_orbit==true,
    "Factorio native orbit still disabled: "..name)
end
check(places.secretas.draw_orbit==true,
  "Natural Secretas space-location should have a native orbit")
check(places["sye-solaris"].draw_orbit==false,
  "Synthetic slipstream ring should remain suppressed")
check(planets.athos.orbit==optional_orbit and
  planets.athos.orbit.sprite.filename=="custom-optional-orbit.png",
  "Optional source orbit identity or unique sprite was overwritten")
check(planets.rabbasca.draw_orbit==false and moon.sprite==native_moon_sprite,
  "Moon's own orbit drawing settings were modified")
check(planets.rabbasca.orbit==moon,
  "Native Gleba moon orbit must remain untouched")
layout.data_final_fixes()
check(planets.athos.draw_orbit==true,
  "Repeated final fixes reverted native planet orbit")
check(planets.rabbasca.orbit==moon,
  "Repeating layout damaged native moon")

local entrypoint=assert(io.open("data-final-fixes.lua","r"))
local source=entrypoint:read("*a")
entrypoint:close()
local optional=source:find(
  'require("prototypes.system.optional_planets").data_final_fixes()',1,true)
local belt=source:find(
  'require("prototypes.system.asteroid_belt_integration").data_final_fixes()',1,true)
local layout_call=source:find(
  'require("prototypes.system.galaxy_layout").data_final_fixes()',1,true)
check(optional and belt and layout_call and optional<belt
  and belt<layout_call,"Final galaxy layout stage ordering is incorrect")
print("Calidus radial gallery, Factorio native planet orbits and moon preservation passed")
