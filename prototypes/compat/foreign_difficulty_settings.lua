-- Native Factorio prototype-stage bridge for REAL numeric foreign startup setting IDs.
-- Factorio's setting definitions have already loaded, and the saved Razi
-- difficulty is now readable. Changing the data-stage Lua setting view does
-- NOT change mod-settings.dat, the menu, or runtime settings. It allows
-- upstream data-updates.lua / data-final-fixes.lua readers to behave as if
-- their own settings had these difficulty-selected values.
--
-- LIMITATION: this mod loads after its required dependencies' data.lua.
-- Settings consumed solely during those earlier data.lua passes cannot be
-- changed retroactively by this bridge. Only VERIFIED numeric later-stage consumers
-- are mapped below. Never add entries merely because settings.lua defines them.
local M={}
M.profiles={
 easy={
  ["space-science-pack-output"]=4,
  ["muluna-interstellar-science-pack-packs-required"]=1,
  ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]=25,
  ["rubia-tech-cost-multiplier"]=1,
 },
 normal={
  ["space-science-pack-output"]=2,
  ["muluna-interstellar-science-pack-packs-required"]=2,
  ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]=50,
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
-- Only numeric scaling controls are eligible; this deliberately excludes
-- binary choices such as K2SO fuel-recipe reverts and Muluna unlock toggles.
-- Normal values are the upstream defaults, not a gameplay rewrite.
-- Both fixed and dynamic percentage requirement values are mapped without
-- changing Muluna's saved dynamic-packs boolean switch.
M.owners={
 ["space-science-pack-output"]="planet-muluna",
 ["muluna-interstellar-science-pack-packs-required"]="planet-muluna",
 ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]="planet-muluna",
 ["rubia-tech-cost-multiplier"]="rubia",
}
local original={}
local active=false
local function report(msg)
 if type(log)=="function" then log("[Razi difficulty source settings] "..msg) end
end
function M.apply(startup,enabled)
 startup=startup or (settings and settings.startup)
 enabled=enabled or mods or {}
 if active then return 0 end
 local selected=startup and startup["razi-difficulty-preset"]
 local mode=selected and selected.value or "normal"
 -- Custom explicitly uses players' real source-mod saved settings.
 local profile=M.profiles[mode]
 if not profile then return 0 end
 local count=0
 for name,value in pairs(profile) do
  local owner=M.owners[name]
  local record=owner and enabled[owner] and startup and startup[name]
  if type(value)=="number" and type(record)=="table"
      and type(record.value)=="number" and record.value~=value then
   -- Settings prototypes themselves are not touched. This is only the
   -- shared data-stage Lua view. Fail closed on non-writable value tables.
   local previous=record.value
   local ok=pcall(function() record.value=value end)
   if ok and record.value==value then
    original[name]={record=record,value=previous,chosen=value}
    count=count+1
   else
    report("Cannot set prototype-stage value for "..name)
   end
  end
 end
 active=count>0
 if count>0 then
  report("Effective "..mode.." values injected for "..count..
    " source mod options before the later prototype passes")
 end
 return count
end
function M.restore()
 local count=0
 for name,entry in pairs(original) do
  -- Never lose another mod's subsequent intentional change to this table.
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
