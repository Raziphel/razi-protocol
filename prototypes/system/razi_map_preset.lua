-- World profiles for all compatible resource/enemy controls.
-- Normal is the plain game: it writes nothing, so a world on Normal is the
-- world of a pack without difficulty levels. Easy, Hard and Nightmare scale
-- the controls of every planet and the global map settings. Curated is a
-- fifth profile (a ready-made, slightly richer start) that is only offered in
-- the New Game list and never applied by itself.
-- The active level is the auto-selected default marker.
-- A default=true preset must not contain basic/advanced settings, so its
-- real values are placed in the game/planet prototype defaults at data stage.
-- Other profiles carry fully editable MapGenPreset fields.
local M={}
local difficulty=require("scripts.razi_difficulty_presets")
local tuning=require("scripts.razi_difficulty_tuning")
local economy=require("scripts.razi_economy_difficulty")
-- Profile order in the New Game list.
M.modes={"easy","normal","hard","nightmare","curated"}
-- A profile without `evolution` or `expansion` keeps the values of the
-- map-settings prototype (Normal), so the numbers of the game version in use
-- are never copied here.
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
 normal={starting_area=1,resource={frequency=1,size=1,richness=1},
  oil=1,enemy={frequency=1,size=1},water=1,trees=1,
  cliffs=1,asteroids=1,pollution_ageing=1,attack_consumption=1,
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
  research=1.75},
 curated={starting_area=1.65,resource={frequency=1.05,size=1.08,richness=1.20},
  oil=1.2,enemy={frequency=.85,size=1},water=1,trees=1.05,
  cliffs=1,asteroids=1,pollution_ageing=1,attack_consumption=1,
  evolution={time_factor=.000004,destroy_factor=.002,
    pollution_factor=.0000009},
  expansion={min_expansion_distance=2,max_expansion_distance=7,
    settler_group_min_size=5,settler_group_max_size=12,
    min_expansion_cooldown=14400,max_expansion_cooldown=216000},
  research=1}
}
local EVOLUTION_FIELDS={"time_factor","destroy_factor","pollution_factor"}
local EXPANSION_FIELDS={"min_expansion_distance","max_expansion_distance",
 "settler_group_min_size","settler_group_max_size",
 "min_expansion_cooldown","max_expansion_cooldown"}
-- A control value above this is not raised by a profile unless the source
-- value is already higher.
local CONTROL_CAP=6
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
-- The scaled value of a control. The cap only stops a value that would newly
-- cross it: a source value that is already above the cap (a steam geyser
-- with richness 150) is scaled like any other and never cut down.
local function scaled(base,factor)
 local value=number(base)
 if value==nil then return nil end
 -- Zero means deliberately absent: do not enable a forbidden resource
 -- on another planet or override a source-owned terrain restriction.
 if value<=0 then return 0 end
 local result=value*factor
 if value<=CONTROL_CAP and result>CONTROL_CAP then result=CONTROL_CAP end
 return math.max(0,result)
end
M.scaled=scaled
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
-- Oil controls (crude-oil, offshore-oil, aquilo_crude_oil, heavy-oil-geyser)
-- but not rich-soil.
local function multiplier(spec,kind,key,id)
 if kind=="resource" then
   if key=="richness" and (id:find("^oil") or id:find("[^%a]oil")) then
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
-- The map-settings prototype as the game and the other mods left it, taken
-- once: applying the world defaults twice must not compound, and Normal
-- needs the untouched numbers.
local original_map_settings=setmetatable({},{__mode="k"})
local function map_settings()
 return (data.raw["map-settings"] or {})["map-settings"]
end
local function original_settings()
 local source=map_settings()
 if not source then return nil end
 local original=original_map_settings[source]
 if not original then
  original=deepcopy(source)
  original_map_settings[source]=original
 end
 return original
end
local function pick(source,fields)
 if type(source)~="table" then return nil end
 local result
 for _,field in ipairs(fields) do
  if type(source[field])=="number" then
   result=result or {}
   result[field]=source[field]
  end
 end
 return result
end
-- The profiles with the evolution and expansion values that a profile leaves
-- out taken from the map-settings prototype.
local function completed_profiles()
 local profiles=deepcopy(M.profiles)
 local base=original_settings()
 if base then
  for _,profile in pairs(profiles) do
   profile.evolution=profile.evolution
     or pick(base.enemy_evolution,EVOLUTION_FIELDS)
   profile.expansion=profile.expansion
     or pick(base.enemy_expansion,EXPANSION_FIELDS)
  end
 end
 return profiles
end
local function resolve(mode,resolver)
 return economy.profile(
   tuning.profile(mode,completed_profiles(),resolver),resolver)
end
-- A resolver that reads only the level `mode`, for the New Game list: a
-- listed profile shows its own level whichever level is active.
local function level_resolver(mode)
 local levels=difficulty.presets
 local level=levels[mode] or levels.normal
 return {
  active=function() return mode end,
  is_overridden=function() return false end,
  effective=function(name,fallback)
   if level[name]~=nil then return level[name] end
   return fallback
  end
 }
end
-- Read only real registered resource/enemy controls, including all optional
-- planet ores, scrap, asteroid surface minerals and modded biter species.
-- Terrain noise (except trees/water) and scripted enemy factories are not
-- generic ore patches; keep the owning mod's climate/territory mechanics.
-- A factor of exactly 1 is left out: the planet keeps its own value.
function M.control_entries(mode,spec)
 spec=spec or resolve(mode,level_resolver(mode))
 local out={}
 for id,proto in pairs((data.raw["autoplace-control"] or {})) do
   local kind=control_kind(id,proto)
   if kind then
     local entry={}
     for _,key in ipairs({"frequency","size","richness"}) do
       if not (key=="richness" and proto.richness==false) then
         local factor=multiplier(spec,kind,key,id)
         if factor and factor~=1 then entry[key]=factor end
       end
     end
     if next(entry) then out[id]=entry end
   end
 end
 return out
end
-- Capture original planet controls once: applying the final pass twice must
-- not multiply the controls a second time. Keep zero-valued controls zero
-- and leave every control with a factor of 1 as the source mod wrote it.
local originals=setmetatable({},{__mode="k"})
function M.scale_planets(mode)
 local spec=resolve(mode,difficulty)
 local count=0
 local controls=(data.raw["autoplace-control"] or {})
 for _,planet in pairs(data.raw.planet or {}) do
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
           if factor and factor~=1
             and (key~="richness" or proto.richness~=false) then
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
local function advanced(spec)
 local result={
  difficulty_settings={technology_price_multiplier=spec.research}
 }
 if spec.evolution then
  result.enemy_evolution={enabled=true}
  for _,field in ipairs(EVOLUTION_FIELDS) do
   result.enemy_evolution[field]=spec.evolution[field]
  end
 end
 if spec.expansion then
  result.enemy_expansion={enabled=true}
  for _,field in ipairs(EXPANSION_FIELDS) do
   result.enemy_expansion[field]=spec.expansion[field]
  end
 end
 return result
end
function M.explicit_preset(mode)
 local spec=resolve(mode,level_resolver(mode))
 local index=1
 for i,name in ipairs(M.modes) do if name==mode then index=i end end
 local entry={
  order="01[razi]-"..index..mode,
  basic_settings={
   starting_area=spec.starting_area,
   peaceful_mode=false,
   autoplace_controls=M.control_entries(mode,spec)},
  advanced_settings=advanced(spec)
 }
 -- Pollution and asteroid rate are part of the Advanced tab as well.
 -- Use source prototype baselines for a consistent, predictable multiplier.
 local source=original_settings()
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
 -- The New Game selector must reflect the actual startup choice. Custom has
 -- its own visible default marker; its baseline mapgen remains Normal, while
 -- individual saved gameplay overrides are resolved by the difficulty layer.
 local name=difficulty.selected()
 if name=="custom" then return "custom" end
 return M.profiles[name] and name or "normal"
end
-- Writes `value` only when it differs, so a field that is already right (or
-- absent on Normal) is never created or rewritten.
local function put(target,field,value)
 if type(target)=="table" and value~=nil and target[field]~=value then
  target[field]=value
 end
end
function M.set_world_defaults(mode)
 local source=map_settings()
 local original=original_settings()
 if source and original then
   local spec=resolve(mode,difficulty)
   for _,field in ipairs(EVOLUTION_FIELDS) do
     put(source.enemy_evolution,field,spec.evolution
       and spec.evolution[field])
   end
   for _,field in ipairs(EXPANSION_FIELDS) do
     put(source.enemy_expansion,field,spec.expansion
       and spec.expansion[field])
   end
   put(source.difficulty_settings,"technology_price_multiplier",spec.research)
   -- Factorio's DifficultySettings has a spoil-time modifier, but named
   -- MapGenPresetDifficultySettings does not expose this field. Apply only
   -- in the world defaults so existing source mod recipes remain intact.
   if source.difficulty_settings and spec.spoil_time_modifier~=1 then
     local original_difficulty=original.difficulty_settings or {}
     local baseline=original_difficulty.spoil_time_modifier or 1
     source.difficulty_settings.spoil_time_modifier=
       math.max(.01,math.min(100,baseline*spec.spoil_time_modifier))
   end
   if source.pollution and original.pollution then
     tuning.pollution(source.pollution,original.pollution,spec)
     for field,multiplier_value in pairs({
       ageing=spec.pollution_ageing,
       enemy_attack_pollution_consumption_modifier=spec.attack_consumption
     }) do
       if type(original.pollution[field])=="number"
         and multiplier_value~=1 then
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
      and type(original.asteroids.spawning_rate)=="number"
      and spec.asteroids~=1 then
     source.asteroids.spawning_rate=
       original.asteroids.spawning_rate*spec.asteroids
   end
 end
 -- Every loaded planet, not just Nauvis. Existing map-gen controls only:
 -- don't enable disabled resource slots or modify a planet's noise rules.
 M.scale_planets(mode)
end
-- Opting in to "Select Razi's map preset by default" gives Razi control of
-- the initial selector even if another mod advertises a default (their
-- presets remain available). Factorio allows exactly one active default, so
-- the flag of every other preset is removed, and a default=true entry
-- cannot also contain map-generation settings.
function M.claim_default(group,mode)
 local key="razi-protocol-"..mode
 for id,preset in pairs(group) do
   if type(preset)=="table" and preset.default==true then
     preset.default=nil
     if log and id~=key then
       log("razi-protocol: map preset "..tostring(id)
         .." is no longer the default of New Game")
     end
   end
 end
 group[key]={order="00[razi-default]",default=true}
 return key
end
function M.data_final_fixes()
 local group=data.raw["map-gen-presets"]
   and data.raw["map-gen-presets"].default
 if not group then return false end
 -- Remove only the old "Recommended (Auto)" compatibility alias. The
 -- Custom marker is rebuilt below only if the player actually selects it.
 group["razi-protocol"]=nil
 group["razi-protocol-custom"]=nil
 local selected=M.active_mode()
 local auto=settings and settings.startup
   and settings.startup["razi-default-new-game-map"]
 local autoselect=not auto or auto.value~=false
 -- Always provide the editable Razi profiles. The selected level becomes a
 -- lightweight default marker only when auto-selection is on.
 for _,mode in ipairs(M.modes) do
   group["razi-protocol-"..mode]=M.explicit_preset(mode)
 end
 if autoselect then
   M.claim_default(group,selected)
   -- Custom still honors saved Razi gameplay controls via the Normal
   -- world-generation baseline. This does not override source mod settings.
   M.set_world_defaults(selected=="custom" and "normal" or selected)
 end
 -- When disabled, leave every other mod's default flag untouched. Razi's
 -- selectable profiles remain available but are never forced as defaults.
 return true
end
return M
