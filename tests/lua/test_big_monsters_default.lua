-- Check RP3's Big-Monsters *default* override without forcing saved values.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
local path="settings-final-fixes.lua"
local function run(installed,prototype)
  rawset(_G,"mods",installed and {["Big-Monsters"]="2.2.1"} or {})
  rawset(_G,"data",{raw={["int-setting"]={}}})
  if prototype then data.raw["int-setting"]["bm-event-days"]=prototype end
  dofile(path)
  return prototype
end
local normal={setting_type="runtime-global",default_value=6,
  minimum_value=0,maximum_value=20}
run(true,normal)
check(normal.default_value==0,"New Big-Monsters saves should start at zero")
check(normal.forced_value==nil and not normal.hidden,
  "RP3 must not force or hide the original adjustable setting")
local absent={setting_type="runtime-global",default_value=6,
  minimum_value=0,maximum_value=20}
run(false,absent)
check(absent.default_value==6,"Missing optional Big-Monsters must be ignored")
local different={setting_type="runtime-global",default_value=6,
  minimum_value=1,maximum_value=20}
run(true,different)
check(different.default_value==6,"Never set an out-of-range default")
local wrong_type={setting_type="startup",default_value=6,
  minimum_value=0,maximum_value=20}
run(true,wrong_type)
check(wrong_type.default_value==6,"Don't rewrite unrelated setting types")
run(true,nil)
print("Big-Monsters new-game default is 0; existing values stay player-owned")
