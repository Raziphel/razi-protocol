-- Native-first route styling: normal travel gets no fake halo.
package.path="./?.lua;./?/init.lua;"..package.path
local h=require("prototypes.system.route_highlights")
local guide={filename="source-guide.png",size={245,541},
  shift={-100,800},kind="middle"}
local hazard={r=.3,g=.7,b=.9}
assert(#h.layers_for_guide(guide,hazard,"subtle")==0,
  "Subtle routes should be the exact native Factorio geometry")
assert(#h.layers_for_guide(guide,hazard,"off")==0,
  "Off must not create guide art")
local layers=h.layers_for_guide(guide,hazard,"clear")
assert(#layers==1,"Clear routes need only one accurate stroke")
assert(layers[1].filename==guide.filename and layers[1].shift==guide.shift,
  "Native-aligned guide mask identity changed")
assert(layers[1].scale==4,"Guide mask geometry no longer matches native route")
assert(layers[1].tint.a<.5,"Clear guide should not dominate planet labels")
guide.kind="belt"
local belt=h.layers_for_guide(guide,hazard,"clear")
assert(belt[1].tint.a>layers[1].tint.a,
  "A verified asteroid crossing gets slightly more emphasis")
guide.kind="first"
local first=h.layers_for_guide(guide,hazard,"clear")
assert(first[1].tint.a<layers[1].tint.a,
  "Early exploration lanes should remain softer")
assert(not h.field_marker({
  from="sye-solaris",to="sye-vibrant",start={20,30},finish={60,50}
},"clear"),"Fuzzy midpoint debris graphic must be removed")
print("Native-first route styling passed")
