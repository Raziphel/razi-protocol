-- Resource-rich, optional second ways to produce system cards.
-- A freight batch consumes FOUR complete native card recipes plus real
-- native materials, and yields FIVE cards. No source content is replaced.
local M={}
M.rules={
 {name="razi-solaris-multiplex-cards",card="solaris-tech-card",
  unlock="planet-discovery-corrundum",
  freight={{"kr-rare-metals",6},{"tungsten-plate",8}}},
 {name="razi-nyxaris-multiplex-cards",card="nyxaris-tech-card",
  unlock="planet-discovery-apia-carnova",
  freight={{"bioflux",6},{"optical-cable",8}}},
 {name="razi-vibrant-multiplex-cards",card="vibrant-tech-card",
  unlock="planet-discovery-paracelsin",
  freight={{"electric-coil",8},{"holmium-plate",6}}},
 {name="razi-vespera-multiplex-cards",card="vespera-tech-card",
  unlock="planet-discovery-rubia",
  freight={{"craptonite-frame",8},{"carbon-fiber",8}}},
 {name="razi-beetlejuice-multiplex-cards",card="beetlejuice-tech-card",
  unlock="planet-discovery-secretas",
  freight={{"gold-plate",6},{"rare-earth-powder",4}}},
 {name="razi-umbra-multiplex-cards",card="umbra-tech-card",
  unlock="planet-discovery-vesta",
  freight={{"chitosan",4},{"supermagnet",3},{"rare-earth-powder",3}}},
 {name="razi-deep-space-multiplex-cards",card="deep-space-tech-card",
  unlock="discovery-aegis-outer",
  freight={{"space-logistic-science-pack",2},{"pulsar-science-pack",2}}}
}
local function item(name)
 return (data.raw.item and data.raw.item[name])
  or (data.raw.tool and data.raw.tool[name])
end
local function duplicate(value)
 if table.deepcopy then return table.deepcopy(value) end
 local t={}
 for k,v in pairs(value) do
  t[k]=type(v)=="table" and duplicate(v) or v
 end
 return t
end
local function valid_base(recipe,card)
 if not recipe or recipe.hidden or recipe.enabled~=false
  or not recipe.ingredients or not recipe.results
  or recipe.category and recipe.category~="crafting" then return false end
 if recipe.categories then
  local craft=false
  for _,c in ipairs(recipe.categories) do
   if c=="crafting" then craft=true break end
  end
  if not craft then return false end
 end
 if #recipe.results~=1 then return false end
 local result=recipe.results[1]
 if result.name~=card or result.amount~=1 then return false end
 for _,ingredient in ipairs(recipe.ingredients) do
  if not ingredient.name or not ingredient.amount
   or ingredient.amount<=0 or ingredient.type=="fluid"
   or not item(ingredient.name) then return false end
 end
 return true
end
-- Multiplex recipes must fit an installed *existing* crafting machine.
-- Optional high-ingredient variants simply skip registration if none can
-- handle their inputs. Never create a new assembler to rescue a recipe.
local function has_crafting_machine(ingredient_count)
 for _,machine in pairs(data.raw["assembling-machine"] or {}) do
  if not machine.fixed_recipe and
   (not machine.ingredient_count
     or machine.ingredient_count>=ingredient_count) then
   for _,category in ipairs(machine.crafting_categories or {}) do
    if category=="crafting" then return true end
   end
  end
 end
 return false
end
function M.data_final_fixes()
 local recipes=data.raw.recipe or {}
 local technologies=data.raw.technology or {}
 for _,rule in ipairs(M.rules) do
  local technology=technologies[rule.unlock]
  local base=recipes[rule.card]
  local card=item(rule.card)
  local approved=technology and technology.enabled~=false
    and not technology.hidden and card
    and not recipes[rule.name] and valid_base(base,rule.card)
  if approved then
   for _,part in ipairs(rule.freight) do
    if not item(part[1]) then approved=false break end
   end
  end
  local ingredients
  if approved then
   ingredients=duplicate(base.ingredients)
   for _,part in ipairs(ingredients) do
    part.amount=part.amount*4
   end
   for _,part in ipairs(rule.freight) do
    ingredients[#ingredients+1]={type="item",name=part[1],
      amount=part[2]}
   end
   if not has_crafting_machine(#ingredients) then
    approved=false
   end
  end
  if approved then
   -- The card icon belongs to Razi. Source mods own all imported icons.
   local recipe={type="recipe",name=rule.name,
    localised_name={"recipe-name."..rule.name},
    localised_description={"recipe-description."..rule.name},
    icon=card.icons and nil or card.icon,
    icon_size=card.icons and nil or card.icon_size,
    icons=card.icons and duplicate(card.icons) or nil,
    categories={"crafting"},enabled=false,energy_required=(base.energy_required or 10)*4*1.15,
    allow_productivity=false,maximum_productivity=0,
    auto_recycle=false,allow_decomposition=false,
    subgroup="system-tech-card",
    order="s[system]-z[multiplex]-"..rule.card,
    ingredients=ingredients,
    results={{type="item",name=rule.card,amount=5}}}
   data:extend({recipe})
   technology.effects=technology.effects or {}
   local found=false
   for _,effect in ipairs(technology.effects) do
    if effect.type=="unlock-recipe" and effect.recipe==rule.name then
     found=true break
    end
   end
   if not found then
    technology.effects[#technology.effects+1]={
      type="unlock-recipe",recipe=rule.name}
   end
  end
 end
end
return M
