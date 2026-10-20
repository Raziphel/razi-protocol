-- RP3 selectable world generation profiles with one safe auto-selected entry.
-- Factorio 2.1 forbids basic_settings/advanced_settings on a default=true
-- preset. A Razi default marker therefore reads prototype baseline settings,
-- while explicitly named profiles provide complete, editable map-gen values.
-- No post-start world mutations; previews remain honest.
local M={}
local diff=require("scripts.razi_difficulty_presets")
local keys={"iron-ore","copper-ore","coal","stone","uranium-ore",
 "crude-oil","water","trees","enemy-base"}
M.profiles={
 easy={starting_area=2.55,enemy=.48,resources=1.45,oil=1.48,
  evolution={time_factor=.0000014,destroy_factor=.0015,
   pollution_factor=.00000045},
  expansion={min_expansion_distance=3,max_expansion_distance=8,
   settler_group_min_size=3,settler_group_max_size=8,
   min_expansion_cooldown=36000,max_expansion_cooldown=300000},
  research=1},
 normal={starting_area=1.65,enemy=.85,resources=1.20,oil=1.20,
  evolution={time_factor=.000004,destroy_factor=.002,
   pollution_factor=.0000009},
  expansion={min_expansion_distance=2,max_expansion_distance=7,
   settler_group_min_size=5,settler_group_max_size=12,
   min_expansion_cooldown=14400,max_expansion_cooldown=216000},
  research=1},
 hard={starting_area=1.15,enemy=1.35,resources=.90,oil=.95,
  evolution={time_factor=.000009,destroy_factor=.0025,
   pollution_factor=.0000012},
  expansion={min_expansion_distance=2,max_expansion_distance=8,
   settler_group_min_size=6,settler_group_max_size=16,
   min_expansion_cooldown=10800,max_expansion_cooldown=144000},
  research=1.25},
 nightmare={starting_area=.90,enemy=1.75,resources=.80,oil=.85,
  evolution={time_factor=.000015,destroy_factor=.0030,
   pollution_factor=.0000015},
  expansion={min_expansion_distance=2,max_expansion_distance=9,
   settler_group_min_size=8,settler_group_max_size=20,
   min_expansion_cooldown=9000,max_expansion_cooldown=120000},
  research=1.75}
}
local function copy(v)
 if table.deepcopy then return table.deepcopy(v) end
 if type(v)~="table" then return v end
 local out={}
 for key,value in pairs(v) do out[key]=copy(value) end
 return out
end
local function control_entries(spec)
 -- Never replace source-controlled mapgen entries absent from the world.
 local out={}
 for _,key in ipairs(keys) do
   local entry
   if key=="enemy-base" then
     entry={frequency=spec.enemy,size=1,richness=1}
   elseif key=="water" then
     entry={frequency=1,size=1}
   elseif key=="trees" then
     entry={frequency=1.08,size=1.05}
   else
     local level=key=="crude-oil" and spec.oil or spec.resources
     entry={frequency=key=="uranium-ore" and .85 or 1,
       size=1.05,richness=level}
   end
   out[key]=entry
 end
 return out
end
local function explicit_preset(mode,spec)
 return {
   order="01[razi]-"..mode,
   basic_settings={
     starting_area=spec.starting_area,
     peaceful_mode=false,
     autoplace_controls=control_entries(spec)
   },
   advanced_settings={
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
       max_expansion_cooldown=spec.expansion.max_expansion_cooldown
     },
     difficulty_settings={technology_price_multiplier=spec.research}
   }
 }
end
M.explicit_preset=explicit_preset
function M.active_mode()
 local selected=diff.active()
 return M.profiles[selected] and selected or "normal"
end
function M.set_world_defaults(mode)
 local profile=M.profiles[mode] or M.profiles.normal
 local raw=data.raw
 -- Default advanced settings come from the map-settings prototype, not
 -- from a map-gen preset. Never overwrite the original difficulty preset.
 local settings_map=(raw["map-settings"] or {})["map-settings"]
 if settings_map then
   for _,field in ipairs({"enemy_evolution","enemy_expansion"}) do
     local target=settings_map[field]
     if target then
       for key,value in pairs(profile[field=="enemy_evolution"
         and "evolution" or "expansion"]) do target[key]=value end
     end
   end
 end
 -- Nauvis's planet prototype owns the *basic* source mapgen defaults.
 -- Only patch existing, valid controls, leaving unrelated planet-specific
 -- generation, resources, custom noise and source-mod additions intact.
 local nauvis=(raw.planet or {}).nauvis
 local map=nauvis and nauvis.map_gen_settings
 local controls=map and map.autoplace_controls
 if controls then
   for name,values in pairs(control_entries(profile)) do
     if (not raw["autoplace-control"] or raw["autoplace-control"][name])
       and controls[name] then
       for key,value in pairs(values) do controls[name][key]=value end
     end
   end
 end
 return true
end
function M.data_final_fixes()
 local raw=data and data.raw
 local group=raw and (raw["map-gen-presets"] or {}).default
 if not group then return false end
 -- Keep all five explicit profiles. Custom is a fresh editable Normal
 -- starting point, never a forced mutation of other mods' saved settings.
 for _,mode in ipairs({"easy","normal","hard","nightmare"}) do
   group["razi-protocol-"..mode]=explicit_preset(mode,M.profiles[mode])
 end
 group["razi-protocol-custom"]=explicit_preset("custom",M.profiles.normal)
 -- Preserve other mods' chosen default (if any) rather than setting two
 -- default=true entries. This avoids a startup validation conflict.
 local autoselect=settings and settings.startup
   and settings.startup["razi-default-new-game-map"]
 local enabled=not autoselect or autoselect.value~=false
 if enabled then
   local competing=false
   for name,preset in pairs(group) do
     if name~="default" and name~="razi-protocol"
       and type(preset)=="table" and preset.default==true then
       competing=true
       break
     end
   end
   if not competing then
     -- Default selection may carry only default=true and order in 2.1.
     -- We keep the vanilla "Default" option selectable as a named preset.
     if group.default and group.default.default==true then
       group.default.default=nil
     end
     group["razi-protocol"]={default=true,order="00[razi-default]"}
     M.set_world_defaults(M.active_mode())
   end
 end
 return true
end
return M
