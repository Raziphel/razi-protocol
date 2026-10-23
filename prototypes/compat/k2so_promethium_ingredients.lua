-- Some optional research/recipe integrations append biter eggs to K2SO's
-- promethium research recipe more than once. Keep the total count unchanged.
local M = {}

local function merge_duplicates(ingredients)
  if type(ingredients) ~= "table" then return end
  local seen = {}
  local index = 1
  while index <= #ingredients do
    local ingredient = ingredients[index]
    local name = type(ingredient) == "table" and (ingredient.name or ingredient[1])
    local kind = type(ingredient) == "table" and (ingredient.type or "item")
    local amount = type(ingredient) == "table" and (ingredient.amount or ingredient[2])
    if name == "biter-egg" and kind == "item" and type(amount) == "number" then
      local previous = seen[name]
      if previous then
        local original = ingredients[previous]
        local sum = (original.amount or original[2]) + amount
        if original.amount ~= nil then original.amount = sum else original[2] = sum end
        table.remove(ingredients, index)
      else
        seen[name] = index
        index = index + 1
      end
    else
      index = index + 1
    end
  end
end

function M.data_final_fixes()
  local recipe = data.raw.recipe and data.raw.recipe["kr-promethium-research-data"]
  if not recipe then return end
  merge_duplicates(recipe.ingredients)
  if recipe.normal then merge_duplicates(recipe.normal.ingredients) end
  if recipe.expensive then merge_duplicates(recipe.expensive.ingredients) end
end

return M
