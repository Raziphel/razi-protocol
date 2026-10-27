-- Synthetic 2.1 data-final-fixes science fixture; no Factorio binary required.
package.path="./?.lua;./?/init.lua;"..package.path
local function copy(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[copy(k)]=copy(v) end
  return out
end
table.deepcopy=copy
local function pack(kind,name,extras)
  local result={type=kind,name=name,icon="mock.png",icon_size=64,
    stack_size=200,science_capacity=1}
  for k,v in pairs(extras or {}) do result[k]=v end
  return result
end
data={raw={
  item={
    ["agricultural-science-pack"]=pack("item","agricultural-science-pack",
      {spoil_ticks=3600,spoil_result="spoilage"})
  },
  tool={
    ["automation-science-pack"]=pack("tool","automation-science-pack"),
    ["aerospace-science-pack"]=pack("tool","aerospace-science-pack"),
    ["kr-matter-tech-card"]=pack("tool","kr-matter-tech-card"),
    ["research-data"]=pack("tool","research-data")
  },
  technology={
    farming={name="farming",unit={count=100,time=20,ingredients={
      {"automation-science-pack",2},{"agricultural-science-pack",3}}}},
    orbit={name="orbit",unit={ingredients={
      {type="item",name="aerospace-science-pack",amount=4}}}},
    vanilla={name="vanilla",unit={ingredients={{"kr-matter-tech-card",1}}}}
  },
  lab={
    lab={inputs={"automation-science-pack","agricultural-science-pack"}},
    moon={inputs={"aerospace-science-pack"}}
  },
  ["item-group"]={["intermediate-products"]={}},
  ["item-subgroup"]={},
  recipe={}
}}
function data:extend(list)
  for _,prototype in ipairs(list) do
    self.raw[prototype.type][prototype.name]=prototype
  end
end
settings={startup={["razi-auto-tech-cards"]={value=true}}}
log=function() end
local auto=require("prototypes.compat.auto_tech_cards")
auto.data_final_fixes()
local cards=data.raw.tool
local items=data.raw.item
local recipes=data.raw.recipe
local a="razi-automation-science-pack-tech-card"
local g="razi-agricultural-science-pack-tech-card"
local s="razi-aerospace-science-pack-tech-card"
assert(cards[a] and items[g] and cards[s])
assert(items[g].spoil_ticks==3600 and items[g].spoil_result=="spoilage")
assert(cards["automation-science-pack"] and items["agricultural-science-pack"])
assert(not cards["razi-kr-matter-tech-card-tech-card"])
assert(data.raw.technology.farming.unit.ingredients[1][1]==a)
assert(data.raw.technology.farming.unit.ingredients[1][2]==2)
assert(data.raw.technology.farming.unit.ingredients[2][1]==g)
assert(data.raw.technology.farming.unit.ingredients[2][2]==3)
assert(data.raw.technology.orbit.unit.ingredients[1].name==s)
assert(data.raw.technology.orbit.unit.ingredients[1].amount==4)
assert(data.raw.technology.vanilla.unit.ingredients[1][1]=="kr-matter-tech-card")
local recipe=recipes["razi-convert-agricultural-science-pack-tech-card"]
assert(recipe and recipe.ingredients[1].name=="agricultural-science-pack")
assert(recipe.results[1].name==g)
assert(recipe.results[1].reset_freshness_on_craft==false)
assert(recipe.allow_productivity==false and recipe.auto_recycle==false)
local function contains(list,value)
  for _,entry in ipairs(list) do if entry==value then return true end end
  return false
end
assert(contains(data.raw.lab.lab.inputs,a))
assert(contains(data.raw.lab.lab.inputs,g))
assert(contains(data.raw.lab.lab.inputs,"agricultural-science-pack"))
assert(not contains(data.raw.lab.lab.inputs,s))
assert(contains(data.raw.lab.moon.inputs,s))
assert(not contains(data.raw.lab.moon.inputs,a))
auto.data_final_fixes() -- no new candidates on a second run
local before=0
for _ in pairs(data.raw.recipe) do before=before+1 end
settings.startup["razi-auto-tech-cards"].value=false
auto.data_final_fixes() -- off is inert
local after=0
for _ in pairs(data.raw.recipe) do after=after+1 end
assert(before==after)
print("auto tech cards: synthetic Factorio research and lab fixture passed")
