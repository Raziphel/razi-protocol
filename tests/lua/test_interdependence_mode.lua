---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok,why) if not ok then error(why,2) end end
local mode = require("prototypes.compat.interdependence_mode")
rawset(_G,"settings",nil)
check(mode.current()=="balanced" and mode.enabled() and not mode.deep(),
  "Missing setting should retain established behavior")
for _,entry in ipairs({
  {"off",false,false},{"balanced",true,false},{"deep",true,true}
}) do
  rawset(_G,"settings",{startup={
    ["razi-planetary-interdependence"]={value=entry[1]}
  }})
  check(mode.current()==entry[1],"Wrong startup mode")
  check(mode.enabled()==entry[2],"Off must suppress elective research and trade")
  check(mode.deep()==entry[3],"Only Deep may create new recipes")
end
settings.startup["razi-planetary-interdependence"].value="invalid"
check(mode.current()=="balanced","Unknown saved value should fail safe")
rawset(_G,"settings",nil)

local function file(path)
  local f=assert(io.open(path,"r"))
  local contents=f:read("*a"); f:close(); return contents
end
check(file("data-final-fixes.lua"):find(
  'require("prototypes.compat.deep_interdependence").data_final_fixes()',1,true),
  "Deep catalog not registered in final prototype stage")
local industry=file("prototypes/compat/planet_production_exchanges.lua")
check(industry:find("native_amount * rule.batch * 0.30",1,true),
  "Deep yield ceiling missing")
check(industry:find("alternative.allow_productivity = false",1,true),
  "Bonus production must not stack productivity")
local deep=file("prototypes/compat/deep_interdependence.lua")
local count=0
for _ in deep:gmatch('name="razi%-deep%-[^"]+"') do count=count+1 end
check(count==9,"Expected nine distinct Deep recipe profiles")
check(file("prototypes/technology/campaign_weave.lua"):find(
  "not interdependence.enabled()",1,true),"Research mode off not respected")
check(file("prototypes/compat/k2so_planet_integration.lua"):find(
  'require("prototypes.compat.interdependence_mode").enabled()',1,true),
  "K2SO science-card links ignore the Off mode")
print("Interdependence startup modes and deep industry guards passed")
