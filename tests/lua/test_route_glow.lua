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
print("Progression/danger route palette fixtures passed")
