-- The final, additive and planet-scoped enemy ecology pass.
-- Source nest prototypes are NEVER given union-of-galaxy tile restrictions:
-- the same nest may be native to a very different biome elsewhere.
-- Static, deterministic placement only; no per-tick spawning controller.
local M={}
local router=require("prototypes.compat.enemy_autoplace")
local by_theme={
 {mod={"ArmouredBiters21Compat","ArmouredBiters"},
  planets={"hyarion","crucible","castra","athos","ferrum","obsidiax","nexus"},
  names={"armoured-biter-spawner"},
  habitat={"dirt","rock","sand","stone","soil","crystal","ash","volcan","slag"}},
 {mod={"Cold_biters"},
  planets={"aquilo","frozeta","shchierbin","vesta","muria","bm-balack","nexus"},
  names={"cb-cold-spawner","small-cold-worm-turret",
    "medium-cold-worm-turret","big-cold-worm-turret"},
  habitat={"ice","snow","frost","crystal","cold","dust"}},
 {mod={"Explosive_biters"},
  planets={"moshine","cubium","corrundum","crucible","obsidiax","nexus"},
  names={"explosive-biter-spawner","small-explosive-worm-turret",
    "medium-explosive-worm-turret","big-explosive-worm-turret"},
  habitat={"ash","volcan","crack","dirt","stone","rock","sand","dust","slag"}},
 {mod={"Toxic_biters"},
  planets={"cubium","vesta","paracelsin","rabbasca","foliax",
    "gleba","velora","alchemy-planet","crucible","nexus"},
  names={"toxic-biter-spawner","small-toxic-worm-turret",
    "medium-toxic-worm-turret","big-toxic-worm-turret"},
  habitat={"soil","mud","swamp","grass","dirt","rock","fung",
    "forest","ash","volcan","sand","dust","crust"}},
 {mod={"Arachnids_enemy"},
  planets={"arig","crucible","castra","athos","panglia","tenebris","nexus"},
  names={"arachnid-spawner-unitspawner"},
  habitat={"sand","dirt","soil","grass","desert","rock","ash","stone"}},
 {mod={"Electric_flying_enemies"},
  planets={"corrundum","ribbonia","fulgora","ferrum","cerys",
    "alchemy-planet","nexus"},
  names={"flying-electric-unit-spawner","walker-electric-unit-spawner",
    "fulgoran-enemy-spawner","electric-flying-enemy-spawner",
    "electric-flying-enemies-spawner","electric-enemy-spawner",
    "fulgoran-replicator","fulgoran-unit-replicator"},
  habitat={"fulgor","electric","conduit","metal","machine","scrap",
    "rock","dust","dirt","sand","soil","stone"}}
}
M.by_theme=by_theme
local function has_mod(names)
 for _,name in ipairs(names) do if mods and mods[name] then return true end end
 return false
end
local function maps(name)
 local proto=(data.raw.planet or {})[name]
 return proto and proto.map_gen_settings
end
local function source_entity(name)
 local kinds={"unit-spawner","turret"}
 for _,kind in ipairs(kinds) do
  local e=(data.raw[kind] or {})[name]
  if e and router.has_valid_autoplace(e) then return e,kind end
 end
end
local function is_land(name)
 local low=name:lower()
 for _,fragment in ipairs({"water","ocean","lava","ammoniacal",
   "molten","void","out-of-map","empty-space","space-platform",
   "deepwater","abyss","bottomless","acid-lake","oil-sea",
   "ribbonia-gap","ribbonia-void","brash-ice"}) do
  if low:find(fragment,1,true) then return false end
 end
 return true
end
local function land_tiles(map,habitat)
 local tiles=map and map.autoplace_settings
   and map.autoplace_settings.tile
   and map.autoplace_settings.tile.settings or {}
 local all,preferred={},{}
 for name in pairs(tiles) do
  if (data.raw.tile or {})[name] and is_land(name) then
   all[#all+1]=name
   if habitat then
    for _,fragment in ipairs(habitat) do
     if name:lower():find(fragment,1,true) then
      preferred[#preferred+1]=name
      break
     end
    end
   end
  end
 end
 table.sort(all)
 table.sort(preferred)
 -- If the planet mod uses uncommon tile names, using all known land is
 -- preferable to silently producing zero nests or putting nests on oceans.
 return #preferred>0 and preferred or all
end
M.land_tiles=land_tiles
local function entity_settings(map)
 map.autoplace_settings=map.autoplace_settings or {}
 map.autoplace_settings.entity=map.autoplace_settings.entity or {}
 local entity=map.autoplace_settings.entity
 entity.settings=entity.settings or {}
 return entity.settings
end
local function put(planet,name,kind,habitat,seed,weight)
 local map=maps(planet)
 local source,actual_kind=source_entity(name)
 if not (map and source and (not kind or kind==actual_kind)) then return false end
 local tiles=land_tiles(map,habitat)
 if #tiles==0 then return false end
 local id="razi-"..planet.."-"..name
 local registry=data.raw[actual_kind] or {}
 if not registry[id] then
  local clone=table.deepcopy(source)
  clone.name=id
  clone.type=actual_kind
  clone.autoplace={
   control="enemy-base",
   order="z[razi-ecology]-"..name,
   force="enemy",
   probability_expression=string.format(
     "enemy_autoplace_base(0, %d) * %.3f",seed,weight),
   richness_expression=1,
   tile_restriction=tiles
  }
  data:extend({clone})
 end
 local settings=entity_settings(map)
 settings[id]=settings[id] or {}
 -- If this pack previously registered the shared original spawner on the
 -- same planet, retire only that mapgen entry to prevent double spawning.
 settings[name]=nil
 map.autoplace_controls=map.autoplace_controls or {}
 if (data.raw["autoplace-control"] or {})["enemy-base"]
   and not map.autoplace_controls["enemy-base"] then
  map.autoplace_controls["enemy-base"]={
    frequency=router.pressure(planet),size=1,richness=1}
 end
 return true
end
M.put=put
local function ensure(planet,name)
 -- Used only for a fully formed Nexus-only clone, not a shared source
 -- prototype whose tile restriction would otherwise be changed globally.
 local map=maps(planet)
 if not (map and source_entity(name)) then return false end
 local settings=entity_settings(map)
 settings[name]=settings[name] or {}
 return true
end
-- Gleba's original egg-raft noise may depend on its own biome.
-- Clone the source spawner ONLY for Nexus, with valid general enemy noise.
-- This retains its actual pentapod units, source art, AI and death effects;
-- no new per-tick spawning controller or changes to vanilla Gleba.
local function nexus_pentapod_raft(name,map)
 local base=(data.raw["unit-spawner"] or {})[name]
 if not router.has_valid_autoplace(base) then return false end
 local tiles=land_tiles(map,{"grass","dirt","soil","rock","sand"})
 if #tiles==0 then return false end
 local id="razi-nexus-"..name
 if (data.raw["unit-spawner"] or {})[id] then return ensure("nexus",id) end
 local nest=table.deepcopy(base)
 nest.name=id
 nest.type="unit-spawner"
 nest.autoplace={
   control="enemy-base",
   order="z[razi-nexus]-"..name,
   force="enemy",
   probability_expression=name=="gleba-spawner-small"
     and "enemy_autoplace_base(0, 25) * 0.15"
     or "enemy_autoplace_base(0, 26) * 0.10",
   richness_expression=1,
   tile_restriction=tiles
 }
 data:extend({nest})
 return ensure("nexus",id)
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
 -- Preserve native Nauvis enemies through Nexus-only spawn variants.
 -- This also heals earlier external integrations that set frequency=0.
 for index,id in ipairs({"biter-spawner","spitter-spawner",
   "small-worm-turret","medium-worm-turret",
   "big-worm-turret","behemoth-worm-turret"}) do
   local kind=id:find("spawner",1,true) and "unit-spawner" or "turret"
   if not put("nexus",id,kind,{"grass","dirt","soil","sand",
     "rock","stone"},80+index*11,.12) then
     -- Source IDs are still valid fallback when a map has no usable
     -- tile settings. Never mutate their tile restrictions globally.
     if source_entity(id) then entity.settings[id]=entity.settings[id] or {} end
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
     or name:match("egg%-raft")) and source_entity(name) then
     if not nexus_pentapod_raft(name,map) then
       -- Source-version fallback, still keeping vanilla Gleba intact.
       ensure("nexus",name)
     end
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
 local installed=0
 for family,group in ipairs(by_theme) do
   if has_mod(group.mod) then
     for world,planet in ipairs(group.planets) do
       for index,id in ipairs(group.names) do
         local is_worm=id:find("worm",1,true)~=nil
         local chance=is_worm and .034 or .085
         -- Only the first two worm sizes appear away from Nexus.
         -- Other worlds should not receive endgame-class worm nests at
         -- game start by bypassing the pack's original evolution curve.
         -- Nexus is the everything-spawns endgame and gets every tier.
         local available=not is_worm or index<=3 or planet=="nexus"
         if planet=="nexus" then chance=chance*1.22 end
         if available and put(planet,id,
           is_worm and "turret" or "unit-spawner",
           group.habitat,110+family*130+world*13+index,
           chance) then installed=installed+1 end
       end
     end
   end
 end
 nexus()
 return installed
end
return M
