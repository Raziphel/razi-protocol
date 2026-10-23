-- LithiumBattery may remove legacy recipe clones that Crucible's
-- productivity research still targets. Factorio validates those effects at
-- assignID, even when the source technology remains otherwise valid.
-- Keep every existing recipe effect and other research bonus untouched.
local M = {}

function M.data_final_fixes()
  if not (mods["LithiumBattery"] and mods["planet-crucible"]) then return end

  local recipes = data.raw.recipe or {}
  for name, technology in pairs(data.raw.technology or {}) do
    if name:match("^planet%-crucible%-.+%-productivity$") and technology.effects then
      for index = #technology.effects, 1, -1 do
        local effect = technology.effects[index]
        if type(effect) == "table"
          and (effect.type == "change-recipe-productivity" or effect.type == "unlock-recipe")
          and type(effect.recipe) == "string"
          and not recipes[effect.recipe]
        then
          table.remove(technology.effects, index)
        end
      end
    end
  end
end

return M
