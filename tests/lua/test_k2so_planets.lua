---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(value, msg) if not value then error(msg, 2) end end
local function setup(k2)
  local raw={
    item={["oxygen"]={hidden=true},["kr-oxygen"]={},
      ["hydrogen"]={hidden=true},["kr-hydrogen"]={},
      ["sand"]={hidden=true},["kr-sand"]={},
      ["kr-metallurgic-research-data"]={},
      ["kr-agricultural-research-data"]={},
      ["kr-cryogenic-research-data"]={},
      ["custom-hidden"]={hidden=true},["kr-custom-hidden"]={}},
    fluid={["oxygen"]={hidden=true},["kr-oxygen"]={},
      ["hydrogen"]={},["kr-hydrogen"]={hidden=true}},
    tool={["solaris-tech-card"]={},["nyxaris-tech-card"]={},
      ["vespera-tech-card"]={}},
    planet={vulcanus={},gleba={},aquilo={}},
    recipe={
      ["planet-oxygen"]={ingredients={{type="fluid",name="oxygen",amount=10}},
        results={{type="fluid",name="oxygen",amount=20}},main_product="oxygen"},
      ["planet-sand"]={ingredients={{type="item",name="sand",amount=5}},
        results={{type="item",name="sand",amount=2}}},
      ["nulls-common-fluid"]={ingredients={{type="fluid",name="hydrogen",amount=5}}},
      ["missing-material"]={ingredients={{type="item",name="unused",amount=1}}},
      ["unrelated-mod"]={ingredients={{type="item",name="custom-hidden",amount=1}}},
      ["old-expensive-only"]={expensive={ingredients={{type="item",name="sand",amount=1}}}},
      ["kr-metallurgic-research-data"]={results={{type="item",name="kr-metallurgic-research-data",amount=1}}},
      ["kr-agricultural-research-data"]={results={{type="item",name="kr-agricultural-research-data",amount=1}}},
      ["kr-cryogenic-research-data"]={results={{type="item",name="kr-cryogenic-research-data",amount=1}}},
      ["solaris-tech-card"]={ingredients={{type="item",name="calidus-tech-card",amount=1}}},
      ["nyxaris-tech-card"]={ingredients={{type="item",name="calidus-tech-card",amount=1}}},
      ["vespera-tech-card"]={ingredients={{type="item",name="solaris-tech-card",amount=1}}}
    },
    resource={["k2-ore"]={minable={results={{type="item",name="sand",amount=3}}}}},
    ["simple-entity"]={["debris"]={minable={result="sand"}}},
    ["simple-entity-with-owner"]={["rock"]={minable={
      results={{type="item",name="sand",amount=1}}}}},
    tree={["dry-tree"]={minable={result="sand"}}},
    fish={["fish-ore"]={minable={results={{type="item",name="sand",amount=1}}}}},
    technology={["planet-oxygen-trigger"]={
      research_trigger={type="craft-fluid",fluid="oxygen"}}},
    tile={["gas-lake"]={fluid="oxygen"}}
  }
  rawset(_G,"data",{raw=raw})
  rawset(_G,"mods",k2 and {["Krastorio2-spaced-out"]="2.0.17"} or {})
  package.loaded["prototypes.compatibility.Krastorio2-spaced-out.k2so_planet_integration"]=nil
  return raw,require("prototypes.compatibility.Krastorio2-spaced-out.k2so_planet_integration")
end
local raw,mod=setup(true)
package.loaded["prototypes.fixes.Krastorio2-spaced-out.renamed_research_triggers"]=nil
local triggers=require("prototypes.fixes.Krastorio2-spaced-out.renamed_research_triggers")
triggers.data_final_fixes()
check(raw.technology["planet-oxygen-trigger"].research_trigger.fluid=="oxygen",
  "Early scan wrongly rewrote a still-producible native oxygen output")
mod.data_final_fixes()
triggers.data_final_fixes()
check(raw.technology["planet-oxygen-trigger"].research_trigger.fluid=="kr-oxygen",
  "Late normalized oxygen recipe left its research trigger stranded")
check(raw.recipe["planet-oxygen"].ingredients[1].name=="kr-oxygen",
  "K2SO hidden oxygen was not reconciled")
check(raw.recipe["planet-oxygen"].results[1].name=="kr-oxygen",
  "K2SO oxygen product was not reconciled")
check(raw.recipe["planet-oxygen"].main_product=="kr-oxygen",
  "Recipe main product was left obsolete")
check(raw.recipe["planet-sand"].ingredients[1].name=="kr-sand",
  "Hidden sand ingredient remained in another planet")
check(raw.recipe["nulls-common-fluid"].ingredients[1].name=="hydrogen",
  "Null's visible common hydrogen fluid was overwritten")
check(raw.recipe["missing-material"].ingredients[1].name=="unused",
  "Unknown modded material was changed")
check(raw.recipe["unrelated-mod"].ingredients[1].name=="custom-hidden",
  "Non-K2SO hidden material was modified")
check(raw.recipe["old-expensive-only"].expensive.ingredients[1].name=="kr-sand",
  "Old expensive-only recipe variant was missed")
check(raw.resource["k2-ore"].minable.results[1].name=="kr-sand",
  "Planet mining output was not standardized")
check(raw["simple-entity"].debris.minable.result=="kr-sand",
  "Debris minable output was not standardized")
check(raw["simple-entity-with-owner"].rock.minable.results[1].name=="kr-sand",
  "Mineable owned scenery still produces hidden sand")
check(raw.tree["dry-tree"].minable.result=="kr-sand",
  "Mineable planet tree still produces hidden sand")
check(raw.fish["fish-ore"].minable.results[1].name=="kr-sand",
  "Mineable fish entity still produces hidden sand")
check(raw.tile["gas-lake"].fluid=="kr-oxygen",
  "Planet tile fluid was not standardized")
-- K2SO research data is never an ingredient in Razi's system cards.
-- The actual science packs and predecessor system cards remain as designed.
for _, spec in ipairs({
  {"solaris-tech-card","calidus-tech-card"},
  {"nyxaris-tech-card","calidus-tech-card"},
  {"vespera-tech-card","solaris-tech-card"}
}) do
  local card=raw.recipe[spec[1]]
  check(#card.ingredients==1 and card.ingredients[1].name==spec[2],
    "K2SO modified the system card recipe "..spec[1])
end
mod.data_final_fixes()
check(#raw.recipe["solaris-tech-card"].ingredients==1,
  "Repeat integration modified Solaris's ingredients")
check(raw.recipe["vibrant-tech-card"]==nil,
  "Missing optional recipe was invented")

local absent,disabled=setup(false)
disabled.data_final_fixes()
check(absent.recipe["planet-oxygen"].ingredients[1].name=="oxygen",
  "K2SO-disabled integration touched the recipe")
check(#absent.recipe["solaris-tech-card"].ingredients==1,
  "K2SO-disabled integration changed research cards")

-- Existing non-K2SO compatibility patches can retain the common fluid.
local common,enabled=setup(true)
common.fluid.oxygen.hidden=false
common.fluid["kr-oxygen"].hidden=true
enabled.data_final_fixes()
check(common.recipe["planet-oxygen"].ingredients[1].name=="oxygen",
  "Visible source fluid was overwritten by hidden K2SO fluid")

-- All eight Razi system cards stay unchanged even when all K2SO research-data
-- items, native production recipes and owner planets are available.
local cards={
  "calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
  "vibrant-tech-card","vespera-tech-card","beetlejuice-tech-card",
  "umbra-tech-card","deep-space-tech-card"
}
local data_items={
  "kr-metallurgic-research-data","kr-agricultural-research-data",
  "kr-electromagnetic-research-data","kr-cryogenic-research-data",
  "kr-matter-research-data","kr-promethium-research-data"
}
for _,level in ipairs({"normal","easy","hard","nightmare","custom"}) do
  local world,compat=setup(true)
  rawset(_G,"settings",{startup={
    ["razi-difficulty-preset"]={value=level},
    ["razi-planetary-interdependence"]={value="deep"}
  }})
  for _,name in ipairs(data_items) do
    world.item[name]={}
    world.recipe[name]={results={{type="item",name=name,amount=1}}}
  end
  for index,name in ipairs(cards) do
    world.tool[name]={}
    world.recipe[name]={ingredients={
      {type="item",name="automation-science-pack",amount=2},
      {type="item",name=index==1 and "space-science-pack"
        or cards[index-1],amount=1}
    }}
  end
  compat.data_final_fixes()
  compat.data_final_fixes()
  for index,name in ipairs(cards) do
    local ingredients=world.recipe[name].ingredients
    check(#ingredients==2 and ingredients[1].name=="automation-science-pack"
      and ingredients[1].amount==2
      and ingredients[2].name==(index==1 and "space-science-pack"
        or cards[index-1]) and ingredients[2].amount==1,
      level.." K2SO integration changed normal system card ingredients: "..name)
    for _,input in ipairs(ingredients) do
      check(not input.name:find("research-data",1,true),
        level.." adds research data to "..name)
    end
  end
end
rawset(_G,"settings",nil)

-- Missing owner worlds must not make an otherwise valid recipe fail.
local lost,lost_mod=setup(true)
lost.planet.vulcanus=nil
lost_mod.data_final_fixes()
check(#lost.recipe["solaris-tech-card"].ingredients==1
  and #lost.recipe["nyxaris-tech-card"].ingredients==1,
  "Removing a planet must not introduce research-data ingredients")

-- Off mode also preserves cards while still unifying hidden K2SO materials.
local off,off_mod=setup(true)
rawset(_G,"settings",{startup={}})
settings.startup["razi-planetary-interdependence"]={value="off"} -- luacheck: ignore 122
off_mod.data_final_fixes()
rawset(_G,"settings",nil)
check(#off.recipe["solaris-tech-card"].ingredients==1
  and #off.recipe["nyxaris-tech-card"].ingredients==1
  and #off.recipe["vespera-tech-card"].ingredients==1,
  "Off mode still added research data to the system cards")
check(off.recipe["planet-sand"].ingredients[1].name=="kr-sand",
  "Off mode skipped the K2SO material replacement")

local f=assert(io.open("data-final-fixes.lua","r"))
local source=f:read("*a")
f:close()
local layout=assert(source:find('require("prototypes.world.starmap.galaxy_layout").data_final_fixes()',1,true))
local integration=assert(source:find('require("prototypes.compatibility.Krastorio2-spaced-out.k2so_planet_integration").data_final_fixes()',1,true))
check(integration>layout,"K2SO reconciliation should run after planet layout")
local late=assert(source:find(
  'require("prototypes.fixes.Krastorio2-spaced-out.renamed_research_triggers").data_final_fixes()',
  integration+1,true))
check(late>integration,"The last research trigger repair must follow material normalization")
print("K2SO material compatibility and system-card research-data exclusion passed")
