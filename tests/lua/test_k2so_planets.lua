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
  package.loaded["prototypes.compat.k2so_planet_integration"]=nil
  return raw,require("prototypes.compat.k2so_planet_integration")
end
local raw,mod=setup(true)
package.loaded["prototypes.compat.renamed_research_triggers"]=nil
local triggers=require("prototypes.compat.renamed_research_triggers")
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
for _, spec in ipairs({
  {"solaris-tech-card","kr-metallurgic-research-data"},
  {"nyxaris-tech-card","kr-agricultural-research-data"},
  {"vespera-tech-card","kr-cryogenic-research-data"}
}) do
  local card=raw.recipe[spec[1]]
  check(#card.ingredients==2 and card.ingredients[#card.ingredients].name==spec[2],
    "K2SO data was not integrated into "..spec[1])
end
mod.data_final_fixes()
check(#raw.recipe["solaris-tech-card"].ingredients==2,
  "Repeat integration duplicated the K2SO data")
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

-- Each family of research data goes into the card of its own system only.
local own,own_mod=setup(true)
own_mod.data_final_fixes()
for _, spec in ipairs({
  {"solaris-tech-card","kr-agricultural-research-data"},
  {"solaris-tech-card","kr-cryogenic-research-data"},
  {"nyxaris-tech-card","kr-metallurgic-research-data"},
  {"nyxaris-tech-card","kr-cryogenic-research-data"},
  {"vespera-tech-card","kr-metallurgic-research-data"}
}) do
  for _, ingredient in ipairs(own.recipe[spec[1]].ingredients) do
    check(ingredient.name~=spec[2],spec[2].." leaked into "..spec[1])
  end
end

-- The owner planet must exist, otherwise the card stays as it was.
local lost,lost_mod=setup(true)
lost.planet.vulcanus=nil
lost_mod.data_final_fixes()
check(#lost.recipe["solaris-tech-card"].ingredients==1,
  "Research data was added for a planet that is not in the game")
check(#lost.recipe["nyxaris-tech-card"].ingredients==2,
  "A missing planet blocked the data of another system")

-- The Off mode keeps the research untouched but still unifies the materials.
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
local layout=assert(source:find('require("prototypes.system.galaxy_layout").data_final_fixes()',1,true))
local integration=assert(source:find('require("prototypes.compat.k2so_planet_integration").data_final_fixes()',1,true))
check(integration>layout,"K2SO reconciliation should run after planet layout")
local late=assert(source:find(
  'require("prototypes.compat.renamed_research_triggers").data_final_fixes()',
  integration+1,true))
check(late>integration,"The last research trigger repair must follow material normalization")
print("K2SO science-data backbone, planet materials and upstream ownership passed")
