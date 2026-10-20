-- Ensure endgame quality asteroids never hijack SLP plasma encounters.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
package.loaded["scripts.galactic_catalog"]={system=function()
 return "unassigned"
end}
package.loaded["scripts.razi_asteroid_difficulty"]=nil
package.loaded["prototypes.system.quality_asteroids"]=nil
local quality=require("prototypes.system.quality_asteroids")
local native={from="nauvis",to="sun-orbit",length=125000}
local inner={from="sun-orbit",to="close-sun-orbit",length=65000}
local normal={from="nauvis",to="muluna",length=8000}
check(quality.preserve_stellar_source_enemy(native,"slp-plasma-clot"),
 "Outer corona must preserve native Dyson plasma")
check(quality.preserve_stellar_source_enemy(inner,"slp-plasma-clot"),
 "Inner corona must preserve native Dyson plasma")
for _,family in ipairs({"metallic","carbonic","oxide","promethium"}) do
 for _,size in ipairs({"small","medium","big","huge"}) do
  check(not quality.preserve_stellar_source_enemy(inner,
    size.."-"..family.."-asteroid"),
    "Space Age hostile lost quality tier on the corona route")
 end
end
check(not quality.preserve_stellar_source_enemy(normal,"slp-plasma-clot"),
 "Non-stellar routes should retain their existing compatibility behaviour")
print("HELIOS preserves SLP solar plasma and grades vanilla late-game asteroids")
