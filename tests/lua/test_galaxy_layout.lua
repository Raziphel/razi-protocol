---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(value, message)
  if not value then error(message, 2) end
end
local planets = {}
local places = {star={}}
for _, name in ipairs({
  "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra",
  "solar-system-edge","sye-calidus",
  "sye-solaris","sye-nyxaris","sye-vibrant","sye-vespera",
  "sye-beetlejuice","sye-umbra","apia-carnova-orbit",
  "crucible-orbit","secretas"
}) do places[name]={name=name} end
for _, name in ipairs({
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
  for _, item in ipairs(values) do
    local dest=data.raw[item.type][item.name]
    check(dest~=nil,"Unknown layout destination")
    dest.orbit=item.orbit
  end
end})
package.loaded["prototypes.system.galaxy_layout"]=nil
local layout=require("prototypes.system.galaxy_layout")
layout.data_final_fixes()
local function position(name)
  local orbit=places[name].orbit
  check(orbit~=nil,"Missing orbit for "..name)
  local angle=orbit.orientation*2*math.pi
  return math.sin(angle)*orbit.distance,-math.cos(angle)*orbit.distance
end
local last_x=0
for _, pair in ipairs({
  {"solaris","nyxaris"},{"vibrant","vespera"},
  {"beetlejuice","umbra"}
}) do
  local ax,ay=position(pair[1])
  local bx,by=position(pair[2])
  check(ax>last_x+72,"Compact systems still need distinct star columns")
  check(math.abs(ax-bx)<5,"Parallel pair not aligned")
  check(ay < -35 and by > 35,"Star pairs must be above/below center")
  last_x=ax
end
local edge_x,edge_y=position("solar-system-edge")
check(edge_x>last_x+90 and edge_x<370 and math.abs(edge_y)<5,
  "Deep Space should finish the compact right-hand frontier")
for _, name in ipairs({
  "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"
}) do
  check(places["sye-"..name].orbit.parent.name==name,"Orphaned slipstream")
  check(places[name].draw_orbit==false,"Giant star orbit obscures map")
end
check(places["sye-calidus"].orbit.parent.name=="star","Calidus departure misparented")
for _, name in ipairs({"vulcanus","castra","arig","hyarion","tellus",
  "corrundum","gleba","moshine","panglia","fulgora","ribbonia",
  "paracelsin","shchierbin","muria","aquilo","rubia","maraxsis",
  "cubium","linox-planet_linox","tenebris","vesta"}) do
  check(planets[name].draw_orbit==false,
    "A crowded star-centered orbital ring survived: "..name)
end
check(planets.rabbasca.orbit==moon,"Rabbasca lost its Gleba moon parent")
layout.data_final_fixes()
check(planets.rabbasca.orbit==moon,"Repeated layout damaged native moon")
-- Guard the real data-stage wiring, not only the standalone layout function.
-- Applying the layout before optional planet placement would overwrite it.
local entrypoint = assert(io.open("data-final-fixes.lua", "r"))
local source = entrypoint:read("*a")
entrypoint:close()
local optional_call = source:find(
  'require("prototypes.system.optional_planets").data_final_fixes()', 1, true)
local layout_call = source:find(
  'require("prototypes.system.galaxy_layout").data_final_fixes()', 1, true)
check(optional_call and layout_call and layout_call > optional_call,
  "Final starmap layout must run after optional planets in data-final-fixes.lua")
print("Paired star arrangement, preserved moons and final-stage wiring passed")
