-- Native Factorio prototype-stage bridge for REAL foreign startup setting IDs.
-- Factorio's setting definitions have already loaded, and the saved Razi
-- difficulty is now readable. Changing the data-stage Lua setting view does
-- NOT change mod-settings.dat, the menu, or runtime settings. It allows
-- upstream data-updates.lua / data-final-fixes.lua readers to behave as if
-- their own settings had these difficulty-selected values.
--
-- LIMITATION: this mod loads after its required dependencies' data.lua.
-- Settings consumed solely during those earlier data.lua passes cannot be
-- changed retroactively by this bridge. Only VERIFIED later-stage consumers
-- are mapped below. Never add entries merely because settings.lua defines them.
local M={}
M.profiles={
 easy={
  ["space-science-pack-output"]=4,
  ["muluna-easy-simple-wood-gasification"]=true,
  ["muluna-easy-alternative-battery-recipe"]=true,
  ["muluna-easy-vanilla-advanced-thruster-fuel-costs"]=true,
  ["muluna-change-quality-science-pack-drain"]=true,
  ["muluna-interstellar-science-pack-dynamic-packs-required"]=false,
  ["muluna-interstellar-science-pack-packs-required"]=1,
  ["rubia-tech-cost-multiplier"]=1,
  ["kr-revert-thruster-fuel-changes"]=true,
 },
 normal={
  ["space-science-pack-output"]=2,
  ["muluna-easy-simple-wood-gasification"]=false,
  ["muluna-easy-alternative-battery-recipe"]=false,
  ["muluna-easy-vanilla-advanced-thruster-fuel-costs"]=false,
  ["muluna-change-quality-science-pack-drain"]=true,
  ["muluna-interstellar-science-pack-dynamic-packs-required"]=false,
  ["muluna-interstellar-science-pack-packs-required"]=2,
  ["rubia-tech-cost-multiplier"]=1,
  ["kr-revert-thruster-fuel-changes"]=false,
 },
 hard={
  ["space-science-pack-output"]=1,
  ["muluna-easy-simple-wood-gasification"]=false,
  ["muluna-easy-alternative-battery-recipe"]=false,
  ["muluna-easy-vanilla-advanced-thruster-fuel-costs"]=false,
  ["muluna-change-quality-science-pack-drain"]=false,
  ["muluna-interstellar-science-pack-dynamic-packs-required"]=false,
  ["muluna-interstellar-science-pack-packs-required"]=3,
  ["rubia-tech-cost-multiplier"]=2,
  ["kr-revert-thruster-fuel-changes"]=false,
 },
 nightmare={
  ["space-science-pack-output"]=1,
  ["muluna-easy-simple-wood-gasification"]=false,
  ["muluna-easy-alternative-battery-recipe"]=false,
  ["muluna-easy-vanilla-advanced-thruster-fuel-costs"]=false,
  ["muluna-change-quality-science-pack-drain"]=false,
  ["muluna-interstellar-science-pack-dynamic-packs-required"]=false,
  ["muluna-interstellar-science-pack-packs-required"]=4,
  ["rubia-tech-cost-multiplier"]=3,
  ["kr-revert-thruster-fuel-changes"]=false,
 }
}
-- Both the dependency ID and the source's actual Mod Settings ID are
-- essential. Collision-prone names are never applied to an absent mod.
M.owners={
 ["space-science-pack-output"]="planet-muluna",
 ["muluna-easy-simple-wood-gasification"]="planet-muluna",
 ["muluna-easy-alternative-battery-recipe"]="planet-muluna",
 ["muluna-easy-vanilla-advanced-thruster-fuel-costs"]="planet-muluna",
 ["muluna-change-quality-science-pack-drain"]="planet-muluna",
 ["muluna-interstellar-science-pack-dynamic-packs-required"]="planet-muluna",
 ["muluna-interstellar-science-pack-packs-required"]="planet-muluna",
 ["rubia-tech-cost-multiplier"]="rubia",
 ["kr-revert-thruster-fuel-changes"]="Krastorio2-spaced-out"
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
  if type(record)=="table" and type(record.value)==type(value)
      and record.value~=value then
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
