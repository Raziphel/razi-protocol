-- Small, pure helpers for drawing source-owned and Razi-owned factory
-- previews in the Codex. One lookup per visible quest, never a recipe scan.
local M={}

function M.recipe(quest,native,recipes)
  if not (quest and quest.site and native and recipes) then return nil end
  local name=quest.recipe or quest.tech
  local recipe=name and recipes[name]
  if not (recipe and not recipe.hidden) then return nil end
  for _,effect in ipairs(native.prototype and native.prototype.effects or {}) do
    if effect.type=="unlock-recipe" and effect.recipe==name then
      return recipe
    end
  end
  return nil
end

function M.quantity(entry)
  if not entry then return "" end
  local amount=entry.amount
  if amount==nil and entry.amount_min and entry.amount_max then
    amount=tostring(entry.amount_min).."–"..tostring(entry.amount_max)
  end
  if amount==nil then return "" end
  local result=" ×"..tostring(amount)
  if entry.probability and entry.probability<1 then
    result=result.." ("..tostring(math.floor(entry.probability*100+0.5)).."%)"
  end
  return result
end

-- Avoid unresolved dynamic journal-workshop localisation keys.
-- Display the actual source location when known, otherwise neutral text.
function M.workshop_fallback(quest,available)
  if quest and quest.world then
    local locations=available and available.space_location or {}
    local world=locations[quest.world]
    if world and world.localised_name then return world.localised_name end
    return quest.world:gsub("[-_]"," ")
  end
  if quest and quest.site then return quest.site:gsub("[-_]"," ") end
  return "Expedition-dependent"
end

return M
