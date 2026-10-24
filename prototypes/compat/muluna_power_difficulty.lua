-- Muluna's platform-power-consumption on Easy, Hard and Nightmare. Muluna
-- reads it in its own data.lua, so the finished satellite radar is scaled by
-- target / saved: power draw, buffer, input limit, the electromagnetic waves
-- it emits, the scan energy of its mod-data and the scan energy in its
-- tooltip, together. Scan area, quality
-- bonuses and every other field stay. Normal and Custom write nothing.
--
-- platform-power-consumption is a double of 0.3..1000 (MW); the values below
-- stay inside.
local M={}
M.values={easy=75,hard=125,nightmare=170}
M.entity="muluna-satellite-radar"
local TOOLTIP="tooltip-value.muluna-satellite-radar-scan-energy"

-- The first value a field had, so a second call never compounds.
local originals=setmetatable({},{__mode="k"})
local function positive(v) return type(v)=="number" and v>0 and v==v and v<math.huge end
local function base_for(t,k)
 local o=originals[t]
 if not o then o={};originals[t]=o end
 local v=o[k]
 if v==nil then v=t[k];o[k]=v end
 return v
end
local function number_text(n) return string.format("%.14g",n) end
local function numeric(t,k,ratio)
 if type(t)~="table" or not positive(t[k]) then return false end
 local v=base_for(t,k)
 if not positive(v) then return false end
 local desired=v*ratio
 if not positive(desired) or t[k]==desired then return false end
 t[k]=desired
 return true
end
-- "100MW" -> "125MW"
local function energy(t,k,ratio)
 if type(t)~="table" or type(t[k])~="string" then return false end
 local raw=base_for(t,k)
 if type(raw)~="string" then return false end
 local text,unit=raw:match("^%s*([%d%.]+)%s*([kMGTPE]?[WJ])%s*$")
 local amount=tonumber(text)
 if not amount or not positive(amount) then return false end
 local desired=string.format("%.8g%s",amount*ratio,unit)
 if t[k]==desired then return false end
 t[k]=desired
 return true
end

-- The scan energy of a quality, from the formula that Muluna publishes in its
-- mod-data (the game evaluates it); the ratio of the shown value otherwise.
local function quality_energy(raw,mod,entity,quality,previous,ratio)
 local level=raw.quality and raw.quality[quality] and raw.quality[quality].level
 local expression=mod.data and mod.data.energy_per_scan_expression
 if type(level)=="number" and type(expression)=="string"
     and helpers and helpers.evaluate_expression then
  local ok,value=pcall(helpers.evaluate_expression,expression,
   {base=entity.energy_per_scan,quality_level=level})
  if ok and positive(value) then return string.format("%.0f",value) end
 end
 return string.format("%.0f",(tonumber(previous) or 0)*ratio)
end

local function tooltip(raw,mod,entity,field,ratio)
 if type(field)~="table" or type(field.value)~="table" then return 0 end
 if field.value[1]~=TOOLTIP or not positive(entity.energy_per_scan) then
  return 0
 end
 local count=0
 local original=base_for(field.value,2)
 if positive(tonumber(original)) then
  local desired=number_text(entity.energy_per_scan)
  if field.value[2]~=desired then field.value[2]=desired;count=count+1 end
 end
 for quality,value in pairs(field.quality_values or {}) do
  if type(value)=="table" and value[1]==TOOLTIP then
   local previous=base_for(value,2)
   if positive(tonumber(previous)) then
    local desired=quality_energy(raw,mod,entity,quality,previous,ratio)
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
 if not target or not enabled["planet-muluna"] then return 0 end
 local saved=startup["platform-power-consumption"]
 local original=saved and saved.value
 if not positive(original) then return 0 end
 local beacon=raw.accumulator and raw.accumulator[M.entity]
 local mod=raw["mod-data"] and raw["mod-data"][M.entity]
 local entity=mod and mod.data and mod.data.entities and
    mod.data.entities[M.entity]
 if not beacon or not entity then return 0 end
 local ratio=target/original
 local count=0
 if energy(beacon,"energy_usage",ratio) then count=count+1 end
 local source=beacon.energy_source
 if energy(source,"buffer_capacity",ratio) then count=count+1 end
 if energy(source,"input_flow_limit",ratio) then count=count+1 end
 if numeric(entity,"energy_per_scan",ratio) then count=count+1 end
 -- Pelagos derives the electromagnetic waves of an accumulator from its
 -- buffer; they follow the buffer.
 local waves=source and source.emissions_per_minute
 if numeric(waves,"electromagnetic_waves",ratio) then count=count+1 end
 if numeric(beacon.emissions_per_second,"electromagnetic_waves",ratio) then
  count=count+1
 end
 -- Only the energy text of the tooltip Muluna wrote and its per-quality
 -- entries; the scan size and every other line stay.
 local fields=beacon.custom_tooltip_fields
 if type(fields)=="table" then
  for _,field in pairs(fields) do count=count+tooltip(raw,mod,entity,field,ratio) end
 end
 if count>0 then
  log("razi-protocol: the "..mode.." level set the power of "..M.entity
   .." to "..target.." MW per scan ("..count.." fields)")
 end
 return count
end

function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end

return M
