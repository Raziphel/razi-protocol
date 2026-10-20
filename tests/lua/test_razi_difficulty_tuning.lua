-- Native challenge profiles, resolved Custom and performance guards.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local tuning=require("scripts.razi_difficulty_tuning")
local presets={
 easy={expansion={settler_group_min_size=3,settler_group_max_size=8,
   min_expansion_cooldown=36000,max_expansion_cooldown=300000}},
 normal={expansion={settler_group_min_size=5,settler_group_max_size=12,
   min_expansion_cooldown=14400,max_expansion_cooldown=216000}},
 hard={expansion={settler_group_min_size=6,settler_group_max_size=16,
   min_expansion_cooldown=10800,max_expansion_cooldown=144000}},
 nightmare={expansion={settler_group_min_size=8,settler_group_max_size=20,
   min_expansion_cooldown=9000,max_expansion_cooldown=120000}}
}
local resolver={active=function()return "normal" end,
 effective=function(name,default)return default end}
local base={diffusion_ratio=.02,min_to_diffuse=15}
local raids={max_unit_group_size=200,max_gathering_unit_groups=20,
 min_group_gathering_time=3000,max_group_gathering_time=18000}
local previous_cooldown=math.huge
for _,name in ipairs({"easy","normal","hard","nightmare"}) do
 local spec=tuning.profile(name,presets,resolver)
 local planet,groups={},{}
 tuning.pollution(planet,base,spec)
 tuning.unit_groups(groups,raids,spec)
 check(planet.diffusion_ratio>0 and planet.min_to_diffuse>0,
  "Invalid pollution values on "..name)
 check(groups.max_unit_group_size<=200
   and groups.max_gathering_unit_groups<=24,
   "Native enemy raid caps exceeded on "..name)
 check(spec.expansion.min_expansion_cooldown<previous_cooldown,
   "Expansion cooldown did not become harder in "..name)
 previous_cooldown=spec.expansion.min_expansion_cooldown
 if name=="normal" then
  check(groups.max_unit_group_size==200
    and planet.diffusion_ratio==.02,
    "Normal must preserve native pollution and raiding behavior")
 end
end
local custom={active=function()return "custom" end,
 effective=function(name,default)
  if name=="razi-pollution-pressure" then return "toxic" end
  if name=="razi-raid-coordination" then return "siege" end
  if name=="razi-colony-expansion" then return "invasive" end
  return default
 end}
local overridden=tuning.profile("normal",presets,custom)
check(overridden.pollution_tuning.diffusion==1.32
 and overridden.raid_tuning.size==1.27
 and overridden.expansion.min_expansion_cooldown<14400,
 "Manual Custom gameplay options were not applied")
check(presets.normal.expansion.min_expansion_cooldown==14400,
 "The difficulty resolver mutated the original source profile")
print("RP3 pollution, raids, colonies and Custom difficulty fixture passed")
