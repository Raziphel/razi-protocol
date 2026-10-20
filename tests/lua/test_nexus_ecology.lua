-- Endgame Nexus: source nests and Gleba rafts, no vanilla suppression.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(a,b) if not a then error(b,2) end end
-- Factorio supplies table.deepcopy in the data stage. Provide an equivalent
-- for this pure Lua fixture, so the source prototype is demonstrably cloned.
table.deepcopy=table.deepcopy or function(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[k]=table.deepcopy(v) end
  return out
end
local function tile_map()
 return {map_gen_settings={autoplace_controls={
   ["enemy-base"]={frequency=1}},
   autoplace_settings={entity={settings={}},tile={settings={
     ["grass-1"]={},["sand-1"]={},["water"]={}}}}}}
end
local native=function()
 return {autoplace={control="enemy-base",
   probability_expression="enemy_autoplace_base(0, 6)"},result_units={}}
end
rawset(_G,"settings",{startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["razi-enable-enemy-routing"]={value=true}}})
rawset(_G,"mods",{})
rawset(_G,"data",{raw={
 planet={nexus=tile_map(),nauvis=tile_map(),gleba=tile_map(),
   vulcanus=tile_map()},
 tile={["grass-1"]={},["sand-1"]={},["water"]={}},
 ["unit-spawner"]={
   ["biter-spawner"]=native(),["spitter-spawner"]=native(),
   ["gleba-spawner"]=native(),["gleba-spawner-small"]=native()
 },
 turret={["small-worm-turret"]=native()},
 ["segmented-unit"]={["small-demolisher"]={}},
 ["autoplace-control"]={["enemy-base"]={}}
},extend=function(_,elements)
 for _,proto in ipairs(elements) do
   data.raw[proto.type]=data.raw[proto.type] or {}
   check(not data.raw[proto.type][proto.name],"duplicate prototype")
   data.raw[proto.type][proto.name]=proto
 end
end})
data.raw.planet.gleba.map_gen_settings.autoplace_settings.entity.settings={
 ["gleba-spawner"]={},["gleba-spawner-small"]={}
}
data.raw.planet.vulcanus.map_gen_settings.territory_settings={
 units={"small-demolisher"},
 territory_index_expression="vulcanus_demolisher_territory",
 territory_variation_expression="vulcanus_demolisher_variation"
}
package.loaded["prototypes.compat.enemy_autoplace"]=nil
package.loaded["prototypes.compat.razi_enemy_ecology"]=nil
local router=require("prototypes.compat.enemy_autoplace")
router.disable_vanilla_enemies_on_planet("nexus")
local eco=require("prototypes.compat.razi_enemy_ecology")
check(eco.data_final_fixes(),"Nexus ecology final pass didn't run")
local planet=data.raw.planet.nexus.map_gen_settings
local units=planet.autoplace_settings.entity.settings
check(units["biter-spawner"] and units["spitter-spawner"],
 "Nexus must preserve vanilla Nauvis biters")
check(units["razi-nexus-gleba-spawner"]
 and units["razi-nexus-gleba-spawner-small"],
 "Nexus must actually register native pentapod egg-raft types")
check(data.raw["unit-spawner"]["razi-nexus-gleba-spawner"]~=nil,
 "Pentapod spawner clone prototype must exist")
check(planet.territory_settings.units[1]=="small-demolisher",
 "Native Vulcanus demolisher territory list must be copied")
check(data.raw["unit-spawner"]["gleba-spawner"].name==nil,
 "Native Gleba spawner should not be mutated")
print("Nexus native biters, real pentapod spawners and demolisher territory pass")
