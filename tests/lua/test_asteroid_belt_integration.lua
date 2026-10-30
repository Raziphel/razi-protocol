---@diagnostic disable: need-check-nil, undefined-field, assign-type-mismatch
-- luacheck: ignore 122
-- Razi-owned Vibrant belt geometry, original art and repeated-pass safety.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local layout=require("prototypes.system.galaxy_layout")
local cx,cy=layout.anchor_position("vibrant")
check(cx and math.abs(cx-118)<.01,"Vibrant sun missing or wrong chart radius")
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
for _,entry in ipairs({{inner,30,.670},{outer,40,.690}}) do
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
local ix,iy=xy(inner)
local ox,oy=xy(outer)
check(math.sqrt((ix-ox)^2+(iy-oy)^2)>10,
  "Vibrant Inner and Outer markers must not pile labels together")
check(math.sqrt((ix-ox)^2+(iy-oy)^2)<12,
  "Vibrant markers must straddle the actual rock band, not empty space")
local vinner=math.sqrt((ix-cx)^2+(iy-cy)^2)
local vouter=math.sqrt((ox-cx)^2+(oy-cy)^2)
check(vinner<31 and vinner>=29 and vouter>39 and vouter<=41,
  "Both rim markers must be immediately beside the 31–39 chart-unit debris")
check(math.abs(iy-oy)<2,
  "The surveyed passage should cross the southwest rim without a long diagonal")
check(#layers==5,"Expected three restrained Vibrant belt layers")
for i=1,3 do
  local layer=layers[i]
  check(layer.filename:find("__razi%-protocol__/graphics/starmap/razi/"),
    "Belt still references an upstream mod texture")
  check(math.abs(layer.shift[1]-cx*32)<.01 and
    math.abs(layer.shift[2]-cy*32)<.01,"Decorative ring not sun-centered")
end
check(layers[4].shift[1]==2 and layers[5].shift[1]==37,
  "Original starmap sprites were displaced by the debris layers")
local expected={
  {"belt-vibrant-core.png",.77},
  {"belt-vibrant-scatter.png",.44},
  {"belt-vibrant-dust.png",.33}
}
for i,entry in ipairs(expected) do
  local layer=layers[i]
  check(layer.filename:sub(-#entry[1])==entry[1],
    "Vibrant sprite order must be core, scatter, dust")
  check(math.abs(layer.tint.a-entry[2])<.001,
    "Belt art opacity became too heavy")
  local visual_radius=layer.scale*6
  check(visual_radius>31 and visual_radius<39,
    "Belt artwork moved away from the actual crossing rims")
end
check(layers[1].tint.r>.84 and layers[3].tint.b>.90,
  "Vibrant mineral tint should stay neutral, not purple neon")
belt.data_final_fixes()
check(#layers==5,"Repeated pass added duplicate belt layers")
data.raw["space-location"][outer.name]=nil
belt.data_final_fixes()
check(#layers==5 and inner.orbit,
  "Missing legacy rim should be handled without crashing")
-- Cosmetic toggles affect the artwork only, never the saved coordinates.
for _=1,3 do table.remove(layers,1) end
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
check(#layers==5 and layers[1].filename:find("belt%-vibrant%-core")
  and layers[3].filename:find("belt%-vibrant%-dust"),
  "Belt textures must return in the correct order after re-enabling")
local f=assert(io.open("info.json","r"))
local info=f:read("*a");f:close()
check(info:find('"! AsteroidBelt"',1,true),
  "Original AsteroidBelt must be excluded to avoid duplicate prototypes")
check(info:find('"! kry-asteroid-belt"',1,true),
  "The kry-asteroid-belt mod must be excluded to avoid duplicate prototypes")
print("Vibrant broken-rock field, legacy rims and static sprite controls passed")
