-- Companion-only research pacing for distinctive FluxWorks machinery.
-- The original source tech IDs, prerequisites, science types, unlock effects,
-- and material supply requirements remain unchanged.
--
-- The research counts below are ceilings: if another integration has already
-- made a technology cheaper, do not undo that decision.
local M={}

local targets={
  -- Reach the first useful synthesis district without paying several full
  -- late-chemical research costs back-to-back.
  ["fw-flux-yellow-catalysis"]={count=180,time=35},
  ["fw-flux-stabilization"]={count=210,time=35}, -- Synthesis Plant
  ["fw-harvester-systems"]={count=250,time=35}, -- Flux Harvester

  -- These paths retain all required Vulcanus/Gleba/planet science and recipes.
  ["fw-flux-red-energetics"]={count=260,time=40},
  ["fw-flux-metallurgy"]={count=460,time=40}, -- Arc Foundry
  ["fw-flux-green-cultivation"]={count=690,time=45},

  -- The advanced research should still feel substantial at the outer edge.
  ["fw-flux-phase-engineering"]={count=820,time=55},
  ["fw-cross-planetary-industrial-convergence"]={count=1760,time=65},
}

function M.data_final_fixes()
  if not (mods and mods["FluxWorks"]) then return 0 end
  local changed=0
  for name,limit in pairs(targets) do
    local tech=data.raw.technology and data.raw.technology[name]
    local unit=tech and tech.unit
    if unit and not unit.count_formula and type(unit.count)=="number"
      and unit.count>0 and unit.ingredients and #unit.ingredients>0 then
      local original=unit.count
      unit.count=math.min(original,limit.count)
      if type(unit.time)=="number" then
        unit.time=math.min(unit.time,limit.time)
      end
      if unit.count<original then changed=changed+1 end
    end
  end
  log("Razi FluxWorks: paced "..changed.." specialist engineering researches")
  return changed
end

return M
