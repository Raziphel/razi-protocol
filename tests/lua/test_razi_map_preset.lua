-- Razi curated Nauvis new-game selection, without hijacking Freeplay.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,s) if not v then error(s,2) end end
rawset(_G,"data",{raw={["map-gen-presets"]={default={
 default={default=true,order="a"},
 ["death-world"]={order="d"}}}}})
local engine=require("prototypes.system.razi_map_preset")
check(engine.data_final_fixes(),"Curated preset not installed")
local presets=data.raw["map-gen-presets"].default
local r=presets["razi-protocol"]
check(r and r.order and r.basic_settings.starting_area==1.65,
 "Curated Nauvis setup missing")
check(presets.default.default and presets["death-world"],
 "Native Freeplay map-generation presets were overwritten")
check(r.advanced_settings.enemy_evolution.enabled,
 "Enemy evolution must remain active")
check(r.advanced_settings.difficulty_settings.technology_price_multiplier==1,
 "Normal research should not become a science multiplier trap")
check(not engine.data_final_fixes(),"Map generation preset must be idempotent")
print("RP3 map-generation preset coexists with Freeplay and original presets")
