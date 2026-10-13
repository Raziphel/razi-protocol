-- Route drawing is static and progression/danger driven, not three glows.
package.path="./?.lua;./?/init.lua;"..package.path
local h=require("prototypes.system.route_highlights")
local guide={filename="source-guide.png",size={245,541},
  shift={-100,800},kind="first"}
local safe={from="sye-calidus",to="sye-solaris",
  asteroid_spawn_definitions={}}
local danger={from="sye-calidus",to="sye-solaris",
  asteroid_spawn_definitions={
    {asteroid="big-metallic-asteroid",probability=.08}
  }}
local teal=h.color_for_guide(guide,safe)
assert(teal.g>teal.r and teal.b>teal.r,
  "First chapter travel should be cool turquoise")
guide.kind="middle"
local gold=h.color_for_guide(guide,safe)
assert(gold.r>gold.b and gold.g>gold.b,
  "Middle chapter travel should be warm gold")
guide.kind="outer"
local violet=h.color_for_guide(guide,safe)
assert(violet.b>violet.g and violet.b>violet.r,
  "Outer frontier should be lilac")
guide.kind="first"
local hard=h.color_for_guide(guide,danger)
assert(hard.r>teal.r and hard.g<teal.g,
  "Dangerous routes should shift from turquoise toward red")
local layer=h.layers_for_guide(guide,teal,"subtle")
assert(#layer==1,"Subtle needs one tinted guide, not three beams")
assert(layer[1].filename==guide.filename and layer[1].shift==guide.shift,
  "Guide should align to actual existing route mask")
assert(layer[1].scale==4 and layer[1].tint.a<.6,
  "Subtle overlay should be narrow and restrained")
local clear=h.layers_for_guide(guide,teal,"clear")
assert(#clear==1 and clear[1].tint.a>layer[1].tint.a,
  "Clear mode may brighten but cannot add a second glow")
assert(#h.layers_for_guide(guide,teal,"off")==0,
  "Off should preserve native routes only")
assert(h.field_marker()==nil,"No false middle-route debris portals")
-- Every installed positionable connection, including arcs, must now have
-- shared-atlas segments without needing a hand-authored guide manifest.
local world={
  nauvis={distance=10,orientation=.30},
  ["sye-calidus"]={distance=20,orientation=.50},
  ["sye-solaris"]={origin={x=52,y=90},distance=27,orientation=.75},
  ["sye-vibrant"]={origin={x=104,y=0},distance=28,orientation=.65},
  fulgora={origin={x=104,y=0},distance=22,orientation=.55},
  ribbonia={origin={x=104,y=0},distance=27,orientation=.39}
}
local roads={
  local_early={from="nauvis",to="sye-calidus",shape="arc",
    asteroid_spawn_definitions={}},
  outer_crossing={from="sye-calidus",to="sye-solaris",shape="line",
    asteroid_spawn_definitions={}},
  progression={from="sye-solaris",to="sye-vibrant",shape="line",
    asteroid_spawn_definitions={}},
  native_arc={from="fulgora",to="ribbonia",shape="arc",
    origin={x=104,y=0},asteroid_spawn_definitions={}}
}
rawset(_G,"data",{raw={
  planet={nauvis=world.nauvis,fulgora=world.fulgora,
    ribbonia=world.ribbonia},
  ["space-location"]={
    ["sye-calidus"]=world["sye-calidus"],
    ["sye-solaris"]=world["sye-solaris"],
    ["sye-vibrant"]=world["sye-vibrant"]
  },
  ["space-connection"]=roads,
  ["utility-sprites"]={default={starmap_star={layers={}}}}
}})
rawset(_G,"settings",{startup={
  ["razi-route-highlight-style"]={value="subtle"}}})
rawset(_G,"mods",{})
package.loaded["prototypes.system.galaxy_layout"]={
  anchor_position=function(name)
    local p={solaris={52,90},nyxaris={-52,90},vibrant={104,0},
      vespera={-104,0},beetlejuice={52,-90},
      umbra={-52,-90},["solar-system-edge"]={0,-190}}
    local point=p[name]
    if point then return point[1],point[2] end
  end
}
-- Reload after the fake layout is in place, exercising all-route painting.
package.loaded["prototypes.system.route_highlights"]=nil
local actual=require("prototypes.system.route_highlights")
for _,road in pairs(roads) do
  assert(#actual.strokes_for_connection(road,"subtle")>0,
    "A real source route was left without a coloured stroke")
end
local atlas=data.raw["utility-sprites"].default.starmap_star.layers
actual.data_final_fixes()
assert(#atlas>=4,"All installed routes must receive static coloured segments")
for _,sprite in ipairs(atlas) do
  assert(sprite.filename:find("directional%-strokes",1,false),
    "A new overlay did not use the reusable tiny sprite sheet")
  assert(sprite.x>=0 and sprite.y>=0 and
    sprite.x+sprite.size[1]<=2048 and sprite.y+sprite.size[2]<=2048,
    "One directional atlas crop is outside the texture")
end
local count=#atlas
actual.data_final_fixes()
assert(#atlas==count,"Repeated layout must not duplicate route sprites")
print("Progression/danger route palette and all-route coverage fixtures passed")
