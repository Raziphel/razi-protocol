-- Native challenge profiles: pollution, raids, colonies and spoilage.
-- A multiplier of 1 leaves the source numbers alone.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local tuning=require("scripts.razi_difficulty_tuning")
local presets={
 easy={expansion={settler_group_min_size=3,settler_group_max_size=8,
   min_expansion_cooldown=36000,max_expansion_cooldown=300000}},
 normal={expansion={settler_group_min_size=5,settler_group_max_size=10,
   min_expansion_cooldown=36000,max_expansion_cooldown=216000}},
 hard={expansion={settler_group_min_size=6,settler_group_max_size=16,
   min_expansion_cooldown=10800,max_expansion_cooldown=144000}},
 nightmare={expansion={settler_group_min_size=8,settler_group_max_size=20,
   min_expansion_cooldown=9000,max_expansion_cooldown=120000}}
}
local resolver={active=function()return "normal" end,
 effective=function(_,default)return default end}
local base={diffusion_ratio=.02,min_to_diffuse=15}
local raids={max_unit_group_size=200,max_gathering_unit_groups=20,
 min_group_gathering_time=3000,max_group_gathering_time=18000}
local previous_cooldown=math.huge
local expected_spoil={easy=1.4,normal=1,hard=.82,nightmare=.65}
for _,name in ipairs({"easy","normal","hard","nightmare"}) do
 local spec=tuning.profile(name,presets,resolver)
 local planet,groups={},{}
 check(spec.spoil_time_modifier==expected_spoil[name],
  "Native spoil-time modifier did not match "..name)
 tuning.pollution(planet,base,spec)
 tuning.unit_groups(groups,raids,spec)
 check(planet.diffusion_ratio>0 and planet.min_to_diffuse>0,
  "Invalid pollution values on "..name)
 check(groups.max_unit_group_size<=200
   and groups.max_gathering_unit_groups<=24,
   "Native enemy raid caps exceeded on "..name)
 check(spec.expansion.min_expansion_cooldown<previous_cooldown
   or name=="easy",
   "Expansion cooldown did not become harder in "..name)
 if name~="easy" then previous_cooldown=spec.expansion.min_expansion_cooldown end
 if name=="normal" then
  check(groups.max_unit_group_size==200
    and planet.diffusion_ratio==.02 and planet.min_to_diffuse==15,
    "Normal must preserve native pollution and raiding behavior")
  check(spec.expansion.settler_group_max_size==10
    and spec.expansion.min_expansion_cooldown==36000,
    "Normal must preserve the native expansion")
 end
end
-- Normal keeps values that a source mod set outside the usual limits.
local odd_base={diffusion_ratio=.5,min_to_diffuse=.5}
local odd_raids={max_unit_group_size=500,max_gathering_unit_groups=40,
 min_group_gathering_time=90000,max_group_gathering_time=60000}
local normal=tuning.profile("normal",presets,resolver)
local odd_planet,odd_groups={},{}
tuning.pollution(odd_planet,odd_base,normal)
tuning.unit_groups(odd_groups,odd_raids,normal)
check(odd_planet.diffusion_ratio==.5 and odd_planet.min_to_diffuse==.5,
 "Normal changed pollution values outside the usual limits")
check(odd_groups.max_unit_group_size==500
 and odd_groups.max_gathering_unit_groups==40
 and odd_groups.min_group_gathering_time==90000
 and odd_groups.max_group_gathering_time==60000,
 "Normal changed raid values outside the usual limits")
-- A profile without expansion numbers is left without them.
local bare=tuning.profile("normal",{normal={}},resolver)
check(bare.expansion==nil,"A missing expansion must stay missing")
local custom={active=function()return "custom" end,
 effective=function(name,default)
  if name=="razi-pollution-pressure" then return "toxic" end
  if name=="razi-raid-coordination" then return "siege" end
  if name=="razi-colony-expansion" then return "invasive" end
  if name=="razi-spoilage-pressure" then return "brutal" end
  return default
 end}
local overridden=tuning.profile("normal",presets,custom)
check(overridden.pollution_tuning.diffusion==1.32
 and overridden.raid_tuning.size==1.27
 and overridden.spoil_time_modifier==.65
 and overridden.expansion.min_expansion_cooldown==25200
 and overridden.expansion.settler_group_max_size==12,
 "Manual Custom gameplay options were not applied")
check(presets.normal.expansion.min_expansion_cooldown==36000,
 "The difficulty resolver mutated the original source profile")
print("Pollution, raids, colonies and Custom difficulty fixture passed")
