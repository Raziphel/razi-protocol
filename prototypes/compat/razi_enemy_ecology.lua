-- Final world-gen enemy ecology. Nexus deliberately mixes all species,
-- including native Nauvis nests, Gleba pentapods and Vulcanus demolishers.
-- Existing map chunks cannot be changed by prototype edits.
local M={}
local router=require("prototypes.compat.enemy_autoplace")
local difficulty=require("scripts.razi_difficulty_presets")
local by_theme={
  {mod={"ArmouredBiters21Compat","ArmouredBiters"},
    planets={"hyarion","castra","athos","nexus"},
    names={"armoured-biter-spawner"}},
  {mod={"Cold_biters"},
    planets={"aquilo","vesta","frozeta","shchierbin","nexus"},
    names={"cb-cold-spawner"}},
  {mod={"Explosive_biters"},
    planets={"moshine","cubium","corrundum","nexus"},
    names={"explosive-biter-spawner"}},
  {mod={"Toxic_biters"},
    planets={"cubium","vesta","paracelsin","rabbasca","foliax","nexus"},
    names={"toxic-biter-spawner"}},
  {mod={"Arachnids_enemy"},
    planets={"arig","crucible","castra","athos","nexus"},
    names={"arachnid-spawner-unitspawner"}}
}
local function has_mod(group)
 for _,name in ipairs(group) do if mods and mods[name] then return true end end
 return false
end
local function maps(planet)
 local entry=(data.raw.planet or {})[planet]
 return entry and entry.map_gen_settings
end
local function valid_entity(name)
 local e=router.enemy_entity_exists(name)
 return e and router.has_valid_autoplace(e) and e or nil
end
local function land_tiles(map)
 -- Source mods often restrict their enemies to native biome tiles.
 -- Include target-world LAND tiles so their nests can really generate on
 -- new planet mods. Never include lava/ocean/lake or void tiles.
 local available={}
 local tile_settings=map and map.autoplace_settings
   and map.autoplace_settings.tile
   and map.autoplace_settings.tile.settings
 for name in pairs(tile_settings or {}) do
   if (data.raw.tile or {})[name]
     and not name:match("water") and not name:match("ocean")
     and not name:match("lava") and not name:match("lake")
     and not name:match("void") then
     available[#available+1]=name
   end
 end
 table.sort(available)
 return available
end
local function extend_restriction(entity,tiles)
 if not (entity and entity.autoplace and #tiles>0) then return end
 if type(entity.autoplace.tile_restriction)~="table" then return end
 local before=entity.autoplace.tile_restriction
 local seen={}
 for _,name in ipairs(before) do seen[name]=true end
 for _,name in ipairs(tiles) do
   if not seen[name] then before[#before+1]=name;seen[name]=true end
 end
end
local function ensure(planet,name)
 local map=maps(planet)
 if not map then return false end
 local entry=valid_entity(name)
 if not entry then return false end
 map.autoplace_settings=map.autoplace_settings or {}
 map.autoplace_settings.entity=map.autoplace_settings.entity or {}
 local entity=map.autoplace_settings.entity
 entity.settings=entity.settings or {}
 entity.settings[name]=entity.settings[name] or {}
 -- Respect the enemy pack's own autoplace-control prototype. Register its
 -- control on previously unsupported planets rather than trusting that a
 -- copied spawner will use the destination's unrelated enemy-base noise.
 local control=entry.autoplace and entry.autoplace.control
 if type(control)=="string"
   and (data.raw["autoplace-control"] or {})[control] then
   map.autoplace_controls=map.autoplace_controls or {}
   if not map.autoplace_controls[control] then
     map.autoplace_controls[control]={
       frequency=router.pressure(planet),size=1,richness=1}
   end
 end
 extend_restriction(entry,land_tiles(map))
 return true
end
local function nexus()
 local map=maps("nexus")
 if not map then return end
 map.autoplace_controls=map.autoplace_controls or {}
 map.autoplace_settings=map.autoplace_settings or {}
 map.autoplace_settings.entity=map.autoplace_settings.entity or {}
 local entity=map.autoplace_settings.entity
 entity.settings=entity.settings or {}
 local multiplier=router.pressure("nexus")
 local native=maps("nauvis")
 local native_entities=native and native.autoplace_settings
   and native.autoplace_settings.entity
   and native.autoplace_settings.entity.settings or {}
 -- Restore all source vanilla biter/spitter nest and worm entries.
 -- This also heals earlier external integrations that set frequency=0.
 for _,id in ipairs({"biter-spawner","spitter-spawner",
   "small-worm-turret","medium-worm-turret",
   "big-worm-turret","behemoth-worm-turret"}) do
   if valid_entity(id) then
     entity.settings[id]={}
     extend_restriction(valid_entity(id),land_tiles(map))
   end
 end
 map.autoplace_controls["enemy-base"]={
   frequency=multiplier,size=1,richness=1
 }
 -- Native Gleba egg rafts are unit spawners. Copy their actual source
 -- settings only where the source prototype and autoplace are valid.
 local gleba=maps("gleba")
 local eggs=gleba and gleba.autoplace_settings
   and gleba.autoplace_settings.entity
   and gleba.autoplace_settings.entity.settings or {}
 for name in pairs(eggs) do
   if (name=="gleba-spawner" or name=="gleba-spawner-small"
     or name:match("egg%-raft")) and valid_entity(name) then
     ensure("nexus",name)
     local gcontrols=gleba and gleba.autoplace_controls or {}
     for key,val in pairs(gcontrols) do
       if (data.raw["autoplace-control"] or {})[key]
         and map.autoplace_controls[key]==nil then
         map.autoplace_controls[key]=table.deepcopy(val)
       end
     end
   end
 end
 -- Demolishers are segmented territorial units, not biter spawners.
 -- Import the native territory definition rather than inserting fake
 -- spawn entries or running scripted per-tick checks.
 local vulcanus=maps("vulcanus")
 local native_territory=vulcanus and vulcanus.territory_settings
 if not map.territory_settings and native_territory
   and type(native_territory.territory_index_expression)=="string"
   and native_territory.units and #native_territory.units>0 then
   local usable=true
   for _,id in ipairs(native_territory.units) do
     if not (data.raw["segmented-unit"] or {})[id] then
       usable=false;break
     end
   end
   if usable then map.territory_settings=table.deepcopy(native_territory) end
 end
end
function M.data_final_fixes()
 if not router.enabled() then return false end
 for _,group in ipairs(by_theme) do
   if has_mod(group.mod) then
     for _,planet in ipairs(group.planets) do
       for _,id in ipairs(group.names) do
         -- Add validated nests to the actual final planet map prototypes,
         -- not just names in the catalog.
         ensure(planet,id)
       end
     end
   end
 end
 nexus()
 return true
end
return M
