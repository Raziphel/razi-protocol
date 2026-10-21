-- Native numeric difficulty for Biological Machines: Planet Balack,
-- plus its optional Promethium Belts companion. Each field is the exact one
-- read from the owning mod's published startup setting. No foreign settings
-- are saved, no recipe toggles, no global machine/technology changes.
local M={}
M.profiles={
 easy={
  ["bm-cube-speed"]=1.25,
  ["bm-cube-pollution"]=7500,
  ["promethium-belt-science-count"]=3000,
  ["promethium-belt-speed"]=120,
 },
 hard={
  ["bm-cube-speed"]=0.85,
  ["bm-cube-pollution"]=16000,
  ["promethium-belt-science-count"]=7500,
  ["promethium-belt-speed"]=90,
 },
 nightmare={
  ["bm-cube-speed"]=0.65,
  ["bm-cube-pollution"]=25000,
  ["promethium-belt-science-count"]=12000,
  ["promethium-belt-speed"]=75,
 },
}
local previous=setmetatable({},{__mode="k"})
local function positive(value)
 return type(value)=="number" and value>0 and value==value
    and value<math.huge
end
local function scale(t,field,ratio,integer)
 if type(t)~="table" or not positive(t[field]) or not positive(ratio) then
  return false
 end
 local captured=previous[t]
 if not captured then captured={};previous[t]=captured end
 local base=captured[field]
 if base==nil then base=t[field];captured[field]=base end
 local target=base*ratio
 if integer then target=math.max(1,math.floor(target+0.5)) end
 if not positive(target) or t[field]==target then return false end
 t[field]=target
 return true
end
local function ratio(startup,setting,target)
 local saved=startup and startup[setting]
 local value=saved and saved.value
 if not positive(value) or not positive(target) then return nil end
 return target/value
end
function M.apply(raw,startup,enabled)
 raw=raw or (data and data.raw) or {}
 startup=startup or (settings and settings.startup) or {}
 enabled=enabled or mods or {}
 local selected=startup["razi-difficulty-preset"]
 local mode=selected and selected.value
 local profile=M.profiles[mode]
 local changed={machine=0,pollution=0,technology=0,belts=0}
 -- Normal and Custom are unconditional NO-OPS, even with manual source edits.
 if not profile then return changed end

 if enabled["biological-machines-planet-balack"] then
  local cube=raw["assembling-machine"] and
    raw["assembling-machine"]["bm-bio-cube"]
  if cube then
   local speed=ratio(startup,"bm-cube-speed",profile["bm-cube-speed"])
   if speed and scale(cube,"crafting_speed",speed) then
    changed.machine=changed.machine+1
   end
   local pollution=ratio(startup,"bm-cube-pollution",
     profile["bm-cube-pollution"])
   local source=cube.energy_source
   local emissions=source and source.emissions_per_minute
   if pollution and scale(emissions,"pollution",pollution) then
    changed.pollution=changed.pollution+1
   end
  end
 end

 -- Promethium Belts is an optional companion to Balack, not an RP hard
 -- requirement. Guard every owner field and prototype independently.
 if enabled["biological-machines-promethium-belts"] then
  local cost=ratio(startup,"promethium-belt-science-count",
    profile["promethium-belt-science-count"])
  local tech=raw.technology and raw.technology["promethium-transport-belt"]
  if cost and tech and scale(tech.unit,"count",cost,true) then
   changed.technology=changed.technology+1
  end
  local speed=ratio(startup,"promethium-belt-speed",
    profile["promethium-belt-speed"])
  if speed then
   for _,type_and_name in ipairs({
    {"transport-belt","promethium-transport-belt"},
    {"underground-belt","promethium-underground-belt"},
    {"splitter","promethium-splitter"},
    {"loader","promethium-loader"},
   }) do
    local group=raw[type_and_name[1]]
    local entity=group and group[type_and_name[2]]
    if entity and scale(entity,"speed",speed) then
     changed.belts=changed.belts+1
    end
   end
  end
 end
 return changed
end
function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end
return M
