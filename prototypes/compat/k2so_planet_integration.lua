-- K2SO planetary research backbone and late material-name reconciliation.
-- Runs after source compatibility passes and the Razi campaign/card builders.
-- All changes are prototype-guarded; missing optional planets are untouched.
local integration = {}

-- Every K2SO research-data family joins the existing Razi progression at
-- the frontier where its native planet can actually be reached. Later cards
-- carry the earlier systems' data forward, never the reverse.
local data_bridges = {
  {"solaris-tech-card", "kr-metallurgic-research-data", "vulcanus"},
  {"nyxaris-tech-card", "kr-agricultural-research-data", "gleba"},
  {"vibrant-tech-card", "kr-electromagnetic-research-data", "fulgora"},
  {"vespera-tech-card", "kr-cryogenic-research-data", "aquilo"},
  {"beetlejuice-tech-card", "kr-matter-research-data", "aquilo"},
  {"umbra-tech-card", "kr-matter-research-data", "aquilo"},
  {"deep-space-tech-card", "kr-promethium-research-data", "shattered-planet"}
}

-- Exact material identities standardized by K2SO. Do not rewrite other
-- materials or guess aliases for independently designed planet resources.
local replaced_materials = {
  oxygen=true, hydrogen=true, chlorine=true, sand=true,
  glass=true, silicon=true, lithium=true, ammonia=true
}

local function material(kind, name)
  return data.raw[kind] and data.raw[kind][name]
end

local function visible_replacement(kind, old)
  if not replaced_materials[old] then return nil end
  local original = material(kind, old)
  local replacement = material(kind, "kr-" .. old)
  -- Null's K2SO Tweaks may deliberately retain common oxygen/hydrogen or
  -- nitrogen. If the common prototype is visible, it owns that identity.
  if original and original.hidden and replacement and not replacement.hidden then
    return "kr-" .. old
  end
  return nil
end

local function entry_name(entry)
  return entry and (entry.name or entry[1])
end

local function set_entry_name(entry, name)
  if entry.name then entry.name = name else entry[1] = name end
end

local function reconcile_entries(entries)
  for _, entry in ipairs(entries or {}) do
    local name = entry_name(entry)
    if name then
      local kind = entry.type == "fluid" and "fluid" or "item"
      local replacement = visible_replacement(kind, name)
      if replacement then set_entry_name(entry, replacement) end
    end
  end
end

local function reconcile_recipe_variant(variant)
  if not variant then return end
  reconcile_entries(variant.ingredients)
  reconcile_entries(variant.results)
  local main_product = variant.main_product
  if main_product then
    local kind = material("fluid", main_product) and "fluid" or "item"
    local replacement = visible_replacement(kind, main_product)
    if replacement then variant.main_product = replacement end
  end
end

local function reconcile_recipes()
  for _, recipe in pairs(data.raw.recipe or {}) do
    reconcile_recipe_variant(recipe)
    -- Pre-2.1 forks can carry only an expensive variant, with no normal.
    reconcile_recipe_variant(rawget(recipe, "normal"))
    reconcile_recipe_variant(rawget(recipe, "expensive"))
  end
end

local function reconcile_mining()
  for _, family in ipairs({"resource", "simple-entity"}) do
    for _, entity in pairs(data.raw[family] or {}) do
      local minable = entity.minable
      if minable then
        if minable.result then
          local replacement = visible_replacement("item", minable.result)
          if replacement then minable.result = replacement end
        end
        reconcile_entries(minable.results)
      end
    end
  end
  for _, tile in pairs(data.raw.tile or {}) do
    if tile.fluid then
      local replacement = visible_replacement("fluid", tile.fluid)
      if replacement then tile.fluid = replacement end
    end
  end
end

local function recipe_makes_item(recipe, name)
  if recipe.result == name then return true end
  for _, entry in ipairs(recipe.results or {}) do
    if entry_name(entry) == name then return true end
  end
  return false
end

local function add_existing_research_data()
  for _, bridge in ipairs(data_bridges) do
    local card, research_data, owner = bridge[1], bridge[2], bridge[3]
    local planet = material("planet", owner)
      or material("space-location", owner)
    local card_recipe = material("recipe", card)
    local data_recipe = material("recipe", research_data)
    if planet and card_recipe and card_recipe.ingredients
      and material("tool", card) and material("item", research_data)
      and data_recipe and recipe_makes_item(data_recipe, research_data) then
      local found = false
      for _, ingredient in ipairs(card_recipe.ingredients) do
        if entry_name(ingredient) == research_data then
          found = true
          break
        end
      end
      if not found then
        card_recipe.ingredients[#card_recipe.ingredients + 1] = {
          type = "item", name = research_data, amount = 1
        }
      end
    end
  end
end

function integration.data_final_fixes()
  if not (mods and mods["Krastorio2-spaced-out"]) then return end
  -- Source mods sometimes reintroduce obsolete prototypes in their final
  -- compatibility passes. Reconcile only when the old material is hidden
  -- and the K2SO counterpart is actually available and visible.
  reconcile_recipes()
  reconcile_mining()
  add_existing_research_data()
end

return integration
