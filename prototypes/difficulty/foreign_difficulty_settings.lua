-- Numeric startup settings of other mods, as the difficulty level would have
-- them. Easy, Hard and Nightmare put the value of the level into the data
-- stage view of the setting (settings.startup) from Razi's data.lua until the
-- end of its data-final-fixes.lua, so the data-updates.lua and
-- data-final-fixes.lua of those mods read the value of the level. Normal and
-- Custom write nothing.
--
-- Not the saved value: mod-settings.dat, the settings window and the runtime
-- see the saved value again once restore() has run.
--
-- Reach: Razi loads after the data.lua of the mods it requires, so a setting
-- that a mod reads in its own data.lua is out of reach here. Those are
-- corrected on the finished prototypes by foreign_numeric_stage_effects.lua,
-- muluna_power_difficulty.lua and biological_machines_difficulty.lua. Only
-- settings with a reader after Razi's data.lua are listed below; never add
-- a setting just because it exists.
local M={}

-- The values stay inside the limits of each setting:
--   space-science-pack-output                 int    1..10
--   muluna-interstellar-science-pack-packs-required   int >= 1
--   ...-dynamic-packs-required-percentage-required    double 1..100
--   rubia-tech-cost-multiplier                int    1..69420
M.profiles={
 easy={
  ["space-science-pack-output"]=4,
  ["muluna-interstellar-science-pack-packs-required"]=1,
  ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]=25,
  ["rubia-tech-cost-multiplier"]=1,
 },
 hard={
  ["space-science-pack-output"]=1,
  ["muluna-interstellar-science-pack-packs-required"]=3,
  ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]=65,
  ["rubia-tech-cost-multiplier"]=2,
 },
 nightmare={
  ["space-science-pack-output"]=1,
  ["muluna-interstellar-science-pack-packs-required"]=4,
  ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]=85,
  ["rubia-tech-cost-multiplier"]=3,
 },
}

-- The mod that owns each setting; a setting of a mod that is not installed
-- is skipped. Yes/no choices (Muluna's dynamic requirement switch, unlock
-- toggles, recipe reverts) are never touched.
M.owners={
 ["space-science-pack-output"]="planet-muluna",
 ["muluna-interstellar-science-pack-packs-required"]="planet-muluna",
 ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]="planet-muluna",
 ["rubia-tech-cost-multiplier"]="rubia",
}

local original={}
local active=false

-- The level Easy, Hard or Nightmare; Normal and Custom have no profile.
function M.level(startup)
 local item=startup and startup["razi-difficulty-preset"]
 local name=item and item.value
 return M.profiles[name] and name or nil
end

function M.apply(startup,enabled)
 startup=startup or (settings and settings.startup)
 enabled=enabled or mods or {}
 if active then return 0 end
 local level=M.level(startup)
 if not level then return 0 end
 local count=0
 -- Sorted: the log and the result do not depend on the order of pairs.
 local names={}
 for name in pairs(M.profiles[level]) do names[#names+1]=name end
 table.sort(names)
 for _,name in ipairs(names) do
  local value=M.profiles[level][name]
  local owner=M.owners[name]
  local record=owner and enabled[owner] and startup and startup[name]
  if type(record)=="table" and type(record.value)=="number"
      and record.value~=value then
   local previous=record.value
   local ok=pcall(function() record.value=value end)
   if ok and record.value==value then
    original[name]={record=record,value=previous,chosen=value}
    count=count+1
   else
    log("razi-protocol: the setting "..name.." cannot be set for the data stage")
   end
  end
 end
 active=count>0
 if count>0 then
  log("razi-protocol: the "..level.." level set "..count
   .." settings of other mods for their data-updates and data-final-fixes")
 end
 return count
end

-- Puts the saved values back. A setting that another mod changed in the
-- meantime keeps that change.
function M.restore()
 local count=0
 for name,entry in pairs(original) do
  if entry.record.value==entry.chosen then
   local ok=pcall(function() entry.record.value=entry.value end)
   if ok then count=count+1 end
  end
  original[name]=nil
 end
 active=false
 return count
end

return M
