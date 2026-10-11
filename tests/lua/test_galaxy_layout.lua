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
    -- data-updates mock also needs to model native absolute polar coordinates
    -- of sprite-only stars, not merely copy orbit metadata.
    if item.orbit.parent.name=="star" then
      dest.distance=item.orbit.distance
      dest.orientation=item.orbit.orientation
    end
  end
end})

package.loaded["prototypes.system.galaxy_layout"]=nil
local layout=require("prototypes.system.galaxy_layout")
local shchierbin_x,shchierbin_y=layout.anchor_position("shchierbin")
check(shchierbin_x>130 and shchierbin_y<0,
  "Asteroid Belt host is no longer the Vibrant outer planet")
layout.data_updates()
-- A star missing its data-updates placement caused all earlier screenshots:
-- assert its real native coordinates before PlanetsLib renders its art.
for name,bearing in pairs({
  solaris=5/12,nyxaris=7/12,vibrant=.25,
  vespera=.75,beetlejuice=1/12,umbra=11/12
}) do
  check(math.abs(places[name].distance-124)<.001 and
        math.abs(places[name].orientation-bearing)<.000002,
    "Sprite-only star was not moved before PlanetsLib rendered it: "..name)
end
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


-- Reproduce the real PlanetsLib 2.0.9 load sequence. PlanetsLib removes
-- sprite_only stars in its own data-final-fixes, before Razi's final fixes.
-- This used to silently skip every orbit whose parent was a deleted star.
local original_positions={}
for _,name in ipairs({"solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"}) do
  original_positions[name]={distance=places[name].orbit.distance,
    orientation=places[name].orbit.orientation}
  places[name]=nil
end
-- Simulate a later source mod moving a planet and a slipstream off the ring.
planets.gleba.origin={x=800,y=800}
planets.gleba.distance=10
planets.gleba.orientation=.5
places["sye-nyxaris"].origin={x=500,y=500}
places["sye-nyxaris"].distance=8
places["sye-nyxaris"].orientation=.5
local moon_before=planets.rabbasca.orbit
local orbit_art_before=planets.athos.orbit.sprite
local native_moon_before=planets.rabbasca.orbit.sprite
-- And a source-owned Frozeta-like moon that must follow its moved planet.
planets.rabbasca.distance=4
planets.rabbasca.orientation=.25
local function fixed_position(name)
  local location=planets[name] or places[name]
  check(location~=nil,"Native test missing "..name)
  local origin=location.origin or {}
  local r=location.distance
  local o=location.orientation
  return (origin.x or 0)+r*math.sin(o*math.pi*2),
    (origin.y or 0)-r*math.cos(o*math.pi*2)
end
layout.data_final_fixes()
local ex=-62
local ey=124*math.sqrt(3)/2
check(math.abs(planets.gleba.origin.x-ex)<.05 and
      math.abs(planets.gleba.origin.y-ey)<.05,
  "Final native layout did not recover a planet after its star was deleted")
check(math.abs(places["sye-nyxaris"].origin.x-ex)<.05 and
      math.abs(places["sye-nyxaris"].origin.y-ey)<.05,
  "Final native layout skipped a slipstream with a deleted star parent")
check(math.abs(planets.gleba.distance-37.706964)<.001,
  "Native planet distance was not restored")
local gx,gy=fixed_position("gleba")
check(math.abs(planets.rabbasca.origin.x-gx)<.01 and
      math.abs(planets.rabbasca.origin.y-gy)<.01,
  "Source-owned moon origin did not follow its parent's relocation")
check(planets.rabbasca.orbit==moon_before and
      planets.rabbasca.orbit.sprite==native_moon_before,
  "Final native movement damaged unique moon artwork")
check(planets.athos.orbit.sprite==orbit_art_before,
  "Optional special orbit sprite was destroyed")
-- A world with dashed custom orbit art must not gain a second native ring.
planets.athos.draw_orbit=false
layout.data_final_fixes()
check(planets.athos.draw_orbit==false and
  planets.athos.orbit.sprite==orbit_art_before,
  "Unique source orbit art should not be doubled by native circles")
local dzx,dzy=fixed_position("solar-system-edge")
check(math.abs(dzx)<.01 and math.abs(dzy+248)<.01,
  "Native Deep Space was no longer directly north")
-- Astral sprite positions were already fixed by the pre-final stage.
for name,expect in pairs(original_positions) do
  check(math.abs(expect.distance-124)<.001,
    "Pre-render parent star radius was wrong: "..name)
end

local data_updates_file=assert(io.open("data-updates.lua","r"))
local updates_source=data_updates_file:read("*a")
data_updates_file:close()
check(updates_source:find(
  'require("prototypes.system.galaxy_layout").data_updates()',1,true),
  "Pre-render star placement is not called during data-updates")

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
