-- Multiple compatibility mods can append biter eggs to K2SO's
-- promethium research data recipe. Factorio 2.1 rejects duplicate items.
-- Merge matching item ingredients, preserving the total required amount.
local M = {}

local function normalize(ingredients)
  if type(ingredients) ~= "table" then return end
  local first = {}
  for index = #ingredients, 1, -1 do
    local ingredient = ingredients[index]
    if type(ingredient) == "table" then
      local name = ingredient.name or ingredient[1]
      local ingredient_type = ingredient.type or "item"
      if name == "biter-egg" and ingredient_type == "item" then
        local amount = ingredient.amount or ingredient[2]
        if type(amount) == "number" then
          if first[name] then
            local keeper = ingredients[first[name]]
            local previous = keeper.amount or keeper[2]
            if type(previous) == "number" then
              if keeper.amount then keeper.amount = previous + amount
              else keeper[2] = previous + amount end
              table.remove(ingredients, index)
              -- Removing an earlier entry shifts the retained index.
              first[name] = first[name] - 1
            end
          else
            first[name] = index
          end
        end
      end
    end
  end
end

function M.data_final_fixes()
  local recipe = data.raw.recipe and data.raw.recipe["kr-promethium-research-data"]
  if not recipe then return end
  normalize(recipe.ingredients)
  if recipe.normal then normalize(recipe.normal.ingredients) end
  if recipe.expensive then normalize(recipe.expensive.ingredients) end
end

return M
