package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local function clone(v)
 if type(v)~="table" then return v end
 local t={}
 for k,x in pairs(v) do t[k]=clone(x) end
 return t
end
table.deepcopy=clone
local names={"solaris-tech-card","nyxaris-tech-card",
 "vibrant-tech-card","vespera-tech-card",
 "beetlejuice-tech-card","umbra-tech-card","deep-space-tech-card"}
local tools,raw_recipes,technologies,items={},{},{},{}
for _,name in ipairs(names) do
 tools[name]={icon="__base__/graphics/icons/automation-science-pack.png",
  icon_size=64}
 raw_recipes[name]={name=name,enabled=false,
   categories={"crafting"},energy_required=12,
   ingredients={{type="item",name="calidus-tech-card",amount=1}},
   results={{type="item",name=name,amount=1}}}
end
items["calidus-tech-card"]={}
for _,part in ipairs({"kr-rare-metals","tungsten-plate","bioflux",
 "optical-cable","electric-coil","holmium-plate","craptonite-frame",
 "carbon-fiber","gold-plate","rare-earth-powder","chitosan",
 "supermagnet","space-logistic-science-pack","pulsar-science-pack"}) do
 items[part]={}
end
for _,tech in ipairs({"planet-discovery-corrundum",
 "planet-discovery-apia-carnova","planet-discovery-paracelsin",
 "planet-discovery-rubia","planet-discovery-secretas",
 "planet-discovery-vesta","discovery-aegis-outer"}) do
 technologies[tech]={effects={}}
end
rawset(_G,"data",{raw={recipe=raw_recipes,technology=technologies,
 tool=tools,item=items,
 ["assembling-machine"]={large={crafting_categories={"crafting"},
   ingredient_count=16}}}})
function data:extend(objects)
 for _,object in ipairs(objects) do
  check(not self.raw[object.type][object.name],"Duplicate recipe")
  self.raw[object.type][object.name]=object
 end
end
local mod=require("prototypes.compat.system_card_manufacturing")
mod.data_final_fixes()
for _,rule in ipairs(mod.rules) do
 local recipe=assert(raw_recipes[rule.name],"Missing bulk recipe")
 local native=assert(raw_recipes[rule.card])
 check(native.ingredients[1].amount==1,
  "Original card manufacture has been changed")
 check(recipe.results[1].amount==5 and
  recipe.ingredients[1].amount==4,
  "Bulk route must need four complete source batches for five cards")
 check(math.abs(recipe.energy_required - native.energy_required*4*1.15)<0.0001,
  "Freight recipe should charge 15 percent extra native-batch time")
 check(#recipe.ingredients==#native.ingredients+#rule.freight,
  "Missing actual native freight inputs")
 check(recipe.auto_recycle==false and recipe.allow_productivity==false,
  "No free productivity amplification")
 local registered=false
 for _,effect in ipairs(technologies[rule.unlock].effects) do
  if effect.recipe==rule.name then registered=true end
 end
 check(registered,"Missing source technology unlock")
end
mod.data_final_fixes()
check(#technologies["planet-discovery-corrundum"].effects==1,
 "Second registration must not duplicate the source unlock")
raw_recipes["razi-nyxaris-multiplex-cards"]=nil
items["bioflux"]=nil
mod.data_final_fixes()
check(raw_recipes["razi-nyxaris-multiplex-cards"]==nil,
 "Missing supplier must disable only its own freight option")
raw_recipes["razi-umbra-multiplex-cards"]=nil
data.raw["assembling-machine"].large.ingredient_count=3
mod.data_final_fixes()
check(raw_recipes["razi-umbra-multiplex-cards"]==nil,
 "Unavailable ingredient-capable machines must suppress only optional synthesis")
print("Card multiplex: native conservation, freight, science and safety passed")
