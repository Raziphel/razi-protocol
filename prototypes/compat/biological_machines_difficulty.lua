-- Biological Machines: Planet Balack on Easy, Hard and Nightmare: crafting
-- speed and pollution of the bio fabricator and of the copies of it that
-- other mods make. Balack reads both settings in its own data.lua, so the
-- finished prototypes are scaled by target / saved. Normal and Custom write
-- nothing.
--
-- Not covered: the research count of Promethium Belts. Its technology has
-- the id of LithiumBattery's (a recommended dependency of Razi), which
-- takes its count from its own setting, so the setting of Promethium Belts
-- does not decide the count where both are installed.
--
-- Limits of the settings: bm-cube-speed double 0.01..100,
-- bm-cube-pollution int 100..1000000.
local M={}
M.profiles={
 easy={
  ["bm-cube-speed"]=1.25,
  ["bm-cube-pollution"]=7500,
 },
 hard={
  ["bm-cube-speed"]=0.85,
  ["bm-cube-pollution"]=16000,
 },
 nightmare={
  ["bm-cube-speed"]=0.65,
  ["bm-cube-pollution"]=25000,
 },
}
-- The first value a field had, so a second call never compounds.
local previous=setmetatable({},{__mode="k"})
local function positive(value)
 return type(value)=="number" and value>0 and value==value
    and value<math.huge
end
local function scale(t,field,ratio)
 if type(t)~="table" or not positive(t[field]) or not positive(ratio) then
  return false
 end
 local captured=previous[t]
 if not captured then captured={};previous[t]=captured end
 local base=captured[field]
 if base==nil then base=t[field];captured[field]=base end
 local target=base*ratio
 if not positive(target) or t[field]==target then return false end
 t[field]=target
 return true
end
-- Balack's recipe category of the bio fabricator.
local function crafts_cubes(machine)
 for _,category in pairs(machine.crafting_categories or {}) do
  if category=="bm-bio-cube" then return true end
 end
 return false
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
 local changed={machine=0,pollution=0}
 if not profile or not enabled["biological-machines-planet-balack"] then
  return changed
 end
 local speed=ratio(startup,"bm-cube-speed",profile["bm-cube-speed"])
 local pollution=ratio(startup,"bm-cube-pollution",
   profile["bm-cube-pollution"])
 -- The bio fabricator and the variants that other mods copy from it (they
 -- copy the finished prototype, so they carry the saved speed and
 -- pollution): every machine that crafts in Balack's category.
 for _,machine in pairs(raw["assembling-machine"] or {}) do
  if type(machine)=="table" and crafts_cubes(machine) then
   if speed and scale(machine,"crafting_speed",speed) then
    changed.machine=changed.machine+1
   end
   local source=machine.energy_source
   local emissions=source and source.emissions_per_minute
   if pollution and scale(emissions,"pollution",pollution) then
    changed.pollution=changed.pollution+1
   end
  end
 end
 if changed.machine+changed.pollution>0 then
  log("razi-protocol: the "..mode.." level scaled the speed of "..changed.machine
   .." bio fabricators and the pollution of "..changed.pollution)
 end
 return changed
end

function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end

return M
