-- Razi-owned Vibrant belt geometry, original art and repeated-pass safety.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local layout=require("prototypes.system.galaxy_layout")
local cx,cy=layout.anchor_position("vibrant")
check(cx and math.abs(cx-104)<.01,"Vibrant sun missing")
local inner={name="asteroid-belt-inner-edge"}
local outer={name="asteroid-belt-outer-edge"}
local layers={{filename="unrelated",shift={2,4}},
  {filename="another",shift={37,11}}}
rawset(_G,"data",{raw={["space-location"]={
  [inner.name]=inner,[outer.name]=outer
},["utility-sprites"]={default={starmap_star={layers=layers}}}}})
rawset(_G,"mods",{})
package.loaded["prototypes.system.asteroid_belt_integration"]=nil
local belt=require("prototypes.system.asteroid_belt_integration")
belt.data_final_fixes()
local function xy(location)
  local theta=location.orientation*2*math.pi
  return location.distance*math.sin(theta),
    -location.distance*math.cos(theta)
end
for _,entry in ipairs({{inner,31,.08},{outer,39,.095}}) do
  local loc,radius=entry[1],entry[2]
  check(loc.orbit.parent.name=="star" and not loc.draw_orbit,
    "Vibrant belt must use a native root-star orbit")
  local x,y=xy(loc)
  check(math.abs(x-(cx+radius*math.sin(entry[3]*2*math.pi)))<.01,
    "Belt rim X coordinate changed")
  check(math.abs(y-(cy-radius*math.cos(entry[3]*2*math.pi)))<.01,
    "Belt rim Y coordinate changed")
end
check(#layers==4,"Expected exactly two first-party decorative layers")
for i=1,2 do
  local layer=layers[i]
  check(layer.filename:find("__razi%-protocol__/graphics/starmap/razi/"),
    "Belt still references an upstream mod texture")
  check(math.abs(layer.shift[1]-cx*32)<.01 and
    math.abs(layer.shift[2]-cy*32)<.01,"Decorative ring not sun-centered")
end
check(layers[3].shift[1]==2 and layers[4].shift[1]==37,
  "Existing source art was modified or belt art drew above the native layers")
-- The actual rock textures have faceted bright/dark pixels and a thinner
-- scattered rim. They are not a transparent smooth neon ring anymore.
for i=1,2 do
  local visual_radius=layers[i].scale*6
  check(visual_radius>31 and visual_radius<39,
    "Visible belt fragments no longer align with the 31/39-unit rims")
  check(layers[i].tint.a>.55 and layers[i].tint.a<.9,
    "Rock fragments are too faint or obscure the star and labels")
end
check(layers[1].tint.r>.85 and layers[2].tint.g>.80,
  "Mineral fragments should retain neutral, rocky colors")
belt.data_final_fixes()
check(#layers==4,"Repeated data-stage pass duplicated belt artwork")
data.raw["space-location"][outer.name]=nil
belt.data_final_fixes()
check(#layers==4 and inner.orbit,
  "Missing legacy rim should be handled without crashing")
-- Cosmetic toggles affect the artwork only, never the saved coordinates.
table.remove(layers,1)
table.remove(layers,1)
rawset(_G,"settings",{startup={
  ["razi-starmap-background-style"]={value="off"},
  ["razi-starmap-belt-atmosphere"]={value=true}
}})
belt.data_final_fixes()
check(#layers==2 and inner.orbit,
  "Background Off should suppress the ring without removing navigation")
settings.startup["razi-starmap-background-style"].value="subtle"
settings.startup["razi-starmap-belt-atmosphere"].value=false
belt.data_final_fixes()
check(#layers==2,"Belt atmosphere Off must suppress Vibrant debris")
settings.startup["razi-starmap-belt-atmosphere"].value=true
mods["Better_Starmap_Background"]=true
belt.data_final_fixes()
check(#layers==2,"External sky background should not be covered")
mods["Better_Starmap_Background"]=nil
belt.data_final_fixes()
check(#layers==4 and layers[1].filename:find("belt%-vibrant"),
  "Original Vibrant art must return when toggles are enabled again")
local f=assert(io.open("info.json","r"))
local info=f:read("*a");f:close()
check(info:find('"! AsteroidBelt"',1,true),
  "Original AsteroidBelt must be excluded to avoid duplicate prototypes")
print("Razi-owned Vibrant ring, legacy IDs and static art passed")
