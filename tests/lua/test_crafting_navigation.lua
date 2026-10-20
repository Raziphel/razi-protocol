---@diagnostic disable: missing-fields
-- Recipe-visibility smoke tests, including source-mod and character categories.
local navigation = dofile("prototypes/compat/crafting_navigation.lua")
local function check(predicate, message)
  if not predicate then error(message,2) end
end

local function fixture(mode, spoilables, barrels)
  local raw = {
    ["item-group"] = {fluids={},["intermediate-products"]={}},
    ["item-subgroup"] = {
      ["fluid-recipes"]={group="fluids"},
      ["intermediate-product"]={group="intermediate-products"}
    },
    character = {character={crafting_categories={"crafting","special-hand"}}},
    ["god-controller"] = {god={crafting_categories={"sandbox-craft"}}},
    item = {["fresh-gel"]={spoil_ticks=300,subgroup="intermediate-product"}},
    recipe = {
      ["hand-gear"]={category="crafting",enabled=false},
      ["default-category"]={ingredients={{type="item",name="iron-plate",amount=1}}},
      ["hybrid-machine"]={categories={"chemistry","crafting"}},
      ["special-hand"]={category="special-hand"},
      ["sandbox-only"]={categories={"sandbox-craft"}},
      ["machine-metallurgy"]={category="metallurgy"},
      ["razi-machine-metallurgy"]={categories={"metallurgy"}},
      ["fluid-chemical"]={category="chemistry",ingredients={{type="fluid",name="water",amount=10}}},
      ["fluid-mixed"]={categories={"crafting","chemistry"},ingredients={{type="fluid",name="water",amount=10}}},
      ["already-hidden"]={category="chemistry",hide_from_player_crafting=true},
      ["fully-hidden"]={category="chemistry",hidden=true},
      ["fill-water-barrel"]={
        category="crafting-with-fluid",subgroup="fluid-recipes",
        ingredients={{type="fluid",name="water",amount=50},
          {type="item",name="empty-barrel",amount=1}},
        results={{type="item",name="water-barrel",amount=1}}
      },
      ["empty-water-barrel"]={
        category="crafting-with-fluid",subgroup="fluid-recipes",
        ingredients={{type="item",name="water-barrel",amount=1}},
        results={{type="fluid",name="water",amount=50},
          {type="item",name="empty-barrel",amount=1}}
      },
      ["fresh-gel"]={
        category="crafting",subgroup="intermediate-product",
        results={{type="item",name="fresh-gel",amount=1}}
      }
    }
  }
  rawset(_G,"data",{
    raw=raw,
    extend=function(_,records)
      for _,proto in ipairs(records) do
        raw["item-subgroup"][proto.name]=proto
      end
    end
  })
  rawset(_G,"settings",{startup={
    ["razi-group-barreling-recipes"]={value=barrels},
    ["razi-group-spoilable-recipes"]={value=spoilables},
    ["razi-hand-crafting-cleanup"]={value=mode}
  }})
  return raw.recipe,raw
end

local recipes = fixture("all",true,true)
navigation.data_final_fixes()
for _, name in ipairs({"hand-gear","default-category","hybrid-machine",
    "special-hand","sandbox-only","fresh-gel"}) do
  check(not recipes[name].hide_from_player_crafting,
    "Player-craftable recipe hidden: "..name)
end
for _, name in ipairs({"machine-metallurgy","razi-machine-metallurgy",
    "fluid-chemical","fluid-mixed","fill-water-barrel",
    "empty-water-barrel"}) do
  check(recipes[name].hide_from_player_crafting == true,
    "Machine-only recipe not hidden: "..name)
end
check(recipes["hand-gear"].enabled == false,
  "Technology-locked recipe enablement changed")
check(recipes["already-hidden"].hide_from_player_crafting == true
  and recipes["fully-hidden"].hidden == true,
  "Existing source visibility was overridden")
check(recipes["fill-water-barrel"].subgroup == "razi-fluid-barreling"
  and recipes["empty-water-barrel"].subgroup == "razi-fluid-barreling",
  "Barrel grouping did not survive hand-crafting cleanup")
check(recipes["fresh-gel"].subgroup == "razi-perishable-products",
  "Spoilable grouping did not survive hand-crafting cleanup")

recipes = fixture("razi",false,true)
navigation.data_final_fixes()
check(not recipes["machine-metallurgy"].hide_from_player_crafting,
  "Razi-only mode changed another mod's machine recipes")
check(recipes["razi-machine-metallurgy"].hide_from_player_crafting == true,
  "Razi-only mode failed to hide a Razi recipe")
check(recipes["fresh-gel"].subgroup == "intermediate-product",
  "Disabled spoilable option still moved source recipes")
check(recipes["fill-water-barrel"].subgroup == "razi-fluid-barreling",
  "Barrel option should work independently of cleanup scope")

recipes = fixture("off",false,false)
navigation.data_final_fixes()
check(not recipes["machine-metallurgy"].hide_from_player_crafting
  and not recipes["razi-machine-metallurgy"].hide_from_player_crafting,
  "Off mode did not preserve source crafting menu")
check(recipes["fill-water-barrel"].subgroup == "fluid-recipes",
  "Disabled barrel option still moved source recipes")
check(recipes["fresh-gel"].subgroup == "intermediate-product",
  "Disabled spoilable option still moved source recipes")

print("Razi hand-crafting recipe cleanup and grouping fixtures passed")
