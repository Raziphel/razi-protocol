-- Factorio 2.1 world profiles for all compatible resource/enemy controls.
-- The active named Razi profile is the auto-selected default marker.
-- A default=true preset must not contain basic/advanced settings, so its
-- real values are placed in the game/planet prototype defaults at data stage.
-- Other modes carry fully editable MapGenPreset fields.
local M={}
local difficulty=require("scripts.razi_difficulty_presets")
local tuning=require("scripts.razi_difficulty_tuning")
local economy=require("scripts.razi_economy_difficulty")
M.profiles={
 easy={starting_area=2.55,resource={frequency=1.30,size=1.30,richness=1.55},
  oil=1.62,enemy={frequency=.48,size=.72},water=1.25,trees=1.28,
  cliffs=.72,asteroids=.78,pollution_ageing=1.2,attack_consumption=1.3,
  evolution={time_factor=.0000014,destroy_factor=.0015,
    pollution_factor=.00000045},
  expansion={min_expansion_distance=3,max_expansion_distance=8,
    settler_group_min_size=3,settler_group_max_size=8,
    min_expansion_cooldown=36000,max_expansion_cooldown=300000},
  research=1},
 normal={starting_area=1.65,resource={frequency=1.05,size=1.08,richness=1.20},
  oil=1.2,enemy={frequency=.85,size=1},water=1,trees=1.05,
  cliffs=1,asteroids=1,pollution_ageing=1,attack_consumption=1,
  evolution={time_factor=.000004,destroy_factor=.002,
    pollution_factor=.0000009},
  expansion={min_expansion_distance=2,max_expansion_distance=7,
    settler_group_min_size=5,settler_group_max_size=12,
    min_expansion_cooldown=14400,max_expansion_cooldown=216000},
  research=1},
 hard={starting_area=1.15,resource={frequency=.82,size=.85,richness=.75},
  oil=.82,enemy={frequency=1.35,size=1.18},water=.87,trees=.85,
  cliffs=1.14,asteroids=1.08,pollution_ageing=.90,attack_consumption=.88,
  evolution={time_factor=.000009,destroy_factor=.0025,
    pollution_factor=.0000012},
  expansion={min_expansion_distance=2,max_expansion_distance=8,
    settler_group_min_size=6,settler_group_max_size=16,
    min_expansion_cooldown=10800,max_expansion_cooldown=144000},
  research=1.25},
 nightmare={starting_area=.90,resource={frequency=.68,size=.75,richness=.60},
  oil=.65,enemy={frequency=1.70,size=1.28},water=.78,trees=.70,
  cliffs=1.28,asteroids=1.12,pollution_ageing=.82,attack_consumption=.78,
  evolution={time_factor=.000015,destroy_factor=.0030,
    pollution_factor=.0000015},
  expansion={min_expansion_distance=2,max_expansion_distance=9,
    settler_group_min_size=8,settler_group_max_size=20,
    min_expansion_cooldown=9000,max_expansion_cooldown=120000},
  research=1.75}
}
local function deepcopy(v)
 if type(v)~="table" then return v end
 local result={}
 for key,child in pairs(v) do result[key]=deepcopy(child) end
 return result
end
local function number(v)
 if type(v)=="number" then return v end
 local known={none=0,["very-low"]=.33,low=.5,normal=1,
   high=2,["very-high"]=3,["very-good"]=4,good=2}
 return known[v]
end
local function scaled(base,factor)
 local value=number(base)
 if value==nil then return nil end
 -- Zero means deliberately absent: do not enable a forbidden resource
 -- on another planet or override a source-owned terrain restriction.
 if value<=0 then return 0 end
 return math.max(0,math.min(6,value*factor))
end
local function control_kind(id,proto)
 if not proto then return nil end
 local category=proto.category
 if category=="resource" then return "resource" end
 if category=="enemy" then return "enemy" end
 if category=="cliff" then return "cliff" end
 if category=="terrain" and (id=="water" or id=="trees") then
   return id
 end
 return nil
end
local function multiplier(spec,kind,key,id)
 if kind=="resource" then
   if key=="richness" and (id=="crude-oil" or id:find("oil",1,true)) then
     return spec.oil
   end
   return spec.resource[key]
 elseif kind=="enemy" then
   if key=="richness" then return nil end
   return spec.enemy[key]
 elseif kind=="cliff" then
   return key=="frequency" and spec.cliffs or nil
 elseif kind=="water" then
   return key=="frequency" and spec.water or nil
 elseif kind=="trees" then
   return key=="frequency" and spec.trees or nil
 end
end
-- Read only real registered resource/enemy controls, including all optional
-- planet ores, scrap, asteroid surface minerals and modded biter species.
-- Terrain noise (except trees/water) and scripted enemy factories are not
-- generic ore patches; keep the owning mod's climate/territory mechanics.
function M.control_entries(mode)
 local spec=economy.profile(mode,tuning.profile(mode,M.profiles,difficulty),difficulty)
 local out={}
 for id,proto in pairs((data.raw["autoplace-control"] or {})) do
   local kind=control_kind(id,proto)
   if kind then
     local entry={}
     for _,key in ipairs({"frequency","size","richness"}) do
       if not (key=="richness" and proto.richness==false) then
         local factor=multiplier(spec,kind,key,id)
         if factor then entry[key]=factor end
       end
     end
     if next(entry) then out[id]=entry end
   end
 end
 return out
end
-- Capture original planet controls once: applying the final pass twice must
-- not multiply the controls a second time. Keep zero-valued controls zero.
local originals=setmetatable({},{__mode="k"})
local original_map_settings=setmetatable({},{__mode="k"})
function M.scale_planets(mode)
 local spec=economy.profile(mode,tuning.profile(mode,M.profiles,difficulty),difficulty)
 local count=0
 local controls=(data.raw["autoplace-control"] or {})
 for name,planet in pairs(data.raw.planet or {}) do
   local map=planet.map_gen_settings
   if map and type(map.autoplace_controls)=="table" then
     local original=originals[map]
     if not original then
       original=deepcopy(map.autoplace_controls)
       originals[map]=original
     end
     for id,initial in pairs(original) do
       local proto=controls[id]
       local kind=control_kind(id,proto)
       if kind and type(initial)=="table" then
         local current=map.autoplace_controls[id]
         for _,key in ipairs({"frequency","size","richness"}) do
           local factor=multiplier(spec,kind,key,id)
           if factor and (key~="richness" or proto.richness~=false) then
             local value=scaled(initial[key] or 1,factor)
             if value~=nil then current[key]=value end
           end
         end
         count=count+1
       end
     end
   end
 end
 return count
end
local function advanced(mode)
 local spec=economy.profile(mode,tuning.profile(mode,M.profiles,difficulty),difficulty)
 return {
  enemy_evolution={enabled=true,
    time_factor=spec.evolution.time_factor,
    destroy_factor=spec.evolution.destroy_factor,
    pollution_factor=spec.evolution.pollution_factor},
  enemy_expansion={
    enabled=true,
    min_expansion_distance=spec.expansion.min_expansion_distance,
    max_expansion_distance=spec.expansion.max_expansion_distance,
    settler_group_min_size=spec.expansion.settler_group_min_size,
    settler_group_max_size=spec.expansion.settler_group_max_size,
    min_expansion_cooldown=spec.expansion.min_expansion_cooldown,
    max_expansion_cooldown=spec.expansion.max_expansion_cooldown},
  difficulty_settings={technology_price_multiplier=spec.research}
 }
end
function M.explicit_preset(mode)
 local spec=economy.profile(mode,tuning.profile(mode,M.profiles,difficulty),difficulty)
 local entry={
  order="01[razi]-"..mode,
  basic_settings={
   starting_area=spec.starting_area,
   peaceful_mode=false,
   autoplace_controls=M.control_entries(mode)},
  advanced_settings=advanced(mode)
 }
 -- Pollution and asteroid rate are part of the Advanced tab as well.
 -- Use source prototype baselines for a consistent, predictable multiplier.
 local active=(data.raw["map-settings"] or {})["map-settings"]
 local source=active and (original_map_settings[active] or active)
 if source then
   if source.pollution then
     local ageing=source.pollution.ageing
     local consume=source.pollution.enemy_attack_pollution_consumption_modifier
     entry.advanced_settings.pollution={}
     -- Only diffusion_ratio exists on MapGenPresetPollutionSettings.
     -- min_to_diffuse belongs to global MapSettings, not map presets.
     tuning.pollution(entry.advanced_settings.pollution,
       source.pollution,spec)
     entry.advanced_settings.pollution.min_to_diffuse=nil
     if type(ageing)=="number" then
       entry.advanced_settings.pollution.ageing=
         math.max(.1,ageing*spec.pollution_ageing)
     end
     if type(consume)=="number" then
       entry.advanced_settings.pollution.enemy_attack_pollution_consumption_modifier=
         math.max(.1,consume*spec.attack_consumption)
     end
   end
   if source.asteroids and type(source.asteroids.spawning_rate)=="number" then
     entry.advanced_settings.asteroids={
       spawning_rate=source.asteroids.spawning_rate*spec.asteroids}
   end
 end
 return entry
end
function M.active_mode()
 local name=difficulty.active()
 return M.profiles[name] and name or "normal"
end
function M.set_world_defaults(mode)
 local spec=economy.profile(mode,tuning.profile(mode,M.profiles,difficulty),difficulty)
 local source=(data.raw["map-settings"] or {})["map-settings"]
 if source then
   local original=original_map_settings[source]
   if not original then original=deepcopy(source);original_map_settings[source]=original end
   local result=advanced(mode)
   -- Factorio's DifficultySettings has a spoil-time modifier, but named
   -- MapGenPresetDifficultySettings does not expose this field. Apply only
   -- in the world defaults so existing source mod recipes remain intact.
   if source.difficulty_settings then
     local original_difficulty=original.difficulty_settings or {}
     local baseline=original_difficulty.spoil_time_modifier or 1
     source.difficulty_settings.spoil_time_modifier=
       math.max(.01,math.min(100,baseline*spec.spoil_time_modifier))
   end
   for _,field in ipairs({"enemy_evolution","enemy_expansion",
     "difficulty_settings"}) do
     if source[field] then
       for key,value in pairs(result[field]) do source[field][key]=value end
     end
   end
   if source.pollution and original.pollution then
     tuning.pollution(source.pollution,original.pollution,spec)
     for field,multiplier_value in pairs({
       ageing=spec.pollution_ageing,
       enemy_attack_pollution_consumption_modifier=spec.attack_consumption
     }) do
       if type(original.pollution[field])=="number" then
         source.pollution[field]=math.max(.1,
           original.pollution[field]*multiplier_value)
       end
     end
   end
   -- Native engine attack organization (no per-tick AI controller).
   if source.unit_group and original.unit_group then
     tuning.unit_groups(source.unit_group,original.unit_group,spec)
   end
   if source.asteroids and original.asteroids
      and type(original.asteroids.spawning_rate)=="number" then
     source.asteroids.spawning_rate=
       original.asteroids.spawning_rate*spec.asteroids
   end
 end
 -- Every loaded planet, not just Nauvis. Existing map-gen controls only:
 -- don't enable disabled resource slots or modify a planet's noise rules.
 M.scale_planets(mode)
end
function M.data_final_fixes()
 local group=data.raw["map-gen-presets"]
   and data.raw["map-gen-presets"].default
 if not group then return false end
 -- Drop obsolete "Recommended (Auto)" and the duplicate Custom map preset.
 group["razi-protocol"]=nil
 group["razi-protocol-custom"]=nil
 local selected=M.active_mode()
 local auto=settings and settings.startup
   and settings.startup["razi-default-new-game-map"]
 local autoselect=not auto or auto.value~=false
 local competing=false
 for name,preset in pairs(group) do
   if name~="default" and not name:match("^razi%-protocol%-")
      and type(preset)=="table" and preset.default==true then
     competing=true
   end
 end
 for _,mode in ipairs({"easy","normal","hard","nightmare"}) do
   local name="razi-protocol-"..mode
   if autoselect and not competing and mode==selected then
     -- In Factorio 2.1 a default=true entry cannot carry any mapgen data.
     group[name]={order="00[razi-default]",default=true}
   else
     group[name]=M.explicit_preset(mode)
   end
 end
 if autoselect and not competing then
   if group.default then group.default.default=nil end
   M.set_world_defaults(selected)
 end
 return true
end
return M
