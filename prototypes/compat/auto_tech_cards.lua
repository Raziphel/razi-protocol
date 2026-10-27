-- Create tech cards for science from installed planet mods at prototype load.
-- Native science stays intact for third-party recipes, inventory and scripting.
local M = {}

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
local function readable_name(name)
  local text=name:gsub("%-science%-pack$",""):gsub("%-science$","")
    :gsub("_"," "):gsub("%-"," ")
  return (text:gsub("(%a)([%w']*)",function(first,rest)
    return first:upper()..rest
  end))
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
local function generate(name)
  local original,kind=science_source(name)
  if not original then return nil end
  local card_name="razi-"..name.."-tech-card"
  local recipe_name="razi-convert-"..name.."-tech-card"
  if (data.raw.item or {})[card_name]
    or (data.raw.tool or {})[card_name]
    or (data.raw.recipe or {})[recipe_name] then return nil end
  local card=table.deepcopy(original)
  card.type=kind
  card.name=card_name
  card.subgroup="razi-planet-tech-card"
  card.order="c[card]-"..name
  card.localised_name=readable_name(name).." Tech Card"
  card.localised_description={"","Refined from ",
    original.localised_name or {"item-name."..name},
    ". The source science pack remains available."}
  local recipe={
    type="recipe",name=recipe_name,
    localised_name=card.localised_name,
    localised_description=card.localised_description,
    icon=original.icon,icons=original.icons and table.deepcopy(original.icons) or nil,
    icon_size=original.icon_size,
    categories={"crafting"},enabled=true,energy_required=0.5,
    ingredients={{type="item",name=name,amount=1}},
    results={{type="item",name=card_name,amount=1,
      reset_freshness_on_craft=false}},
    subgroup="razi-planet-tech-card",order="c[conversion]-"..name,
    allow_productivity=false,maximum_productivity=0,
    auto_recycle=false,allow_decomposition=false
  }
  -- Preserve source spoilage, science capacity, stack size and icon artwork.
  data:extend({card,recipe})
  return card_name
end
local function register_native_labs(mapping)
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
        -- Keep quantity, research duration, costs and prerequisites untouched.
        changed=changed+1
      end
    end
  end
  return changed
end
function M.data_final_fixes()
  local flag=settings.startup and settings.startup["razi-auto-tech-cards"]
  if flag and flag.value==false then return end
  local names=candidates()
  if #names==0 then return end
  ensure_subgroup()
  local mapping,n={},0
  for _,name in ipairs(names) do
    local card=generate(name)
    if card then
      mapping[name]=card
      n=n+1
    end
  end
  register_native_labs(mapping)
  local references=change_research(mapping)
  if log then log("[Razi Protocol/tech-cards] generated "..n..
    " individual science cards; rewired "..references..
    " research ingredients; original science and labs kept.") end
end
return M
