-- Freight progression must not acquire additional, redundant science
-- requirements after prototype registration.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
local module=require("prototypes.technology.planetary_science_weave")
check(type(module.data_final_fixes)=="function","Compatibility entry point missing")
check(#module.rules==0,"Old additional planetary science rules must be retired")
local techs={
  ["razi-network-precision-matrix"]={
    prerequisites={"planet-discovery-moshine","planet-discovery-paracelsin"},
    unit={ingredients={{"chemical-science-pack",1},{"production-science-pack",1}}}},
  ["razi-network-umbra-pressure-frame"]={
    prerequisites={"planet-discovery-crucible","planet-discovery-vesta"},
    unit={ingredients={{"production-science-pack",1},{"utility-science-pack",1}}}}
}
local function copy(t)
  if type(t)~="table" then return t end
  local result={}
  for k,v in pairs(t) do result[k]=copy(v) end
  return result
end
data={raw={technology=techs}}
local old=copy(techs)
check(module.data_final_fixes()==0,"Retired research weaving should be inert")
check(module.data_final_fixes()==0,"Repeated research pass should be inert")
for name,node in pairs(techs) do
  for key,v in pairs(node) do
    local function equal(a,b)
      if type(a)~=type(b) then return false end
      if type(a)~="table" then return a==b end
      for k,x in pairs(a) do if not equal(x,b[k]) then return false end end
      for k in pairs(b) do if a[k]==nil then return false end end
      return true
    end
    check(equal(v,old[name][key]),
      "Old science weave must not edit "..name.."."..key)
  end
end
local f=assert(io.open("data-final-fixes.lua","r"))
local src=f:read("*a"); f:close()
check(src:find('require("prototypes.technology.planetary_science_weave").data_final_fixes()',1,true),
  "Stable compatibility entrypoint must remain")
print("Planetary research: no previous-star science card tax or late weaving")
