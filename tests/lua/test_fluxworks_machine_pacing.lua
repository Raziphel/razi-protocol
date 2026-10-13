-- Run from repo root with Lua 5.2+:
-- lua tests/lua/test_fluxworks_machine_pacing.lua
local caps={
  ["fw-flux-yellow-catalysis"]={220,180,35},
  ["fw-flux-stabilization"]={260,210,35},
  ["fw-harvester-systems"]={320,250,35},
  ["fw-flux-red-energetics"]={320,260,40},
  ["fw-flux-metallurgy"]={580,460,40},
  ["fw-flux-green-cultivation"]={860,690,45},
  ["fw-flux-phase-engineering"]={980,820,55},
  ["fw-cross-planetary-industrial-convergence"]={2200,1760,65},
}
local techs={}
for name,values in pairs(caps) do
  techs[name]={
    prerequisites={"space-science-pack","another-source-tech"},
    effects={{type="unlock-recipe",recipe="fw-original-recipe"}},
    unit={count=values[1],time=70,
      ingredients={{"chemical-science-pack",1},{"space-science-pack",1}}}
  }
end
techs["razi-main-gate"]={unit={count=1000,time=60,ingredients={{"space-science-pack",1}}}}
techs["fw-industrial-district-project"]={unit={count=300,time=45,ingredients={{"fw-industrial-methods-science-pack",1}}}}
_G.data={raw={technology=techs}}
_G.mods={FluxWorks="0.2.14"}
_G.log=function() end
local p=dofile("prototypes/compat/fluxworks_machine_pacing.lua")
assert(p.data_final_fixes()==8)
for name,v in pairs(caps) do
  local t=techs[name]
  assert(t.unit.count==v[2],name..": count ceiling")
  assert(t.unit.time==v[3],name..": time ceiling")
  assert(t.prerequisites[1]=="space-science-pack" and #t.prerequisites==2)
  assert(#t.unit.ingredients==2 and #t.effects==1)
end
assert(techs["razi-main-gate"].unit.count==1000)
assert(techs["fw-industrial-district-project"].unit.count==300)
assert(p.data_final_fixes()==0,"Second pass should not repeatedly reduce costs")

-- Other mods are allowed to reduce a tech below our ceiling.
techs["fw-flux-stabilization"].unit.count=125
techs["fw-flux-stabilization"].unit.time=20
assert(p.data_final_fixes()==0)
assert(techs["fw-flux-stabilization"].unit.count==125)
assert(techs["fw-flux-stabilization"].unit.time==20)

_G.mods={}
techs["fw-flux-metallurgy"].unit.count=580
assert(p.data_final_fixes()==0)
assert(techs["fw-flux-metallurgy"].unit.count==580)
print("FluxWorks machine pacing: eight optional research ceilings and all prerequisites OK")
