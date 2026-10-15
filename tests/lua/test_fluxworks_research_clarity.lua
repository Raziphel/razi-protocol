-- Run from repository root: lua tests/lua/test_fluxworks_research_clarity.lua
dofile("tests/lua/razi_lib_bootstrap.lua")
-- Proves transitive arrow cleanup changes no effective research dependencies.
local function technology(name,prerequisites)
  return {name=name,prerequisites=prerequisites or {}}
end
local function base()
  return {
    ["fw-a"]=technology("fw-a"),
    ["fw-b"]=technology("fw-b",{"fw-a"}),
    ["fw-c"]=technology("fw-c",{"fw-a","fw-b"}),
    ["fw-d"]=technology("fw-d",{"fw-a","fw-c"}),
    ["fw-e"]=technology("fw-e",{"fw-a","fw-other"}),
    ["fw-other"]=technology("fw-other"),
    ["fw-industrial-district-project"]=technology("fw-industrial-district-project",{"fw-a","fw-b"}),
    ["razi-campaign-gate"]=technology("razi-campaign-gate",{"fw-a","fw-b"}),
  }
end
local function ancestors(techs,start)
  local reached,stack={},{start}
  while #stack>0 do
    local current=stack[#stack]
    stack[#stack]=nil
    if not reached[current] then
      reached[current]=true
      for _,ancestor in ipairs(techs[current].prerequisites or {}) do
        stack[#stack+1]=ancestor
      end
    end
  end
  return reached
end
local techs=base()
local before={}
for name in pairs(techs) do before[name]=ancestors(techs,name) end
_G.data={raw={technology=techs}}
_G.mods={FluxWorks="0.2.14"}
_G.log=function() end
local module=dofile("prototypes/compat/fluxworks_research_clarity.lua")
assert(module.data_final_fixes()==2)
assert(#techs["fw-c"].prerequisites==1 and techs["fw-c"].prerequisites[1]=="fw-b")
assert(#techs["fw-d"].prerequisites==1 and techs["fw-d"].prerequisites[1]=="fw-c")
assert(#techs["fw-e"].prerequisites==2)
assert(#techs["fw-industrial-district-project"].prerequisites==2)
assert(#techs["razi-campaign-gate"].prerequisites==2)
for name in pairs(techs) do
  local after=ancestors(techs,name)
  for node in pairs(before[name]) do
    assert(after[node],"Lost required research "..node.." under "..name)
  end
end
assert(module.data_final_fixes()==0,"Repeated pass should not remove more arrows")
techs=base()
_G.data={raw={technology=techs}}
_G.mods={}
assert(module.data_final_fixes()==0)
assert(#techs["fw-c"].prerequisites==2)
print("FluxWorks tech-tree clarity: safe transitive reduction OK")
