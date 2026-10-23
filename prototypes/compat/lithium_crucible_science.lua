-- LithiumBattery removes Crucible's legacy cryogenic science clone recipe.
-- Crucible may still keep a change-recipe-productivity effect targeting it.
-- Preserve the technology and all valid effects, removing only the dangling
-- recipe reference so Factorio's assignID validation can complete.
local M = {}

function M.data_final_fixes()
  if not (mods["LithiumBattery"] and mods["planet-crucible"]) then return end

  local technologies = data.raw.technology or {}
  local technology = technologies["planet-crucible-cryogenic-science-pack-productivity"]
  if not technology or not technology.effects then return end

  local recipes = data.raw.recipe or {}
  for index = #technology.effects, 1, -1 do
    local effect = technology.effects[index]
    if effect
      and effect.recipe == "cryogenic-science-pack-clone"
      and not recipes[effect.recipe]
    then
      table.remove(technology.effects, index)
    end
  end
end

return M
