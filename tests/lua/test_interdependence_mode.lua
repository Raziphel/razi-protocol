---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok,why) if not ok then error(why,2) end end
local mode = require("prototypes.compat.interdependence_mode")
rawset(_G,"settings",nil)
check(mode.current()=="balanced" and mode.enabled(),
  "Missing setting should retain established behavior")
for _,entry in ipairs({{"off",false},{"balanced",true},{"deep",true}}) do
  rawset(_G,"settings",{startup={
    ["razi-planetary-interdependence"]={value=entry[1]}
  }})
  check(mode.current()==(entry[1]=="off" and "off" or "balanced"),"Wrong startup mode")
  check(mode.enabled()==entry[2],"Off must suppress elective research")
end
settings.startup["razi-planetary-interdependence"].value="invalid"
check(mode.current()=="balanced","Unknown saved value should fail safe")
rawset(_G,"settings",nil)

local function file(path)
  local f=assert(io.open(path,"r"))
  local contents=f:read("*a"); f:close(); return contents
end
check(file("prototypes/technology/campaign_weave.lua"):find(
  "not interdependence.enabled()",1,true),"Research mode off not respected")
check(file("prototypes/technology/regional_research_bridges.lua"):find(
  "not interdependence.enabled()",1,true),"Bridges ignore the Off mode")
print("Interdependence startup modes passed")
