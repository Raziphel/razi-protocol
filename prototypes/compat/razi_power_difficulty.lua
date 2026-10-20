-- All ordinary solar panels and accumulators, including modded ones.
-- Does not modify foreign mod settings, reactors, Dyson scripts or solar rules.
local M={}
local resolver=require("scripts.razi_difficulty_presets")
M.factors={robust=1.20,normal=1,limited=.90,precarious=.80}
local originals=setmetatable({},{__mode="k"})
local function scaled_energy(value,factor)
 if type(value)=="number" then
   return value>0 and value*factor or nil
 end
 if type(value)~="string" then return nil end
 local number,prefix,unit=value:match("^%s*([%d%.]+)%s*([kMGTPE]?)([WJ])%s*$")
 number=tonumber(number)
 if not number or number<=0 then return nil end
 return string.format("%.6g%s%s",number*factor,prefix,unit)
end
M.scale_energy=scaled_energy
local function adjust(owner,key,factor)
 if type(owner)~="table" then return false end
 local record=originals[owner]
 if not record then record={};originals[owner]=record end
 local initial=record[key]
 if initial==nil then
   initial=owner[key]
   if scaled_energy(initial,1)==nil then return false end
   record[key]=initial
 end
 local target=factor==1 and initial or scaled_energy(initial,factor)
 if target==nil or owner[key]==target then return false end
 owner[key]=target
 return true
end
function M.apply(raw,difficulty)
 raw=raw or {}
 difficulty=difficulty or resolver
 local mode=difficulty.effective("razi-grid-resilience","normal")
 local factor=M.factors[mode] or 1
 local affected={solar_panels=0,accumulators=0}
 for _,proto in pairs(raw["solar-panel"] or {}) do
   if adjust(proto,"production",factor) then
     affected.solar_panels=affected.solar_panels+1
   end
 end
 for _,proto in pairs(raw.accumulator or {}) do
   local source=proto.energy_source
   if type(source)=="table" and source.type=="electric" then
     if adjust(source,"buffer_capacity",factor) then
       affected.accumulators=affected.accumulators+1
     end
   end
 end
 return affected
end
function M.data_final_fixes()
 return M.apply(data.raw,resolver)
end
return M
