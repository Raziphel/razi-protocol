-- Multiply the source-defined crafts per rocket, rather than rewriting
-- recipe ingredients from Space Age, K2SO or other launch providers.
-- One prototype-stage pass only. No on_tick or entity replacements.
local M={}
local difficulty=require("scripts.razi_difficulty_presets")
local economy=require("scripts.razi_economy_difficulty")
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
    -- Existing rockets may be mid-construction on existing saves.
    local crafts=math.max(1,math.min(100000,
      math.floor(original.parts*factor+.5)))
    if silo.rocket_parts_required~=crafts then
      silo.rocket_parts_required=crafts
      changed=changed+1
    end
    -- An explicit nonzero rocket part storage cap must not be below
    -- required crafts, or the silo can stall before the rocket is ready.
    -- Zero is a valid special "no second progress bar" value.
    if original.storage~=nil and original.storage~=0 then
      silo.rocket_parts_storage_cap=math.max(original.storage,crafts)
    end
  end
 end
 return changed
end
function M.data_final_fixes()
 return M.adjust((data.raw or {})["rocket-silo"],difficulty)
end
return M
