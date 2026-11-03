-- Create cards for science packs used by research at prototype load.
local M = {}

local Difficulty = require("scripts.razi_difficulty_presets")
local Graph = require("__razi_lib__/lib/technology_graph")

local function is_science(name)
  return type(name)=="string" and name:find("science",1,true)
    and not name:find("tech-card",1,true)
    and not name:find("research-data",1,true)
end
local function ingredient_name(entry)
  return type(entry)=="table" and (entry.name or entry[1]) or nil
end
local function science_source(name)
  if data.raw.tool and data.raw.tool[name] then
    return data.raw.tool[name],"tool"
  end
  if data.raw.item and data.raw.item[name] then
    return data.raw.item[name],"item"
  end
end
local function candidates()
  local research,lab_inputs={},{}
  for _,technology in pairs(data.raw.technology or {}) do
    for _,entry in ipairs((technology.unit and technology.unit.ingredients) or {}) do
      local name=ingredient_name(entry)
      if is_science(name) then research[name]=true end
    end
  end
  for _,lab in pairs(data.raw.lab or {}) do
    for _,name in ipairs(lab.inputs or {}) do lab_inputs[name]=true end
  end
  local names={}
  for name in pairs(research) do
    local original=science_source(name)
    if lab_inputs[name] and original and not original.hidden
      and (original.icon or original.icons) then
      names[#names+1]=name
    end
  end
  table.sort(names)
  return names
end
local function ensure_subgroup()
  if (data.raw["item-subgroup"] or {})["razi-planet-tech-card"] then return end
  local group=(data.raw["item-group"] or {}).science and "science"
    or "intermediate-products"
  data:extend({{type="item-subgroup",name="razi-planet-tech-card",
    group=group,order="1[planet-tech-cards]"}})
end
local function icon_layers(original)
  local icons=original.icons and table.deepcopy(original.icons)
    or {{icon=original.icon,icon_size=original.icon_size or 64}}
  icons[#icons+1]={
    icon="__base__/graphics/icons/lab.png",
    icon_size=64,scale=0.25,shift={8,8}
  }
  return icons
end
local function generate(name)
  local original,kind=science_source(name)
  if not original then return nil end
  local card_name="razi-"..name.."-tech-card"
  local recipe_name="razi-convert-"..name.."-tech-card"
  if (data.raw.item or {})[card_name]
    or (data.raw.tool or {})[card_name]
    or (data.raw.recipe or {})[recipe_name] then return nil end
  local source_name=original.localised_name or {"item-name."..name}
  local icons=icon_layers(original)
  local card=table.deepcopy(original)
  card.type=kind
  card.name=card_name
  card.subgroup="razi-planet-tech-card"
  card.order="c[card]-"..name
  card.localised_name={"razi-auto-card.name",source_name}
  card.localised_description={"razi-auto-card.description",source_name}
  card.icons=icons
  card.icon=nil
  card.icon_size=nil
  card.pictures=nil
  local recipe={
    type="recipe",name=recipe_name,
    localised_name=card.localised_name,
    localised_description=card.localised_description,
    icons=table.deepcopy(icons),icon=nil,icon_size=nil,
    categories={"crafting"},enabled=false,energy_required=0.5,
    ingredients={{type="item",name=name,amount=1}},
    results={{type="item",name=card_name,amount=1,
      reset_freshness_on_craft=false}},
    subgroup="razi-planet-tech-card",order="c[conversion]-"..name,
    allow_productivity=false,maximum_productivity=0,
    auto_recycle=false,allow_decomposition=false
  }
  data:extend({card,recipe})
  return card_name,recipe_name
end
local function unlock_card(technology,recipe_name)
  for _,effect in ipairs(technology.effects or {}) do
    if effect.type=="unlock-recipe" and effect.recipe==recipe_name then
      return true
    end
  end
  technology.effects=technology.effects or {}
  technology.effects[#technology.effects+1]={
    type="unlock-recipe",recipe=recipe_name
  }
  return true
end
local function ingredient_names(recipe)
  local names={}
  for _,entry in ipairs(recipe.ingredients or {}) do
    local name=ingredient_name(entry)
    if name then names[#names+1]=name end
  end
  return names
end
-- Recipes by the items and fluids they make.
local function producer_index(recipes)
  local index={}
  for name,recipe in pairs(recipes) do
    for _,result in ipairs(recipe.results or {}) do
      local product=ingredient_name(result)
      if product then
        index[product]=index[product] or {}
        index[product][#index[product]+1]=name
      end
    end
  end
  return index
end
local function consumes(recipe,name)
  for _,input in ipairs(ingredient_names(recipe)) do
    if input==name then return true end
  end
  return false
end
-- A recipe that makes the pack back out of the pack (upcycling, preservation
-- and depreservation, crates) does not make the pack available: it consumes
-- the pack, or an item that only recipes consuming the pack make. Recipes
-- that turn an item into itself (quality and infusion variants) are skipped.
local function from_pack(recipe,pack,recipes,producers)
  for _,name in ipairs(ingredient_names(recipe)) do
    if name==pack then return true end
    local found,all_from_pack=false,true
    for _,maker in ipairs(producers[name] or {}) do
      local source=recipes[maker]
      if not consumes(source,name) then
        found=true
        if not consumes(source,pack) then all_from_pack=false break end
      end
    end
    if found and all_from_pack then return true end
  end
  return false
end
local function set_recipe_unlocks(names,mapping,technologies,unlock_index)
  local opened=0
  local recipes=data.raw.recipe or {}
  local producers=producer_index(recipes)
  for _,name in ipairs(names) do
    local card_name=mapping[name]
    if card_name then
      local card_recipe=recipes["razi-convert-"..name.."-tech-card"]
      local has_producer=false
      local added={}
      for _,recipe_name in ipairs(producers[name] or {}) do
        local source_recipe=recipes[recipe_name]
        if source_recipe~=card_recipe and not source_recipe.hidden
          and not from_pack(source_recipe,name,recipes,producers) then
          has_producer=true
          if source_recipe.enabled~=false then
            card_recipe.enabled=true
          else
            for _,technology_name in ipairs(unlock_index[recipe_name] or {}) do
              local technology=technologies[technology_name]
              if technology and not added[technology_name] then
                unlock_card(technology,card_recipe.name)
                added[technology_name]=true
              end
            end
          end
        end
      end
      if not has_producer then card_recipe.enabled=true end
      if card_recipe.enabled~=false then opened=opened+1 end
    end
  end
  return opened
end
local function register_labs(mapping)
  for _,lab in pairs(data.raw.lab or {}) do
    if lab.inputs then
      local inputs,seen={},{}
      for _,native_name in ipairs(lab.inputs) do
        if not seen[native_name] then
          inputs[#inputs+1]=native_name
          seen[native_name]=true
        end
        local card=mapping[native_name]
        if card and not seen[card] then
          inputs[#inputs+1]=card
          seen[card]=true
        end
      end
      lab.inputs=inputs
    end
  end
end
local function change_research(mapping)
  local changed=0
  for _,technology in pairs(data.raw.technology or {}) do
    for _,entry in ipairs((technology.unit and technology.unit.ingredients) or {}) do
      local card=mapping[ingredient_name(entry)]
      if card then
        if entry.name then entry.name=card else entry[1]=card end
        changed=changed+1
      end
    end
  end
  return changed
end
function M.data_final_fixes()
  if not Difficulty.effective("razi-auto-tech-cards",false) then return end
  local names=candidates()
  local technologies=data.raw.technology or {}
  local unlock_index=Graph.unlock_index(technologies)
  local mapping,n={},0
  if #names>0 then ensure_subgroup() end
  for _,name in ipairs(names) do
    local card=generate(name)
    if card then
      mapping[name]=card
      n=n+1
    end
  end
  local opened=set_recipe_unlocks(names,mapping,technologies,unlock_index)
  register_labs(mapping)
  local references=change_research(mapping)
  if log then
    log("[Razi Protocol/tech-cards] "..n.." cards, "..references..
      " research ingredients, "..opened.." cards open from the start")
  end
end
return M
