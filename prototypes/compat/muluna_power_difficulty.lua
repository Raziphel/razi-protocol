-- Exact numeric Muluna source option: platform-power-consumption.
-- Correct ALL related native satellite-radar fields consistently after Muluna
-- builds its prototype, mod-data and late quality tooltips. No broad power
-- balancing, settings writes, feature toggles, or global platform changes.
local M={}
M.values={easy=75,hard=125,nightmare=170}
local originals=setmetatable({},{__mode="k"})
local function positive(v) return type(v)=="number" and v>0 and v==v and v<math.huge end
local function base_for(t,k)
 local o=originals[t]
 if not o then o={};originals[t]=o end
 local v=o[k]
 if v==nil then v=t[k];o[k]=v end
 return v
end
local function numeric(t,k,ratio)
 if type(t)~="table" or not positive(t[k]) then return false end
 local v=base_for(t,k)
 if not positive(v) then return false end
 local desired=v*ratio
 if not positive(desired) or t[k]==desired then return false end
 t[k]=desired
 return true
end
local function energy(t,k,ratio)
 if type(t)~="table" or type(t[k])~="string" then return false end
 local raw=base_for(t,k)
 if type(raw)~="string" then return false end
 local amount,unit=raw:match("^%s*([%d%.]+)%s*([kMGTPE]?[WJ])%s*$")
 amount=tonumber(amount)
 if not positive(amount) then return false end
 local desired=string.format("%.8g%s",amount*ratio,unit)
 if t[k]==desired then return false end
 t[k]=desired
 return true
end
local function tooltip(t,ratio)
 if type(t)~="table" or type(t.value)~="table" then return 0 end
 if t.value[1]~="tooltip-value.muluna-satellite-radar-scan-energy" then
  return 0
 end
 local count=0
 local original=base_for(t.value,2)
 if type(original)=="string" and positive(tonumber(original)) then
  local desired=tostring(tonumber(original)*ratio)
  if t.value[2]~=desired then t.value[2]=desired;count=count+1 end
 end
 for _,value in pairs(t.quality_values or {}) do
  if type(value)=="table" and
     value[1]=="tooltip-value.muluna-satellite-radar-scan-energy" then
   local previous=base_for(value,2)
   if type(previous)=="string" and positive(tonumber(previous)) then
    local desired=string.format("%.0f",tonumber(previous)*ratio)
    if value[2]~=desired then value[2]=desired;count=count+1 end
   end
  end
 end
 return count
end
function M.apply(raw,startup,enabled)
 raw=raw or (data and data.raw) or {}
 startup=startup or (settings and settings.startup) or {}
 enabled=enabled or mods or {}
 local diff=startup["razi-difficulty-preset"]
 local mode=diff and diff.value
 local target=M.values[mode]
 -- Normal and Custom are *absolute* no-ops, no matter the saved source value.
 if not target or not enabled["planet-muluna"] then return 0 end
 local saved=startup["platform-power-consumption"]
 local original=saved and saved.value
 if not positive(original) then return 0 end
 local beacon=raw.accumulator and raw.accumulator["muluna-satellite-radar"]
 local mod=raw["mod-data"] and raw["mod-data"]["muluna-satellite-radar"]
 local entity=mod and mod.data and mod.data.entities and
    mod.data.entities["muluna-satellite-radar"]
 if not beacon or not entity then return 0 end
 local ratio=target/original
 local count=0
 if energy(beacon,"energy_usage",ratio) then count=count+1 end
 local source=beacon.energy_source
 if energy(source,"buffer_capacity",ratio) then count=count+1 end
 if energy(source,"input_flow_limit",ratio) then count=count+1 end
 if numeric(entity,"energy_per_scan",ratio) then count=count+1 end
 -- The native source pass already authored a corresponding custom tooltip.
 -- Update only its energy text and existing per-quality entries; scan area
 -- and every non-energy tooltip remain unmodified.
 local fields=beacon.custom_tooltip_fields
 if type(fields)=="table" then
  for _,field in pairs(fields) do count=count+tooltip(field,ratio) end
 end
 return count
end
function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end
return M
