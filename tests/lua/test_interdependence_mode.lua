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
  check(mode.deep()==entry[3],"Only Deep adds the heavier exchanges")
end
settings.startup["razi-planetary-interdependence"].value="invalid" -- luacheck: ignore 122
check(mode.current()=="balanced","Unknown saved value should fail safe")
rawset(_G,"settings",nil)

local function file(path)
  local f=assert(io.open(path,"r"))
  local contents=f:read("*a"); f:close(); return contents
end
local setting=file("settings.lua")
check(setting:find('allowed_values = {"off", "balanced", "deep"}',1,true),
  "The interdependence setting must offer Off, Balanced and Deep")
local industry=file("prototypes/compat/planet_production_exchanges.lua")
check(industry:find("alternative.allow_productivity = false",1,true),
  "Bonus production must not stack productivity")
check(file("prototypes/technology/campaign_weave.lua"):find(
  "not interdependence.enabled()",1,true),"Research mode off not respected")
check(file("prototypes/technology/regional_research_bridges.lua"):find(
  "not interdependence.enabled()",1,true),"Bridges ignore the Off mode")
print("Interdependence startup modes passed")
