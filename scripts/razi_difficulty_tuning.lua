-- Difficulty of native pollution flow, raids and hostile colonies.
-- Pure and prototype-stage only; no runtime event registrations or scans.
local M={}
local function deepcopy(value)
 if type(value)~="table" then return value end
 local copy={}
 for key,v in pairs(value) do copy[key]=deepcopy(v) end
 return copy
end
local pollution={
 gentle={diffusion=.72,threshold=1.45},
 normal={diffusion=1,threshold=1},
 heavy={diffusion=1.18,threshold=.82},
 toxic={diffusion=1.32,threshold=.67}
}
local raids={
 small={size=.74,groups=.78,wait=1.24},
 normal={size=1,groups=1,wait=1},
 organized={size=1.12,groups=1.10,wait=.90},
 siege={size=1.27,groups=1.16,wait=.82}
}
local colonies={
 slow={settlers=.78,cooldown=1.5},
 normal={settlers=1,cooldown=1},
 rapid={settlers=1.15,cooldown=.83},
 invasive={settlers=1.22,cooldown=.70}
}
local spoilage={forgiving=1.4,normal=1,fast=.82,brutal=.65}
local named={
 easy={"gentle","small","slow","forgiving"},
 normal={"normal","normal","normal","normal"},
 hard={"heavy","organized","rapid","fast"},
 nightmare={"toxic","siege","invasive","brutal"}
}
M.named=named
local function rounded(n) return math.max(1,math.floor(n+.5)) end
function M.profile(mode,profiles,resolver)
 local spec=deepcopy(profiles[mode] or profiles.normal)
 local ids=named[mode] or named.normal
 local function choose(index,key)
  if mode=="normal" and resolver.active()=="custom" then
   return resolver.effective(key,ids[index])
  end
  return ids[index]
 end
 spec.pollution_tuning=pollution[choose(1,"razi-pollution-pressure")]
   or pollution.normal
 spec.raid_tuning=raids[choose(2,"razi-raid-coordination")]
   or raids.normal
 spec.spoil_time_modifier=spoilage[choose(4,"razi-spoilage-pressure")]
   or spoilage.normal
 local colony=colonies[choose(3,"razi-colony-expansion")]
   or colonies.normal
 for _,field in ipairs({"settler_group_min_size",
                        "settler_group_max_size"}) do
  spec.expansion[field]=rounded(spec.expansion[field]*colony.settlers)
 end
 for _,field in ipairs({"min_expansion_cooldown",
                        "max_expansion_cooldown"}) do
  spec.expansion[field]=rounded(spec.expansion[field]*colony.cooldown)
 end
 return spec
end
function M.pollution(target,baseline,spec)
 if not (target and baseline) then return end
 for field,factor in pairs({
   diffusion_ratio=spec.pollution_tuning.diffusion,
   min_to_diffuse=spec.pollution_tuning.threshold
 }) do
  local v=baseline[field]
  if type(v)=="number" then
   target[field]=field=="diffusion_ratio"
     and math.min(.2,math.max(0,v*factor))
     or math.max(1,v*factor)
  end
 end
end
function M.unit_groups(target,baseline,spec)
 if not (target and baseline) then return end
 local mode=spec.raid_tuning
 local fields={
  max_unit_group_size={mode.size,200},
  max_gathering_unit_groups={mode.groups,24},
  min_group_gathering_time={mode.wait,60000},
  max_group_gathering_time={mode.wait,120000}
 }
 for field,rule in pairs(fields) do
  local value=baseline[field]
  if type(value)=="number" then
   -- Never unexpectedly lower a source mod's limits in Normal mode.
   target[field]=rule[1]==1 and value
     or math.min(rule[2],rounded(value*rule[1]))
  end
 end
 if target.min_group_gathering_time
   and target.max_group_gathering_time then
  target.min_group_gathering_time=math.min(
    target.min_group_gathering_time,target.max_group_gathering_time)
 end
end
return M
