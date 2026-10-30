-- Synthetic Factorio 2.1 data-final-fixes science fixture; no game binary required.
---@diagnostic disable: missing-fields, need-check-nil, undefined-field
package.path="./?.lua;./?/init.lua;"..package.path
local function copy(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[copy(k)]=copy(v) end
  return out
end
rawset(table,"deepcopy",copy)
local function check(ok,message)
  if not ok then error(message,2) end
end
local function pack(kind,name,extras)
  local result={type=kind,name=name,icon=name..".png",icon_size=64,
    stack_size=200,science_capacity=1}
  for key,value in pairs(extras or {}) do result[key]=value end
  return result
end
local function source_recipe(name,result,enabled)
  return {
    type="recipe",name=name,enabled=enabled,categories={"crafting"},
    ingredients={{type="item",name="iron-plate",amount=1}},
    results={{type="item",name=result,amount=1}}
  }
end
data={raw={
  item={
    ["agricultural-science-pack"]=pack("item","agricultural-science-pack",{
      icons={{icon="agri-base.png",icon_size=64},
        {icon="agri-tint.png",icon_size=64,tint={r=1,g=1,b=1}}},
      pictures={"belt-only.png"},spoil_ticks=3600,spoil_result="spoilage",
      localised_name={"item-name.agricultural-science-pack"}
    })
  },
  tool={
    ["automation-science-pack"]=pack("tool","automation-science-pack",{
      pictures={"belt-only.png"}
    }),
    ["aerospace-science-pack"]=pack("tool","aerospace-science-pack",{
      icons={{icon="aerospace.png",icon_size=64}}
    }),
    ["orbital-science-pack"]=pack("tool","orbital-science-pack"),
    ["kr-matter-tech-card"]=pack("tool","kr-matter-tech-card"),
    ["research-data"]=pack("tool","research-data")
  },
  technology={
    farming={name="farming",unit={count=100,time=20,ingredients={
      {"automation-science-pack",2},{"agricultural-science-pack",3}
    }}},
    orbit={name="orbit",unit={ingredients={
      {type="item",name="aerospace-science-pack",amount=4},
      {type="item",name="orbital-science-pack",amount=5}
    }}},
    vanilla={name="vanilla",unit={ingredients={
      {"kr-matter-tech-card",1},{"research-data",2}
    }}},
    x={name="x",effects={
      {type="unlock-recipe",recipe="agricultural-source-a"},
      {type="unlock-recipe",recipe="agricultural-source-b"}
    }},
    z={name="z",effects={
      {type="unlock-recipe",recipe="agricultural-source-a"}
    }},
    y={name="y",effects={
      {type="unlock-recipe",recipe="aerospace-source"}
    }}
  },
  lab={
    lab={inputs={"automation-science-pack","agricultural-science-pack"}},
    moon={inputs={"aerospace-science-pack","orbital-science-pack"}}
  },
  ["item-group"]={science={}},
  ["item-subgroup"]={},
  recipe={
    ["automation-source"]=source_recipe(
      "automation-source","automation-science-pack",nil),
    ["agricultural-source-a"]=source_recipe(
      "agricultural-source-a","agricultural-science-pack",false),
    ["agricultural-source-b"]=source_recipe(
      "agricultural-source-b","agricultural-science-pack",false),
    ["aerospace-source"]=source_recipe(
      "aerospace-source","aerospace-science-pack",false),
    -- Open at start, but they only turn the pack back into itself.
    ["agricultural-preservation"]={type="recipe",name="agricultural-preservation",
      ingredients={{type="item",name="agricultural-science-pack",amount=1}},
      results={{type="item",name="agricultural-science-pack-preserved",amount=1}}},
    ["agricultural-depreservation"]={type="recipe",name="agricultural-depreservation",
      ingredients={{type="item",name="agricultural-science-pack-preserved",amount=1}},
      results={{type="item",name="agricultural-science-pack",amount=1}}},
    ["agricultural-preserved-infusion"]={type="recipe",name="agricultural-preserved-infusion",
      ingredients={{type="item",name="agricultural-science-pack-preserved",amount=1}},
      results={{type="item",name="agricultural-science-pack-preserved",amount=1}}},
    ["agricultural-upcycling"]={type="recipe",name="agricultural-upcycling",
      ingredients={{type="item",name="agricultural-science-pack",amount=2}},
      results={{type="item",name="agricultural-science-pack",amount=1}}}
  }
}}
function data:extend(prototypes)
  for _,prototype in ipairs(prototypes) do
    self.raw[prototype.type]=self.raw[prototype.type] or {}
    self.raw[prototype.type][prototype.name]=prototype
  end
end
local messages={}
settings={startup={
  ["razi-difficulty-preset"]={value="normal"},
  ["razi-auto-tech-cards"]={value=false}
}}
log=function(message) messages[#messages+1]=message end
local Difficulty=require("scripts.razi_difficulty_presets")
local auto=require("prototypes.compat.auto_tech_cards")
check(Difficulty.effective("razi-auto-tech-cards",false)==false,
  "Normal must leave automatic cards off")
auto.data_final_fixes()
check(not data.raw.tool["razi-automation-science-pack-tech-card"]
  and not data.raw.item["razi-agricultural-science-pack-tech-card"],
  "Disabled setting must not create cards")
check(data.raw.technology.farming.unit.ingredients[1][1]
  =="automation-science-pack"
  and data.raw.technology.farming.unit.ingredients[2][1]
  =="agricultural-science-pack",
  "Disabled setting must not change research")
check(#data.raw.lab.lab.inputs==2,"Disabled setting must not change labs")

settings.startup["razi-difficulty-preset"].value="hard"
check(Difficulty.effective("razi-auto-tech-cards",false)==true,
  "Hard must enable automatic cards")
auto.data_final_fixes()

local cards={
  ["automation-science-pack"]="razi-automation-science-pack-tech-card",
  ["agricultural-science-pack"]="razi-agricultural-science-pack-tech-card",
  ["aerospace-science-pack"]="razi-aerospace-science-pack-tech-card",
  ["orbital-science-pack"]="razi-orbital-science-pack-tech-card"
}
for source,card in pairs(cards) do
  check((data.raw.tool[card] or data.raw.item[card])~=nil,
    "Missing card for "..source)
end
check(not data.raw.tool["razi-kr-matter-tech-card-tech-card"],
  "Krastorio tech cards must not be copied")
check(not data.raw.tool["razi-research-data-tech-card"],
  "Research data must not be copied")

local farming=data.raw.technology.farming.unit.ingredients
check(farming[1][1]==cards["automation-science-pack"]
  and farming[1][2]==2,"Array research ingredient must retain its amount")
check(farming[2][1]==cards["agricultural-science-pack"]
  and farming[2][2]==3,"Array research ingredient must retain its amount")
local orbit=data.raw.technology.orbit.unit.ingredients
check(orbit[1].name==cards["aerospace-science-pack"]
  and orbit[1].amount==4,"Named research ingredient must retain its amount")
check(orbit[2].name==cards["orbital-science-pack"]
  and orbit[2].amount==5,"Research with no source recipe must be converted")
local vanilla=data.raw.technology.vanilla.unit.ingredients
check(vanilla[1][1]=="kr-matter-tech-card"
  and vanilla[2][1]=="research-data",
  "Excluded research ingredients must stay unchanged")

local agri=data.raw.item[cards["agricultural-science-pack"]]
local automation=data.raw.tool[cards["automation-science-pack"]]
check(agri.spoil_ticks==3600 and agri.spoil_result=="spoilage",
  "Card must preserve source spoilage")
check(agri.pictures==nil and automation.pictures==nil,
  "Cards must not reuse source belt pictures")
check(agri.icon==nil and agri.icon_size==nil,
  "Card must use icon layers only")
check(#agri.icons==3,"Source icon layers plus one mark are required")
check(#automation.icons==2 and automation.icons[1].icon=="automation-science-pack.png",
  "Single source icon must be wrapped as a layer")
local mark=agri.icons[#agri.icons]
check(mark.icon=="__base__/graphics/icons/lab.png" and mark.icon_size==64
  and mark.scale==0.25 and mark.shift[1]==8 and mark.shift[2]==8,
  "Lab icon must be the final mark layer")
check(agri.localised_name[1]=="razi-auto-card.name"
  and agri.localised_name[2]==data.raw.item["agricultural-science-pack"].localised_name,
  "Card name must use the source localized name")
check(automation.localised_name[1]=="razi-auto-card.name"
  and automation.localised_name[2][1]=="item-name.automation-science-pack",
  "Missing source name must fall back to the item-name key")
check(agri.localised_description[1]=="razi-auto-card.description",
  "Card description must use the localized key")

local function card_recipe(source)
  return data.raw.recipe["razi-convert-"..source.."-tech-card"]
end
local automation_recipe=card_recipe("automation-science-pack")
local agri_recipe=card_recipe("agricultural-science-pack")
local aerospace_recipe=card_recipe("aerospace-science-pack")
local orbital_recipe=card_recipe("orbital-science-pack")
check(automation_recipe.enabled==true,
  "Card from a source recipe enabled at start must be enabled at start")
check(agri_recipe.enabled==false and aerospace_recipe.enabled==false,
  "Technology-gated source recipes must keep card recipes locked")
for _,technology in ipairs({"x","z"}) do
  local found=false
  local effects=data.raw.technology[technology].effects --[[@as table]]
  for _,effect in ipairs(effects) do
    if effect.recipe=="razi-convert-agricultural-science-pack-tech-card" then found=true end
  end
  check(found,"The card must unlock with the pack recipe in "..technology)
end
check(orbital_recipe.enabled==true,
  "A card with no source recipe must be enabled at start")
check(agri_recipe.categories[1]=="crafting"
  and agri_recipe.ingredients[1].amount==1
  and agri_recipe.energy_required==0.5,
  "Conversion recipe must use the intended one-to-one crafting cost")
check(agri_recipe.results[1].name==cards["agricultural-science-pack"]
  and agri_recipe.results[1].reset_freshness_on_craft==false,
  "Conversion must preserve spoilage instead of refreshing the result")
check(agri_recipe.allow_productivity==false
  and agri_recipe.maximum_productivity==0
  and agri_recipe.auto_recycle==false
  and agri_recipe.allow_decomposition==false,
  "Conversion recipe must block productivity and recycling")
check(agri_recipe.icon==nil and agri_recipe.icon_size==nil
  and #agri_recipe.icons==3
  and agri_recipe.icons[3].icon=="__base__/graphics/icons/lab.png",
  "Recipe must use the marked card icon")
check(agri_recipe.localised_name[1]=="razi-auto-card.name"
  and agri_recipe.localised_description[1]=="razi-auto-card.description",
  "Conversion recipe must use the card localization keys")

local function unlock_count(technology_name,recipe_name)
  local total=0
  for _,effect in ipairs(data.raw.technology[technology_name].effects or {}) do
    if effect.type=="unlock-recipe" and effect.recipe==recipe_name then
      total=total+1
    end
  end
  return total
end
local agri_recipe_name="razi-convert-agricultural-science-pack-tech-card"
check(unlock_count("x",agri_recipe_name)==1
  and unlock_count("z",agri_recipe_name)==1,
  "Every unlocking technology must unlock the card exactly once")
check(unlock_count("y","razi-convert-aerospace-science-pack-tech-card")==1,
  "Aerospace card must follow its source technology")

local function contains(list,value)
  for _,entry in ipairs(list) do
    if entry==value then return true end
  end
  return false
end
check(contains(data.raw.lab.lab.inputs,cards["automation-science-pack"])
  and contains(data.raw.lab.lab.inputs,cards["agricultural-science-pack"])
  and contains(data.raw.lab.lab.inputs,"agricultural-science-pack"),
  "Labs must accept cards alongside their source packs")
check(not contains(data.raw.lab.lab.inputs,cards["aerospace-science-pack"])
  and contains(data.raw.lab.moon.inputs,cards["aerospace-science-pack"])
  and contains(data.raw.lab.moon.inputs,cards["orbital-science-pack"]),
  "Each lab must accept only cards for its native inputs")

local card_count=0
for _,card_name in pairs(cards) do
  if data.raw.tool[card_name] or data.raw.item[card_name] then
    card_count=card_count+1
  end
end
check(card_count==4,"Exactly four cards should be generated")
check(messages[#messages]
  =="[Razi Protocol/tech-cards] 4 cards, 4 research ingredients, 2 cards open from the start",
  "The result log must report card and research counts")

auto.data_final_fixes()
local cards_after_second_pass=0
for _,card_name in pairs(cards) do
  if data.raw.tool[card_name] or data.raw.item[card_name] then
    cards_after_second_pass=cards_after_second_pass+1
  end
end
check(cards_after_second_pass==4 and unlock_count("x",agri_recipe_name)==1,
  "A second pass must not add duplicate cards or unlock effects")
print("auto tech cards: synthetic Factorio research and lab fixture passed")
