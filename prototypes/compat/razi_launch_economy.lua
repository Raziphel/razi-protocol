-- Launch cost of the difficulty level: multiplies the rocket part crafts a
-- launch needs on every rocket silo prototype, whatever mod defines it. The
-- recipes of the rocket parts stay as the source mods made them.
-- One data stage pass. Normal (x1) writes nothing. No tick handlers, no
-- entity replacements.
local M={}
local economy=require("scripts.razi_economy_difficulty")
local difficulty=require("scripts.razi_difficulty_presets")
-- The first value a silo had, so a second call never compounds the factor.
local originals=setmetatable({},{__mode="k"})

function M.adjust(silos,resolver)
 local factor=economy.rocket_factor(resolver)
 local changed=0
 if type(silos)~="table" then return changed end
 for _,silo in pairs(silos) do
  local original=originals[silo]
  if original==nil and type(silo.rocket_parts_required)=="number" then
   original={
    parts=silo.rocket_parts_required,
    storage=silo.rocket_parts_storage_cap
   }
   originals[silo]=original
  end
  if original and original.parts>=1 and factor~=1 then
   -- Rockets may be half built in an existing save: the stored parts stay.
   local crafts=math.max(1,math.min(100000,
    math.floor(original.parts*factor+.5)))
   if silo.rocket_parts_required~=crafts then
    silo.rocket_parts_required=crafts
    changed=changed+1
   end
   -- An explicit storage cap below the crafts a rocket needs would stall
   -- the silo. Zero is a valid cap (no second progress bar): keep it.
   if original.storage~=nil and original.storage~=0 then
    silo.rocket_parts_storage_cap=math.max(original.storage,crafts)
   end
  end
 end
 if changed>0 then
  log("razi-protocol: the rocket launch cost of the difficulty level (x"
   ..factor..") changed the rocket parts of "..changed.." rocket silos")
 end
 return changed
end

function M.data_final_fixes()
 return M.adjust((data.raw or {})["rocket-silo"],difficulty)
end

return M
