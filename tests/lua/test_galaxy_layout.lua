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
  "cerys","rabbasca"
}) do planets[name]={name=name} end

local moon={parent={type="planet",name="gleba"},distance=4}
planets.rabbasca.orbit=moon
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

local centers={
  solaris={62,105},nyxaris={-62,105},
  vibrant={124,0},vespera={-124,0},
  beetlejuice={62,-105},umbra={-62,-105}
}
for name,expected in pairs(centers) do
  local x,y=position(name)
  check(math.abs(x-expected[1])<1 and math.abs(y-expected[2])<1,
    "Star moved out of its circular position: "..name)
  local hx,hy=position("sye-"..name)
  check(math.sqrt((hx-x)^2+(hy-y)^2)>25,
    "Slipstream overlaps its parent star: "..name)
  check(places[name].draw_orbit==false,"Giant orbital ring survived")
end
local dx,dy=position("solar-system-edge")
check(math.abs(dx)<1 and dy < -235 and dy > -260,
  "Deep Space must be a northern outer frontier")
local hx,hy=position("sye-calidus")
check(math.abs(hx)<1 and hy>20 and hy<30,
  "Calidus departure must remain near the central star")

for _,name in ipairs({"vulcanus","castra","arig","hyarion","tellus",
  "corrundum","gleba","moshine","panglia","fulgora","ribbonia",
  "paracelsin","shchierbin","muria","aquilo","rubia","maraxsis",
  "cubium","linox-planet_linox","tenebris","vesta"}) do
  local signature={vulcanus=true,gleba=true,fulgora=true,
    muria=true,cubium=true,tenebris=true}
  check(planets[name].draw_orbit==(signature[name]==true),
    "Wrong signature orbital ring: "..name)
end
check(planets.rabbasca.orbit==moon,
  "Native Gleba moon orbit must remain untouched")
layout.data_final_fixes()
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
print("Calidus radial gallery, native moon and belt order passed")
